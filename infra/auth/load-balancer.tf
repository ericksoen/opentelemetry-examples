
resource "random_id" "bucket" {
  keepers = {
    bucket_prefix = "${var.resource_prefix}"
  }

  byte_length = 8
}

locals {
  bucket_name = "${random_id.bucket.keepers.bucket_prefix}-${lower(random_id.bucket.hex)}"
}

data "aws_iam_policy_document" "bucket_access" {
  # Enforce AES256 encryption for the bucket 
  statement {
    sid = "DenyUnEncryptedObjectUploads"

    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "AES256",
      ]
    }

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "false",
      ]
    }
  }

  # Enable access for the alb to put objects
  # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::127311923021:root"]
    }

    actions = ["s3:PutObject"]

    resources = ["arn:aws:s3:::${local.bucket_name}/AWSLogs/${local.account_id}/*"]

  }
  statement {
    sid = "ALBLogDeliveryWrite"
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    resources = [
      "arn:aws:s3:::${local.bucket_name}/AWSLogs/${local.account_id}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control",
      ]
    }
  }

  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${local.bucket_name}"]
  }  
}

resource "aws_s3_bucket" "access_logs" {
  bucket = "${local.bucket_name}"

  acl = "private"

  policy = data.aws_iam_policy_document.bucket_access.json
}

resource "aws_lb" "alb" {
  name               = "${var.resource_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.to_lb.id]
  subnets            = data.aws_subnet_ids.subnets.ids

  access_logs {
    bucket = aws_s3_bucket.access_logs.bucket
    enabled = true
  }
    
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = module.auth.certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.auth.arn

  }

  depends_on = [module.auth]

}

resource "aws_lb_target_group" "auth" {
  name        = "${var.resource_prefix}-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id

  health_check {
    healthy_threshold = 10
    unhealthy_threshold = 10

    interval = 60
  }
}

