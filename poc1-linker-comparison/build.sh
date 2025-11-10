#!/bin/bash
set -e

# --- 1. The Haskell Program ---
echo "Creating Hello.hs..."
cat > Hello.hs << EOL
main :: IO ()
main = putStrLn "Hello, Haskell!"
EOL

echo ""
echo "--- 2. Compiling to Object File (using LLVM) ---"
# -fllvm tells GHC to use the LLVM backend
# -c tells GHC to compile to an object file (.o) and stop.
ghc -fllvm -c Hello.hs -o Hello.o
echo "Created Hello.o"
echo ""

# --- 3. PoC Attempt 1: Linking with 'lld' (The Naive Way) ---
echo "--- Attempt 1: Linking with lld (The Wrong Way) ---"
echo "Running: ld.lld -o hello_fail Hello.o -lc -lm -lpthread -ldl"
echo "This will fail with 'undefined reference' errors..."
echo ""

# We use '|| true' to let the script continue even after lld fails.
# We add common C libs to be "fair" to lld.
# Note: On Linux, we use ld.lld (not just 'lld' which is a generic driver)
ld.lld -o hello_fail Hello.o -lc -lm -lpthread -ldl 2> lld_errors.log || true

if [ -s lld_errors.log ]; then
    echo "FAILED, as expected. lld errors:"
    grep "undefined reference" lld_errors.log | head -n 5
    echo "[... and many more, missing all 'base' and 'RTS' symbols]"
    rm lld_errors.log
else
    echo "Link with lld succeeded unexpectedly. This is very strange."
fi

echo ""
echo "--- 4. PoC Attempt 2: Capturing GHC's 'Secret' Command ---"
echo "Running: ghc -v -fllvm Hello.hs -o hello_success &> ghc_verbose.log"
echo "GHC will now act as a 'driver' and build the *real* link command."

# -v (verbose) makes GHC print every command it runs.
# We redirect all output to a log file.
ghc -v -fllvm Hello.hs -o hello_success &> ghc_verbose.log

echo "Success! Program built."
echo ""
echo "--- 5. Quantifying the Difference ---"
echo "Here is the REAL command GHC constructed and ran:"
echo "(This is the 'massive' command from the blog post)"
echo ""

# This grep/sed magic finds the final linker command in the verbose log.
# It looks for the line starting with '*** Linker:' and prints the command after it,
# or finds the last call to a linker program.
LINK_CMD=$(grep -A 1 '*** Linker:' ghc_verbose.log | tail -n 1 | sed 's/^[ \t]*//' | sed 's/ \\/ /g')

# Fallback if '*** Linker:' isn't found
if [ -z "$LINK_CMD" ]; then
    LINK_CMD=$(grep -E ' (gcc|clang|ld|lld) ' ghc_verbose.log | grep -- '-o hello_success' | tail -n 1)
fi

# Print it, wrapping it for readability
echo $LINK_CMD | fold -s -w 100
echo ""

ARG_COUNT=$(echo $LINK_CMD | wc -w)

echo "--- PoC Complete ---"
echo "Our simple command was: lld -o hello_fail Hello.o -lc -lm -lpthread -ldl (7 arguments)"
echo "GHC's real command had: $ARG_COUNT arguments."
echo ""
echo "Running the successful program:"
./hello_success

# Clean up
rm Hello.hs Hello.o *.hi ghc_verbose.log hello_success
