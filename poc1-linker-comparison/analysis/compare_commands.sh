#!/bin/bash
# Analysis script to parse and compare linker commands

set -e

echo "Linker Command Analysis Tool"
echo "============================="
echo ""

if [ ! -f "ghc_verbose.log" ]; then
    echo "Error: ghc_verbose.log not found!"
    echo "Please run build.sh first to generate the verbose log."
    exit 1
fi

echo "Extracting GHC's linker command..."
echo ""

# Extract the linker command
LINK_CMD=$(grep -A 1 '*** Linker:' ghc_verbose.log | tail -n 1 | sed 's/^[ \t]*//' | sed 's/ \\/ /g')

if [ -z "$LINK_CMD" ]; then
    LINK_CMD=$(grep -E ' (gcc|clang|ld|lld) ' ghc_verbose.log | grep -- '-o hello_success' | tail -n 1)
fi

# Count arguments
TOTAL_ARGS=$(echo $LINK_CMD | wc -w)

# Extract different categories
RTS_FILES=$(echo $LINK_CMD | grep -o '/.*rts.*/[^ ]*' | wc -l)
BASE_FILES=$(echo $LINK_CMD | grep -o '/.*base.*/[^ ]*' | wc -l)
PRIM_FILES=$(echo $LINK_CMD | grep -o '/.*prim.*/[^ ]*' | wc -l)
OTHER_HS_FILES=$(echo $LINK_CMD | grep -o '/.*libHS[^ ]*' | grep -v base | grep -v prim | grep -v rts | wc -l)
SYSTEM_LIBS=$(echo $LINK_CMD | grep -o '\-l[^ ]*' | wc -l)

echo "Analysis Results"
echo "================"
echo ""
echo "Total Arguments:        $TOTAL_ARGS"
echo ""
echo "Breakdown by Category:"
echo "  RTS files:            $RTS_FILES"
echo "  base library files:   $BASE_FILES"
echo "  ghc-prim files:       $PRIM_FILES"
echo "  Other Haskell libs:   $OTHER_HS_FILES"
echo "  System libraries:     $SYSTEM_LIBS"
echo ""

# Show unique library names
echo "Haskell Libraries Linked:"
echo $LINK_CMD | grep -o 'libHS[^/]*\.a' | sort -u | sed 's/^/  - /'
echo ""

echo "System Libraries Linked:"
echo $LINK_CMD | grep -o '\-l[^ ]*' | sort -u | sed 's/^/  /'
echo ""

# Compare with naive command
echo "Comparison:"
echo "  Naive lld command:    7 arguments"
echo "  GHC's command:        $TOTAL_ARGS arguments"
echo "  Difference:           $(($TOTAL_ARGS - 7)) additional arguments"
echo "  Multiplier:           $((TOTAL_ARGS / 7))x more complex"
echo ""

# Extract and show RTS library details
echo "Runtime System Libraries:"
echo $LINK_CMD | grep -o '/[^ ]*rts[^ ]*/[^ ]*\.a' | sort -u | sed 's/^/  /'
echo ""

echo "This demonstrates why GHC must act as the 'general contractor'"
echo "for linking Haskell programs. It knows about all these components"
echo "and their correct ordering, which a naive linker invocation cannot provide."
