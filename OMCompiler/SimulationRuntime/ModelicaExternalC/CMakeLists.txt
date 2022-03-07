
# We now exclusively use CMake to build ModelicaExternalC. That is, even for
# the autotools+Makefiles build system OpenModelica uses, CMake is used to
# compile ModelicaExternalC.
# If we get here from autotools+Makefiles build we use a standalone CMake project file
# to compile the ModelicaExternalC libs. This is signified by setting MODELICA_EXTERNAL_C_STANDALONE
# when configuring this file.
if(MODELICA_EXTERNAL_C_STANDALONE)
  include(MEC_standalone_2.8.cmake)
  return()
endif()


cmake_minimum_required(VERSION 3.14)
project(OMModelicaExternalC)

## ModelicaExternalC #########################################################################
set(libModelicaExternalC_SOURCES C-Sources/ModelicaFFT.c
                                 C-Sources/ModelicaInternal.c
                                 C-Sources/ModelicaRandom.c
                                 C-Sources/ModelicaStrings.c)

# Static version
add_library(ModelicaExternalC STATIC ${libModelicaExternalC_SOURCES})
add_library(omc::simrt::Modelica::ExternalC ALIAS ModelicaExternalC)

target_link_libraries(ModelicaExternalC PUBLIC m)
target_link_libraries(ModelicaExternalC PUBLIC omc::simrt::runtime)

# Shared version.
add_library(ModelicaExternalC_shared SHARED ${libModelicaExternalC_SOURCES})
add_library(omc::simrt::Modelica::ExternalC::shared ALIAS ModelicaExternalC_shared)
set_target_properties(ModelicaExternalC_shared
                      PROPERTIES OUTPUT_NAME ModelicaExternalC CLEAN_DIRECT_OUTPUT 1)

target_link_libraries(ModelicaExternalC_shared PUBLIC m)
target_link_libraries(ModelicaExternalC_shared PUBLIC omc::simrt::runtime)
if(WIN32)
  target_link_options(ModelicaExternalC_shared PRIVATE -Wl,--export-all-symbols)
endif()



## ModelicaMatIO #########################################################################
set(libModelicaMatIO_SOURCES C-Sources/ModelicaMatIO.c C-Sources/snprintf.c)
# Static version
add_library(ModelicaMatIO STATIC ${libModelicaMatIO_SOURCES})
add_library(omc::simrt::Modelica::MatIO ALIAS ModelicaMatIO)

target_compile_definitions(ModelicaMatIO PRIVATE HAVE_ZLIB)
target_link_libraries(ModelicaMatIO PUBLIC omc::3rd::zlib)
target_link_libraries(ModelicaMatIO PUBLIC omc::simrt::runtime)

# Shared version
add_library(ModelicaMatIO_shared SHARED ${libModelicaMatIO_SOURCES})
add_library(omc::simrt::Modelica::MatIO::shared ALIAS ModelicaMatIO_shared)
set_target_properties(ModelicaMatIO_shared
                      PROPERTIES OUTPUT_NAME ModelicaMatIO CLEAN_DIRECT_OUTPUT 1)

target_compile_definitions(ModelicaMatIO_shared PUBLIC HAVE_ZLIB)
target_link_libraries(ModelicaMatIO_shared PUBLIC omc::3rd::zlib)
target_link_libraries(ModelicaMatIO_shared PUBLIC omc::simrt::runtime)
if(WIN32)
  target_link_options(ModelicaMatIO_shared PRIVATE -Wl,--export-all-symbols)
endif()


## ModelicaIO #########################################################################
set(libModelicaIO_SOURCES C-Sources/ModelicaIO.c)
# Static version
add_library(ModelicaIO STATIC ${libModelicaIO_SOURCES})
add_library(omc::simrt::Modelica::IO ALIAS ModelicaIO)

target_link_libraries(ModelicaIO PUBLIC ModelicaMatIO)

# Shared version
add_library(ModelicaIO_shared SHARED ${libModelicaIO_SOURCES})
add_library(omc::simrt::Modelica::IO::shared ALIAS ModelicaIO_shared)
set_target_properties(ModelicaIO_shared
                      PROPERTIES OUTPUT_NAME ModelicaIO CLEAN_DIRECT_OUTPUT 1)

target_link_libraries(ModelicaIO_shared PUBLIC ModelicaMatIO_shared)
if(WIN32)
  target_link_options(ModelicaIO_shared PRIVATE -Wl,--export-all-symbols)
endif()



## ModelicaStandardTables #########################################################################
set(ModelicaStandardTables_SOURCES C-Sources/ModelicaStandardTables.c
                                   C-Sources/ModelicaStandardTablesUsertab.c)
# Static version.
add_library(ModelicaStandardTables STATIC ${ModelicaStandardTables_SOURCES})
add_library(omc::simrt::Modelica::StandardTables ALIAS ModelicaStandardTables)

# This seems to be needed. Otherwise we get undefined references to function 'usertab'
target_compile_definitions(ModelicaStandardTables PRIVATE -DDUMMY_FUNCTION_USERTAB)

target_link_libraries(ModelicaStandardTables PUBLIC ModelicaIO)
target_link_libraries(ModelicaStandardTables PUBLIC m)

# Shared version
add_library(ModelicaStandardTables_shared SHARED ${ModelicaStandardTables_SOURCES})
add_library(omc::simrt::Modelica::StandardTables::shared ALIAS ModelicaStandardTables_shared)
set_target_properties(ModelicaStandardTables_shared
                      PROPERTIES OUTPUT_NAME ModelicaStandardTables CLEAN_DIRECT_OUTPUT 1)

# This seems to be needed. Otherwise we get undefined references to function 'usertab'
target_compile_definitions(ModelicaStandardTables_shared PRIVATE -DDUMMY_FUNCTION_USERTAB)

target_link_libraries(ModelicaStandardTables_shared PUBLIC ModelicaIO_shared)
target_link_libraries(ModelicaStandardTables_shared PUBLIC m)
if(WIN32)
  target_link_options(ModelicaStandardTables_shared PRIVATE -Wl,--export-all-symbols)
endif()


## Install
# Install the static libs to the normal lib dir.
install(TARGETS ModelicaExternalC
                ModelicaMatIO
                ModelicaIO
                ModelicaStandardTables
       )

# Install the shared libs to a directory 'ffi' within the lib dir.
# This is so that they are not on the normal link path of simulation executables.
# We do not want to have them for anything other than FFI based for constant
# evaluation by omc (They are only loaded never linked)
install(TARGETS ModelicaExternalC_shared
                ModelicaMatIO_shared
                ModelicaIO_shared
                ModelicaStandardTables_shared
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}/ffi
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/ffi
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}/ffi
       )
