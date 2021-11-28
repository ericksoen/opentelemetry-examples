# There are some interesting side effects to this approach related
# to Terraform diff detection. For now, this approach provides a 
# mechanism to template a file and output it to disk, which is a 
# required input to the refinery module. 
# See: https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
resource "local_file" "rules_file" {
  count    = local.honeycomb_refinery_count
  filename = "${path.module}/refinery_rules.toml"
  content = templatefile("${path.module}/refinery_rules.tpl", {
    HONEYCOMB_DATASET_NAME = local.honeycomb_refinery_dataset_name
  })
}

# For now, we'll put this in a separate and public VPC. Eventually,
# we'll deploy this to the same VPC as the rest of the infrastructure
# in this demo.
module "refinery" {

  count             = local.honeycomb_refinery_count
  source            = "git@github.com:vlaaaaaaad/terraform-aws-fargate-refinery.git?ref=main"
  route53_zone_name = var.domain

  refinery_rules_file_path = "${path.module}/${local_file.rules_file[count.index].filename}"

  vpc_id = data.aws_vpc.vpc.id
  vpc_alb_subnets = data.aws_subnet_ids.private.ids
  redis_subnets = data.aws_subnet_ids.private.ids
  ecs_service_subnets = data.aws_subnet_ids.private.ids
  alb_internal = var.assign_public_ip
  ecs_service_assign_public_ip = var.assign_public_ip

  depends_on = [
    local_file.rules_file
  ]
}