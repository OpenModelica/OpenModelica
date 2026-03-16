# This script will build the doxygen based documentation for the c++ simulation runtime
#
# The following variables are used to modify the configuration file of doxygen.
#
#    TEMPLATE_ROOT_DIR            the root folder for all html and css files that define the layout and style
#    IMAGE_ROOT_DIR               path to the root folder containing the images
#    SOURCE_ROOT_DIR              path to the folder of the simulation runtime code
#    ADDITIONAL_DOC_ROOT_DIR      path to the folder containing additional doxygen files
#
# The behaviour can be influenced by passing arguments to CMAKE
#     if write output should be handled in parallel                                -DSOURCE_ROOT=PATH
#     if ScoreP should be used for performance analysis                            -DTARGET_PATH=PATH
#

cmake_minimum_required(VERSION 3.5)
PROJECT(CppSolverInterface)
set(CMAKE_VERBOSE_MAKEFILE ON)
LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/CMake")

MESSAGE(STATUS "CMake version ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}.${CMAKE_PATCH_VERSION}")

FIND_PACKAGE(Doxygen)

IF(NOT(SOURCE_ROOT))
  MESSAGE(FATAL_ERROR "Please specify the root directory of the c++ sources.")
ENDIF(NOT(SOURCE_ROOT))
SET(SOURCE_ROOT_DIR ${SOURCE_ROOT})

IF(NOT(TARGET_PATH))
  MESSAGE(STATUS "Target path was not set, so the current binary dir is used.")
  SET(TARGET_PATH ${CMAKE_CURRENT_BINARY_DIR})
ENDIF(NOT(TARGET_PATH))

SET(TEMPLATE_ROOT_DIR "../../doxygen")
SET(IMAGE_ROOT_DIR "./Images")
SET(ADDITIONAL_DOC_ROOT_DIR "./")

if (NOT DOXYGEN_FOUND)
  message(FATAL_ERROR "Doxygen is needed to build the documentation. Please install it correctly")
endif()
MESSAGE(STATUS "Build the documentation with Doxygen")
#-- Configure the Template Doxyfile for our specific project
configure_file(CppRuntimeDoc.config.in
               ${PROJECT_BINARY_DIR}/CppRuntimeDoc.config  @ONLY IMMEDIATE)
#-- Add a custom target to run Doxygen when ever the project is built
add_custom_target (Docs ALL
                   ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/CppRuntimeDoc.config
                   WORKING_DIRECTORY ${TARGET_PATH}
                   COMMENT "Generating API documentation with Doxygen" VERBATIM
                  )
