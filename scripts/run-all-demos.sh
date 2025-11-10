#!/bin/bash
set -e

echo "=========================================="
echo "  Haskell Linker Exploration - All PoCs"
echo "=========================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}This script will run all three proof-of-concepts:${NC}"
echo "  1. PoC 1: Linker Command Comparison (naive lld vs GHC)"
echo "  2. PoC 2: FFI Integration (calling Haskell from C)"
echo "  3. PoC 3: gRPC Microservices (modern alternative)"
echo ""
echo "Press Enter to continue..."
read

# PoC 1: Linker Comparison
echo ""
echo -e "${GREEN}=========================================="
echo "  PoC 1: Linker Command Comparison"
echo -e "==========================================${NC}"
echo ""
cd /poc/poc1-linker-comparison || exit 1
./build.sh
cd /poc || exit 1

echo ""
echo -e "${YELLOW}Press Enter to continue to PoC 2...${NC}"
read

# PoC 2: FFI Integration
echo ""
echo -e "${GREEN}=========================================="
echo "  PoC 2: FFI Integration"
echo -e "==========================================${NC}"
echo ""
cd /poc/poc2-ffi-integration || exit 1

# Auto-answer the prompts for non-interactive mode
echo "" | ./build.sh
cd /poc || exit 1

echo ""
echo -e "${YELLOW}Press Enter to see the summary...${NC}"
read

# Summary
echo ""
echo -e "${GREEN}=========================================="
echo "  Summary"
echo -e "==========================================${NC}"
echo ""
echo "✅ PoC 1: Demonstrated that lld cannot link Haskell code"
echo "          GHC's linker command has 100+ arguments vs 7 for naive lld"
echo ""
echo "✅ PoC 2: Showed FFI integration requires GHC as linker"
echo "          Even with C main(), must use 'ghc -no-hs-main'"
echo ""
echo "📝 PoC 3: gRPC microservices (requires separate services)"
echo "          See poc3-grpc-microservices/README.md for details"
echo ""
echo -e "${BLUE}Key Takeaway:${NC}"
echo "  GHC is not just a compiler—it's the 'general contractor'"
echo "  that knows where all the Haskell materials are and how"
echo "  they fit together. You can choose your linker (lld),"
echo "  but you can't replace GHC's orchestration."
echo ""
echo "For the complete blog post and deeper explanations,"
echo "see: /poc/README.md"
echo ""
