# There are some interesting side effects to this approach related
# to Terraform diff detection. For now, this approach provides a 
# mechanism to template a file and output it to disk, which is a 
# required input to the refinery module. 
# See: https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
locals {
    honeycomb_refinery_count = var.honeycomb_refinery_config.write_key != "" ? 1 : 0
    honeycomb_refinery_dataset_name = var.honeycomb_refinery_config.dataset_name != "" ? var.honeycomb_refinery_config.dataset_name : "${var.resource_prefix}-refinery"
}
resource "local_file" "rules_file" {
  count = local.honeycomb_refinery_count
  filename = "${path.module}/refinery_rules.toml"
  content  = templatefile("${path.module}/refinery_rules.tpl", {
      HONEYCOMB_DATASET_NAME = local.honeycomb_refinery_dataset_name
  })
}



# For now, we'll put this in a separate and public VPC. Eventually,
# we'll deploy this to the same VPC as the rest of the infrastructure
# in this demo.
module "refinery" {

  count = local.honeycomb_refinery_count
  source = "git@github.com:vlaaaaaaad/terraform-aws-fargate-refinery.git?ref=main"
  route53_zone_name = var.domain

  refinery_rules_file_path = "${path.module}/${local_file.rules_file[count.index].filename}"
  
  # Optional: customize the VPC
  azs                = ["us-east-2a", "us-east-2b", "us-east-2c"]
#   vpc_id = "vpc-0cc65c07f3166e993"
  vpc_cidr           = "10.20.0.0/16"
  vpc_public_subnets = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]

  depends_on = [
    local_file.rules_file
  ]
}

locals {
    gateway_config = [
        {
          "name": "AOT_CONFIG_CONTENT",
          "valueFrom": aws_ssm_parameter.gateway_config.arn
        }]

    honeycomb_base_write_key = local.honeycomb_base_count > 0 ? [        {
          "name" : "HONEYCOMB_BASE_WRITE_KEY",
          "valueFrom" : aws_ssm_parameter.honeycomb_base_write_key[0].arn
        }] : []

    honeycomb_refinery_write_key = local.honeycomb_refinery_count > 0 ? [{
          "name" : "HONEYCOMB_REFINERY_WRITE_KEY",
          "valueFrom" : aws_ssm_parameter.honeycomb_base_write_key[0].arn
        }] : []

    combined_gateway_secrets = concat(local.gateway_config, local.honeycomb_base_write_key, local.honeycomb_refinery_write_key)
}
