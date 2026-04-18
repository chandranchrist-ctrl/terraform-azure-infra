locals {
  common_listeners = [
    {
      name                           = "${var.env}-common-lsn"
      frontend_ip_configuration_name = "${var.env}-appgw-public-fe"
      frontend_port_name             = "${var.env}-appgw-fe-port"
      protocol                       = "Https"
      host_name                      = "uat-hotel.hbcdev.co.in"
      ssl_certificate_name           = "${var.env}-appgw-ssl-cert"
    },
    {
      name                           = "${var.env}-http-lsn"
      frontend_ip_configuration_name = "${var.env}-appgw-public-fe"
      frontend_port_name             = "${var.env}-appgw-fe-port-80"
      protocol                       = "Http"
      host_name                      = "uat-hotel.hbcdev.co.in"
    },
  ]

}