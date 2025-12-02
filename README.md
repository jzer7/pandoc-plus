# Pandoc/LaTeX container image

[![Build, Test, and Publish](https://github.com/jzer7/pandoc-plus/actions/workflows/build-test-publish.yml/badge.svg)](https://github.com/jzer7/pandoc-plus/actions/workflows/build-test-publish.yml)

This image simplifies the process of generating PDF documents from Markdown using Pandoc with LaTeX.

It starts with the official [pandoc/latex:ubuntu](https://hub.docker.com/r/pandoc/latex) image, and adds a few additional LaTeX packages to produce better-formatted documents.
The image also includes tools so it can be used in document pipelines.

## Features

- additional LaTeX styles and packages
- simple tools (`make`, `wget`, and `unzip`)
- run as a non-root user
- CI/CD automated tests, builds, and publishing to GitHub Container Registry

## Usage

The entrypoint of the image is set to `pandoc`.
So it's usage is similar to running the `pandoc` command directly on a Linux host.

```sh
pandoc document.md -o document.pdf
```

To use a pre-built version of the Docker image, run:

```sh
docker run --rm \
           --volume "`pwd`:/data" \
           --user `id -u`:`id -g` \
           ghcr.io/jzer7/pandoc-plus:main \
           document.md -o document.pdf
```

Or use a locally built version of the image:

```sh
docker run --rm \
           --volume "`pwd`:/data" \
           --user `id -u`:`id -g` \
           jzer7/pandoc-plus \
           document.md -o document.pdf
```

## Development

### Build image

The Makefile includes a target to build the image locally.

```sh
make image
```

It also supports environment variables to customize the build process.

```sh
# Build with a specific image tag
make image IMAGE_TAG="v2.1"
```

### Debugging the container

The image entrypoint is set to `pandoc`.
So any command you pass to `docker run` will be executed as arguments to `pandoc`.
To debug issues, you might want to bypass the entrypoint and start an interactive shell.

```sh
docker run --rm -it \
           --volume "`pwd`:/data" \
           --user `id -u`:`id -g` \
           --entrypoint "" \
           jzer7/pandoc-plus /bin/bash
```

## Container Registry

### Automated Builds

Container images are automatically built and published to GitHub Container Registry.
Look at [`.github/workflows/build-test-publish.yml`](.github/workflows/build-test-publish.yml) for details.

The path to the image is `ghcr.io/jzer7/pandoc-plus:TAG`.
Where `TAG` can be:

- `main`: latest image built from `main` branch
- `sha-<commit>`: specific commit
- `vX.Y.Z`: release versions (when tagged)
