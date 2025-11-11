#!/bin/bash
set -e

echo "--- Building Haskell Library (MyLib.hs) ---"
# 1. Compile the Haskell code into an object file (.o)
#    and an FFI header file (.h).
ghc -c MyLib.hs

echo ""
echo "--- Building C Main Program (main.c) ---"
# 2. Compile the C code into an object file using cc.
#    We need to tell the compiler where to find GHC's header files (HsFFI.h, etc.)
GHC_LIBDIR=$(ghc --print-libdir)
echo "GHC libdir: $GHC_LIBDIR"

# Try to find HsFFI.h by searching common locations
GHC_INCLUDE=""
for candidate in \
    "$GHC_LIBDIR/include" \
    "${GHC_LIBDIR%/lib}/include" \
    "$GHC_LIBDIR/../include" \
    "$GHC_LIBDIR/rts/include" \
    "${GHC_LIBDIR%/lib}/rts/include" \
    "$(dirname $(dirname $(which ghc)))/lib/ghc-$(ghc --numeric-version)/include" \
    "$(dirname $GHC_LIBDIR)/include" \
    ; do
    if [ -f "$candidate/HsFFI.h" ]; then
        GHC_INCLUDE="$candidate"
        break
    fi
done

# If still not found, use find as last resort
if [ -z "$GHC_INCLUDE" ]; then
    echo "Standard locations failed, searching with find..."
    GHC_BASE=$(dirname "$GHC_LIBDIR")
    FOUND=$(find "$GHC_BASE" -name "HsFFI.h" 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
        GHC_INCLUDE=$(dirname "$FOUND")
        echo "Found via search: $GHC_INCLUDE"
    fi
fi

if [ -z "$GHC_INCLUDE" ]; then
    echo "Error: Could not find HsFFI.h"
    echo "Searched in:"
    echo "  - $GHC_LIBDIR/include"
    echo "  - ${GHC_LIBDIR%/lib}/include"
    echo "  - $GHC_LIBDIR/../include"
    echo "  - $GHC_LIBDIR/rts/include"
    echo "  - And used find in $(dirname $GHC_LIBDIR)"
    exit 1
fi

echo "Found HsFFI.h in: $GHC_INCLUDE"
cc -c main.c -I. -I"$GHC_INCLUDE"

echo ""
echo "--- Attempt 1: Linking with clang/lld (The Wrong Way) ---"
echo "This will fail with 'undefined reference' errors."
if [ -t 0 ]; then
    echo "Press Enter to continue..."
    read
else
    echo "(Running in non-interactive mode, continuing automatically...)"
fi

# 3. This is the command that *should* work in a pure C/LLVM world,
#    but it will fail. We'll try to use cc as the driver.
#    It will fail to find all the Haskell libraries (RTS, base, etc.)
echo "Trying with cc as driver..."
cc -o my_program_fail main.o MyLib.o -pthread -ldl 2> clang_errors.txt || true

if [ -s clang_errors.txt ]; then
    echo "FAILED (with cc), as expected. Errors:"
    cat clang_errors.txt | grep "undefined reference" | head -n 5
    echo "[... and many more]"
    rm clang_errors.txt
else
    echo "Link with cc succeeded unexpectedly. Check your environment."
fi

echo ""
echo "Trying with ld.lld directly..."
# We add -lc, -lpthread, etc., which a driver would normally do.
# This will also fail, missing all the Haskell symbols.
# Note: On Linux, we use ld.lld (not just 'lld' which is a generic driver)
ld.lld -o my_program_fail main.o MyLib.o -lpthread -ldl -lc 2> lld_errors.txt || true

if [ -s lld_errors.txt ]; then
    echo "FAILED (with ld.lld), as expected. Errors:"
    cat lld_errors.txt | grep "undefined reference" | head -n 5
    echo "[... and many more]"
    rm lld_errors.txt
else
    echo "Link with ld.lld succeeded unexpectedly. Check your environment."
fi


echo ""
echo "--- Attempt 2: Linking with ghc (The Right Way) ---"
if [ -t 0 ]; then
    echo "Press Enter to continue..."
    read
else
    echo "(Running in non-interactive mode, continuing automatically...)"
fi

# 4. Use 'ghc' as the "general contractor" linker.
#    -no-hs-main: We are providing our own C 'main' function.
#    This command tells GHC to find the RTS and all 100+ dependencies.
ghc -o my_program_success main.o MyLib.o -no-hs-main

echo ""
echo "--- Success! ---"
echo "Created executable: ./my_program_success"
echo "Running it now:"
echo ""
./my_program_success

# Clean up build files
rm *.o *.hi *_stub.h my_program_success
