locals {
  nat_rule_collections = var.enable_public_ip ? [
    {
      name     = "web-nat"
      priority = 400
      action   = "Dnat"
      rules = [
        {
          name                = "http-to-web"
          enabled             = true
          source_addresses    = ["*"]
          destination_address = var.firewall_public_ip
          destination_ports   = ["80"]
          translated_address  = var.vm_private_ips # "10.2.1.70"
          translated_port     = "80"
          protocols           = ["TCP"]
        },
        {
          name                = "https-to-web"
          enabled             = true
          source_addresses    = ["*"]
          destination_address = var.firewall_public_ip
          destination_ports   = ["443"]
          translated_address  = var.vm_private_ips # "10.2.1.70"
          translated_port     = "443"
          protocols           = ["TCP"]
        }
      ]
    }
  ] : []
}