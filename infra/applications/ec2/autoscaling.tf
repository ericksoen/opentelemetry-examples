resource "aws_lb_target_group" "ec2" {
  name     = "${var.resource_prefix}-lb-ec2-tg"
  port     = 5001
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled  = true
    path     = "${var.health_check_path}"
    interval = 30
  }
}

resource "aws_ssm_parameter" "lambda" {
  name  = "lambda-target-url"
  type  = "String"
  value = "https://${var.server_hostname}${var.server_request_resource}"
}

data "aws_ami" "image" {
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*"]

  }

  most_recent = true
}

resource "aws_launch_template" "instance" {
  name = var.resource_prefix

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  ebs_optimized = true

  iam_instance_profile {
    name = aws_iam_instance_profile.profile.name
  }

  image_id = data.aws_ami.image.id

  instance_market_options {
    market_type = "spot"
  }

  instance_type = "t3.micro"

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = var.assign_public_ip
    security_groups = [aws_security_group.allow_tls.id]
  }

  user_data = base64encode(data.template_file.bootstrap.rendered)
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.resource_prefix}-asg"
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  vpc_zone_identifier       = var.subnet_ids

  target_group_arns = [aws_lb_target_group.ec2.arn]
  launch_template {
    id      = aws_launch_template.instance.id
    version = "$Latest"
  }

}