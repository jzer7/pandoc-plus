# Load configuration file as environment variables
ifneq (,$(wildcard .config.env))
    include .config.env
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
BUILD_ARGS_FLAG := --build-arg $(BUILD_ARGS)
IMAGE_FULL      := ${IMAGE_NAME}:${IMAGE_TAG}

# The first is the expected command to use the container image, the second
# bypasses the entrypoint, user/group id, and volume mounting (for testing
# testing purposes only)
DOCKER_RUN      := docker run --rm --user $$(id -u):$$(id -g) -v $$(pwd):/data ${IMAGE_FULL}
DOCKER_RUN_RAW  := docker run --rm --entrypoint='' ${IMAGE_FULL}


.PHONY: all
all: image

.PHONY: image
image: ${DOCKERFILE}
	@echo "Building Docker image..."
	docker buildx build ${BUILD_FLAGS} ${BUILD_ARGS_FLAG} \
		--cache-from type=local,src=/tmp/.buildx-cache \
		--cache-to type=local,dest=/tmp/.buildx-cache-new,mode=max \
		-t ${IMAGE_NAME}:${IMAGE_TAG} .
	@if [ -d "/tmp/.buildx-cache-new" ]; then \
		rm -rf /tmp/.buildx-cache; \
		mv /tmp/.buildx-cache-new /tmp/.buildx-cache; \
	fi

.PHONY: refresh
refresh: ${DOCKERFILE}
	@echo "Refreshing base Docker images..."
	@for base in $$(awk '/^FROM/{print $$2}' ${DOCKERFILE}); do \
		echo "Pulling $$base..."; \
		docker image pull $$base || exit 1; \
	done

.PHONY: test-container
test-container:
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
test-conversion:
	@echo "Testing document conversion..."
	@echo "  ==> Creating test document..."
	@echo "# Test Document" > test.md
	@echo "This is a test document to verify pandoc functionality." >> test.md
	@echo "  ==> Converting markdown to PDF..."
	@${DOCKER_RUN} test.md -o test.pdf
	@echo "  ==> Verifying PDF was created..."
	@test -f test.pdf || (echo "ERROR: PDF not created!" && exit 1)
	@echo "PDF conversion test passed!"

.PHONY: test-cleanup
test-cleanup:
	@echo "Cleaning up test artifacts..."
	@rm -f test.md test.pdf
	@echo "Cleanup completed."
