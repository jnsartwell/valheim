terraform {
  cloud {
    # TODO: replace with your Terraform Cloud organization name
    organization = "your-org-name"

    workspaces {
      name = "valheim"
    }
  }
}
