variable "resource_prefix" {
  description = "The prefix/name for all resources"
  default     = "otel-gateway"
}

variable "vpc_filters" {
  description = "A set of filters used to dynamically identify a single VPC to use"
  type        = map(any)
}

variable "subnet_filters" {
  description = "A set of filters used to dynamically identify the subnets to associate with your load balancers"
  type        = map(any)
}

variable "private_subnet_filters" {
  description = "A set of filters used to dynamically identify the subnets to associate with your EC2 instances"
  type        = map(any)
}

variable "image_repository" {
  description = "The image id to use"
}

variable "default_tags" {
  description = "The tags to assign to all resources"
}

variable "honeycomb_write_key" {
  description = "The write key to provide as a secret"
}

variable "honeycomb_dataset" {
  description = "The honeycomb dataset to provide as a secret"
}

variable "domain" {
  description = "The name of the domain to associate with resources"
}

variable "otlp_subdomain" {
  description = "The subdomain for OTLP traffic"
  default     = "otlp"
}

variable "app_subdomain" {
  description = "The subdomain for application traffic"
  default     = "demo"
}

variable "jaeger_subdomain" {
  description = "The subdomain for the jaeger UI"
  default     = "jaeger"
}

variable "telemetry_subdomain" {
  description = "The subdomain to review OpenCollector agent telemetry"
  default = "telemetry"
}