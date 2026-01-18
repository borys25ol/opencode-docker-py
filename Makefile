.PHONY: config build agent

# Tools to install in to the containers with apt-get.
LOCAL_TOOLS := "curl ca-certificates git vim make"

# Directories to exclude from the container (working only with directories).
DIRS_TO_EXCLUDE := ".venv .git"

# Ports to expose.
PORTS := "5000 8000"


config:
	@echo "Copy config files"
	cp -n ./config/opencode.example.json ./config/opencode.json || true

build:
	@echo "Building docker image"
	docker build \
		--build-arg LOCAL_TOOLS=$(LOCAL_TOOLS) \
		-t opencode-docker-py-agent \
		-f ./docker/Dockerfile ./docker

agent:
	@echo "Running coding agent"
	DIRS_TO_EXCLUDE=$(DIRS_TO_EXCLUDE) \
	PORTS=$(PORTS) \
	./docker/run_agent.sh $(DIR)
