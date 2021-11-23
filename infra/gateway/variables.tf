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

variable "default_tags" {
  description = "The tags to assign to all resources"
}


variable "honeycomb_base_config" {
  type = object({
    write_key    = string
    dataset_name = string
  })

  default = {
    dataset_name = ""
    write_key    = ""
  }

  validation {
    condition     = (var.honeycomb_base_config.dataset_name != "" ? var.honeycomb_base_config.write_key != "" : true)
    error_message = "A write key must be provided with a dataset name."
  }
}

variable "honeycomb_refinery_config" {
  type = object({
    write_key    = string
    dataset_name = string
  })

  default = {
    dataset_name = ""
    write_key    = ""
  }

  validation {
    condition     = (var.honeycomb_refinery_config.dataset_name != "" ? var.honeycomb_refinery_config.write_key != "" : true)
    error_message = "A write key must be provided with a dataset name."
  }
}

variable "lightstep_config" {
  type = object({
    access_token = string
  })

  default = {
    access_token = ""
  }
}

variable "newrelic_config" {
  type = object({
    api_key = string
  })

  default = {
    api_key = ""
  }
}
variable "domain" {
  description = "The name of the domain to associate with resources"
}

variable "otlp_subdomain_prefix" {
  description = "The subdomain prefix for OTLP traffic"
  default     = "otlp"
}