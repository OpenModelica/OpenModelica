# Install script for directory: E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/../binaries/win64")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set default install directory permissions.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "C:/SystemDev/OMDev/tools/msys/ucrt64/bin/objdump.exe")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/../binaries/win64/libTestFMU.dll.a")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/../binaries/win64" TYPE STATIC_LIBRARY OPTIONAL PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE FILES "E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/build_cmake_dynamic/libTestFMU.dll.a")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/../binaries/win64/TestFMU.dll")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/../binaries/win64" TYPE SHARED_LIBRARY PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE FILES "E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/build_cmake_dynamic/TestFMU.dll")
  if(EXISTS "$ENV{DESTDIR}/E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/../binaries/win64/TestFMU.dll" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}/E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/../binaries/win64/TestFMU.dll")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "C:/SystemDev/OMDev/tools/msys/ucrt64/bin/strip.exe" "$ENV{DESTDIR}/E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/../binaries/win64/TestFMU.dll")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(GET_RUNTIME_DEPENDENCIES
    RESOLVED_DEPENDENCIES_VAR _CMAKE_DEPS
    LIBRARIES
      "E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/build_cmake_dynamic/TestFMU.dll"
    DIRECTORIES
      "E:/apps/workspace/topenmodelica/build_cmake/install_cmake/bin"
      "E:/apps/workspace/topenmodelica/build_cmake/install_cmake/lib//omc"
    PRE_EXCLUDE_REGEXES
      "api-ms-"
      "ext-ms-"
    POST_EXCLUDE_REGEXES
      "^\\/lib.*"
      "^\\/usr\\/lib.*"
      "^\\/usr\\/local\\/lib.*"
      ".*system32/.*\\.dll"
    POST_INCLUDE_FILES
      "E:/Apps/workspace/topenmodelica/build_cmake/install_cmake/lib/omc/libsundials_cvode.a"
      "E:/Apps/workspace/topenmodelica/build_cmake/install_cmake/lib/omc/libsundials_nvecserial.a"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  foreach(_CMAKE_TMP_dep IN LISTS _CMAKE_DEPS)
    foreach(_cmake_abs_file IN LISTS _CMAKE_TMP_dep)
      get_filename_component(_cmake_abs_file_name "${_cmake_abs_file}" NAME)
      list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES "E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/../binaries/win64/${_cmake_abs_file_name}")
    endforeach()
    unset(_cmake_abs_file_name)
    unset(_cmake_abs_file)
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/../binaries/win64" TYPE SHARED_LIBRARY PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE FILES ${_CMAKE_TMP_dep}
      FOLLOW_SYMLINK_CHAIN)
  endforeach()
endif()

if(CMAKE_INSTALL_COMPONENT)
  set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
file(WRITE "E:/Apps/workspace/topenmodelica/testsuite/openmodelica/fmi/CoSimulation/2.0/TestFMU-dynamic-cvode-tmp/TestFMU.fmutmp/sources/build_cmake_dynamic/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
