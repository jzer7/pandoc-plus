FROM pandoc/latex:3.7-ubuntu

LABEL org.opencontainers.image.authors="Juan Rubio <j.c.rubio@gmail.com>"
LABEL org.opencontainers.image.base="pandoc/latex:3.7-ubuntu"
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
    apt-get update
    apt-get install -y \
        --no-install-recommends \
        make \
        unzip \
        wget \
        ;
    apt-get clean
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOT

# Extra Tex styles
RUN <<EOT bash
    set -euxo pipefail
    tlmgr update --self
    tlmgr install \
        enumitem \
        moderncv \
        sectsty \
        underscore \
        lastpage \
        ;
    tlmgr path remove
EOT

# Switch to non-root user
USER pandoc

WORKDIR /data
