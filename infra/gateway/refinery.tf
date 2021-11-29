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

module "refinery" {

  count             = local.honeycomb_refinery_count
  source            = "git@github.com:vlaaaaaaad/terraform-aws-fargate-refinery.git?ref=main"
  route53_zone_name = var.domain

  refinery_rules_file_path = "${path.module}/${local_file.rules_file[count.index].filename}"

  vpc_id = data.aws_vpc.vpc.id

  redis_subnets                = data.aws_subnet_ids.service.ids
  ecs_service_subnets          = data.aws_subnet_ids.service.ids
  ecs_service_assign_public_ip = local.use_public_service_ips
  vpc_alb_subnets              = data.aws_subnet_ids.lb.ids


  depends_on = [
    local_file.rules_file
  ]
}