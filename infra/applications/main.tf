locals {
  primary_rest_resource   = "ecs"
  secondary_rest_resource = "ec2"

  tertiary_rest_resource = "lambda"

}

module "ecs" {
  source = "./ecs"

  source_security_group_id = aws_security_group.alb_sg.id

  server_hostname         = module.app.record_name
  server_request_resource = local.secondary_rest_resource
  health_check_path       = "/status"

  subnet_ids      = data.aws_subnet_ids.private.ids
  vpc_id          = data.aws_vpc.vpc.id
  resource_prefix = var.resource_prefix

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

  subnet_ids      = data.aws_subnet_ids.private.ids
  vpc_id          = data.aws_vpc.vpc.id
  resource_prefix = var.resource_prefix

  otlp_hostname = var.otlp_grpc_hostname
}

module "lambda" {
  source = "./lambda"

  resource_prefix = var.resource_prefix
  region_name     = local.region_name

  otlp_hostname            = var.otlp_grpc_hostname
  subnet_ids               = data.aws_subnet_ids.private.ids
  source_security_group_id = aws_security_group.alb_sg.id

  vpc_id = data.aws_vpc.vpc.id
}

module "proxy" {
  source = "./proxy"

  resource_prefix             = var.resource_prefix
  target_base_url             = "https://${module.app.record_name}"
  http_trace_gateway_base_url = "https://${var.otlp_http_hostname}"
  subnet_ids                  = data.aws_subnet_ids.private.ids
  source_security_group_id    = aws_security_group.alb_sg.id

  vpc_id = data.aws_vpc.vpc.id
}