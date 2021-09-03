data "aws_iam_policy_document" "doc" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

  }
}

resource "aws_iam_role" "task" {

  name_prefix = "${var.resource_prefix}-"

  assume_role_policy = data.aws_iam_policy_document.doc.json
}

resource "aws_iam_role_policy_attachment" "cw" {
  role       = aws_iam_role.task.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  role       = aws_iam_role.task.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_task" {
  role       = aws_iam_role.task.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}