variable "resource_prefix" {
  description = "The prefix/name for all resources"
  default     = "otel-gateway"
}

variable subnet_configuration {
  description = "The subnet configuration to use for your gateway services. The default configuration will launch _all_ services in a public subnet with a public IP."
  type = object({
    prefer_private_ip = bool
    public_subnet_filters = map(any)
    private_subnet_filters = map(any)
  })

  default = {
    prefer_private_ip = false
    public_subnet_filters = {}
    private_subnet_filters = {}
  }

    validation {
        condition = (length(var.subnet_configuration.public_subnet_filters) > 0 
            && (var.subnet_configuration.prefer_private_ip == true ? length(var.subnet_configuration.private_subnet_filters) > 0 : true))
        error_message = "Public subnet filters are _always_ required. Private subnet filters are required when prefer_private_ip == true."
    }
}

variable "vpc_filters" {
  description = "A set of filters used to dynamically identify a single VPC to use"
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