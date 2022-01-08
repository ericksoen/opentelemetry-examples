# Migrate from inline load balancer resource definitions to terraform-aws-lb module

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