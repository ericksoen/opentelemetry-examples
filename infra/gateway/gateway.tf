resource "aws_ecs_cluster" "cluster" {
  name = "${var.resource_prefix}"

  capacity_providers = ["FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 1
  }
}

resource "aws_ecs_service" "gateway" {
  name            = "${var.resource_prefix}"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnet_ids.private.ids
    security_groups  = [aws_security_group.allow_otlp.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.otlp.arn
    container_name   = "${var.resource_prefix}"

    container_port = 4317
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.jaeger_ui.arn
    container_name   = "${var.resource_prefix}-jaeger"

    container_port = 16686
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.telemetry.arn
    container_name   = "${var.resource_prefix}"

    container_port = 55679
  }

  depends_on = [
    aws_iam_role.task,
    aws_lb_target_group.otlp,
    aws_lb_target_group.jaeger_ui,
    aws_lb_target_group.telemetry,
  ]
}

resource "aws_ecs_task_definition" "gateway" {
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
      image     = "${var.image_repository}:dev"
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
      secrets = [
        {
          "name" : "HONEYCOMB_WRITE_KEY",
          "valueFrom" : aws_ssm_parameter.honeycomb_write_key.arn
        },
        {
          "name" : "HONEYCOMB_DATASET",
          "valueFrom" : aws_ssm_parameter.honeycomb_dataset.arn
        }
      ]
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = 4317
          hostPort      = 4317
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
        }
      ]
    },
    {
      name      = "${var.resource_prefix}-jaeger"
      image     = "jaegertracing/all-in-one:latest"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-region        = "${local.region_name}"
          awslogs-group         = "/${var.resource_prefix}"
          awslogs-stream-prefix = "jaeger"
        }
      }
      portMappings = [
        {
          protocol      = "http"
          containerPort = 16686
          hostPort      = 16686
        },
        {
          protocol      = "tcp"
          containerPort = 14268
          hostPort      = 14268
        },
        {
          protocol      = "tcp"
          containerPort = 14250
          hostPort      = 14250
        }
      ]
    }
  ])

  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_ssm_parameter" "honeycomb_write_key" {
  name  = "/${var.resource_prefix}/honeycomb-write-key"
  type  = "String"
  value = var.honeycomb_write_key
}

resource "aws_ssm_parameter" "honeycomb_dataset" {
  name  = "/${var.resource_prefix}/honeycomb-dataset"
  type  = "String"
  value = var.honeycomb_dataset
}
