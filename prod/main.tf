terraform {
  required_providers {
    digitalocean = "= 1.14"
  }
}

provider "digitalocean" {}

resource "digitalocean_project" "prod" {
  name        = "Sample Infra Prod"
  description = "Production Project for Sample Infra"
  purpose     = "Sample Infra"
  environment = "Production"
  resources   = [digitalocean_domain.prod.urn]
}

resource "digitalocean_domain" "prod" {
  name = "sampleinfra.com"
}
