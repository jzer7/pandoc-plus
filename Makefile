# Configuration: Fail-fast if image.cfg is missing or incomplete
ifeq (,$(wildcard image.cfg))
	$(error image.cfg file not found - this file is required for all configuration)
endif

include image.cfg
export

# Validate that all required variables are set
REQUIRED_VARS   := IMAGE_NAME IMAGE_TAG REGISTRY BASE_IMAGE PLATFORMS LATEX_PACKAGES SYSTEM_PACKAGES
$(foreach var,$(REQUIRED_VARS),$(if $($(var)),,$(error $(var) not set in image.cfg)))

# Fixed values
DOCKERFILE      := Dockerfile

# Derived variables
BUILD_FLAGS     := --platform $(PLATFORMS) --build-arg $(BUILD_ARGS)
IMAGE_FULL      := $(IMAGE_NAME):$(IMAGE_TAG)

# Docker run commands
DOCKER_RUN      := docker run --rm --user $$(id -u):$$(id -g) --volume $$(pwd):/data $(IMAGE_FULL)
DOCKER_RUN_RAW  := docker run --rm --entrypoint='' $(IMAGE_FULL)

# Advanced variables (do not modify unless you understand the implications)
ACT_PLATFORM    := ubuntu-latest=catthehacker/ubuntu:act-latest

# Test configuration
TEST_DIR := tests
TEST_MD  := $(TEST_DIR)/test.md
TEST_PDF := $(TEST_DIR)/test.pdf

.PHONY: help
help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: show-config
show-config: ## Show current configuration values
	@echo "Current configuration:"
	@echo "  IMAGE_NAME:      $(IMAGE_NAME)"
	@echo "  IMAGE_TAG:       $(IMAGE_TAG)"
	@echo "  REGISTRY:        $(REGISTRY)"
	@echo "  BASE_IMAGE:      $(BASE_IMAGE)"
	@echo "  PLATFORMS:       $(PLATFORMS)"
	@echo "  LATEX_PACKAGES:  $(LATEX_PACKAGES)"
	@echo "  SYSTEM_PACKAGES: $(SYSTEM_PACKAGES)"

.PHONY: image
image: ${DOCKERFILE} ## Build Docker image
	@echo "Building Docker image..."
	docker buildx build ${BUILD_FLAGS} \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg IMAGE_NAME=$(IMAGE_NAME) \
		--build-arg LATEX_PACKAGES=$(LATEX_PACKAGES) \
		--build-arg SYSTEM_PACKAGES=$(SYSTEM_PACKAGES) \
		--cache-from type=local,src=/tmp/.buildx-cache \
		--cache-to type=local,dest=/tmp/.buildx-cache-new,mode=max \
		-t ${IMAGE_NAME}:${IMAGE_TAG} .
	@if [ -d "/tmp/.buildx-cache-new" ]; then \
		rm -rf /tmp/.buildx-cache; \
		mv /tmp/.buildx-cache-new /tmp/.buildx-cache; \
	fi

.PHONY: refresh
refresh: ${DOCKERFILE} ## Pull latest base images
	@echo "Refreshing base Docker images..."
	@for base in $$(awk '/^FROM/{print $$2}' ${DOCKERFILE}); do \
		echo "Pulling $$base..."; \
		docker image pull $$base || exit 1; \
	done

.PHONY: test-container
test-container: ## Test container functionality
	@echo "Testing Docker image functionality..."
	@echo "  ==> Testing pandoc availability..."
	@${DOCKER_RUN_RAW} pandoc --version
	@echo "  ==> Testing LaTeX availability..."
	@${DOCKER_RUN_RAW} pdflatex --version
	@echo "  ==> Testing additional LaTeX packages..."
	@${DOCKER_RUN_RAW} kpsewhich enumitem.sty
	@${DOCKER_RUN_RAW} kpsewhich moderncv.cls
	@echo "  ==> Testing user is not root..."
	@${DOCKER_RUN_RAW} sh -c 'if [ "$$(id -un)" = "root" ]; then echo "ERROR: Running as root!" && exit 1; else echo "OK: Running as $$(id -un)"; fi'
	@echo "All container tests passed!"

.PHONY: test-conversion
test-conversion: ## Test document conversion
	@echo "Testing document conversion..."
	@echo "  ==> Creating test document..."
	@echo "# Test Document" > test.md
	@echo "This is a test document to verify pandoc functionality." >> test.md
	@ls -l test.*
	@echo "  ==> Converting markdown to PDF..."
	@${DOCKER_RUN} test.md -o test.pdf
	@ls -l test.*
	@echo "  ==> Verifying PDF was created..."
	@test -f test.pdf || (echo "ERROR: PDF not created!" && exit 1)
	@echo "PDF conversion test passed!"

.PHONY: act
act: ## Run GitHub Actions workflow locally (requires act)
	@echo "Running GitHub Actions workflow locally using act..."
	@act \
		--job build-test \
		--platform ${ACT_PLATFORM} \
		--actor ${IMAGE_NAME} \
		--defaultbranch main \
		--use-gitignore \
		--bind \
		--use-new-action-cache \
		--strict

.PHONY: test-cleanup
test-cleanup: ## Clean up test artifacts
	@echo "Cleaning up test artifacts..."
	@rm -f test.md test.pdf
	@echo "Cleanup completed."

.PHONY: clean-build-artifacts
clean-build-artifacts: ## Clean up build artifacts
	@echo "Cleaning up build artifacts..."
	@rm -rf /tmp/.buildx-cache*
	@echo "Build artifacts cleanup completed."

.PHONY: clean
clean: test-cleanup test-build-artifacts ## Clean up build artifacts and cache
	@echo "Clean completed."
