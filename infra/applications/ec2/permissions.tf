resource "aws_iam_role" "ec2_role" {
  name = "${var.resource_prefix}-ec2-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF    
}

data "aws_iam_policy_document" "permission" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.b.arn, "${aws_s3_bucket.b.arn}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ssm:*"]
    resources = [aws_ssm_parameter.config.arn]
  }
}

resource "aws_iam_role_policy" "permission" {
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.permission.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "agent" {
  role       = aws_iam_role.ec2_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.resource_prefix}-profile"
  role = aws_iam_role.ec2_role.name
}