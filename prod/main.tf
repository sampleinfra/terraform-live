terraform {
  required_providers {
    digitalocean = "= 1.14"
    tls          = "= 2.1.1"
    http         = "= 1.1.1"
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

data "http" "icanhazip" {
  url = "http://icanhazip.com"
}

resource "digitalocean_firewall" "web" {
  name        = "only-22-80-and-443"
  tags        = ["tf"]
  droplet_ids = [digitalocean_droplet.docker01.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["${chomp(data.http.icanhazip.body)}/24"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_droplet" "docker01" {
  image    = "docker-18-04"
  name     = "docker-01"
  region   = var.do_region
  size     = "s-1vcpu-1gb"
  ssh_keys = [digitalocean_ssh_key.prod.id]
  tags     = ["tf"]
}
