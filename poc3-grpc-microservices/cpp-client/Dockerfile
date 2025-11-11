FROM debian:bookworm-slim as builder

WORKDIR /build

# Install build dependencies with clang 18 and lld
RUN apt-get update && \
    apt-get install -y \
        wget \
        gnupg \
        software-properties-common \
        cmake \
        build-essential \
    && wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && echo "deb http://apt.llvm.org/bookworm/ llvm-toolchain-bookworm-18 main" > /etc/apt/sources.list.d/llvm.list \
    && apt-get update \
    && apt-get install -y clang-18 lld-18 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100 \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100 \
    && update-alternatives --install /usr/bin/lld lld /usr/bin/lld-18 100 \
    && rm -rf /var/lib/apt/lists/*

# Copy source files
COPY client.cpp benchmark.cpp ./

# Build with clang++ and lld linker (demonstrating modern LLVM toolchain)
RUN clang++ -std=c++17 -O2 -fuse-ld=lld client.cpp -o fib-client -pthread && \
    clang++ -std=c++17 -O2 -fuse-ld=lld benchmark.cpp -o benchmark -pthread

# Runtime image
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y \
        libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binaries from builder
COPY --from=builder /build/fib-client .
COPY --from=builder /build/benchmark .

CMD ["./fib-client"]
