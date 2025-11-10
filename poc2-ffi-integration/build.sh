#!/bin/bash
set -e

echo "--- Building Haskell Library (MyLib.hs) ---"
# 1. Compile the Haskell code into an object file (.o)
#    and an FFI header file (.h).
ghc -c MyLib.hs

echo ""
echo "--- Building C Main Program (main.c) ---"
# 2. Compile the C code into an object file using clang.
#    Note: The Docker container has 'gcc' from build-essential,
#    let's use 'cc' to be generic, which will point to gcc.
cc -c main.c -I. # -I. tells clang to look for headers in the current dir

echo ""
echo "--- Attempt 1: Linking with clang/lld (The Wrong Way) ---"
echo "This will fail with 'undefined reference' errors."
echo "Press Enter to continue..."
read

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
echo "Trying with lld directly..."
# We add -lc, -lpthread, etc., which a driver would normally do.
# This will also fail, missing all the Haskell symbols.
lld -o my_program_fail main.o MyLib.o -lpthread -ldl -lc 2> lld_errors.txt || true

if [ -s lld_errors.txt ]; then
    echo "FAILED (with lld), as expected. Errors:"
    cat lld_errors.txt | grep "undefined reference" | head -n 5
    echo "[... and many more]"
    rm lld_errors.txt
else
    echo "Link with lld succeeded unexpectedly. Check your environment."
fi


echo ""
echo "--- Attempt 2: Linking with ghc (The Right Way) ---"
echo "Press Enter to continue..."
read

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
