locals {
  create_network = length(var.subnet_ids) > 0 ? true : false
}


resource "aws_security_group" "lambda" {

  count = local.create_network ? 1 : 0
  name        = "${var.resource_prefix}-lambda-sg"
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

  function_name = "${var.resource_prefix}-lambda"
  handler = "index.handler"
  runtime = "nodejs12.x"
  memory_size = 512
  timeout = 10

  create_package = false
  local_existing_package = "${path.module}/../../../src/dist/otlp_lambda.zip"
  layers = ["arn:aws:lambda:${var.region_name}:901920570463:layer:aws-otel-nodejs-ver-1-0-0:1"]

  environment_variables = {
      OPENTELEMETRY_COLLECTOR_CONFIG_FILE = "/var/task/config.yaml"
      OTLP_GATEWAY_HOST                   = var.otlp_hostname
      NODE_OPTIONS = "--require lambda-wrapper"

      # From observationsd, using the AWS_LAMBDA_EXEC_WRAPPER and the packaged lambda-wrapper.js
      # provide a similar function. At development time, the AWS_LAMBDA_EXEC_WRAPPER provided
      # less consistent results. See also: https://dev.to/aspecto/how-to-use-opentelemetry-with-aws-lambda-87l
      # AWS_LAMBDA_EXEC_WRAPPER             = "/opt/otel-instrument"
  }

  publish = true

  create_role = false
  lambda_role = aws_iam_role.iam_for_lambda.arn

  tracing_mode = "Active"

  vpc_subnet_ids = local.create_network ? var.subnet_ids : null
  vpc_security_group_ids = local.create_network ? [aws_security_group.lambda[0].id] : null

  use_existing_cloudwatch_log_group = var.use_existing_cloudwatch_log_group
}

module "alias" {
  source = "terraform-aws-modules/lambda/aws//modules/alias"

  refresh_alias = false

  name = "LIVE"

  function_name = module.lambda.lambda_function_arn
  function_version = module.lambda.lambda_function_version
  create_version_allowed_triggers = false
  
  allowed_triggers = {
    LoadBalancer = {
      service = "elasticloadbalancing"
      source_arn = aws_lb_target_group.lambda.arn
    }
  }
}

resource "aws_lb_target_group" "lambda" {
  name        = "${var.resource_prefix}-lambda-tg"
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = aws_lb_target_group.lambda.arn
  target_id        = module.alias.lambda_alias_arn

}