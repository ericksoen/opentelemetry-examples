output "target_group_arn" {
    description = "The target group arn that forwards traffic to the Lambda service"
    value = aws_lb_target_group.lambda.arn
}