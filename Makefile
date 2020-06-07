-include .env

#
##@ HELP
#

.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
.DEFAULT_GOAL := help

#
##@ DOCKER CONTAINER
#

start: ## Start nginx-proxy & dnsmasq & create needed files
	@${MAKE} generate_certificate;
	@docker run -d \
		--name nginx-proxy \
		-p 80:80 \
		-p 443:443 \
		-v /var/run/docker.sock:/tmp/docker.sock:ro \
		-v ${PWD}/certs:/etc/nginx/certs:ro \
		--restart unless-stopped \
		jwilder/nginx-proxy:alpine \
	;
	@${MAKE} generate_dnsmasq_config;
	@${MAKE} add_resolver;
	@docker run -u root -d \
		--name dnsmasq \
		--cap-add NET_ADMIN \
		-p 53:53/tcp \
		-p 53:53/udp \
		-v ${PWD}/dnsmasq.conf:/etc/dnsmasq.conf \
		--restart unless-stopped \
		andyshinn/dnsmasq \
	;

stop: ## Stop nginx-proxy & dnsmasq & remove files
	@docker stop nginx-proxy && \
	docker rm -v nginx-proxy && \
	docker stop dnsmasq && \
	docker rm -v dnsmasq && \
	${MAKE} remove_resolver && \
	${MAKE} remove_certificate && \
	${MAKE} remove_dsnmasq_config \
;

generate_certificate:
	@docker run --rm \
		-v ${PWD}/certs:/root/.local/share/mkcert \
		vishnunair/docker-mkcert \
		mkcert -install *.${LOCAL_DOMAIN} \
	;
	@mv ${PWD}/certs/*.${LOCAL_DOMAIN}-key.pem ${PWD}/certs/${LOCAL_DOMAIN}.key && \
	mv ${PWD}/certs/*.${LOCAL_DOMAIN}.pem ${PWD}/certs/${LOCAL_DOMAIN}.crt && \
	sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ${PWD}/certs/rootCA.pem \
;

remove_certificate: ## Remove certificate generated for local domain
	@rm ${PWD}/certs/${LOCAL_DOMAIN}.key && \
	rm ${PWD}/certs/${LOCAL_DOMAIN}.crt && \
	sudo security remove-trusted-cert -d ${PWD}/certs/rootCA.pem && \
	rm ${PWD}/certs/rootCA-key.pem && \
	rm ${PWD}/certs/rootCA.pem \
;

generate_dnsmasq_config: ## Generate dnsmasq config in host
	@cp ${PWD}/dnsmasq.conf.dist ${PWD}/dnsmasq.conf && \
	sudo bash -c 'echo "address=/.${LOCAL_DOMAIN}/127.0.0.1" >> ${PWD}/dnsmasq.conf' \
;

remove_dsnmasq_config: ## Remove dnsmasq config generated in host
	@rm ${PWD}/dnsmasq.conf;

add_resolver: ## Add resolver for local domain in host
	@sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/${LOCAL_DOMAIN}';

remove_resolver: ## Remove resolver for local domain in host
	@sudo rm /etc/resolver/${LOCAL_DOMAIN};

flush_dns_cache: ## Flush dns cache for mac
	@sudo killall -HUP mDNSResponder;

setup_dns_servers: ## Setup all servers for mac
	@sudo networksetup -setdnsservers Wi-Fi 127.0.0.1 192.168.1.1 8.8.8.8 8.8.4.4;

terminal: ## Enter in nginx-proxy terminal
	@docker exec -it nginx-proxy /bin/bash;

terminal-dnsmasq: ## Enter in dnsmasq terminal
	@docker exec -it dnsmasq /bin/sh;
