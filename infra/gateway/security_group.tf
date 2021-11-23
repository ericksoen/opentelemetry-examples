# Application Load Balancer Security
resource "aws_security_group" "alb" {
  name        = "${var.resource_prefix}-alb-sg"
  description = "Allow inbound traffic to the load balancer"

  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_security_group_rule" "to_lb" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress" {
  type     = "egress"
  protocol = "all"

  from_port = 0
  to_port   = 0

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group" "ecs" {
  name        = "${var.resource_prefix}-ecs-sg"
  description = "Allows traffic to the otlp service"

  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_security_group_rule" "otlp_http" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 4318
  to_port   = 4318

  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "zpage" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 55679
  to_port   = 55679

  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "metrics" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 8888
  to_port   = 8888

  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs.id
}

# We can restrict access to this SG to traffic that originates
# from the application load balancer since the port is also used
# by health checks for target groups attached to the NLB. 
resource "aws_security_group_rule" "health_check" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 13133
  to_port   = 13133

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "otlp" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 4317
  to_port   = 4317

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "ecs_egress" {
  type     = "egress"
  protocol = "all"

  from_port = 0
  to_port   = 0

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
}