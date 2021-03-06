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
    subnets          = data.aws_subnet_ids.service.ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = local.use_public_service_ips
  }

  load_balancer {
    target_group_arn = module.nlb_lb.target_group_arns[0]
    container_name   = var.resource_prefix

    container_port = 4317
  }


  load_balancer {
    target_group_arn = module.alb_lb.target_group_arns[0]
    container_name   = var.resource_prefix

    container_port = 55679
  }

  load_balancer {
    target_group_arn = module.alb_lb.target_group_arns[1]
    container_name   = var.resource_prefix

    container_port = 4318
  }

  load_balancer {
    target_group_arn = module.alb_lb.target_group_arns[2]
    container_name   = var.resource_prefix

    container_port = 8888
  }

  depends_on = [
    aws_iam_role.task,
  ]
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
      image     = "amazon/aws-otel-collector"
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