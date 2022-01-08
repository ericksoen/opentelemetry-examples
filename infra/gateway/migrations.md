# Overview

Generally, we avoid changes to Terraform resource definitions that force resource deletion/creation cycles. In the case where the downside of maintaining duplicate code encourages this behavior, we provide a migration script to move resources from the deprecated location to the new address.

**Note**: this migration script is _only_ necessary if you created your gateway infrastructure prior to 01/08/2022.

1. Migrate the ALB and associated resources

```bash
terraform state mv aws_lb.alb module.alb_lb.aws_lb.this[0]
terraform state mv aws_lb_listener.default module.alb_lb.aws_lb_listener.frontend_https[0]
terraform state mv aws_lb_listener_rule.debug module.alb_lb.aws_lb_listener_rule.https_listener_rule[0]
terraform state mv aws_lb_listener_rule.otlp_http module.alb_lb.aws_lb_listener_rule.https_listener_rule[1]
terraform state mv aws_lb_listener_rule.metrics module.alb_lb.aws_lb_listener_rule.https_listener_rule[2]
terraform state mv aws_lb_target_group.otlp_http module.alb_lb.aws_lb_target_group.main[1]
terraform state mv aws_lb_target_group.telemetry module.alb_lb.aws_lb_target_group.main[0]
terraform state mv aws_lb_target_group.metrics module.alb_lb.aws_lb_target_group.main[2]
```

1. Migrate the NLB and associated resources

```bash
terraform state mv aws_lb.nlb module.nlb_lb.aws_lb.this[0]
terraform state mv aws_lb_listener.otlp module.nlb_lb.aws_lb_listener.frontend_https[0]
terraform state mv aws_lb_target_group.otlp module.nlb_lb.aws_lb_target_group.main[0]
```