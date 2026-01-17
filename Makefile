.PHONY: sync generate config build agent


# Directories to exclude from the container.
DIRS_TO_EXCLUDE := ".venv .git"

sync:
	@echo "Syncing project"
	uv sync

generate:
	@echo "Generate docker-compose.yml"
	uv run generate_docker_compose.py --masked-dirs $(DIRS_TO_EXCLUDE)

config:
	@echo "Copy config files"
	cp -n ./config/opencode.example.json ./config/opencode.json || true

build:
	@echo "Building docker image"
	docker compose build

agent:
	@echo "Running coding agent"
	@./docker/run_agent.sh $(DIR)
