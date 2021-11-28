vpc_filters = {
  "tag:Name" = ["value"]
}

subnet_configuration = {
  prefer_private_ip = true
  public_subnet_filters = {
    "tag:Tier" = ["value"]
  }
  private_subnet_filters = {
    "tag:Tier" = ["value2"]
  }

default_tags = {
  Key = "value"
}

domain = "domain.com"