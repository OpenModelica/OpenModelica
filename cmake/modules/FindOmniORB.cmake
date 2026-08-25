# FindOmniORB
# -----------
#
# Finds an omniORB installation: the two libraries omc needs for its CORBA
# interface (omniORB4 and omnithread) and the omniidl IDL compiler.
#
# This mirrors what the autotools build did in common/m4/corba.m4 for
# '--with-omniORB', i.e. locate 'omniidl' and link against
# '-lomniORB4 -lomnithread -lpthread'. As there, we cannot search for the
# libraries by symbol (they are C++) nor rely on a single fixed include layout,
# so pkg-config is used for hints and plain find_* calls do the rest.
#
# Hint variables
#   OmniORB_ROOT / OMNIORB_HOME  - Prefix of an omniORB installation to use.
#                                  Equivalent of '--with-omniORB=DIR'.
#
# Result variables
#   OmniORB_FOUND                - True if omniORB was found.
#   OmniORB_VERSION              - Version reported by pkg-config, if available.
#   OmniORB_INCLUDE_DIRS         - Include directories.
#   OmniORB_LIBRARIES            - Libraries to link against.
#   OmniORB_IDL_COMPILER         - Full path to the omniidl executable.
#   OmniORB_LINK_FLAGS           - '-L.../-l...' style flags. Used to substitute
#                                  @CORBALIBS@ in Compiler/Util/Autoconf.mo.in,
#                                  which is a plain string handed to gcc.
#
# Imported targets
#   OmniORB::omniORB4            - The ORB library.
#   OmniORB::omnithread          - The omniORB threading library.
#   OmniORB::OmniORB             - Convenience target linking both of the above
#                                  plus the platform thread library.

# Allow the usual '--with-omniORB=DIR' style override through OMNIORB_HOME as well.
if(NOT OmniORB_ROOT AND DEFINED ENV{OMNIORB_HOME})
  set(OmniORB_ROOT "$ENV{OMNIORB_HOME}")
endif()

# Try finding with PkgConfig to get some hints.
find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
  pkg_check_modules(PC_OmniORB QUIET omniORB4)
  pkg_check_modules(PC_Omnithread QUIET omnithread4)
endif()

find_path(OmniORB_INCLUDE_DIR
  NAMES omniORB4/CORBA.h
  HINTS ${OmniORB_ROOT}
  PATHS ${PC_OmniORB_INCLUDE_DIRS}
  PATH_SUFFIXES include
)

find_library(OmniORB_omniORB4_LIBRARY
  NAMES omniORB4
  HINTS ${OmniORB_ROOT}
  PATHS ${PC_OmniORB_LIBRARY_DIRS}
  PATH_SUFFIXES lib
)

# The library is called 'omnithread' on Unix installations and
# 'omnithread40_rt'/'omnithread4' on some Windows/prebuilt ones.
find_library(OmniORB_omnithread_LIBRARY
  NAMES omnithread omnithread4
  HINTS ${OmniORB_ROOT}
  PATHS ${PC_Omnithread_LIBRARY_DIRS}
  PATH_SUFFIXES lib
)

# The IDL compiler. Corresponds to IDLCMD/IDLPATH in the autotools build.
find_program(OmniORB_IDL_COMPILER
  NAMES omniidl
  HINTS ${OmniORB_ROOT}
  PATHS ${PC_OmniORB_PREFIX}
  PATH_SUFFIXES bin
)

if(PC_OmniORB_VERSION)
  set(OmniORB_VERSION ${PC_OmniORB_VERSION})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OmniORB
  FOUND_VAR OmniORB_FOUND
  REQUIRED_VARS
    OmniORB_omniORB4_LIBRARY
    OmniORB_omnithread_LIBRARY
    OmniORB_INCLUDE_DIR
    OmniORB_IDL_COMPILER
  VERSION_VAR OmniORB_VERSION
  FAIL_MESSAGE
    "Could NOT find omniORB. Install the omniORB development files and the omniidl compiler (Debian/Ubuntu: 'libomniorb4-dev omniidl', Fedora: 'omniORB-devel', Homebrew: 'omniorb'), or configure with -DOM_OMC_USE_CORBA=OFF to build without CORBA support."
)

if(OmniORB_FOUND)
  set(OmniORB_INCLUDE_DIRS ${OmniORB_INCLUDE_DIR})
  set(OmniORB_LIBRARIES ${OmniORB_omniORB4_LIBRARY} ${OmniORB_omnithread_LIBRARY})

  if(NOT TARGET OmniORB::omniORB4)
    add_library(OmniORB::omniORB4 UNKNOWN IMPORTED)
    set_target_properties(OmniORB::omniORB4 PROPERTIES
      IMPORTED_LOCATION "${OmniORB_omniORB4_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${OmniORB_INCLUDE_DIR}"
    )
  endif()

  if(NOT TARGET OmniORB::omnithread)
    add_library(OmniORB::omnithread UNKNOWN IMPORTED)
    set_target_properties(OmniORB::omnithread PROPERTIES
      IMPORTED_LOCATION "${OmniORB_omnithread_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${OmniORB_INCLUDE_DIR}"
    )
  endif()

  if(NOT TARGET OmniORB::OmniORB)
    find_package(Threads QUIET)
    add_library(OmniORB::OmniORB INTERFACE IMPORTED)
    set_target_properties(OmniORB::OmniORB PROPERTIES
      INTERFACE_LINK_LIBRARIES "OmniORB::omniORB4;OmniORB::omnithread"
    )
    if(TARGET Threads::Threads)
      set_property(TARGET OmniORB::OmniORB APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES Threads::Threads)
    endif()
  endif()

  # Flags for generated simulation/external-function code (@CORBALIBS@). The
  # autotools build hardcoded "-lomniORB4 -lomnithread -lpthread"; add the
  # library directory too in case omniORB lives outside the default search path.
  get_filename_component(_omniorb_libdir "${OmniORB_omniORB4_LIBRARY}" DIRECTORY)
  set(OmniORB_LINK_FLAGS "-lomniORB4 -lomnithread -lpthread")
  set(_omniorb_default_libdirs
      ${CMAKE_C_IMPLICIT_LINK_DIRECTORIES} ${CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES})
  if(NOT _omniorb_libdir IN_LIST _omniorb_default_libdirs)
    set(OmniORB_LINK_FLAGS "-L${_omniorb_libdir} ${OmniORB_LINK_FLAGS}")
  endif()
  unset(_omniorb_libdir)
  unset(_omniorb_default_libdirs)
endif()

mark_as_advanced(
  OmniORB_INCLUDE_DIR
  OmniORB_omniORB4_LIBRARY
  OmniORB_omnithread_LIBRARY
  OmniORB_IDL_COMPILER
)
