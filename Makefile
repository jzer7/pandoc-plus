# Load configuration file as environment variables
ifneq (,$(wildcard image.cfg))
	include image.cfg
	export
endif

# Set defaults for all variables
DOCKERFILE      := Dockerfile
IMAGE_NAME      ?= jzer7/pandoc-plus
IMAGE_TAG       ?= latest
REGISTRY        ?= ghcr.io
BASE_IMAGE      ?= pandoc/latex:3.7-ubuntu
PLATFORMS       ?= linux/amd64,linux/arm64
DOCKER_BUILDKIT ?= 1
BUILD_ARGS      ?= BUILDKIT_INLINE_CACHE=1
LATEX_PACKAGES  ?= enumitem moderncv sectsty underscore lastpage
SYSTEM_PACKAGES ?= bsdextrautils make sudo unzip wget

# Derived variables
BUILD_FLAGS     := --platform $(PLATFORMS)
BUILD_FLAGS     += --build-arg $(BUILD_ARGS)
IMAGE_FULL      := ${IMAGE_NAME}:${IMAGE_TAG}

# The first is the expected command to use the container image, the second
# bypasses the entrypoint, user/group id, and volume mounting (for testing
# testing purposes only)
DOCKER_RUN      := docker run --rm --user $$(id -u):$$(id -g) -v $$(pwd):/data ${IMAGE_FULL}
DOCKER_RUN_RAW  := docker run --rm --entrypoint='' ${IMAGE_FULL}


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
		--build-arg LATEX_PACKAGES="$(LATEX_PACKAGES)" \
		--build-arg SYSTEM_PACKAGES="$(SYSTEM_PACKAGES)" \
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

.PHONY: test-cleanup
test-cleanup: ## Clean up test artifacts
	@echo "Cleaning up test artifacts..."
	@rm -f test.md test.pdf
	@echo "Cleanup completed."
