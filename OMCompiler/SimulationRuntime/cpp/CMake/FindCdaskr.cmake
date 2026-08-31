# Find Cdaskr include dir and sources
#
# Sets the variables:
#
# CDASKR_INCLUDE_DIR - header location
# CDASKR_SRCS - list of all source files (cause they are splited above several directories).
# CDASKR_FOUND - true if Cdaskr was found.
#

FIND_PATH(CDASKR_INCLUDE_DIR NAMES ddaskr_types.h PATHS "${CMAKE_SOURCE_DIR}/../../3rdParty/Cdaskr/solver/" NO_DEFAULT_PATH)

IF(CDASKR_INCLUDE_DIR)
  FILE(GLOB CDASKR_SRCS "${CDASKR_INCLUDE_DIR}/*.c")
ELSE(CDASKR_INCLUDE_DIR)
  MESSAGE(STATUS "Cdaskr includes not found.")
ENDIF(CDASKR_INCLUDE_DIR)

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Cdaskr DEFAULT_MSG CDASKR_INCLUDE_DIR CDASKR_SRCS)
