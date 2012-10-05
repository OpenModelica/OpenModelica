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
#ADD_SUBDIRECTORY(c_runtime)
#ADD_SUBDIRECTORY(modelica_parser)
#ADD_SUBDIRECTORY(flat_modelica_parser)
#ADD_SUBDIRECTORY(Compiler)
#ADD_SUBDIRECTORY(doc)
#ADD_SUBDIRECTORY(Examples)
ADD_SUBDIRECTORY(SimulationRuntime)
ADD_SUBDIRECTORY(3rdParty/FMIL/ThirdParty/Expat/expat-2.0.1)

# -------------------------------------------------------------
# Models
# -------------------------------------------------------------
# add here your models to compile (add filename without ".mo")
# Example:
#    BUILDMODEL(model dir Flags CSRC)
#BUILDMODEL(BouncingBall ${CMAKE_CURRENT_SOURCE_DIR}/testsuite/mosfiles-dassl +d=bltdump "")
#BUILDMODEL(Test ${CMAKE_CURRENT_SOURCE_DIR}/build/bin/Test +d=dumpdaelow)
#BUILDMODEL(WheelLoader_der_state ${CMAKE_CURRENT_SOURCE_DIR}/build/bin/Test +d=bltdump "")
#BUILDMODELFMU(Test ${CMAKE_CURRENT_SOURCE_DIR}/build/bin/Test/FMU +d=bltdump "")
#BUILDMODEL(Test1 ${CMAKE_CURRENT_SOURCE_DIR}/build/bin/Test/FMU +d=bltdump "")
#BUILDMODEL(CombiTable2DTest CombiTable2DTest.mo ${OMCTRUNCHOME}/build/bin/Test +d= "")
BUILDMODELMOS(BouncingBall BouncingBall.mos ${CMAKE_CURRENT_SOURCE_DIR}/testsuite/mosfiles  +simCodeTarget=C "")
#BUILDMODELFMUMOS(WheelLoader D:/Temp/Modell/Radlader-CNH/WheelLoader.mos +d=bltdump "")
#BUILDMODELFMUMOS(Weidemann_CX60_Sarturis D:/Programming/Models/Radlader_Hexapod/FMU/fmu.mos +d=bltdump "")
