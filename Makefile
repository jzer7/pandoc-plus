BUILD_FLAGS := --platform linux/amd64,linux/arm64
DOCKERFILE  := Dockerfile
IMAGE_NAME  ?= jzer7/pandoc-plus
IMAGE_TAG   ?= latest

IMAGE_FULL  := ${IMAGE_NAME}:${IMAGE_TAG}
# Expected regular use of container image
DOCKER_RUN  := docker run --rm --user $$(id -u):$$(id -g) -v $$(pwd):/data ${IMAGE_FULL}
# For testing purposes, bypass entrypoint, user/group id, and volume mounting
DOCKER_RUN_RAW := docker run --rm --entrypoint='' ${IMAGE_FULL}


.PHONY: all
all: image

.PHONY: image
image: ${DOCKERFILE}
	@echo "Docker image build..."
	docker buildx build ${BUILD_FLAGS} -t ${IMAGE_NAME}:${IMAGE_TAG} .

.PHONY: refresh
refresh: ${Dockerfile}
	@echo "Refresh base Docker image..."
	for base in $$(awk '/^FROM/{print $$2}' ${DOCKERFILE}); do \
		docker image pull $${base}; \
	done

.PHONY: test-container
test-container:
	@echo "Testing Docker image functionality..."
	# Test that the image runs and pandoc is available
	@${DOCKER_RUN_RAW} pandoc --version
	# Test that LaTeX is available
	@${DOCKER_RUN_RAW} pdflatex --version
	# Test that additional LaTeX packages are installed
	@${DOCKER_RUN_RAW} kpsewhich enumitem.sty
	@${DOCKER_RUN_RAW} kpsewhich moderncv.cls
	# Test user is not root
	@${DOCKER_RUN_RAW} sh -c 'if [ "$$(id -un)" = "root" ]; then echo "ERROR: Running as root!" && exit 1; else echo "OK: Running as $$(id -un)"; fi'

.PHONY: test-conversion
test-conversion:
	@echo "Testing document conversion..."
	# Create a simple test document
	@echo "# Test Document" > test.md
	@echo "This is a test document to verify pandoc functionality." >> test.md
	# Test markdown to PDF conversion
	@${DOCKER_RUN} test.md -o test.pdf
	# Verify the PDF was created
	@test -f test.pdf || (echo "ERROR: PDF not created!" && exit 1)
	@echo "PDF conversion test passed!"

.PHONY: test-cleanup
test-cleanup:
	@echo "Cleaning up test artifacts..."
	@rm -f test.md test.pdf
	@echo "Cleanup completed."
