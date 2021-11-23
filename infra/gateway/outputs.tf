output "otlp_grpc_hostname" {
  value = module.nlb.record_name
}

output "otlp_https_hostname" {
  value = module.alb.record_name
}