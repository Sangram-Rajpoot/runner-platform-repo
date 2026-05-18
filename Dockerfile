FROM ubuntu:24.04

ARG RUNNER_VERSION=2.333.1

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    jq \
    git \
    sudo \
    unzip \
    tar \
    gzip \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /home/runner -s /bin/bash runner \
    && usermod -aG sudo runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/runner/actions-runner

RUN ARCH="$(dpkg --print-architecture)" && \
    if [ "$ARCH" = "amd64" ]; then RUNNER_ARCH="x64"; \
    elif [ "$ARCH" = "arm64" ]; then RUNNER_ARCH="arm64"; \
    elif [ "$ARCH" = "armhf" ]; then RUNNER_ARCH="arm"; \
    else echo "Unsupported architecture: $ARCH" && exit 1; fi && \
    curl -fsSL -o actions-runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" && \
    tar xzf actions-runner.tar.gz && \
    rm actions-runner.tar.gz && \
    ./bin/installdependencies.sh

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && chown -R runner:runner /home/runner /entrypoint.sh

USER runner

ENTRYPOINT ["/entrypoint.sh"]
