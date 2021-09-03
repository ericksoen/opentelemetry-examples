resource "aws_s3_bucket" "b" {
  bucket_prefix = "${var.resource_prefix}-"

  acl = "private"
}

resource "aws_s3_bucket_object" "app" {
  bucket = aws_s3_bucket.b.id

  key = "scripts/app.py"

  source = "../../src/ec2/app.py"

  etag = filemd5("../../src/ec2/app.py")
}

resource "aws_s3_bucket_object" "requirements" {
  bucket = aws_s3_bucket.b.id

  key = "scripts/requirements.txt"

  source = "../../src/ec2/requirements.txt"

  etag = filemd5("../../src/ec2/requirements.txt")
}

data "template_file" "bootstrap" {
  template = file("${path.module}/bootstrap.template")

  vars = {
    s3_bucket_name   = aws_s3_bucket.b.id
    otel_config_path = aws_ssm_parameter.config.name
    cw_config_path   = aws_ssm_parameter.cw_config.name
  }
}

resource "aws_ssm_parameter" "config" {
  name = "/${var.resource_prefix}-otel-agent-config.yml"
  type = "String"

  value = data.template_file.config.rendered
}

resource "aws_ssm_parameter" "cw_config" {
  name = "/${var.resource_prefix}-cw-agent-config.json"
  type = "String"

  value = file("${path.module}/cw-agent-config.json")
}

data "template_file" "config" {
  template = file("../../src/ec2/otel-agent-config.template")

  vars = {
    OTLP_GATEWAY_HOST_INSECURE = var.otlp_insecure_hostname
  }
}
