locals {
  route_definitions = [
    {
      name        = "spoke-web"
      subnet_keys = ["web"] # this points to subnets_map["web"]
      routes = [
        {
          name                = "internet-via-fw"
          address_prefix      = "0.0.0.0/0"
          next_hop_type       = "VirtualAppliance"
          next_hop_ip_address = var.firewall_ip
        }
        # {
        #   name                = "internet-via-lb"
        #   address_prefix      = "0.0.0.0/0"
        #   next_hop_type       = "Internet"
        # }        
      ]
    },
    {
      name        = "spoke-db"
      subnet_keys = ["db"] # this points to subnets_map["db"]
      routes = [
        {
          name                = "internet-via-fw"
          address_prefix      = "0.0.0.0/0"
          next_hop_type       = "VirtualAppliance"
          next_hop_ip_address = var.firewall_ip
        }
        # {
        #   name                = "internet-via-lb"
        #   address_prefix      = "0.0.0.0/0"
        #   next_hop_type       = "Internet"
        # }
      ]
    },
    {
      name        = "spoke-app"
      subnet_keys = ["app"] # this points to subnets_map["app"]
      routes = [
        # {
        #   name                = "internet-via-fw"
        #   address_prefix      = "0.0.0.0/0"
        #   next_hop_type       = "VirtualAppliance"       
        #   next_hop_ip_address = var.firewall_ip             
        # },
        {
          name           = "internet-via-lb"
          address_prefix = "0.0.0.0/0"
          next_hop_type  = "Internet"
        }
      ]
    }
  ]
}