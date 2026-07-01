#---
# name: build-essential
# group: build
# notes: installs compilers, build tools & configures the default locale
# buildkit_device: nvidia.com/gpu=all
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive \
    LANGUAGE=en_US:en \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    WGET_FLAGS="--quiet --show-progress --progress=bar:force:noscroll --no-check-certificate --timeout=60 --tries=3 --retry-connrefused --retry-on-host-error --retry-on-http-error=500,502,503,504" \
    CCACHE_DIR=/root/.cache/ccache \
    CCACHE_MAXSIZE=20G \
    CCACHE_COMPRESS=1 \
    PATH=/usr/lib/ccache:${PATH}
    #TERM=dumb

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
        locales-all \
        tzdata \
    && locale-gen en_US $LANG \
    && update-locale LC_ALL=$LC_ALL LANG=$LANG \
    && locale \
    \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ccache \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        lsb-release \
        pkg-config \
        gnupg \
        git \
        git-lfs \
        gdb \
        wget \
        wget2 \
        curl \
        nano \
        zip \
        unzip \
        libnuma-dev \
        libibverbs-dev \
        time \
        sshpass \
        ssh-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    \
    && ccache --set-config=max_size=$CCACHE_MAXSIZE \
    && ccache --show-config \
    && gcc --version \
    && g++ --version \
    \
    # Abort-and-retry stalled git fetches instead of hanging forever: if a transfer
    # drops below ~1 KB/s for 60s, git aborts (the build's retry/|| logic re-attempts).
    # Deeply nested submodule clones (pytorch's kineto/dynolog, full-history ffmpeg)
    # can otherwise stall a single throttled GitHub fetch with no progress. --system
    # writes /etc/gitconfig so every later stage's git clone inherits it.
    && git config --system http.lowSpeedLimit 1000 \
    && git config --system http.lowSpeedTime 60

COPY tarpack vercmp /usr/local/bin/
RUN chmod a+rx /usr/local/bin/tarpack /usr/local/bin/vercmp
