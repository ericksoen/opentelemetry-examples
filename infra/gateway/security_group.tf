resource "aws_security_group" "allow_otlp" {
  name        = "${var.resource_prefix}-allow-otlp"
  description = "Allow inbound traffic to OTLP port"

  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_security_group_rule" "health_check" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 13133
  to_port   = 13133

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_otlp.id
}

resource "aws_security_group_rule" "otlp" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 4317
  to_port   = 4317

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_otlp.id
}

resource "aws_security_group_rule" "jaeger_ui" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 16686
  to_port   = 16686

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_otlp.id
}

resource "aws_security_group_rule" "zpage" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 55679
  to_port   = 55679

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_otlp.id
}

resource "aws_security_group_rule" "egress" {
  type     = "egress"
  protocol = "all"

  from_port = 0
  to_port   = 0

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_otlp.id
}
