# Comprehensive Dockerfile for all Haskell Linker Exploration PoCs
# Based on official GHC image with additional tools

FROM haskell:9.4.8

# Metadata
LABEL maintainer="prasanna"
LABEL description="Haskell Linker Exploration - Demonstrating GHC's role as a linker orchestrator"
LABEL version="1.0"

# Switch to root for system package installation
USER root

# Update and install system dependencies
# - lld: LLVM linker for testing naive linking attempts
# - llvm: LLVM toolchain (opt, llc) for GHC's -fllvm backend
# - build-essential: gcc, g++, make for C/C++ compilation
# - libgmp-dev: Required by GHC for arbitrary-precision integers
# - cmake: For building C++ projects
# - protobuf-compiler: For gRPC PoC (protocol buffers)
# - vim, less: Utilities for interactive exploration
RUN apt-get update && \
    apt-get install -y \
        lld \
        llvm \
        build-essential \
        libgmp-dev \
        cmake \
        protobuf-compiler \
        vim \
        less \
        tree \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /poc

# Copy all project files
COPY . /poc/

# Make all shell scripts executable
RUN find /poc -type f -name "*.sh" -exec chmod +x {} \;

# Create output directory for logs and artifacts
RUN mkdir -p /poc/output

# Switch to non-root user (provided by base image)
USER stack

# Set environment variables for better output
ENV TERM=xterm-256color
ENV PAGER=less

# Default command: run the master demo script
CMD ["./scripts/run-all-demos.sh"]

# Alternative commands (can override with docker run):
# - Run specific PoC 1: docker run --rm ghc-linker-poc ./poc1-linker-comparison/build.sh
# - Run specific PoC 2: docker run --rm -it ghc-linker-poc ./poc2-ffi-integration/build.sh
# - Interactive shell: docker run --rm -it ghc-linker-poc /bin/bash
# - Analysis tool: docker run --rm ghc-linker-poc ./poc1-linker-comparison/analysis/compare_commands.sh

# Exposed ports (for future gRPC PoC)
EXPOSE 50051

# Health check (verify GHC is accessible)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ghc --version || exit 1

# Build instructions:
# docker build -t ghc-linker-poc .
#
# Run instructions:
# docker run --rm ghc-linker-poc                    # Run all demos
# docker run --rm -it ghc-linker-poc /bin/bash     # Interactive shell
