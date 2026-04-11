output "lb_id" {
  value = azurerm_lb.lb.id
}

output "frontend_ip_name" {
  value = "${var.lb_name}-fe"
}

output "backend_pool_ids" {
  value = { for k, v in azurerm_lb_backend_address_pool.backend_pools : k => v.id }
}

output "public_ip_address" {
  value = var.frontend_ip_type == "Public" ? azurerm_public_ip.lb_public_ip[0].ip_address : ""
}

output "nat_pool_ids" {
  value = { for k, v in azurerm_lb_nat_pool.nat_pools : k => v.id }
}

output "nat_rule_ids" {
  value = { for k, v in azurerm_lb_nat_rule.nat_rules : k => v.id }
}

output "outbound_rule_ids" {
  value = { for k, v in azurerm_lb_outbound_rule.out_rules : k => v.id }
}

output "probe_ids" {
  value = { for k, v in azurerm_lb_probe.probes : k => v.id }
}

output "lb_rule_ids" {
  value = { for k, v in azurerm_lb_rule.lb_rules : k => v.id }
}

output "nat_rule_mapping" {
  value = {
    for k, v in azurerm_lb_nat_rule.nat_rules : k => {
      backend_pool  = v.pool # The backend pool name from locals merge
      vm_id         = v.backend_ip_configuration_id
      frontend_port = v.frontend_port
      backend_port  = v.backend_port
    }
  }
}