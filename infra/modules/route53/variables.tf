variable "domain" {
    description = "The primary domain for your record"
}

variable "subdomain" {
    description = "The subdomain to assicate with your record"
}
variable "record_ttl_seconds" {
    description = "The time to live in seconds to associae with Route53 records"
    default = 300
}

variable "route53_zone_id" {
    description = "The zone to associate with your records"
}

variable "records" {
    description = "The list of records to associate with "
    type = list(string)
}