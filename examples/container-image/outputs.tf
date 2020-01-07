output "dns_endpoint" {
  value = "${var.test_name}.${local.zone_name}"
}
