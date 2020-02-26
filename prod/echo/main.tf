terraform {
  required_providers {
    digitalocean = "= 1.14"
    http         = "= 1.1.1"
    docker       = "= 2.7"
    acme = "= 1.5"
    tls = "= 2.1.1"
  }
}

provider "digitalocean" {}

provider "docker" {
  host = "ssh://root@${digitalocean_droplet.docker01.ipv4_address}:22"
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

data "http" "icanhazip" {
  url = "http://icanhazip.com"
}

data "terraform_remote_state" "shared" {
  backend = "local"

  config = {
    path = "${path.module}/../shared/terraform.tfstate"
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
  image     = "docker-18-04"
  name      = "docker-01"
  region    = var.do_region
  size      = "s-1vcpu-1gb"
  ssh_keys  = [data.terraform_remote_state.shared.outputs.ssh_key_id]
  tags      = ["tf"]
  user_data = <<EOF
#!/bin/bash
useradd -M echo
EOF
}

resource "docker_image" "echo" {
  name = "jmalloc/echo-server:latest"
}

resource "docker_container" "echo" {
  image = docker_image.echo.latest
  name  = "echo"

  user = "1000:1000"

  networks_advanced {
    name = "bridge"
  }
}

resource "digitalocean_record" "echo" {
  domain = data.terraform_remote_state.shared.outputs.domain_name
  type   = "A"
  name   = "echo"
  value  = digitalocean_droplet.docker01.ipv4_address
}

resource "tls_private_key" "tls_cert" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.tls_cert.private_key_pem
  email_address   = var.email
}

resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = "echo.sampleinfra.com"

  dns_challenge {
    provider = "digitalocean"
  }
}

resource "docker_image" "tls_proxy" {
  name = "flaccid/tls-proxy"
}

resource "docker_container" "tls_proxy" {
  image = docker_image.tls_proxy.latest
  name  = "tls_proxy"

  ports {
    internal = 443
    external = 443
  }
  ports {
    internal = 80
    external = 80
  }

  networks_advanced {
    name = "bridge"
  }

  env = [
    "TLS_CERTIFICATE=${acme_certificate.certificate.certificate_pem}",
    "TLS_KEY=${acme_certificate.certificate.private_key_pem}",
    "UPSTREAM_HOST=${docker_container.echo.network_data[0]["ip_address"]}",
    "UPSTREAM_PORT=8080",
    "FORCE_HTTPS=true"
  ]
}

