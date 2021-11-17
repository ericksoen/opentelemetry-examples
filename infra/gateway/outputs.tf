output "otlp_hostname" {
    value = module.otlp.record_name
}

output "jaeger_hostname" {
    value = module.jaeger.record_name
}