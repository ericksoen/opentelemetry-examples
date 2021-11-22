# The assumption with vendor keys is that we will store them as SSM
# parameters and then inject them into the container environment at launch
resource "aws_ssm_parameter" "honeycomb_base_write_key" {
  name  = "/${var.resource_prefix}/honeycomb/base-write-key"
  type  = "String"
  value = var.honeycomb_base_config.write_key
}

resource "aws_ssm_parameter" "honeycomb_refinery_write_key" {
  name  = "/${var.resource_prefix}/honeycomb/refinery-write-key"
  type  = "String"
  value = var.honeycomb_refinery_config.write_key
}