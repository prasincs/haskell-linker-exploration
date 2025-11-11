cmake_minimum_required(VERSION 3.15)
project(FibonacciClient CXX)

# Require clang++ 18 or later
set(CMAKE_CXX_COMPILER "clang++")
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Check compiler version
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "18.0")
        message(FATAL_ERROR "clang++ 18 or later is required. Found: ${CMAKE_CXX_COMPILER_VERSION}")
    endif()
    # Use lld linker
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=lld")
endif()

# Find packages
find_package(Threads REQUIRED)
find_package(Protobuf REQUIRED)
find_package(gRPC CONFIG)

# Proto file
set(PROTO_FILES ../proto/fibonacci.proto)

# Generated sources
set(PROTO_SRC_DIR ${CMAKE_CURRENT_BINARY_DIR}/proto-src)
file(MAKE_DIRECTORY ${PROTO_SRC_DIR})

set(PROTO_SRCS "${PROTO_SRC_DIR}/fibonacci.pb.cc")
set(PROTO_HDRS "${PROTO_SRC_DIR}/fibonacci.pb.h")
set(GRPC_SRCS "${PROTO_SRC_DIR}/fibonacci.grpc.pb.cc")
set(GRPC_HDRS "${PROTO_SRC_DIR}/fibonacci.grpc.pb.h")

# Custom command to generate proto files
add_custom_command(
    OUTPUT "${PROTO_SRCS}" "${PROTO_HDRS}" "${GRPC_SRCS}" "${GRPC_HDRS}"
    COMMAND protobuf::protoc
    ARGS --grpc_out "${PROTO_SRC_DIR}"
         --cpp_out "${PROTO_SRC_DIR}"
         -I "${CMAKE_CURRENT_SOURCE_DIR}/../proto"
         --plugin=protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_cpp_plugin>
         "${CMAKE_CURRENT_SOURCE_DIR}/../proto/fibonacci.proto"
    DEPENDS "${PROTO_FILES}"
    COMMENT "Generating protocol buffer files"
)

# Executable
add_executable(fib-client
    client.cpp
    benchmark.cpp
    ${PROTO_SRCS}
    ${GRPC_SRCS}
)

target_include_directories(fib-client PRIVATE ${PROTO_SRC_DIR})

if(gRPC_FOUND)
    target_link_libraries(fib-client
        gRPC::grpc++
        gRPC::grpc++_reflection
        protobuf::libprotobuf
        Threads::Threads
    )
else()
    # Fallback for systems without gRPC config
    target_link_libraries(fib-client
        grpc++
        grpc++_reflection
        protobuf
        Threads::Threads
    )
endif()
