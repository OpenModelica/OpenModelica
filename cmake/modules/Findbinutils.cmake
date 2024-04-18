# This small module (which is not as 'proper' as it should be) finds and sets up
# libbfd from binutils. libbfd is need for providing crash reporting backtrace
# support for OMEdit on Windows (OMDev/MinGW). Unfortunately neither CMake nor
# the binutils people provide a CMake module or config files to set up the libraries.

# This small module tries to find libbfd as well as its dependencies. Currently these
# are libiberty, libsframe, libzstd and libintl. The first two are part of the binutils packages
# so we manually manage the finding here.

# zstd is a separate package and comes with its own CMake config files
# (at least on recent versions) so we use that. That is perfect.

# libintl is also a separate package and a find module is provided by CMake
# itself for now (albeit old style, i.e, no imported targets)

# Finally this module exports an imported targets 'binutils::bfd', 'binutils::iberty' and
# binutils::sframe to be used as needed.

if(binutils_FOUND)
  return()
endif()

find_library(LIBBFD_LIBRARY
             NAMES libbfd.a)

find_library(LIBIBERTY_LIBRARY
             NAMES libiberty.a)

find_library(LIBSFRAME_LIBRARY
             NAMES libsframe.a)


if(MINGW)
  find_path(BINUTILS_INCLUDE_DIR
            bfd.h
            PATHS include)
endif()

include (FindPackageHandleStandardArgs)


# handle the QUIETLY and REQUIRED arguments and set binutils_FOUND to TRUE if all listed variables are TRUE
find_package_handle_standard_args(binutils
                                  REQUIRED_VARS LIBBFD_LIBRARY LIBIBERTY_LIBRARY LIBSFRAME_LIBRARY BINUTILS_INCLUDE_DIR
                                  HANDLE_COMPONENTS)

mark_as_advanced(LIBBFD_LIBRARY LIBIBERTY_LIBRARY LIBSFRAME_LIBRARY BINUTILS_INCLUDE_DIR)

if(binutils_FOUND)

  find_package(Intl REQUIRED)
  find_package(zstd CONFIG REQUIRED)

  add_library(binutils::iberty STATIC IMPORTED)
  set_target_properties(binutils::iberty PROPERTIES IMPORTED_LOCATION ${LIBIBERTY_LIBRARY})

  add_library(binutils::sframe STATIC IMPORTED)
  set_target_properties(binutils::sframe PROPERTIES IMPORTED_LOCATION ${LIBSFRAME_LIBRARY})

  add_library(binutils::bfd STATIC IMPORTED)
  set_target_properties(binutils::bfd PROPERTIES IMPORTED_LOCATION ${LIBBFD_LIBRARY})
  set_target_properties(binutils::bfd PROPERTIES INTERFACE_INCLUDE_DIRECTORIES ${BINUTILS_INCLUDE_DIR})

  target_link_libraries(binutils::bfd INTERFACE binutils::iberty)
  target_link_libraries(binutils::bfd INTERFACE binutils::sframe)
  target_link_libraries(binutils::bfd INTERFACE zstd::libzstd_static)
  target_link_libraries(binutils::bfd INTERFACE ${Intl_LIBRARIES})
endif()
