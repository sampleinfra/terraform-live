terraform {
  required_providers {
    digitalocean = "= 1.14"
    http         = "= 1.1.1"
  }
}

provider "digitalocean" {}

data "http" "icanhazip" {
  url = "http://icanhazip.com"
}

data "terraform_remote_state" "shared" {
  backend = "local"

  config = {
    path = "${path.module}/shared/terraform.tfstate"
  }
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
  ssh_keys = [data.terraform_remote_state.shared.outputs.ssh_key_id]
  tags     = ["tf"]
}
