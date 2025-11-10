#include <stdio.h>
#include "HsFFI.h" // GHC's main FFI header
#include "MyLib_stub.h" // The header generated from MyLib.hs

int main(int argc, char *argv[]) {
    // 1. Initialize the Haskell Runtime System (RTS)
    // This is the "life support"
    hs_init(&argc, &argv);

    // 2. Call our exported Haskell function
    int n = 10;
    int result = hs_fib(n);
    printf("Haskell calculated fib(%d) = %d\n", n, result);

    // 3. Shut down the Haskell RTS
    hs_exit();
    
    return 0;
}
