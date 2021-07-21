
cmake_minimum_required(VERSION 3.14)
project(OMModelicaExternalC)


# ModelicaExternalC
set(libModelicaExternalC_SOURCES C-Sources/ModelicaFFT.c
                                 C-Sources/ModelicaInternal.c
                                 C-Sources/ModelicaRandom.c
                                 C-Sources/ModelicaStrings.c)
add_library(ModelicaExternalC STATIC ${libModelicaExternalC_SOURCES})

target_link_libraries(ModelicaExternalC PUBLIC m)


# ModelicaMatIO
set(libModelicaMatIO_SOURCES C-Sources/ModelicaMatIO.c C-Sources/snprintf.c)
add_library(ModelicaMatIO STATIC ${libModelicaMatIO_SOURCES})

find_package(ZLIB)
if(ZLIB_FOUND)
    target_link_libraries(ModelicaMatIO PUBLIC ZLIB::ZLIB)
    target_compile_definitions(ModelicaMatIO PRIVATE HAVE_ZLIB)
endif()

# find_package(HDF5)
# if(HDF5_FOUND)
#     target_include_directories(ModelicaMatIO PRIVATE ${HDF5_INCLUDE_DIRS})
#     target_link_libraries(ModelicaMatIO PUBLIC ${HDF5_LIBRARIES})
#     target_compile_definitions(ModelicaMatIO PRIVATE HAVE_HDF5)
# endif()


# ModelicaIO
set(libModelicaIO_SOURCES C-Sources/ModelicaIO.c)
add_library(ModelicaIO STATIC ${libModelicaIO_SOURCES})

target_link_libraries(ModelicaIO PUBLIC ModelicaMatIO)



# ModelicaStandardTables
set(ModelicaStandardTables_SOURCES C-Sources/ModelicaStandardTables.c
                                   C-Sources/ModelicaStandardTablesUsertab.c)
add_library(ModelicaStandardTables STATIC ${ModelicaStandardTables_SOURCES})

target_link_libraries(ModelicaStandardTables INTERFACE ModelicaMatIO)
target_link_libraries(ModelicaStandardTables PUBLIC m)




install(TARGETS ModelicaExternalC
                ModelicaMatIO
                ModelicaIO
                ModelicaStandardTables)
