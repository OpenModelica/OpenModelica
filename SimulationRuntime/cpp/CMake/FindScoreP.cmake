# Find the header files of the scorep compiler wrapper.
#
# Sets the usual variables expected for find_package scripts:
#
# SCOREP_INCLUDE_DIR - header location
# SCOREP_FOUND - true if scorep was found.
#
# To influence the behaviour, you can use the following variable:
#   SCOREP_HOME - the folder that contains the scorep include folder

IF(NOT SCOREP_HOME)
  SET(SCOREP_HOME $ENV{SCOREP_HOME})
ENDIF()

FIND_PATH(SCOREP_INCLUDE_DIR NAMES scorep/SCOREP_User.h PATHS ${SCOREP_HOME}/include)

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(SCOREP DEFAULT_MSG SCOREP_INCLUDE_DIR)

IF(NOT SCOREP_FOUND)
  MESSAGE(FATAL_ERROR "ScoreP includes not found")
ENDIF(NOT SCOREP_FOUND)

MESSAGE(STATUS "ScoreP includes ${SCOREP_INCLUDE_DIR}")

MARK_AS_ADVANCED(SCOREP_INCLUDE_DIR)