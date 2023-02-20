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
	@${MAKE} generate_dnsmasq_config;
	@${MAKE} add_resolver;
	@docker-compose up -d;

stop: ## Stop nginx-proxy & dnsmasq & remove files
	@docker-compose down && \
	${MAKE} remove_resolver && \
	${MAKE} remove_dsnmasq_config \
;

logs: ## Show containers logs
	@docker-compose logs -f;

generate_certificate: ## Generate a trusted certificate for local domain
	echo "${PWD}/certs";
	@docker run --rm \
		-v ${PWD}/certs://opt/mkcert/data \
		--workdir //opt/mkcert/data \
		-e CAROOT=//opt/mkcert/data \
		flesch/mkcert:latest \
		mkcert -key-file "${LOCAL_DOMAIN}".key -cert-file "${LOCAL_DOMAIN}".crt *.${LOCAL_DOMAIN} ${SUB_DOMAINS} \
	; \
	certutil -addstore -f "ROOT" ${PWD}/certs/rootCA.pem \
;

remove_certificate: ## Remove certificate generated for local domain
	@rm ${PWD}/certs/${LOCAL_DOMAIN}.key && \
	rm ${PWD}/certs/${LOCAL_DOMAIN}.crt && \
	certutil -delstore "ROOT" ${PWD}/certs/rootCA.pem && \
	rm ${PWD}/certs/rootCA-key.pem -f && \
	rm ${PWD}/certs/rootCA.pem \
;

generate_dnsmasq_config: ## Generate dnsmasq config in host
	@cp ${PWD}/dnsmasq.conf.dist ${PWD}/dnsmasq-ext.conf && \
	cp ${PWD}/dnsmasq.conf.dist ${PWD}/dnsmasq-int.conf && \
	bash -c 'echo "address=/.${LOCAL_DOMAIN}/127.0.0.1" >> ${PWD}/dnsmasq-ext.conf' && \
	bash -c 'echo "address=/.${LOCAL_DOMAIN}/172.25.0.255" >> ${PWD}/dnsmasq-int.conf' \
;

remove_dsnmasq_config: ## Remove dnsmasq config generated in host
	@rm ${PWD}/dnsmasq-ext.conf && rm ${PWD}/dnsmasq-int.conf;

add_resolver: ## Add resolver for local domain in host
	@mkdir -p /etc/resolver && bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/${LOCAL_DOMAIN}';

remove_resolver: ## Remove resolver for local domain in host
	@rm /etc/resolver/${LOCAL_DOMAIN};

terminal: ## Enter in nginx-proxy terminal
	@docker exec -it nginx-proxy /bin/bash;

terminal-dnsmasq-ext: ## Enter in dnsmasq for host terminal
	@docker exec -it dnsmasq-ext /bin/sh;

terminal-dnsmasq-int: ## Enter in dnsmasq for containers terminal
	@docker exec -it dnsmasq-int /bin/sh;