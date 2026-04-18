locals {
  application_rule_collections = [
    {
      name     = "app-deny"
      priority = 300
      action   = "Deny"
      rules = [
        {
          name             = "block-social"
          enabled          = true
          source_addresses = var.all_vm_cidrs
          destination_fqdns = [
            "*.youtube.com",
            "*.facebook.com",
            "*.instagram.com"
          ]
        },
        {
          name              = "block-github"
          enabled           = false
          source_addresses  = var.all_vm_cidrs
          destination_fqdns = ["*.github.com"]
        }
      ]
    }
  ]
}