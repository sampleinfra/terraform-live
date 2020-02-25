output "ssh_key_id" {
  value = digitalocean_ssh_key.prod.id
}

output "domain_name" {
  value = digitalocean_domain.prod.name
}
