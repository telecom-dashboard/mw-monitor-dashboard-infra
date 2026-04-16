aws_region   = "ap-southeast-1"
project_name = "nw-monitor-dashboard"
environment  = "mvp"

vpc_cidr = "10.30.0.0/16"

availability_zones = [
  "ap-southeast-1a"
]

public_subnet_cidrs = [
  "10.30.1.0/24"
]

private_subnet_cidrs = []
enable_nat_gateway   = false

web_ingress_cidr_blocks = [
  "0.0.0.0/0"
]

ssh_ingress_cidr_blocks = []

route53_zone_name       = "buildwithhein.com"
route53_record_name     = "mvp.monitor"
deploy_target_tag_key   = "DeployTarget"
deploy_target_tag_value = "nw-monitor-dashboard-mvp-app-host"
enable_https            = true
letsencrypt_email       = "ops@buildwithhein.com"

app_port      = 8000
instance_type = "t3.micro"
ami_id        = ""
key_name      = ""

root_volume_size           = 20
enable_detailed_monitoring = false

assets_bucket_name               = "nw-monitor-dashboard-mvp-assets-091336586598-apse1"
assets_bucket_force_destroy      = false
assets_bucket_versioning_enabled = false

alarm_actions = []
ok_actions    = []

cpu_utilization_threshold = 80

postgres_db_name      = "app"
postgres_app_user     = "app"
postgres_app_password = "replace-me"

app_systemd_service_name = "saas-app"
