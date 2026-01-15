cmake_minimum_required(VERSION 3.5)

add_subdirectory(Base)
add_subdirectory(Extended)
if(USE_FMILIB)
    add_subdirectory(OMSI)
endif(USE_FMILIB)
