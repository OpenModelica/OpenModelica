CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

PROJECT(ParModelicaExpl)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}")

FIND_PACKAGE(OpenCL REQUIRED)

SET(PARMODELICA_SRC omc_ocl_memory_ops.cpp
                    omc_ocl_interface.cpp
                    omc_ocl_builtin_kernels.cpp
                    omc_ocl_util.cpp)

SET(PARMODELICA_OffCompiler_SRC ocl_offcomp.cpp)


INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})
INCLUDE_DIRECTORIES(../../../c)


ADD_LIBRARY(ParModelicaExpl ${PARMODELICA_SRC})

ADD_EXECUTABLE(ParModelicaOCLOffCompiler ${PARMODELICA_OffCompiler_SRC})

TARGET_LINK_LIBRARIES(ParModelicaOCLOffCompiler ParModelicaExpl ${OPENCL_LIBRARY})