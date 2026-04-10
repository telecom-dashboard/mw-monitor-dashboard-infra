locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "mvp"
  }

  route53_zone_name_normalized = trimsuffix(var.route53_zone_name, ".")
  route53_record_fqdn          = var.route53_record_name == "" ? local.route53_zone_name_normalized : "${var.route53_record_name}.${local.route53_zone_name_normalized}"
}
