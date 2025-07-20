# Service Discovery
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "ani.local"
  description = "Private DNS namespace for Ani services"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" "mongodb" {
  name = "mongodb"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}
