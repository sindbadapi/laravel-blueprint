SHELL := /bin/sh

COMPOSE := docker compose
APP := $(COMPOSE) exec app
ARGS ?=

.DEFAULT_GOAL := help

.PHONY: help init build up down restart stop logs ps shell composer artisan migrate migrate-fresh test test-unit test-feature lint lint-fix analyse quality ci clean wait-db health ensure-test-db

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make <target> [ARGS=\"...\"]\n\n"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Build, install dependencies, migrate and health-check the app
	@test -f .env || cp .env.example .env
	$(COMPOSE) build
	$(COMPOSE) up -d
	$(APP) composer install --prefer-dist --no-interaction
	$(APP) sh -lc 'grep -q "^APP_KEY=base64:" .env || php artisan key:generate --ansi'
	$(MAKE) wait-db
	$(MAKE) migrate
	$(MAKE) health
	@printf "\nApplication is running at %s\n" "$$(grep '^APP_URL=' .env | cut -d= -f2-)"

build: ## Build Docker images
	$(COMPOSE) build

up: ## Start containers
	$(COMPOSE) up -d

down: ## Stop and remove containers
	$(COMPOSE) down

restart: ## Restart containers
	$(COMPOSE) restart

stop: ## Stop containers without removing them
	$(COMPOSE) stop

logs: ## Tail container logs
	$(COMPOSE) logs -f --tail=100

ps: ## Show container status
	$(COMPOSE) ps

shell: ## Open a shell in the app container
	$(APP) bash

composer: ## Run Composer, e.g. make composer ARGS="require vendor/package"
	$(APP) composer $(ARGS)

artisan: ## Run Artisan, e.g. make artisan ARGS="route:list"
	$(APP) php artisan $(ARGS)

migrate: ## Run database migrations
	$(APP) php artisan migrate --force

migrate-fresh: ## Drop all tables and re-run migrations
	@printf "This will drop all tables in the configured database. Type 'yes' to continue: "; read answer; [ "$$answer" = "yes" ]
	$(APP) php artisan migrate:fresh --force

test: ensure-test-db ## Run the full test suite
	$(APP) php artisan test

test-unit: ## Run unit tests
	$(APP) php artisan test --testsuite=Unit

test-feature: ensure-test-db ## Run feature tests
	$(APP) php artisan test --testsuite=Feature

lint: ## Check PHP style with Laravel Pint
	$(APP) vendor/bin/pint --test

lint-fix: ## Fix PHP style with Laravel Pint
	$(APP) vendor/bin/pint

analyse: ## Run PHPStan/Larastan
	$(APP) vendor/bin/phpstan analyse

quality: lint analyse test ## Run style, static analysis and tests

ci: quality ## Run local CI checks

clean: ## Remove containers and volumes after confirmation
	@printf "This will remove containers and named volumes. Type 'yes' to continue: "; read answer; [ "$$answer" = "yes" ]
	$(COMPOSE) down -v --remove-orphans

wait-db: ## Wait until PostgreSQL accepts Laravel connections
	$(APP) docker/scripts/wait-for-postgres.sh

ensure-test-db: ## Ensure the PostgreSQL test database exists
	$(APP) docker/scripts/ensure-test-database.sh

health: ## Check the HTTP health endpoint
	@url="$$(grep '^APP_URL=' .env | cut -d= -f2-)/up"; \
	for i in $$(seq 1 30); do \
		if curl -fsS "$$url" >/dev/null; then exit 0; fi; \
		sleep 2; \
	done; \
	printf "Health check failed: %s\n" "$$url"; exit 1
