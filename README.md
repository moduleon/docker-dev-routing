# Docker dev routing

> This project is a Docker stack handling routing to containers during development.

When you come to work with docker locally, you can expose your containers on a given host ports, or eventually, you bind them to an url, and with a solution like jwilder/nginx-proxy, you achieve that goal pretty easily. But, because there is always a but, you have to update your /etc/hosts. And if you want your containers to communicate through their respective url, you will have to bind them (for example with option `--link my-container-name:my-freaky-url.test`). Furthermore, this linking makes them now codependant, and you can not run one without the other.

So, here it is. I want my containers to be accesible through an url from my host if they are exposed, and I want them to be able to communicate through their url without having to link them. If you are at this point, like me, you are in the good place.

The current stack does exactly that.

It uses [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) for redirecting calls made to a prefined local host name (by default docker.local) to the localhost. Then, it uses [jwilder/nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) for redirecting calls made to localhost to container having a matching *VIRTUAL_HOST* environment variable.

Thus, you will never have to declare your *VIRTUAL_HOST* in /etc/hosts again. And you will no longer need to link your containers to make them communicate if they are exposed for a given url.

So, how to make it started ? Simple.

First, **define your local domain**.
**By default, it is docker.local**, but you can override it in `.env` file.
But, (yes, I am tired of that too), **you must NOT use .dev** (top level domain exist since early 2019, and is managed by Google).
And **if you are using a Mac, should avoid using .local**, because it is used internally by the OS (mDNSResponder service to be exact, for a freaky Macbook of whoever.local). If you do, you would need to define your *VIRTUAL_HOST* in `/etc/hosts`. It would be too bad. Just choose something else, like .test, or let it like this, .docker.local.

Then run in your terminal:

```sh
$ make start
```

This will run nginx-proxy, which will capture requests sent to localhost, and redirect them to containers if url is matching a *VIRTUAL_HOST* declared as environment variable among them. This will also run dnsmasq for redirecting every request made on an address ending with the domain set in .env.

Okay, from now you will have to add a configuration in your containers stack.

Second step, you will **plug your containers on network "common"**. So if your using command lines, it will be something like `--net common`. If you are using docker-compose, it will be something like adding these lines:

```yaml
networks:
  default:
    external:
      name: common
```

Then, you will add a dns info to each container which want to communicate freely with others. With pure docker, something like `--dns 172.25.0.254`, and with docker-compose, something like:

```yaml
services:
  web:
    ...
   dns: 172.25.0.254
```

And now, you free to go. Just make a docker-compose up, try a curl from your host on one of your container *VIRTUAL_HOST*, you will get a response. And try within a container to curl to another the same way, you will get a result too.

Okay, it would have been nice not to had this extra config to your containers, I agree, and i am working on it. But it is a great start right ?

**(Mac users only for now)**
To make you feel better, I gave you something more. And what if you could access your containers url with https with a valid certificate ? For that, run:

```sh
$ make generate_certificate
```

Action is run in sudo to grant access to the local keychain, so you will be asked for your password. Now, all containers having your local domain are reachable on 443 port.

But, if you want to have containers bound to a subdomain having more than one level from your base local domain (for example: api.mycompanyname.docker.local instead of api.docker.local), then certificate will be considered as invalid. In those case, you can add subdomains in .env file in the *SUB_DOMAINS* variable, separated by a space. For the previous example, it would be like `SUB_DOMAINS=api.mycompanyname.docker.local`. You can also add a wildcard to match all domains for your subdomain (`SUB_DOMAINS=*.mycompanyname.docker.local`). Once done, you will have to regenerate the certificate (run `make remove_certificate && make generate_certificate`).

You want to stop it, fine! Run:

```sh
$ make remove_certificate
```

That's it.

Ok, now you want to shut down everything? Run:

```sh
$ make stop
```

That's it.
