
cmake_minimum_required(VERSION 3.14)
project(OMModelicaExternalC)


# zlib
# We have decided to use zlib from here. We could have used the system zlib. However,
# modelica annotations request for "zlib" while the system zlib is OFTEN (but not always) called "libz"
# which means it should be used as "z". We can modify the annotations to use "z" but then
# it will be the same issue on systems that call it "zlib". So we need to find a solution.
# Originally I was creating a sym link to the system zlib in our lib directories. However,
# that might be confusing for others. So it might be better to explicitly
# build it and use it from here. The one advantage of this is that we can compile it with -fpic so
# that we can link it into our static FMUs.
file(GLOB libzlib_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/C-Sources/zlib/*.c)
add_library(zlib STATIC ${libzlib_SOURCES})
add_library(omc::simrt::Modelica::zlib ALIAS zlib)


target_include_directories(zlib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/C-Sources/zlib)

## Check if we have unistd.h and define accordingly
## We can not use the omc macro omc_check_header_exists_and_define() because
## this file is processed for the omc-msvc targets right now. Do it manually.
include(CheckIncludeFile)
check_include_file(unistd.h HAVE_UNISTD_H)
if(HAVE_UNISTD_H)
  target_compile_definitions(zlib PRIVATE -DHAVE_UNISTD_H=1)
endif()

install(TARGETS zlib)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/C-Sources/zlib/zlib.h
              ${CMAKE_CURRENT_SOURCE_DIR}/C-Sources/zlib/zconf.h
        TYPE INCLUDE)



# ModelicaExternalC
set(libModelicaExternalC_SOURCES C-Sources/ModelicaFFT.c
                                 C-Sources/ModelicaInternal.c
                                 C-Sources/ModelicaRandom.c
                                 C-Sources/ModelicaStrings.c)

add_library(ModelicaExternalC STATIC ${libModelicaExternalC_SOURCES})
add_library(omc::simrt::Modelica::ExternalC ALIAS ModelicaExternalC)

target_link_libraries(ModelicaExternalC PUBLIC m)


# ModelicaMatIO
set(libModelicaMatIO_SOURCES C-Sources/ModelicaMatIO.c C-Sources/snprintf.c)
add_library(ModelicaMatIO STATIC ${libModelicaMatIO_SOURCES})
add_library(omc::simrt::Modelica::MatIO ALIAS ModelicaMatIO)

target_compile_definitions(ModelicaMatIO PRIVATE HAVE_ZLIB)
target_link_libraries(ModelicaMatIO PUBLIC zlib)
target_link_libraries(ModelicaMatIO PUBLIC omc::simrt::runtime)

# find_package(ZLIB)
# if(ZLIB_FOUND)
#     target_link_libraries(ModelicaMatIO PUBLIC ZLIB::ZLIB)
#     target_compile_definitions(ModelicaMatIO PRIVATE HAVE_ZLIB)
# endif()

# find_package(HDF5)
# if(HDF5_FOUND)
#     target_include_directories(ModelicaMatIO PRIVATE ${HDF5_INCLUDE_DIRS})
#     target_link_libraries(ModelicaMatIO PUBLIC ${HDF5_LIBRARIES})
#     target_compile_definitions(ModelicaMatIO PRIVATE HAVE_HDF5)
# endif()


# ModelicaIO
set(libModelicaIO_SOURCES C-Sources/ModelicaIO.c)
add_library(ModelicaIO STATIC ${libModelicaIO_SOURCES})
add_library(omc::simrt::Modelica::IO ALIAS ModelicaIO)

target_link_libraries(ModelicaIO PUBLIC ModelicaMatIO)



# ModelicaStandardTables
set(ModelicaStandardTables_SOURCES C-Sources/ModelicaStandardTables.c
                                   C-Sources/ModelicaStandardTablesUsertab.c)
add_library(ModelicaStandardTables STATIC ${ModelicaStandardTables_SOURCES})
add_library(omc::simrt::Modelica::StandardTables ALIAS ModelicaStandardTables)

# This seems to be needed. Otherwise we get undefined referenes to function 'usertab'
target_compile_definitions(ModelicaStandardTables PRIVATE -DDUMMY_FUNCTION_USERTAB)

target_link_libraries(ModelicaStandardTables INTERFACE ModelicaMatIO)
target_link_libraries(ModelicaStandardTables PUBLIC m)


install(TARGETS ModelicaExternalC
                ModelicaMatIO
                ModelicaIO
                ModelicaStandardTables)
