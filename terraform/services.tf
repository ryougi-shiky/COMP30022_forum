# ECS Services
resource "aws_ecs_service" "mongodb" {
  name            = "ani-mongodb"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.mongodb.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.mongodb.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.mongodb.arn
  }

  depends_on = [aws_service_discovery_service.mongodb]
}

resource "aws_ecs_service" "backend" {
  name            = "ani-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 17000
  }

  depends_on = [
    aws_lb_listener.main,
    aws_ecs_service.mongodb
  ]
}

resource "aws_ecs_service" "frontend" {
  name            = "ani-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.main,
    aws_ecs_service.backend
  ]
}
