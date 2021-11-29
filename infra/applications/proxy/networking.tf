resource "aws_security_group" "lambda" {

  count = length(var.subnet_ids) > 0 ? 1 : 0
  name        = "${var.resource_prefix}-proxy-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from LB"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"

    security_groups = [var.source_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}