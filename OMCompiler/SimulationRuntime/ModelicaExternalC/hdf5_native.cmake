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
    # The library alone: -lhdf5 misses Debian's serial build, and find_package's
    # dependency closure would put its libz ahead of OpenModelica's zlib.
    # By soname (-l:libhdf5_serial.so.103), not by path: the generated code is
    # linked on the user's machine, which need not have this host's -dev
    # package. ld finds it in lib/<triple>/omc, where linux-deploy.sh bundles
    # it, or in its default directories.
    foreach(_lib IN LISTS HDF5_C_LIBRARIES)
      # Config mode (hdf5-config.cmake) names imported targets, not paths.
      # Arch's import is per-configuration, so IMPORTED_LOCATION is empty.
      set(_path "${_lib}")
      if(TARGET ${_lib})
        set(_path "")
        get_target_property(_cfgs ${_lib} IMPORTED_CONFIGURATIONS)
        foreach(_cfg IN LISTS _cfgs)
          get_target_property(_loc ${_lib} IMPORTED_LOCATION_${_cfg})
          if(_loc)
            set(_path "${_loc}")
            break()
          endif()
        endforeach()
        if(NOT _path)
          get_target_property(_path ${_lib} IMPORTED_LOCATION)
        endif()
      endif()
      if(_path MATCHES "hdf5")
        file(REAL_PATH "${_path}" _real)
        get_filename_component(_dir "${_real}" DIRECTORY)
        get_filename_component(_name "${_real}" NAME)
        set(_soname "")
        if(_name MATCHES "^(.*\\.so\\.[0-9]+)")
          set(_soname "${CMAKE_MATCH_1}")
        endif()
        if(_soname AND EXISTS "${_dir}/${_soname}")
          list(APPEND _om_hdf5_link "-l:${_soname}")
        else()
          list(APPEND _om_hdf5_link ${_path})
        endif()
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
