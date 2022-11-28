# This small module finds and sets up
# libbfd from binutils which is need for providing backtrace support for OMEdit.
# The library is not installed in the standard location on MinGW. It is in
# lib/binutils. This module makes sure that it can be found.
# It exports an imported target 'binutils::bfd' for the library
# which brings in the dependency 'libiberty' (binutils::iberty) library with it.

if(binutils_FOUND)
  return()
endif()

find_library(LIBBFD_LIBRARY
             NAMES libbfd.a
             PATH_SUFFIXES binutils)

find_library(LIBIBERTY_LIBRARY
             NAMES libiberty.a
             PATH_SUFFIXES binutils)

if(MINGW)
  find_path(BINUTILS_INCLUDE_DIR
            bfd.h
            PATHS include
            PATH_SUFFIXES binutils)
endif()

include (FindPackageHandleStandardArgs)


# handle the QUIETLY and REQUIRED arguments and set binutils_FOUND to TRUE if all listed variables are TRUE
find_package_handle_standard_args(binutils
                                  REQUIRED_VARS LIBBFD_LIBRARY LIBIBERTY_LIBRARY BINUTILS_INCLUDE_DIR
                                  HANDLE_COMPONENTS)

mark_as_advanced(LIBBFD_LIBRARY LIBIBERTY_LIBRARY BINUTILS_INCLUDE_DIR)

if(binutils_FOUND)

  find_package(Intl REQUIRED)

  add_library(binutils::iberty STATIC IMPORTED)
  set_target_properties(binutils::iberty PROPERTIES IMPORTED_LOCATION ${LIBIBERTY_LIBRARY})

  add_library(binutils::bfd STATIC IMPORTED)
  set_target_properties(binutils::bfd PROPERTIES IMPORTED_LOCATION ${LIBBFD_LIBRARY})
  set_target_properties(binutils::bfd PROPERTIES INTERFACE_INCLUDE_DIRECTORIES ${BINUTILS_INCLUDE_DIR})

  target_link_libraries(binutils::bfd INTERFACE binutils::iberty)
  target_link_libraries(binutils::bfd INTERFACE ${Intl_LIBRARIES})
endif()
