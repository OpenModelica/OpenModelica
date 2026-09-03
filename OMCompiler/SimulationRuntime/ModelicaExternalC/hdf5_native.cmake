# HDF5 for ModelicaMatIO's MAT v7.3 support, from the system HDF5 (libhdf5-dev,
# hdf5-devel, hdf5-dev). Without it v7.3 stays unsupported, as it has always
# been.
#
# Linux only for now: elsewhere this would define HAVE_HDF5 on ModelicaMatIO
# without the Windows and macOS link lines having been checked.
if(UNIX AND NOT APPLE)
  set(_om_hdf5_default ON)
else()
  set(_om_hdf5_default OFF)
endif()
option(OM_ENABLE_HDF5 "Link the system HDF5 so ModelicaIO reads and writes MAT v7.3 files." ${_om_hdf5_default})
if(OM_ENABLE_HDF5)
  find_package(HDF5 COMPONENTS C)
  if(NOT HDF5_FOUND)
    message(STATUS "HDF5 not found; MAT v7.3 support (HAVE_HDF5) is off.")
  else()
    # Cached for Autoconf.mo.in, which is configured in another directory scope.
    # The library alone, by full path: -lhdf5 misses Debian's serial build, and
    # find_package's dependency closure would put its libz ahead of
    # OpenModelica's zlib.
    foreach(_lib IN LISTS HDF5_C_LIBRARIES)
      if(_lib MATCHES "hdf5")
        list(APPEND _om_hdf5_link ${_lib})
      endif()
    endforeach()
    string(REPLACE ";" " " _om_hdf5_link "${_om_hdf5_link}")
    set(OMC_HDF5_LDFLAGS "${_om_hdf5_link}" CACHE INTERNAL
        "HDF5 on a link line that names ModelicaMatIO, for its MAT v7.3 paths.")
  endif()
endif()

# Give a ModelicaMatIO target the v7.3 code paths.
function(omc_modelica_matio_hdf5 target visibility)
  if(NOT HDF5_FOUND)
    return()
  endif()
  target_compile_definitions(${target} ${visibility} HAVE_HDF5=1)
  target_include_directories(${target} PRIVATE ${HDF5_C_INCLUDE_DIRS})
  target_link_libraries(${target} PUBLIC ${HDF5_C_LIBRARIES})
endfunction()
