BUILD_FLAGS :=
DOCKERFILE := Dockerfile
IMAGE_NAME ?= jzer7/pandoc
IMAGE_TAG ?= latex-plus

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

.PHONY:
test-container:
	@echo "Testing Docker image functionality..."
	# Test that the image runs and pandoc is available
	docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} pandoc --version
	# Test that LaTeX is available
	docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} pdflatex --version
	# Test that additional LaTeX packages are installed
	docker run --rm --entrypoint='' ${IMAGE_NAME}:${IMAGE_TAG} kpsewhich enumitem.sty
	docker run --rm --entrypoint='' ${IMAGE_NAME}:${IMAGE_TAG} kpsewhich moderncv.cls
	# Test user is not root
	docker run --rm --entrypoint='' ${IMAGE_NAME}:${IMAGE_TAG} id -un | grep -v root
