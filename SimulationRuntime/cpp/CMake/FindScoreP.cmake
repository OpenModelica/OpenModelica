# Find the header files of the scorep compiler wrapper.
#
# Sets the usual variables expected for find_package scripts:
#
# SCOREP_INCLUDE_DIR - header location
# SCOREP_FOUND - true if pugixml was found.
#
# To influence the behaviour, you can use the following variable:
#   SCOREP_HOME - the folder that contains the scorep include folder

find_path (SCOREP_INCLUDE_DIR NAMES scorep/SCOREP_User.h PATHS ${SCOREP_HOME}/include)

include (FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS (SCOREP DEFAULT_MSG SCOREP_INCLUDE_DIR)

if (NOT SCOREP_FOUND)
  message (FATAL_ERROR "ScoreP includes not found")
endif(NOT SCOREP_FOUND)

message(STATUS "ScoreP includes ${SCOREP_INCLUDE_DIR}")

mark_as_advanced (SCOREP_INCLUDE_DIR)
