resource "aws_ecs_cluster" "cluster" {
  name = "${var.resource_prefix}"

  capacity_providers = ["FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 1
  }
}

resource "aws_ecs_service" "auth" {
  name            = "${var.resource_prefix}"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.auth.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on = [
    aws_iam_role.task
  ]

  network_configuration {
    subnets          = data.aws_subnet_ids.private.ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.auth.arn
    container_name   = "${var.resource_prefix}"
    container_port   = 8080
  }

}

resource "aws_ecs_task_definition" "auth" {
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
      image     = "jboss/keycloak:latest"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-region        = "${local.region_name}"
          awslogs-group         = "/${var.resource_prefix}"
          awslogs-stream-prefix = "auth"
        }
      },
      environment = [
        {
          "name" : "PROXY_ADDRESS_FORWARDING",
          "value" : "true"
        },
        {
          "name" : "KEYCLOAK_USER",
          "value" : var.keycloak_user
        },
        {
          "name" : "KEYCLOAK_PASSWORD",
          "value" : var.keycloak_password
        }
      ]
      portMappings = [
        {
          protocol      = "http",
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])

  lifecycle {
    ignore_changes = [container_definitions]
  }
}
