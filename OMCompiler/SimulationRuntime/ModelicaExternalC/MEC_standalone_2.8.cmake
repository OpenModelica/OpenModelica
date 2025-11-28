
# We now use this CMake file for standalone compilation of ModelicaExternalC.
# That is, even for the autotools+Makefiles build system OpenModelica uses, this files
# is used to compile ModelicaExternalC.
# So we need to know where some of the OpenModelica libraries are to successfully
# compile DLLs for these files (i.e, no undefined references in the library)

cmake_minimum_required(VERSION 3.4)
project(OMModelicaExternalC)

# Use the OpenModelica lib and bin dirs as linking directories.
# The dependencies (libzlib and libOpenModelicaCompilerC) should have
# been built and installed to this dirs before we can build the ModelicaExternalC libs.
link_directories(${CMAKE_INSTALL_LIBDIR} ${CMAKE_INSTALL_BINDIR})

# Set the rpath to the one dir up as the destination of the libs
# when installing there is an 'ffi' directory in the lib directory.
# See the install command at the end of this file. If that is
# changed make sure to adjust this as well.
if(APPLE)
  set(CMAKE_INSTALL_RPATH "@loader_path/../../${CMAKE_INSTALL_LIBDIR}")
else()
  set(CMAKE_INSTALL_RPATH "$ORIGIN;$ORIGIN/../../${CMAKE_INSTALL_LIBDIR}")
endif()

## ModelicaExternalC #########################################################################
set(libModelicaExternalC_SOURCES C-Sources/ModelicaFFT.c
                                 C-Sources/ModelicaInternal.c
                                 C-Sources/ModelicaRandom.c
                                 C-Sources/ModelicaStrings.c)

# Static version
add_library(ModelicaExternalC STATIC ${libModelicaExternalC_SOURCES})
add_library(omc::simrt::Modelica::ExternalC ALIAS ModelicaExternalC)

if(UNIX)
  target_link_libraries(ModelicaExternalC PUBLIC m)
endif()

target_link_libraries(ModelicaExternalC PUBLIC OpenModelicaRuntimeC)
target_link_libraries(ModelicaExternalC PUBLIC omcgc)

# Shared version.
add_library(ModelicaExternalC_shared SHARED ${libModelicaExternalC_SOURCES})
add_library(omc::simrt::Modelica::ExternalC::shared ALIAS ModelicaExternalC_shared)
set_target_properties(ModelicaExternalC_shared
                      PROPERTIES OUTPUT_NAME ModelicaExternalC CLEAN_DIRECT_OUTPUT 1)

if(UNIX)
  target_link_libraries(ModelicaExternalC_shared PUBLIC m)
endif()

target_link_libraries(ModelicaExternalC_shared PUBLIC OpenModelicaRuntimeC)
target_link_libraries(ModelicaExternalC_shared PUBLIC omcgc)

if(MINGW)
  set_target_properties(ModelicaExternalC_shared PROPERTIES LINK_FLAGS "-Wl,--export-all-symbols")
