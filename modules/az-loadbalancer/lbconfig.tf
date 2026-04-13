locals {
  backend_pools = [
    {
      name = "lb-backend-pool-nginx"

      lb_rules = [
        {
          name          = "nginx-http-rule"
          protocol      = "Tcp"
          frontend_port = 80
          backend_port  = 80
          probe_name    = "nginx-http-probe"
        },
        {
          name          = "nginx-https-rule"
          protocol      = "Tcp"
          frontend_port = 443
          backend_port  = 443
          probe_name    = "nginx-https-probe"
        }
      ]

      probes = [
        {
          name                = "nginx-http-probe"
          protocol            = "Tcp"
          port                = 80
          interval_in_seconds = 5                   # interval_in_seconds → how often LB sends a probe
          number_of_probes    = 2                   # number_of_probes → number of consecutive failed probes before LB marks VM as unhealthy
        },
                {
          name                = "nginx-https-probe"
          protocol            = "Tcp"
          port                = 443
          interval_in_seconds = 5                   # interval_in_seconds → how often LB sends a probe
          number_of_probes    = 2                   # number_of_probes → number of consecutive failed probes before LB marks VM as unhealthy
        }
      ]

      # nat_pools = [
      #   {
      #     name                = "natpool-ssh"
      #     protocol            = "Tcp"
      #     frontend_port_start = 50000
      #     frontend_port_end   = 50010
      #     backend_port        = 22
      #   }
      # ]

# NAT rules in Load Balancer are used to map specific frontend ports to backend VM ports, enabling direct inbound access (e.g., RDP/SSH) to individual VMs without assigning public IPs
      nat_rules = [
        {
          name          = "rdp-uat-biztalk-ap1"
          protocol      = "Tcp"
          frontend_port = 5001
          backend_port  = 3389
        },
        {
          name          = "rdp-uat-biztalk-ap2"
          protocol      = "Tcp"
          frontend_port = 5002
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