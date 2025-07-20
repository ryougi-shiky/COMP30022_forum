# Key Pair for EC2 access
resource "aws_key_pair" "app_server" {
  key_name   = "ani-app-server-key"
  public_key = file("~/.ssh/id_rsa.pub")  # 你需要先生成SSH密钥对
}

# Launch Template with User Data script
resource "aws_launch_template" "app_server" {
  name_prefix   = "ani-app-server-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  key_name      = aws_key_pair.app_server.key_name

  vpc_security_group_ids = [aws_security_group.app_server.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    mongodb_data_dir = "/data/mongodb"
  }))

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }

  # Additional EBS volume for MongoDB data
  block_device_mappings {
    device_name = "/dev/xvdf"
    ebs {
      volume_size = 10
      volume_type = "gp3"
      encrypted   = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ani-app-server"
    }
  }
}

# EC2 Instance
resource "aws_instance" "app_server" {
  launch_template {
    id      = aws_launch_template.app_server.id
    version = "$Latest"
  }

  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name = "ani-app-server"
  }
}

# Elastic IP for stable public address
resource "aws_eip" "app_server" {
  instance = aws_instance.app_server.id
  domain   = "vpc"

  tags = {
    Name = "ani-app-server-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# Data source for Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
