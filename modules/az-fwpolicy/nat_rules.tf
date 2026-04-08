locals {
  nat_rules = {
    name     = "nat-rules"
    priority = 400
    action   = "Dnat"
    rules = [
      {
        name                = "web-1"
        enabled             = true
        source_addresses    = ["*"]
        destination_address = var.firewall_public_ip
        destination_ports   = ["80"]
        translated_address  = "10.2.1.70"
        translated_port     = "80"
        protocols           = ["TCP"]
      }
    ]
  }
}