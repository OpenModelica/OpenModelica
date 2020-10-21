
cmake_minimum_required(VERSION 3.14)
project(OMModelicaExternalC)


set(libModelicaExternalC_SOURCES C-Sources/ModelicaFFT.c
                                 C-Sources/ModelicaInternal.c
                                 C-Sources/ModelicaRandom.c
                                 C-Sources/ModelicaStrings.c)
add_library(ModelicaExternalC STATIC ${libModelicaExternalC_SOURCES})


set(libModelicaMatIO_SOURCES C-Sources/ModelicaMatIO.c C-Sources/snprintf.c)
add_library(ModelicaMatIO STATIC ${libModelicaMatIO_SOURCES})

set(libModelicaIO_SOURCES C-Sources/ModelicaIO.c)
add_library(ModelicaIO STATIC ${libModelicaIO_SOURCES})
target_link_libraries(ModelicaIO INTERFACE ModelicaMatIO)
