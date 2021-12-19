locals {
  create_network = length(var.subnet_ids) > 0 ? true : false
}

resource "aws_security_group" "lambda" {
  count = local.create_network ? 1 : 0

  name        = "${var.resource_prefix}-${var.resource_suffix}-sg"
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

module "lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.resource_prefix}-${var.resource_suffix}"
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  create_package         = false
  local_existing_package = var.lambda_artifact_path

  layers                = var.lambda_layers
  environment_variables = var.environment_variables

  publish = true

  create_role = false
  lambda_role = aws_iam_role.iam_for_lambda.arn

  tracing_mode = var.lambda_tracing_mode

  vpc_subnet_ids         = local.create_network ? var.subnet_ids : null
  vpc_security_group_ids = local.create_network ? [aws_security_group.lambda[0].id] : null

  use_existing_cloudwatch_log_group = var.use_existing_cloudwatch_log_group
}


module "alias" {
  source = "terraform-aws-modules/lambda/aws//modules/alias"

  refresh_alias = false

  name = "LIVE"

  function_name    = module.lambda.lambda_function_arn
  function_version = module.lambda.lambda_function_version

  create_version_allowed_triggers = false
  allowed_triggers = {
    LoadBalancer = {
      service      = "elasticloadbalancing"
      source_arn   = aws_lb_target_group.lambda.arn
      statement_id = "AllowExecutionFromlb"
    }
  }
}


resource "aws_lb_target_group" "lambda" {
  name        = "${var.resource_prefix}-${var.resource_suffix}-tg"
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = aws_lb_target_group.lambda.arn
  target_id        = module.alias.lambda_alias_arn

}