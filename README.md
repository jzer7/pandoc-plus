# Pandoc/LaTeX container image

This image adds a few additional LaTeX packages to build documentation.

## Build image

```sh
make image
```

## Usage

Usage is the same as with the original image:

```sh
docker run --rm --volume "`pwd`:/data" --user `id -u`:`id -g` jzer7/pandoc:latex README.md
```

To debug things, you might need to start in shell mode.
For that, remove the _entrypoint_.

```sh
docker run --rm --volume "`pwd`:/data" --user `id -u`:`id -g` --entrypoint "" jzer7/pandoc:latex /bin/bash
```

## Starting point

This repo's Dockerfile start with the base image

- [pandoc/latex:latest-ubuntu](https://hub.docker.com/r/pandoc/latex)

That image is based on the following layers:

- [ubuntu:noble](https://github.com/docker-library/repo-info/blob/master/repos/ubuntu/tag-details.md#ubuntunoble)
- [pandoc/core:VER-ubuntu](https://github.com/pandoc/dockerfiles/blob/main/ubuntu/Dockerfile)
- [pandoc/latex:VER-ubuntu](https://github.com/pandoc/dockerfiles/blob/main/ubuntu/latex/Dockerfile)

Which results in the image having:

- pandoc
- latex
- workdir: `/data`
- entrypoint: `/usr/local/bin/pandoc`
- user: `root`

## Customization

Changes to that image:

- run with non-root user
- additional LaTeX packages
- include `make`, `wget`, and `unzip`, which are often used during `make` runs
