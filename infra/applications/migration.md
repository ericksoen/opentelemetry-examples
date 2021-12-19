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