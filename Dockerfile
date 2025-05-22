FROM pandoc/latex:3.7-ubuntu

RUN <<EOT bash
    set -ex
    apt-get update
    apt-get install -y \
        --no-install-recommends \
        make \
        unzip \
        wget \
        ; \
    rm -rf /var/lib/apt/lists/*
EOT

# Extra Tex styles
RUN <<EOT bash
    set -ex
    tlmgr update --self
    tlmgr install \
        enumitem \
        moderncv \
        sectsty \
        underscore \
        ;
EOT

# Avoid running as root
RUN groupadd -r pandoc && useradd -r -g pandoc pandoc
USER pandoc

WORKDIR /work