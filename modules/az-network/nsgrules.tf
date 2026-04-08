locals {
  nsg_rules = {
    "spoke-web" = [
      {
        name                   = "allow-http"
        priority               = 100
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        source_port_range      = "*"
        destination_port_range = "80"
        # destination_port_ranges     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]

    "spoke-db" = [
      {
        name                       = "allow-sql"
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1433"
        source_address_prefix      = "10.1.1.0/26"
        destination_address_prefix = "*"
      }
    ]
  }
}