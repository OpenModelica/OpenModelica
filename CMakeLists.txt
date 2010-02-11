# PROJECT
PROJECT(OpenModelica)

# CMAKE
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)

# Includes
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/c_runtime)

# OMC Compiler
SET(OMC ${CMAKE_CURRENT_SOURCE_DIR}/build/bin/omcd.exe)

# Subdirectorys
ADD_SUBDIRECTORY(c_runtime)

# -------------------------------------------------------------
# Models
# -------------------------------------------------------------
# add here your models to compile (add filename without ".mo")
# Example:
#    BUILDMODEL(BouncingBall ${CMAKE_CURRENT_SOURCE_DIR}/testsuite/mofiles +d=bltdump)

BUILDMODEL(BouncingBall ${CMAKE_CURRENT_SOURCE_DIR}/testsuite/mofiles +d=bltdump)
