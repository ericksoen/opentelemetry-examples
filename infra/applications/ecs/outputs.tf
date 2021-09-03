output "target_group_arn" {
    description = "The target group arn that forwards traffic to the EC2 service"
    value = aws_lb_target_group.tg.arn
}