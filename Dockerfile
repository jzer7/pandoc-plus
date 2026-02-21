ARG BASE_IMAGE=pandoc/latex:3.9-ubuntu
FROM $BASE_IMAGE

ARG IMAGE_NAME=jzer7/pandoc-plus
ARG LATEX_PACKAGES="enumitem moderncv sectsty underscore lastpage"
ARG SYSTEM_PACKAGES="bsdextrautils make sudo unzip wget"


LABEL org.opencontainers.image.authors="Juan Rubio <j.c.rubio@gmail.com>"
LABEL org.opencontainers.image.base=${IMAGE_NAME}
LABEL org.opencontainers.image.source="https://github.com/jzer7/pandoc-plus"
LABEL org.opencontainers.image.description="Pandoc with LaTeX and additional packages for document generation"

# Create user first to improve layer caching
RUN <<EOT bash
    set -euxo pipefail
    groupadd -r pandoc && useradd -r -g pandoc -G adm pandoc
    mkdir -p /data
    chown pandoc:pandoc /data
EOT

RUN <<EOT bash
    set -euxo pipefail
    echo "Installing system packages: ${SYSTEM_PACKAGES}"
    apt-get update
    apt-get install -y --no-install-recommends ${SYSTEM_PACKAGES}
    apt-get clean
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOT

RUN <<EOT bash
    set -euxo pipefail
    echo "Installing LaTeX packages: ${LATEX_PACKAGES}"
    tlmgr update --self
    tlmgr install ${LATEX_PACKAGES}
    tlmgr path remove
EOT

# Switch to non-root user
USER pandoc

WORKDIR /data
