variable "resource_prefix" {
  description = "The prefix/name for all resources"
  default     = "otel-app"
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

variable "domain" {
  description = "The name of the domain to associate with resources"
}

variable "app_subdomain" {
  description = "The subdomain for application traffic"
  default     = "demo"
}

variable "gateway_bearer_token" {
  description = "The bearer token to use to authenticate RPC requests to the gateway collector"
}

variable "otlp_authorized_hostname" {
  description = "The URL to send OTLP traffic containing an auth token"
}

variable "otlp_insecure_hostname" {
  description = "The URL to send OTLP traffic without an auth token"
}

variable "jaeger_ui_hostname" {
  description = "The URL to load the Jaeger (tracing) application UI"
}