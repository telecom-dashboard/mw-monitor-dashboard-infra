aws_region   = "ap-southeast-1"
project_name = "terraform-aws-ecs-multi-env-platform"
environment  = "dev"

vpc_cidr = "10.10.0.0/16"

availability_zones = [
  "ap-southeast-1a",
  "ap-southeast-1b"
]

public_subnet_cidrs = [
  "10.10.1.0/24",
  "10.10.2.0/24"
]

private_subnet_cidrs = [
  "10.10.11.0/24",
  "10.10.12.0/24"
]

enable_nat_gateway = true

app_port = 3000

alb_ingress_cidr_blocks = [
  "0.0.0.0/0"
]

health_check_path = "/health"

ecs_log_retention_in_days = 7

enable_container_insights = true

ecs_name_prefix  = "tfecs"
ecr_force_delete = true
container_name   = "app"

# Bootstrap placeholder only.
# The GitHub app deploy workflow will publish SHA-tagged images later.
container_image_tag = "bootstrap"

task_cpu    = 256
task_memory = 512

container_environment = {
  APP_ENV = "dev"
}

# Create the ECS service at zero tasks.
# The GitHub app deploy workflow will scale it up on the first real deploy.
service_desired_count             = 0
enable_execute_command            = false
health_check_grace_period_seconds = 60

enable_https = true

route53_zone_name   = "buildwithhein.com"
route53_record_name = "dev.monitor"
acm_domain_name     = "dev.monitor.buildwithhein.com"

alb_ssl_policy                 = "ELBSecurityPolicy-TLS13-1-2-2021-06"
route53_evaluate_target_health = true
