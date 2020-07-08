# Find the header and source files of the dgesv library.
#
# Sets the usual variables expected for find_package scripts:
#
# DGESV_INCLUDE_DIR - header location
# DGESV_SRCS - list of all source files (cause they are splited above several directories).
# DGESV_HEADERS - list all header files.
# DGESV_FOUND - true if dgesv was found.
#
# To influence the behaviour, you can use the following variable:
#   DGESV_HOME - the folder that contains the dgesv include and source folders.

IF(NOT DGESV_HOME)
  SET(DGESV_HOME $ENV{DGESV_HOME})
ENDIF()

FIND_PATH(DGESV_INCLUDE_DIR NAMES blaswrap.h PATHS "${CMAKE_SOURCE_DIR}/../../3rdParty/dgesv/include/" "${DGESV_HOME}/include/" NO_DEFAULT_PATH)

IF(DGESV_INCLUDE_DIR)
  FILE(GLOB DGESV_HEADERS "${DGESV_INCLUDE_DIR}/*.h")
  FIND_PATH(DGESV_SRC_DIR_BLAS NAMES dgemm.c PATHS "${CMAKE_SOURCE_DIR}/../../3rdParty/dgesv/blas/" "${DGESV_HOME}/blas/" NO_DEFAULT_PATH)
  FIND_PATH(DGESV_SRC_DIR_LAPACK NAMES dgesv.c PATHS "${CMAKE_SOURCE_DIR}/../../3rdParty/dgesv/lapack/" "${DGESV_HOME}/lapack/" NO_DEFAULT_PATH)

  IF(DGESV_SRC_DIR_BLAS AND DGESV_SRC_DIR_LAPACK)
    FILE(GLOB DGESV_SRCS "${DGESV_SRC_DIR_BLAS}/*.c" "${DGESV_SRC_DIR_LAPACK}/*.c" "${DGESV_INCLUDE_DIR}/../libf2c/*.c")
  ELSE()
    MESSAGE(STATUS "Dgesv sources not found.")
  ENDIF()

ELSE(DGESV_INCLUDE_DIR)
  MESSAGE(STATUS "Dgesv includes not found.")
ENDIF(DGESV_INCLUDE_DIR)

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(DGESV DEFAULT_MSG DGESV_INCLUDE_DIR DGESV_SRCS)