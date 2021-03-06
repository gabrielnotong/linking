# To specify text which are not real files or dir
.PHONY: install help up build prune down clean vendor all-tests functional-test unit-test

# make|make help, Displays help
.DEFAULT_GOAL = help

# Docker and docker-compose start commands
DOCKER_COMPOSE = docker-compose
DOCKER = docker

EXEC_PHP = $(DOCKER_COMPOSE) exec -T php

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-10s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

up: down ## Wakes up containers in the detached mode
	$(DOCKER_COMPOSE) up -d

install: down clean build up vendor ## Install the application

vendor: ## Install symfony dependencies
	$(EXEC_PHP) composer install --prefer-dist --no-progress --no-suggest --no-interaction

build: down prune ## Builds images
	$(DOCKER_COMPOSE) build

prune: down ## Cleans up unused containers, images and volumes
	$(DOCKER) system prune -a -f
	$(DOCKER) volume prune -f

down: ## Switches off all running containers
	$(DOCKER_COMPOSE) down

bash:  ## To access php container in command line
	$(DOCKER_COMPOSE) exec php bash
#
#fixtures: migration ## Makes data available for the application
#	$(EXEC_PHP) ./bin/console hautelook:fixtures:load --no-interaction --no-bundles

migrate: db-drop db-create ## Updates database schema
	$(EXEC_PHP) bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

migration: ## Generates migration files
	$(EXEC_PHP) bin/console make:migration --no-interaction

db-drop: ## Drops mysql database
	$(EXEC_PHP) ./bin/console doctrine:database:drop --if-exists --force

db-create: ## Creates mysql database
	$(EXEC_PHP) ./bin/console doctrine:database:create --if-not-exists

clean: prune ## Stops and clean all containers and volumes; removes vendor and var folders
	rm -rf vendor; rm -rf var

all-tests: functional-test unit-test ## Executes functional and unit tests

functional-test: ## Executes functional tests
	docker-compose exec -T php vendor/bin/simple-phpunit --configuration phpunit.xml.dist --testsuite "integration"

unit-test: ## Executes unit tests
	docker-compose exec -T php vendor/bin/simple-phpunit --configuration phpunit.xml.dist --testsuite "unit"
