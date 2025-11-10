{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Main where

import Control.Concurrent (threadDelay)
import Control.Concurrent.Async (concurrently_)
import Data.Int (Int32, Int64)
import Data.Time.Clock (diffUTCTime, getCurrentTime)
import GHC.Generics (Generic)
import Network.GRPC.Server
import Network.GRPC.Server.Handlers.Trans
import qualified Data.ByteString.Char8 as BS
import Data.ProtoLens.Message (defMessage)
import System.IO (hSetBuffering, stdout, BufferMode(..))

-- Simple protobuf message representations
data FibRequest = FibRequest { fibReqN :: Int32 }
  deriving (Show, Generic)

data FibResponse = FibResponse
  { fibRespN :: Int32
  , fibRespResult :: Int64
  , fibRespComputationTimeMs :: Double
  }
  deriving (Show, Generic)

data BatchRequest = BatchRequest { batchReqNumbers :: [Int32] }
  deriving (Show, Generic)

data BatchResponse = BatchResponse
  { batchRespResults :: [FibResponse]
  , batchRespTotalTimeMs :: Double
  }
  deriving (Show, Generic)

-- Pure Haskell Fibonacci implementation (naive recursive - intentionally slow for benchmarking)
fibonacci :: Int -> Integer
fibonacci 0 = 0
fibonacci 1 = 1
fibonacci n = fibonacci (n-1) + fibonacci (n-2)

-- Optimized Fibonacci using memoization
fibMemo :: Int -> Integer
fibMemo n = fibs !! n
  where
    fibs = 0 : 1 : zipWith (+) fibs (tail fibs)

-- Calculate with timing
calculateFib :: Int32 -> IO FibResponse
calculateFib n = do
    startTime <- getCurrentTime
    let result = if n < 30
                 then fibonacci (fromIntegral n)  -- Use naive for small numbers
                 else fibMemo (fromIntegral n)    -- Use optimized for large numbers
    endTime <- getCurrentTime
    let timeDiff = realToFrac (diffUTCTime endTime startTime) * 1000  -- Convert to ms

    return FibResponse
        { fibRespN = n
        , fibRespResult = fromIntegral result
        , fibRespComputationTimeMs = timeDiff
        }

-- Handler for single calculation
handleCalculate :: FibRequest -> IO FibResponse
handleCalculate FibRequest{..} = do
    putStrLn $ "Calculating fib(" ++ show fibReqN ++ ")"
    result <- calculateFib fibReqN
    putStrLn $ "Result: " ++ show (fibRespResult result) ++ " (took " ++ show (fibRespComputationTimeMs result) ++ "ms)"
    return result

-- Handler for batch calculation
handleCalculateBatch :: BatchRequest -> IO BatchResponse
handleCalculateBatch BatchRequest{..} = do
    putStrLn $ "Batch calculation for " ++ show (length batchReqNumbers) ++ " numbers"
    startTime <- getCurrentTime

    -- Calculate all Fibonacci numbers
    results <- mapM calculateFib batchReqNumbers

    endTime <- getCurrentTime
    let totalTime = realToFrac (diffUTCTime endTime startTime) * 1000  -- Convert to ms

    putStrLn $ "Batch completed in " ++ show totalTime ++ "ms"
    return BatchResponse
        { batchRespResults = results
        , batchRespTotalTimeMs = totalTime
        }

-- Simplified gRPC server (note: actual implementation would use proto-lens generated code)
-- This is a demonstration showing the structure
main :: IO ()
main = do
    hSetBuffering stdout LineBuffering
    putStrLn "============================================"
    putStrLn "Haskell Fibonacci gRPC Server"
    putStrLn "============================================"
    putStrLn "Starting on port 50051..."
    putStrLn ""
    putStrLn "This is a demonstration server showing:"
    putStrLn "  - Pure Haskell implementations (naive and optimized)"
    putStrLn "  - Timing and benchmarking capabilities"
    putStrLn "  - Batch processing support"
    putStrLn ""
    putStrLn "Note: Full gRPC integration requires:"
    putStrLn "  - grpc-haskell package"
    putStrLn "  - proto-lens code generation"
    putStrLn "  - Proper RPC handlers"
    putStrLn ""
    putStrLn "For this PoC, see the standalone Fibonacci calculations below:"
    putStrLn "============================================"
    putStrLn ""

    -- Demonstrate the functions working
    putStrLn "Single calculations:"
    mapM_ (\n -> do
        result <- calculateFib n
        putStrLn $ "  fib(" ++ show n ++ ") = " ++ show (fibRespResult result)
                   ++ " (computed in " ++ show (fibRespComputationTimeMs result) ++ "ms)"
        ) [10, 20, 25, 30]

    putStrLn ""
    putStrLn "Batch calculation:"
    batch <- handleCalculateBatch (BatchRequest [5, 10, 15, 20, 25])
    putStrLn $ "  Total batch time: " ++ show (batchRespTotalTimeMs batch) ++ "ms"
    putStrLn $ "  Results count: " ++ show (length $ batchRespResults batch)

    putStrLn ""
    putStrLn "============================================"
    putStrLn "Server demonstration complete!"
    putStrLn ""
    putStrLn "To integrate with real gRPC:"
    putStrLn "  1. Install grpc-haskell: cabal install grpc-haskell"
    putStrLn "  2. Generate proto files: protoc --haskell_out=. fibonacci.proto"
    putStrLn "  3. Replace simplified handlers with real gRPC handlers"
    putStrLn "============================================"

    -- Keep server running for demo purposes
    putStrLn ""
    putStrLn "Press Ctrl+C to exit..."
    threadDelay maxBound  -- Wait indefinitely
