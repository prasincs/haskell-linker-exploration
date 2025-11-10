#!/bin/bash

set -e

echo "============================================"
echo "Building PoC 3: gRPC Microservices"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Build Haskell server
echo -e "${YELLOW}Building Haskell Server...${NC}"
cd haskell-service
if command -v cabal &> /dev/null; then
    echo "Using cabal to build Haskell server..."
    cabal update
    cabal build
    echo -e "${GREEN}✓ Haskell server built successfully${NC}"
elif command -v ghc &> /dev/null; then
    echo "Building with ghc directly..."
    ghc -O2 -threaded Server.hs -o fib-server
    echo -e "${GREEN}✓ Haskell server built with GHC${NC}"
else
    echo -e "${RED}✗ Neither cabal nor ghc found. Please install GHC.${NC}"
    exit 1
fi
cd ..

echo ""

# Build C++ client
echo -e "${YELLOW}Building C++ Client...${NC}"
cd cpp-client

# Check for gRPC (optional - we have fallback)
if pkg-config --exists grpc++ 2>/dev/null; then
    echo "gRPC found - building with full gRPC support"
    mkdir -p build
    cd build
    cmake .. && make
    cd ..
    echo -e "${GREEN}✓ C++ client built with gRPC support${NC}"
elif command -v clang++ &> /dev/null; then
    # Check clang version (require 18+)
    CLANG_VERSION=$(clang++ --version | head -n1 | grep -oP '\d+\.\d+' | head -n1)
    CLANG_MAJOR=$(echo $CLANG_VERSION | cut -d. -f1)

    if [ "$CLANG_MAJOR" -lt 18 ]; then
        echo -e "${RED}✗ clang++ version $CLANG_VERSION found, but version 18+ required${NC}"
        echo "Please install clang++ 18 or later"
        exit 1
    fi

    echo "Building demo client with clang++ $CLANG_VERSION and lld..."
    clang++ -std=c++17 -O2 -fuse-ld=lld client.cpp -o fib-client -pthread 2>/dev/null || \
        clang++ -std=c++17 -O2 client.cpp -o fib-client -pthread
    clang++ -std=c++17 -O2 -fuse-ld=lld benchmark.cpp -o benchmark -pthread 2>/dev/null || \
        clang++ -std=c++17 -O2 benchmark.cpp -o benchmark -pthread
    echo -e "${GREEN}✓ C++ demo clients built with clang++ $CLANG_VERSION${NC}"
elif command -v g++ &> /dev/null; then
    echo "Warning: Using g++ (clang++ preferred for this project)"
    g++ -std=c++17 -O2 client.cpp -o fib-client -pthread
    g++ -std=c++17 -O2 benchmark.cpp -o benchmark -pthread
    echo -e "${GREEN}✓ C++ demo clients built with g++${NC}"
else
    echo -e "${RED}✗ No C++ compiler found (please install clang++)${NC}"
    exit 1
fi
cd ..

echo ""
echo "============================================"
echo -e "${GREEN}Build Complete!${NC}"
echo "============================================"
echo ""
echo "To run the demonstrations:"
echo ""
echo "  Haskell Server:"
echo "    cd haskell-service"
echo "    ./fib-server"
echo ""
echo "  C++ Client:"
echo "    cd cpp-client"
echo "    ./fib-client"
echo ""
echo "  Benchmarks:"
echo "    cd cpp-client"
echo "    ./benchmark"
echo ""
echo "For full gRPC setup, see README.md"
echo "============================================"
