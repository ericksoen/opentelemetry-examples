resource "aws_ecs_cluster" "cluster" {
  name = var.resource_prefix

  capacity_providers = ["FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 1
  }
}

resource "aws_ecs_service" "gateway" {
  name            = var.resource_prefix
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnet_ids.private.ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.otlp.arn
    container_name   = var.resource_prefix

    container_port = 4317
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.otlp_http.arn
    container_name   = var.resource_prefix

    container_port = 4318
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.telemetry.arn
    container_name   = var.resource_prefix

    container_port = 55679
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.metrics.arn
    container_name   = var.resource_prefix

    container_port = 8888
  }

  depends_on = [
    aws_iam_role.task,
    aws_lb_target_group.otlp,
    aws_lb_target_group.telemetry,
    aws_lb_target_group.metrics,
    aws_lb_target_group.otlp_http
  ]
}

locals {

  # As of 11/20/21, versions subsequent to v0.13.0 do not correctly
  # expand environment variables and instead treat them as string literals
  # Pin to the last known working version until the issue is resolved
  # See: https://github.com/aws-observability/aws-otel-collector/issues/748
  aws_otel_collector_image_version = "v0.13.0"

}
resource "aws_ecs_task_definition" "gateway" {
  family                   = var.resource_prefix
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.task.arn
  task_role_arn            = aws_iam_role.task.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048


  container_definitions = jsonencode([
    {
      name      = "${var.resource_prefix}"
      image     = "amazon/aws-otel-collector:${local.aws_otel_collector_image_version}"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-region        = "${local.region_name}"
          awslogs-group         = "/${var.resource_prefix}"
          awslogs-stream-prefix = "collector"
        }
      },
      secrets = local.gateway_remote_environment_variables,
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = 4317
          hostPort      = 4317
        },
        {
          protocol      = "tcp"
          containerPort = 4318
          hostPort      = 4318
        },
        {
          protocol      = "tcp"
          containerPort = 13133
          hostPort      = 13133
        },
        {
          protocol      = "tcp"
          containerPort = 55679
          hostPort      = 55679
        },
        {
          protocol      = "tcp"
          containerPort = 8888
          hostPort      = 8888
        }
      ]
    },
  ])

  # lifecycle {
  #   ignore_changes = [container_definitions]
  # }
}

resource "aws_s3_bucket" "b" {
  bucket_prefix = "${var.resource_prefix}-"

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "bucket-logging-demo"
    target_prefix = "logs/"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.b.id

  block_public_acls   = true
  block_public_policy = true
}