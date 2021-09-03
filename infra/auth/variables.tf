variable "resource_prefix" {
    description = "The prefix to associate with all your resources"
    default = "opentelemetry-auth"
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

variable "domain" {
  description = "The name of the domain to associate with resources"
}

variable "auth_subdomain" {
  description = "The subdomain for the auth UI"
  default     = "auth"
}

variable "keycloak_user" {
    description = "The admin user name to use for Keycloak"
    default = "admin"
}

variable "keycloak_password" {
    description = "The admin password to user for Keycloak"
    default = "admin"
}