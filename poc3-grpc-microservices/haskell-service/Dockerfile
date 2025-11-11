FROM haskell:9.4 as builder

WORKDIR /build

# Copy cabal file and dependencies
COPY fib-server.cabal .
COPY Server.hs .

# Update cabal and build
RUN cabal update && \
    cabal build --only-dependencies && \
    cabal build

# Runtime image
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y \
        libgmp10 \
        netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binary from builder
COPY --from=builder /build/dist-newstyle/build/*/ghc-*/fib-server-*/x/fib-server/build/fib-server/fib-server .

EXPOSE 50051

CMD ["./fib-server"]
