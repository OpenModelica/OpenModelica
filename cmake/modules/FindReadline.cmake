## This is not fully tested.
## It is used only by the optional (default disabled) OMShell-terminal right now.

## readline needs curses. If you switch to static versions of readline enable this
## and explicitly add the target_link_libraries down below.
# find_package(Curses REQUIRED)

# Try finding with PkgConfig to get some hints
find_package(PkgConfig)
pkg_check_modules(PC_Readline QUIET readline)

# message(STATUS "PC_Readline_LIBRARIES: ${PC_Readline_LIBRARIES}")
# message(STATUS "PC_Readline_INCLUDE_DIRS: ${PC_Readline_INCLUDE_DIRS}")
# message(STATUS "PC_Readline_LIBRARY_DIRS: ${PC_Readline_LIBRARY_DIRS}")
# message(STATUS "PC_Readline_LDFLAGS: ${PC_Readline_LDFLAGS}")

## Find and set the Readline_INCLUDE_DIR using the info from PkgConfig
find_path(Readline_INCLUDE_DIR
  NAMES readline.h
  PATHS ${PC_Readline_INCLUDE_DIRS}
  PATH_SUFFIXES readline
)

## Find and set the Readline_LIBRARY using the info from PkgConfig
find_library(Readline_LIBRARY
  NAMES readline
  PATHS ${PC_Readline_LIBRARY_DIRS}
)

# message(STATUS "Readline_LIBRARY: ${Readline_LIBRARY}")
# message(STATUS "Readline_VERSION: ${Readline_VERSION}")

## Handle the standard CMake arguments, e.g REQUIRED, VERSION ...
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Readline
  FOUND_VAR Readline_FOUND
  REQUIRED_VARS
    Readline_LIBRARY
    Readline_INCLUDE_DIR
  VERSION_VAR Readline_VERSION
)

## Add an imported target for the library so we would not have to
## deal with specifying include directories and additional flags manually.
if(Readline_FOUND AND NOT TARGET Readline::Readline)
  add_library(Readline::Readline UNKNOWN IMPORTED)
  set_target_properties(Readline::Readline PROPERTIES
    IMPORTED_LOCATION "${Readline_LIBRARY}"
    INTERFACE_COMPILE_OPTIONS "${PC_Readline_CFLAGS_OTHER}"
    INTERFACE_INCLUDE_DIRECTORIES "${Readline_INCLUDE_DIR}"
  )
#   target_link_libraries(Readline::Readline INTERFACE ${CURSES_LIBRARIES})
endif()

## compatibility variables
set(Readline_VERSION_STRING ${Readline_VERSION})

## Hide some of the variables by default in user interfaces.
## They are just noise most of the time.
mark_as_advanced(
  Readline_INCLUDE_DIR
  Readline_LIBRARY
)
