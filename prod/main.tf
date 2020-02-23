terraform {
  required_providers {
    digitalocean = "= 1.14"
    tls          = "= 2.1.1"
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

resource "tls_private_key" "prod" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "digitalocean_ssh_key" "prod" {
  name       = "Sample Infra Prod (TF Managed)"
  public_key = tls_private_key.prod.public_key_openssh
}
