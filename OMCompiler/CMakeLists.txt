cmake_minimum_required(VERSION 3.14)
project(OMCompiler)

# set(CMAKE_VERBOSE_MAKEFILE ON)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/.cmake/")
include(omc_utils)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING
      "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif(NOT CMAKE_BUILD_TYPE)
omc_add_to_report(CMAKE_BUILD_TYPE)

omc_add_subdirectory(3rdParty)
omc_add_subdirectory(SimulationRuntime)
omc_add_subdirectory(Compiler)
omc_add_subdirectory(Parser)


message(STATUS "--------------------------------------------------------------------------")
message(STATUS "--------------------------------------------------------------------------")
feature_summary(WHAT ALL)












# # Defines for Visual Studio
# if(MSVC)
# 	add_definitions(-D_CRT_SECURE_NO_WARNINGS -DNOMINMAX -D_COMPLEX_DEFINED)
# endif(MSVC)

# # Global Variables
# SET(OMCTRUNCHOME ${CMAKE_CURRENT_SOURCE_DIR})
# SET(CODEGENDIR ${CMAKE_CURRENT_BINARY_DIR}/codegen)
# SET(OPENMODELICAHOME $ENV{OPENMODELICAHOME})
# SET(OMC_DEBUG ${OPENMODELICAHOME}/bin/omc.exe)

# # Tests
# OPTION(RUN_TESTS  "Run Tests"  OFF)
# IF(RUN_TESTS)
# enable_testing()
# ADD_SUBDIRECTORY(testsuite)
# ENDIF(RUN_TESTS)

# # Subdirectorys
# #ADD_SUBDIRECTORY(modelica_parser)
# #ADD_SUBDIRECTORY(flat_modelica_parser)
# #ADD_SUBDIRECTORY(Compiler)
# #ADD_SUBDIRECTORY(doc)
# #ADD_SUBDIRECTORY(Examples)
# ADD_SUBDIRECTORY(SimulationRuntime)
# #ADD_SUBDIRECTORY(3rdParty/FMIL/ThirdParty/Expat/expat-2.0.1)

# IF(RUN_TESTS)
# # -------------------------------------------------------------
# # Models
# # -------------------------------------------------------------
# # add here your models to compile (add filename without ".mo")
# # Example:
# #    BUILDMODEL(model dir Flags CSRC)
# #BUILDMODEL(BouncingBall ${CMAKE_CURRENT_SOURCE_DIR}/testsuite/mosfiles-dassl -d=bltdump "")
# #BUILDMODELFMU(Test ${CMAKE_CURRENT_SOURCE_DIR}/build/bin/Test/FMU -d=bltdump "")
# #BUILDMODELMOS(PolyEvaluate2 PolynomialEvaluatorB.mos ${CMAKE_CURRENT_SOURCE_DIR}/testsuite/simulation/modelica/arrays  +simCodeTarget=C "")
# #BUILDMODELFMUMOS(WheelLoader D:/Temp/Modell/Radlader-CNH/WheelLoader.mos -d=bltdump "")
# ENDIF(RUN_TESTS)
