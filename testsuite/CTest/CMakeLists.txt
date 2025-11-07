cmake_minimum_required(VERSION 3.14)
project(UnitTests
        LANGUAGES CXX)

# GoogleTest requires at least C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


# Download GoogleTest, avoid global collisions with a unique fetchContent source directory
set(FETCHCONTENT_BASE_DIR "${CMAKE_BINARY_DIR}/_deps_ctest")
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/03597a01ee50ed33e9dfd640b249b4be3799d395.zip
  DOWNLOAD_EXTRACT_TIMESTAMP ON
)
# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# Add include directory for all tests
include(GoogleTest)

# Include subdirectories
add_subdirectory(OMCompiler/SimulationRuntime/c)

# Used to build all testsuite dependencies before running unit tests
add_custom_target(ctestsuite-depends DEPENDS
  ctestsuite-simulationruntime-c
)
