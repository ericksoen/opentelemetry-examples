output "otlp_insecure_hostname" {
    value = module.otlp_insecure.record_name
}

output "otlp_authorized_hostname" {
    value = module.otlp.record_name
}

output "jaeger_hostname" {
    value = module.jaeger.record_name
}