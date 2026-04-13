locals {
  # Define NSG rules for each subnet
  # Key format: "<vnet_key>-<subnet_key>" (must match NSG map keys)
  nsg_rules = {
    # Rules for web subnet (example: allow HTTP traffic)
    "spoke-web" = [
      {
        name                   = "allow-http"
        priority               = 100
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        source_port_range      = "*"
        destination_port_range = "80"           # # Use "destination_port_ranges" only when specifying multiple ports

        source_address_prefixes      = [      # Source can be a service tag (e.g., AzureLoadBalancer, Internet) or a CIDR range (e.g., 10.0.2.0/24)
          "10.0.2.0/24", 
          "AzureLoadBalancer", 
          "10.0.0.0/26"
        ]  

        destination_address_prefix = "*"
        source_asg = null
        dest_asg   = null
      },
      {
        name                   = "allow-https"
        priority               = 101
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        source_port_range      = "*"
        destination_port_range = "443"

        source_address_prefixes     = [     # Source can be a service tag (e.g., AzureLoadBalancer, Internet) or a CIDR range (e.g., 10.0.2.0/24)
          "10.0.2.0/24", 
          "AzureLoadBalancer", 
          "10.0.0.0/26"
        ]  

        destination_address_prefix = "*"
        source_asg = null
        dest_asg   = null
      }
    ]

    "spoke-app" = [
      {
        name                       = "allow-http-from-nginx"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "10.1.1.0/26" # Only allow from web subnet where nginx is running
        destination_address_prefix = "*"            
        source_asg = null               # Ex. "uat-ezy-web-asg" - ASG support is optional and can be used instead of CIDR for source/destination in NSG rules
        dest_asg   = null             # Ex. "uat-ezy-app-asg" - ASG support is optional and can be used instead of CIDR for source/destination in NSG rules
      }
    ]

    # Rules for database subnet (example: allow SQL traffic)
    "spoke-db" = [
      {
        name                       = "allow-sql"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1433"
        source_address_prefixes = [             # Only allow from app subnet
          "10.1.1.64/26"
          ] 
        destination_address_prefix = "*"
        source_asg = null
        dest_asg   = null
      }
    ]
  }
}