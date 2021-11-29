resource "aws_lambda_function" "lambda" {
  filename      = "${path.module}/../../../src/dist/lambda.zip"
  function_name = "${var.resource_prefix}-proxy"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.handler"

  source_code_hash = filebase64sha256("${path.module}/../../../src/dist/lambda.zip")

  runtime     = "python3.8"
  memory_size = 512
  timeout     = 10

  environment {
    variables = {
      TARGET_BASE_URL = var.target_base_url
      HTTP_TRACE_GATEWAY_URL = var.http_trace_gateway_base_url
    }
  }

  dynamic "vpc_config" {
    for_each = aws_security_group.lambda
    content {
      subnet_ids = var.subnet_ids
      security_group_ids = [vpc_config.value["id"]]
    }
  }

  tracing_config {
    mode = "Active"
  }

  publish = true
}

resource "aws_lambda_alias" "alias" {
  name             = "LIVE"
  function_name    = aws_lambda_function.lambda.arn
  function_version = aws_lambda_function.lambda.version
}

resource "aws_lb_target_group" "lambda" {
  name        = "${var.resource_prefix}-proxy-tg"
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = aws_lb_target_group.lambda.arn
  target_id        = aws_lambda_alias.alias.arn

  depends_on = [aws_lambda_permission.with_lb]
}

resource "aws_lambda_permission" "with_lb" {
  statement_id  = "AllowExecutionFromlb"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda.arn
  qualifier     = aws_lambda_alias.alias.name
}
