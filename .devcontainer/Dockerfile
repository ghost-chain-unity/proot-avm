# Use the same base image as devcontainer.json
FROM mcr.microsoft.com/devcontainers/go:2-1.25-trixie

# Install additional tools needed for proot-avm development
RUN apt-get update && apt-get install -y \
    qemu-system-x86 \
    qemu-utils \
    proot \
    iptables \
    curl \
    wget \
    git \
    make \
    nano \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Install Go tools for development
RUN go install golang.org/x/tools/cmd/goimports@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest && \
    go install golang.org/x/lint/golint@latest

# Set up workspace
WORKDIR /workspaces/proot-avm

# Copy go mod files first for better caching
COPY avm-go/go.mod avm-go/go.sum ./avm-go/

# Download dependencies
RUN cd avm-go && go mod download

# Copy the rest of the source code
COPY . .

# Build the Go CLI
RUN make build

# Set default shell
ENV SHELL /bin/bash

# Expose common ports for development
EXPOSE 2222 3000 8080

# Default command
CMD ["bash"]