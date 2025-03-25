FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    clang \
    gcc \
    curl \
    make \
    strace \
    unzip \
    build-essential \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV WASI_VERSION=20
ENV WASI_SDK_PATH=/opt/wasi-sdk

RUN curl -LO https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_VERSION}/wasi-sdk-${WASI_VERSION}-linux.tar.gz && \
    tar -xzf wasi-sdk-${WASI_VERSION}-linux.tar.gz && \
    mv wasi-sdk-${WASI_VERSION} ${WASI_SDK_PATH} && \
    rm wasi-sdk-${WASI_VERSION}-linux.tar.gz

RUN curl -s https://wasmcloud.dev/install.sh | bash
ENV PATH="$HOME/.wasmcloud/bin:${PATH}"

WORKDIR /project
COPY . .

CMD ["make"]
