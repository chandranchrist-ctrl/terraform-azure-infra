locals {
  backend_pools = [
    {
      name = "lb-backend-pool-http"

      lb_rules = [
        {
          name          = "http-rule"
          protocol      = "Tcp"
          frontend_port = 80
          backend_port  = 80
          probe_name    = "http-probe"
        }
      ]

      probes = [
        {
          name                = "http-probe"
          protocol            = "Tcp"
          port                = 80
          interval_in_seconds = 5                   # interval_in_seconds → how often LB sends a probe
          number_of_probes    = 2                   # number_of_probes → number of consecutive failed probes before LB marks VM as unhealthy
        }
      ]

      nat_pools = [
        {
          name                = "natpool-ssh"
          protocol            = "Tcp"
          frontend_port_start = 50000
          frontend_port_end   = 50010
          backend_port        = 22
        }
      ]

      nat_rules = [
        {
          name          = "natrule-rdp"
          protocol      = "Tcp"
          frontend_port = 3389
          backend_port  = 3389
        }
      ]
    },
    {
      name = "lb-backend-pool-app"

      lb_rules = [
        {
          name          = "app-rule"
          protocol      = "Tcp"
          frontend_port = 8080
          backend_port  = 8080
          probe_name    = "app-probe"
        }
      ]

      probes = [
        {
          name                = "app-probe"
          protocol            = "Tcp"
          port                = 8080
          interval_in_seconds = 5
          number_of_probes    = 2
        }
      ]

      nat_pools = [
        {
          name                = "natpool-app-ssh"
          protocol            = "Tcp"
          frontend_port_start = 50100
          frontend_port_end   = 50110
          backend_port        = 22
        }
      ]

      nat_rules = [
        {
          name          = "natrule-app-rdp"
          protocol      = "Tcp"
          frontend_port = 3390
          backend_port  = 3389
        }
      ]
    }
  ]

  outbound_rules = [
    {
      name                     = "outbound-rule"
      protocol                 = "All"
      allocated_outbound_ports = 1024
    }
  ]
}