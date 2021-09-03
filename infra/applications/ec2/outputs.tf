output "target_group_arn" {
    description = "The target group arn that forwards traffic to the instance"
    value = aws_lb_target_group.ec2.arn
}