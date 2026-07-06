# ChengetAi DSpace Engine — operational shortcuts
# All targets read configuration from .env (copy .env.example first).

COMPOSE      = docker compose
COMPOSE_PROD = docker compose -f docker-compose.yml -f docker-compose.prod.yml

.PHONY: help up up-prod down logs ps admin backup restore reindex pull config

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

up: ## Start the development stack
	$(COMPOSE) up -d

up-prod: ## Start the production stack (nginx + TLS overlay)
	$(COMPOSE_PROD) up -d

down: ## Stop the stack (data volumes are preserved)
	$(COMPOSE) down

logs: ## Tail logs from all services
	$(COMPOSE) logs -f --tail=100

ps: ## Show service status
	$(COMPOSE) ps

admin: ## Create the first DSpace administrator
	./scripts/init-admin.sh

backup: ## Back up database + assetstore to ./backups
	./scripts/backup.sh

restore: ## Restore a backup: make restore BACKUP=backups/<timestamp>
	./scripts/restore.sh $(BACKUP)

reindex: ## Rebuild the discovery (search) index
	$(COMPOSE) exec dspace /dspace/bin/dspace index-discovery -b

pull: ## Pull the latest images for the pinned DSPACE_VER
	$(COMPOSE) pull

config: ## Render the effective compose configuration
	$(COMPOSE) config