elseif(MSVC)
  set_target_properties(ModelicaExternalC_shared PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
endif()



## ModelicaMatIO #########################################################################
set(libModelicaMatIO_SOURCES C-Sources/ModelicaMatIO.c C-Sources/snprintf.c)
# Static version
add_library(ModelicaMatIO STATIC ${libModelicaMatIO_SOURCES})
add_library(omc::simrt::Modelica::MatIO ALIAS ModelicaMatIO)

target_compile_definitions(ModelicaMatIO PRIVATE HAVE_ZLIB)
target_link_libraries(ModelicaMatIO PUBLIC zlib)
target_link_libraries(ModelicaMatIO PUBLIC OpenModelicaRuntimeC)
target_link_libraries(ModelicaMatIO PUBLIC omcgc)

# Shared version
add_library(ModelicaMatIO_shared SHARED ${libModelicaMatIO_SOURCES})
add_library(omc::simrt::Modelica::MatIO::shared ALIAS ModelicaMatIO_shared)
set_target_properties(ModelicaMatIO_shared
                      PROPERTIES OUTPUT_NAME ModelicaMatIO CLEAN_DIRECT_OUTPUT 1)

target_compile_definitions(ModelicaMatIO_shared PUBLIC HAVE_ZLIB)
target_link_libraries(ModelicaMatIO_shared PUBLIC zlib)
target_link_libraries(ModelicaMatIO_shared PUBLIC OpenModelicaRuntimeC)
target_link_libraries(ModelicaMatIO_shared PUBLIC omcgc)

if(MINGW)
  set_target_properties(ModelicaMatIO_shared PROPERTIES LINK_FLAGS "-Wl,--export-all-symbols")
elseif(MSVC)
  set_target_properties(ModelicaMatIO_shared PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
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
if(MINGW)
  set_target_properties(ModelicaIO_shared PROPERTIES LINK_FLAGS "-Wl,--export-all-symbols")
elseif(MSVC)
  set_target_properties(ModelicaIO_shared PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
endif()



## ModelicaStandardTables #########################################################################
set(ModelicaStandardTables_SOURCES C-Sources/ModelicaStandardTables.c
                                   C-Sources/ModelicaStandardTablesUsertab.c)
# Static version.
add_library(ModelicaStandardTables STATIC ${ModelicaStandardTables_SOURCES})
add_library(omc::simrt::Modelica::StandardTables ALIAS ModelicaStandardTables)

# This seems to be needed. Otherwise we get undefined references to function 'usertab'
target_compile_definitions(ModelicaStandardTables PRIVATE DUMMY_FUNCTION_USERTAB)

target_link_libraries(ModelicaStandardTables PUBLIC ModelicaIO)
if(UNIX)
  target_link_libraries(ModelicaStandardTables PUBLIC m)
endif()

# Shared version
add_library(ModelicaStandardTables_shared SHARED ${ModelicaStandardTables_SOURCES})
add_library(omc::simrt::Modelica::StandardTables::shared ALIAS ModelicaStandardTables_shared)
set_target_properties(ModelicaStandardTables_shared
                      PROPERTIES OUTPUT_NAME ModelicaStandardTables CLEAN_DIRECT_OUTPUT 1)

# This seems to be needed. Otherwise we get undefined references to function 'usertab'
target_compile_definitions(ModelicaStandardTables_shared PRIVATE DUMMY_FUNCTION_USERTAB)

target_link_libraries(ModelicaStandardTables_shared PUBLIC ModelicaIO_shared)
if(UNIX)
  target_link_libraries(ModelicaStandardTables_shared PUBLIC m)
endif()

if(MINGW)
  set_target_properties(ModelicaStandardTables_shared PROPERTIES LINK_FLAGS "-Wl,--export-all-symbols")
elseif(MSVC)
  set_target_properties(ModelicaStandardTables_shared PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
endif()


## Install

# Common source files for all source-code-FMUs
set(SOURCE_FMU_MODELICA_EXTERNAL_C_FILES_LIST
  C-Sources/ModelicaStandardTables.c
  C-Sources/ModelicaStandardTablesDummyUsertab.c
  C-Sources/ModelicaMatIO.c
  C-Sources/ModelicaIO.c
  C-Sources/snprintf.c)

set(SOURCE_FMU_MODELICA_EXTERNAL_HEADER_FILES_LIST
  C-Sources/ModelicaStandardTables.h
  C-Sources/ModelicaMatIO.h
  C-Sources/ModelicaIO.h
  C-Sources/safe-math.h
  C-Sources/read_data_impl.h
)

install(FILES ${SOURCE_FMU_MODELICA_EXTERNAL_C_FILES_LIST}
              ${SOURCE_FMU_MODELICA_EXTERNAL_HEADER_FILES_LIST}
              DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/ModelicaExternalC)

# Install the static libs to the normal lib dir.
install(TARGETS ModelicaExternalC
                ModelicaMatIO
                ModelicaIO
                ModelicaStandardTables
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
       )

# Install the shared libs to a directory 'ffi' within the lib dir.
# This is so that they are not on the normal link path of simulation executables.
# We do not want to have them for anything other than FFI based constant
# evaluation by omc (They are only loaded never linked)
install(TARGETS ModelicaExternalC_shared
                ModelicaMatIO_shared
                ModelicaIO_shared
                ModelicaStandardTables_shared
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}/ffi
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/ffi
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}/ffi
       )
