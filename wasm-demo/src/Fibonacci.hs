{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE JavaScriptFFI #-}

module Fibonacci where

import Data.Int (Int32, Int64)

-- Pure Haskell Fibonacci (naive recursive)
fibonacci :: Int -> Integer
fibonacci 0 = 0
fibonacci 1 = 1
fibonacci n = fibonacci (n-1) + fibonacci (n-2)

-- Optimized version using memoization
fibonacciMemo :: Int -> Integer
fibonacciMemo n = fibs !! n
  where
    fibs = 0 : 1 : zipWith (+) fibs (tail fibs)

-- Export for JavaScript/WASM
foreign export ccall "hs_fibonacci"
  hs_fibonacci :: Int32 -> Int64

hs_fibonacci :: Int32 -> Int64
hs_fibonacci n
  | n < 0     = 0
  | n < 30    = fromIntegral $ fibonacci (fromIntegral n)
  | otherwise = fromIntegral $ fibonacciMemo (fromIntegral n)

-- Export optimized version separately
foreign export ccall "hs_fibonacci_fast"
  hs_fibonacci_fast :: Int32 -> Int64

hs_fibonacci_fast :: Int32 -> Int64
hs_fibonacci_fast n
  | n < 0     = 0
  | otherwise = fromIntegral $ fibonacciMemo (fromIntegral n)

-- Batch calculation for benchmarking
foreign export ccall "hs_fibonacci_batch"
  hs_fibonacci_batch :: Int32 -> Int32 -> IO ()

hs_fibonacci_batch :: Int32 -> Int32 -> IO ()
hs_fibonacci_batch start end = do
  let results = map (hs_fibonacci_fast) [start..end]
  -- Force evaluation
  seq (sum results) (return ())

-- Information about the RTS
foreign export ccall "hs_runtime_info"
  hs_runtime_info :: IO Int32

hs_runtime_info :: IO Int32
hs_runtime_info = do
  -- Return a simple indicator that RTS is running
  return 1
