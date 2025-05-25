BUILD_FLAGS :=
IMAGE_NAME ?= jzer7/pandoc
IMAGE_TAG ?= latex

all: image

.PHONY: image

image: Dockerfile
	docker buildx build ${BUILD_FLAGS} -t ${IMAGE_NAME}:${IMAGE_TAG} .
