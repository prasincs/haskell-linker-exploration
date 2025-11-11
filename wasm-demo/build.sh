#!/bin/bash

set -e

echo "============================================"
echo "Building WebAssembly Demo"
echo "============================================"
echo ""

# Check for GHC with WASM support
if command -v ghc &> /dev/null; then
    GHC_VERSION=$(ghc --numeric-version)
    echo "Found GHC version: $GHC_VERSION"

    # GHC 9.8+ has better WASM support
    if [[ $(echo "$GHC_VERSION >= 9.8" | bc -l 2>/dev/null) -eq 1 ]]; then
        echo "✓ GHC version supports WASM backend"

        echo ""
        echo "Building Haskell to WASM..."
        cd src

        # Note: WASM backend is still experimental
        # This is a placeholder for when it's more mature
        echo "Note: Full WASM compilation requires:"
        echo "  - GHC with WASM backend enabled"
        echo "  - wasm32-wasi target support"
        echo "  - emscripten or similar toolchain"
        echo ""
        echo "For now, the demo uses JavaScript fallback"

        # Example command (when WASM backend is available):
        # ghc --make -fwasm -optl-mexec-model=reactor \
        #     -o ../public/wasm/fibonacci.wasm Fibonacci.hs

        cd ..
    else
        echo "⚠ GHC version < 9.8 detected"
        echo "  WASM support requires GHC 9.8 or later"
        echo "  Demo will use JavaScript fallback"
    fi
else
    echo "⚠ GHC not found"
    echo "  Demo will use JavaScript fallback"
fi

echo ""
echo "============================================"
echo "Demo ready!"
echo "============================================"
echo ""
echo "To run the demo:"
echo ""
echo "  # Using Python"
echo "  cd wasm-demo/public"
echo "  python3 -m http.server 8080"
echo ""
echo "  # Using Node.js (if npx is installed)"
echo "  cd wasm-demo/public"
echo "  npx serve ."
echo ""
echo "Then open: http://localhost:8080"
echo ""
echo "Note: Full WASM compilation requires GHC 9.8+ with WASM backend."
echo "The demo currently uses JavaScript fallback for maximum compatibility."
echo "============================================"
