locals {
  application_rule_collections = [
     {
      name     = "allow-business-apps"
      priority = 100
      action   = "Allow"

      rules = [
        {
          name              = "allow-azure-services"
          enabled           = true
          source_addresses  = var.all_vm_cidrs
          destination_fqdns = [
            "*.microsoft.com",
            "*.azure.com",
            "*.windows.net"
          ]
        },
        {
          name              = "allow-dev-tools"
          enabled           = true
          source_addresses  = var.all_vm_cidrs
          destination_fqdns = [
            "login.github.com",
            "*.visualstudio.com",
            "*.vscode.dev"
          ]
        },
        {
          name              = "allow-package-repos"
          enabled           = true
          source_addresses  = var.all_vm_cidrs
          destination_fqdns = [
            "registry.npmjs.org",
            "pypi.org",
            "*.docker.com"
          ]
        }
      ]
    }
  ]
}