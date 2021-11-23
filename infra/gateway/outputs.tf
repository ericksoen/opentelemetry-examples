output "otlp_hostname" {
  value = module.otlp.record_name
}

output "jaeger_hostname" {
  value = module.jaeger.record_name
}

output "telemetry_hostname" {
  value = module.telemetry.record_name
}