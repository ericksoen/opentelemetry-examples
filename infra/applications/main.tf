locals {
  primary_rest_resource   = "ecs"
  secondary_rest_resource = "ec2"

  tertiary_rest_resource = "lambda"

  quatenary_rest_resource = "lambda-python"
}

module "ecs" {
  source = "./ecs"

  source_security_group_id = aws_security_group.alb_sg.id

  server_hostname         = module.app.record_name
  server_request_resource = local.secondary_rest_resource
  health_check_path       = "/status"

  subnet_ids       = data.aws_subnet_ids.service.ids
  vpc_id           = data.aws_vpc.vpc.id
  assign_public_ip = local.use_public_service_ips
  resource_prefix  = var.resource_prefix

  region_name           = local.region_name
  image_repository_name = var.image_repository

  otlp_hostname = var.otlp_grpc_hostname
}

module "ec2" {
  source = "./ec2"

  source_security_group_id = aws_security_group.alb_sg.id

  server_hostname         = module.app.record_name
  server_request_resource = "/${local.tertiary_rest_resource}"
  health_check_path       = "/status"

  assign_public_ip = local.use_public_service_ips
  subnet_ids       = data.aws_subnet_ids.service.ids
  vpc_id           = data.aws_vpc.vpc.id

  resource_prefix = var.resource_prefix

  otlp_hostname = var.otlp_grpc_hostname
}

module "lambda" {
  source               = "../modules/lambda"
  lambda_artifact_path = "../../src/dist/otlp_lambda.zip"
  resource_prefix      = var.resource_prefix
  resource_suffix      = "lambda"

  vpc_id                   = data.aws_vpc.vpc.id
  subnet_ids               = local.lambda_subnets
  source_security_group_id = aws_security_group.alb_sg.id

  lambda_handler     = "index.handler"
  lambda_runtime     = "nodejs12.x"
  lambda_memory_size = 512
  lambda_timeout     = 10

  lambda_layers       = ["arn:aws:lambda:${local.region_name}:901920570463:layer:aws-otel-nodejs-ver-1-0-0:1"]
  lambda_tracing_mode = "Active"

  environment_variables = {
    OPENTELEMETRY_COLLECTOR_CONFIG_FILE = "/var/task/config.yaml"
    OTLP_GATEWAY_HOST                   = var.otlp_grpc_hostname
    NODE_OPTIONS                        = "--require lambda-wrapper"

    # From observationsd, using the AWS_LAMBDA_EXEC_WRAPPER and the packaged lambda-wrapper.js
    # provide a similar function. At development time, the AWS_LAMBDA_EXEC_WRAPPER provided
    # less consistent results. See also: https://dev.to/aspecto/how-to-use-opentelemetry-with-aws-lambda-87l
    # AWS_LAMBDA_EXEC_WRAPPER             = "/opt/otel-instrument"
  }
  use_existing_cloudwatch_log_group = var.use_existing_cloudwatch_log_group
}

module "lambda_python" {
  source               = "../modules/lambda"
  lambda_artifact_path = "../../src/dist/otlp_python_lambda.zip"

  resource_prefix = var.resource_prefix
  resource_suffix = "python-lambda"

  vpc_id                   = data.aws_vpc.vpc.id
  subnet_ids               = local.lambda_subnets
  source_security_group_id = aws_security_group.alb_sg.id

  lambda_handler     = "main.handler"
  lambda_runtime     = "python3.8"
  lambda_memory_size = 512
  lambda_timeout     = 10

  lambda_layers       = ["arn:aws:lambda:${local.region_name}:901920570463:layer:aws-otel-python38-ver-1-7-1:1"]
  lambda_tracing_mode = "PassThrough"

  environment_variables = {
    AWS_LAMBDA_EXEC_WRAPPER             = "/opt/otel-instrument"
    OPENTELEMETRY_COLLECTOR_CONFIG_FILE = "/var/task/config.yaml"
    OTLP_GATEWAY_HOST                   = var.otlp_grpc_hostname
    OTEL_PROPAGATORS                    = "tracecontext"
  }

  use_existing_cloudwatch_log_group = var.use_existing_cloudwatch_log_group

}

module "proxy" {
  source               = "../modules/lambda"
  lambda_artifact_path = "../../src/dist/lambda.zip"

  resource_prefix = var.resource_prefix
  resource_suffix = "proxy"

  vpc_id                   = data.aws_vpc.vpc.id
  subnet_ids               = local.lambda_subnets
  source_security_group_id = aws_security_group.alb_sg.id

  lambda_handler     = "main.handler"
  lambda_runtime     = "python3.8"
  lambda_memory_size = 512
  lambda_timeout     = 10

  environment_variables = {
    TARGET_BASE_URL        = "https://${module.app.record_name}"
    HTTP_TRACE_GATEWAY_URL = "https://${var.otlp_http_hostname}"
  }

  lambda_tracing_mode = "Active"

  use_existing_cloudwatch_log_group = var.use_existing_cloudwatch_log_group

}