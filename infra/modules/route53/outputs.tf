output "record_name" {
    value = aws_route53_record.primary.name
}

output "certificate_arn" {
    value = aws_acm_certificate.cert.arn
}