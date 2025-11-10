{-# LANGUAGE ForeignFunctionInterface #-}

module MyLib where

import Foreign.C.Types

-- | Calculate the nth Fibonacci number
-- This is a simple, naive recursive implementation for demonstration purposes
fibonacci :: Int -> Int
fibonacci 0 = 0
fibonacci 1 = 1
fibonacci n = fibonacci (n-1) + fibonacci (n-2)

-- | FFI-exported wrapper for the Fibonacci function
-- The 'foreign export ccall' pragma makes this function callable from C
-- The function signature must use C-compatible types (CInt)
foreign export ccall hs_fib :: CInt -> CInt

hs_fib :: CInt -> CInt
hs_fib n = fromIntegral $ fibonacci (fromIntegral n)
