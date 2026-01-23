.PHONY: build agent install uninstall

# Tools to install in to the containers with apt-get.
LOCAL_TOOLS := "curl ca-certificates git vim make"

# Name of the command to be available in the terminal.
BIN_NAME := dockercode
# Path to the system binary directory.
INSTALL_PATH := /usr/local/bin/$(BIN_NAME)

# Absolute path to your script.
SCRIPT_SRC := $(shell realpath ./docker/run_agent.sh)

build:
	@echo "Building docker image"
	docker build \
		--build-arg LOCAL_TOOLS=$(LOCAL_TOOLS) \
		-t opencode-docker-py-agent \
		-f ./docker/Dockerfile ./docker

agent:
	@echo "Running coding agent"
	./docker/run_agent.sh $(DIR)

# Clean up all Docker volumes associated with uv_cache
clean-cache:
	@echo "Searching for opencode cache volumes..."
	@# Find volumes ending with _uv_cache
	@volumes=$$(docker volume ls -q -f name=_uv_cache); \
	if [ -n "$$volumes" ]; then \
		echo "Removing volumes: $$volumes"; \
		docker volume rm $$volumes; \
		echo "Success: All cache volumes have been removed."; \
	else \
		echo "No cache volumes found to clean."; \
	fi

# Create a symbolic link to the script
install:
	@echo "Installing $(BIN_NAME) globally..."
	@# Ensure the script is executable
	@chmod +x $(SCRIPT_SRC)
	@# Remove existing link or file if it exists
	@if [ -L $(INSTALL_PATH) ] || [ -f $(INSTALL_PATH) ]; then \
		sudo rm $(INSTALL_PATH); \
	fi
	@# Create the symlink
	sudo ln -s $(SCRIPT_SRC) $(INSTALL_PATH)
	@echo "Done! You can now run the agent using the '$(BIN_NAME)' command."

# Remove the symbolic link
uninstall:
	@echo "Uninstalling $(BIN_NAME)..."
	@if [ -L $(INSTALL_PATH) ]; then \
		sudo rm $(INSTALL_PATH); \
		echo "Success: $(BIN_NAME) has been removed from $(INSTALL_PATH)."; \
	else \
		echo "Error: $(BIN_NAME) is not installed in $(INSTALL_PATH) (or not a symlink)."; \
	fi
