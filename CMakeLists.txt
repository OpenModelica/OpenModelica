# PROJECT
PROJECT(OpenModelica)

# CMAKE
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)

# Includes
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/c_runtime)


# OMC Compiler
SET(OMC ${CMAKE_CURRENT_SOURCE_DIR}/build/bin/omcd.exe)
MESSAGE(" omc is " ${OMC})
# Subdirectorys
ADD_SUBDIRECTORY(c_runtime)
#ADD_SUBDIRECTORY(modelica_parser)
#ADD_SUBDIRECTORY(flat_modelica_parser)
#ADD_SUBDIRECTORY(Compiler)

# -------------------------------------------------------------
# Models
# -------------------------------------------------------------
# add here your models to compile (add filename without ".mo")
# Example:
#    BUILDMODEL(model dir Flags CSRC)

BUILDMODEL(BouncingBall ${CMAKE_CURRENT_SOURCE_DIR}/testsuite/mofiles +d=bltdump)
#BUILDMODEL(Simple ${CMAKE_CURRENT_SOURCE_DIR}/build/bin/Test +d=bltdump)
#BUILDMODEL(CombiTable2DTest ${CMAKE_CURRENT_SOURCE_DIR}/build/bin/Test +d=bltdump "")
