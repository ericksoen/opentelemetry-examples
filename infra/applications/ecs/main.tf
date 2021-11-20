resource "aws_lb_target_group" "tg" {
  name        = "${var.resource_prefix}-ecs-tg"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled  = true
    path     = "${var.health_check_path}"
    interval = 30
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.resource_prefix}"

  capacity_providers = ["FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 1
  }
}

resource "aws_ecs_service" "ecs" {
  name            = "${var.resource_prefix}"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on = [
    aws_iam_role.task
  ]

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "${var.resource_prefix}"

    container_port = 5000
  }

}

locals {

  # As of 11/20/21, versions subsequent to v0.13.0 do not correctly
  # expand environment variables and instead treat them as string literals
  # Pin to the last known working version until the issue is resolved
  # See: https://github.com/aws-observability/aws-otel-collector/issues/748
  aws_otel_collector_image_version = "v0.13.0"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.resource_prefix}"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.task.arn
  task_role_arn            = aws_iam_role.task.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  container_definitions = jsonencode([
    {
      name      = "${var.resource_prefix}"
      image     = "${var.image_repository_name}:flask"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-region        = "${var.region_name}"
          awslogs-group         = "/${var.resource_prefix}"
          awslogs-stream-prefix = "flask"
        }
      }
      environment : [
        {
          "name" : "PYTHONUNBUFFERED",
          "value" : "1"
        },
        {
          "name" : "OTLP_TARGET",
          "value" : "http://127.0.0.1:4317"
        },
        {
          "name" : "HTTP_REQUEST_TARGET",
          "value" : "https://${var.server_hostname}/${var.server_request_resource}"
        }
      ]
      portMappings = [
        {
          protocol      = "http"
          containerPort = 5000
          hostPort      = 5000
        }
      ]
    },
    {
      name      = "${var.resource_prefix}-agent"
      image     = "amazon/aws-otel-collector:${local.aws_otel_collector_image_version}"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-region        = "${var.region_name}"
          awslogs-group         = "/${var.resource_prefix}"
          awslogs-stream-prefix = "agent"
        }
      },
      secrets = [
        {
          "name": "AOT_CONFIG_CONTENT",
          "valueFrom": aws_ssm_parameter.agent_config.arn
        }
      ]
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = 4317
          hostPort      = 4317
        }
      ]
    }
  ])

}
