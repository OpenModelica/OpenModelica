# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2010-03-30
# CMakefile for compilation of OMC 

# CMAKE
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
# PROJECT
PROJECT(OpenModelicaCompiler)

# Global Variables
SET(OMCTRUNCHOME ${CMAKE_CURRENT_SOURCE_DIR})
SET(CODEGENDIR ${CMAKE_CURRENT_BINARY_DIR}/codegen)

# Tests
OPTION(RUN_TESTS  "Run Tests"  OFF)
IF(RUN_TESTS)
enable_testing()
ADD_SUBDIRECTORY(testsuite)
ENDIF(RUN_TESTS)

# Subdirectorys
ADD_SUBDIRECTORY(c_runtime)
ADD_SUBDIRECTORY(modelica_parser)
ADD_SUBDIRECTORY(flat_modelica_parser)
ADD_SUBDIRECTORY(Compiler)
ADD_SUBDIRECTORY(doc)
ADD_SUBDIRECTORY(Examples)

# -------------------------------------------------------------
# Models
# -------------------------------------------------------------
# add here your models to compile (add filename without ".mo")
# Example:
#    BUILDMODEL(model dir Flags CSRC)
SET(OMC_DEBUG ${OMCTRUNCHOME}/build/bin/omcd.exe)
#BUILDMODEL(BouncingBall ${CMAKE_CURRENT_SOURCE_DIR}/testsuite/mofiles +d=bltdump)
#BUILDMODEL(Simple ${CMAKE_CURRENT_SOURCE_DIR}/build/bin/Test +d=bltdump)
#BUILDMODEL(CombiTable2DTest ${CMAKE_CURRENT_SOURCE_DIR}/build/bin/Test +d=bltdump "")
