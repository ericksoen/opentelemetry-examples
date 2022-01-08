# Overview

Generally, we avoid changes to Terraform resource definitions that force resource deletion/creation cycles. In the case where the downside of maintaining duplicate code encourages this behavior, we provide a migration script to move resources from the deprecated location to the new address.

**Note**: this migration script is _only_ necessary if you created your application infrastructure prior to 12/19/2021.

## Migration Script

```hcl
terraform state mv module.lambda.aws_lambda_alias.alias module.lambda.module.alias.aws_lambda_alias.no_refresh[0]
terraform state mv module.lambda.aws_lambda_function.lambda module.lambda.module.lambda.aws_lambda_function.this[0]
terraform state mv module.lambda.aws_lambda_permission.with_lb module.lambda.module.alias.aws_lambda_permission.qualified_alias_triggers[\"LoadBalancer\"]

terraform state mv module.lambda_python.aws_lambda_alias.alias module.lambda_python.module.alias.aws_lambda_alias.no_refresh[0]
terraform state mv module.lambda_python.aws_lambda_function.lambda module.lambda_python.module.lambda.aws_lambda_function.this[0]
terraform state mv module.lambda_python.aws_lambda_permission.with_lb module.lambda_python.module.alias.aws_lambda_permission.qualified_alias_triggers[\"LoadBalancer\"]

terraform state mv module.proxy.aws_lambda_alias.alias module.proxy.module.alias.aws_lambda_alias.no_refresh[0]
terraform state mv module.proxy.aws_lambda_function.lambda module.proxy.module.lambda.aws_lambda_function.this[0]
terraform state mv module.proxy.aws_lambda_permission.with_lb module.proxy.module.alias.aws_lambda_permission.qualified_alias_triggers[\"LoadBalancer\"]
```

## Migration Script

```bash
terraform state mv aws_lb.alb module.lb.aws_lb.this[0]
terraform state mv aws_lb_listener.https module.lb.aws_lb_listener.frontend_https[0]
terraform state mv aws_lb_listener_rule.ec2 module.lb.aws_lb_listener_rule.https_listener_rule[2]
terraform state mv aws_lb_listener_rule.ecs module.lb.aws_lb_listener_rule.https_listener_rule[1]
terraform state mv aws_lb_listener_rule.lambda module.lb.aws_lb_listener_rule.https_listener_rule[3]
terraform state mv aws_lb_listener_rule.lambda_python module.lb.aws_lb_listener_rule.https_listener_rule[4]
terraform state mv aws_lb_listener_rule.proxy module.lb.aws_lb_listener_rule.https_listener_rule[0]
terraform state mv module.ec2.aws_lb_target_group.ec2 module.lb.aws_lb_target_group.main[2]
terraform state mv module.ecs.aws_lb_target_group.tg module.lb.aws_lb_target_group.main[1]
terraform state mv module.lambda.aws_lb_target_group.lambda module.lb.aws_lb_target_group.main[3]
terraform state mv module.lambda_python.aws_lb_target_group.lambda module.lb.aws_lb_target_group.main[4]
terraform state mv module.proxy.aws_lb_target_group.lambda module.lb.aws_lb_target_group.main[0]
terraform state mv module.proxy.aws_lb_target_group_attachment.lambda module.lb.aws_lb_target_group_attachment.this[\"0.proxy\"]
terraform state mv module.lambda.aws_lb_target_group_attachment.lambda module.lb.aws_lb_target_group_attachment.this[\"3.lambda\"]
terraform state mv module.lambda_python.aws_lb_target_group_attachment.lambda module.lb.aws_lb_target_group_attachment.this[\"4.python_lambda\"]
```