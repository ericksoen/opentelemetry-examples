output "target_group_arn" {
  description = "The target group arn that forwards traffic to the Lambda service"
  value       = local.target_group_arn
}