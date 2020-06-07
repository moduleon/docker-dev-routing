This project is a stack with a preconfigured stack running nginx-proxy, dnsmasq, and mkcert.

This has been done for MacOs.

What to do to make it work.

First in .env, set your local domain. By default, it is `docker.local`. Just avoid `.dev` (Top level domain belongs to Google), `.local` (used by mDNSResponder on MacOs).

Then run
```sh
$ make start
```

This will run nginx-proxy, which will capture requests sent to localhost, and redirect them to containers if url is matching a VIRTUAL_HOST declared as environment variable among them. (visit https://github.com/nginx-proxy/nginx-proxy);

This will also run dnsmasq for redirecting every request made on an address ending with the domain set in .env.

And finally, this will run mkcert for generating a valid certificate for the domain set in .env, and will add it in the local keychain of your machine (again, this was made for mac, you would have to make some research for another OS). This action requires to ben run as root. So you will be asked for the root password.

If everything worked as expected, you just have to run a container with a VIRTUAL_HOST environment variable ending with the lost declared in .env. No other action is required, like editing /etc/hosts. Just hit its VIRTUAL_HOST with a curl, you norrmally will see a response.

By the way, the certificate generated is valid for the domain, and all subdomain, so the ssl is already enabled for your container without having to do any action about it.

For stopping the stack, just run

```
$ make stop
```

It will stop nginx-poxy and dnsmasq, and will clear local keychain from the certificate originally generated for running the stack. So, once again, this action need root access, and a password will be asked.
