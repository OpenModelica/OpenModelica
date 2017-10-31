# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2010-03-30
# CMakefile for compilation of OMC

# CMAKE
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
# PROJECT
PROJECT(OpenModelicaCompiler)

# Defines for Visual Studio
if(MSVC)
	add_definitions(-D_CRT_SECURE_NO_WARNINGS -DNOMINMAX -D_COMPLEX_DEFINED)
endif(MSVC)

# Global Variables
SET(OMCTRUNCHOME ${CMAKE_CURRENT_SOURCE_DIR})
SET(CODEGENDIR ${CMAKE_CURRENT_BINARY_DIR}/codegen)
SET(OPENMODELICAHOME $ENV{OPENMODELICAHOME})
SET(OMC_DEBUG ${OPENMODELICAHOME}/bin/omc.exe)

# Tests
OPTION(RUN_TESTS  "Run Tests"  OFF)
IF(RUN_TESTS)
enable_testing()
ADD_SUBDIRECTORY(testsuite)
ENDIF(RUN_TESTS)

# Subdirectorys
#ADD_SUBDIRECTORY(modelica_parser)
#ADD_SUBDIRECTORY(flat_modelica_parser)
#ADD_SUBDIRECTORY(Compiler)
#ADD_SUBDIRECTORY(doc)
#ADD_SUBDIRECTORY(Examples)
ADD_SUBDIRECTORY(SimulationRuntime)
#ADD_SUBDIRECTORY(3rdParty/FMIL/ThirdParty/Expat/expat-2.0.1)

IF(RUN_TESTS)
# -------------------------------------------------------------
# Models
# -------------------------------------------------------------
# add here your models to compile (add filename without ".mo")
# Example:
#    BUILDMODEL(model dir Flags CSRC)
#BUILDMODEL(BouncingBall ${CMAKE_CURRENT_SOURCE_DIR}/testsuite/mosfiles-dassl -d=bltdump "")
#BUILDMODELFMU(Test ${CMAKE_CURRENT_SOURCE_DIR}/build/bin/Test/FMU -d=bltdump "")
#BUILDMODELMOS(PolyEvaluate2 PolynomialEvaluatorB.mos ${CMAKE_CURRENT_SOURCE_DIR}/testsuite/simulation/modelica/arrays  +simCodeTarget=C "")
#BUILDMODELFMUMOS(WheelLoader D:/Temp/Modell/Radlader-CNH/WheelLoader.mos -d=bltdump "")
ENDIF(RUN_TESTS)
