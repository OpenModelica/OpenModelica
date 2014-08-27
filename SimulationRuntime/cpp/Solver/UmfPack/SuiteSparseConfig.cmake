set(SuiteSparse_found true)
message(STATUS "Searching for UmfPack")
find_file(UMFPACK_H umfpack.h HINTS "${CMAKE_SOURCE_DIR}/../../build/include/omc/c/suitesparse")
if(UMFPACK_H)
	get_filename_component(UMFPACK_INCLUDE_DIRS "${UMFPACK_H}" PATH)
	message(STATUS "${UMFPACK_H}")
else()
    message(STATUS "umfpack.h not found")
    set(SuiteSparse_found false)
endif()
find_library(UMFPACK_LIB umfpack
		HINTS "${CMAKE_SOURCE_DIR}/../../build/lib/omc"
		NO_DEFAULT_PATH
		DOC "The UMFPACK library")
if(UMFPACK_LIB)
	list(APPEND SUITESPARSE_LIBRARIES ${UMFPACK_LIB})
else()
	message(STATUS "Could not find the UMFPACK library")
	set(SuiteSparse_found false)
endif()

find_package(BLAS)
if(BLAS_FOUND)
        list(APPEND SUITESPARSE_LIBRARIES ${BLAS_LIBRARIES})
else()
        message(STATUS "Could not find the BLAS library. Please set the variable BLAS_LIBRARY to the blas library with full path")
endif()


find_library(AMD_LIB amd
	HINTS "${CMAKE_SOURCE_DIR}/../../build/lib/omc"
	NO_DEFAULT_PATH
	DOC "The AMD library")
if(AMD_LIB)
	list(APPEND SUITESPARSE_LIBRARIES ${AMD_LIB})
else()
	message("Could not find the AMD library.")
	set(SuiteSparse_found false)
endif()

find_file(UFCONFIG_H UFconfig.h HINTS "${CMAKE_SOURCE_DIR}/../../build/include/omc/c/suitesparse")
if(UFCONFIG_H)
	get_filename_component(SUITESPARSE_INCLUDE_DIRS "${UFCONFIG_H}" PATH)
else()
    message(STATUS "UFconfig.h not found")
    set(SuiteSparse_found false)
endif()
