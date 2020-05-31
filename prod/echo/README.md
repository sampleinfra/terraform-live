= Notes 

== Getting Started From Scratch

Since the docker provider needs the host ip, the host has to be created 
Due to provider dependencies you need to run separate commands if starting off with nothing.

This will automatically create the droplet and firewall to allow for SSH, then do a `ssh-keyscan` on the droplet ip so the docker provider can ssh to the host.
```
terraform apply -target=null_resource.ssh_keyscan
```

If you don't want to have terraform run keyscan for you use this instead. Make sure to update `known_hosts`.
```
terraform apply -target=digitalocean_firewall.web
```

== SSH

Make sure to add `key.pem` from `../shared` to your ssh-agent
