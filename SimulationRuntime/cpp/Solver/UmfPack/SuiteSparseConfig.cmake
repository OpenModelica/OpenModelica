set(SuiteSparse_found true)
find_file(UMFPACK_H umfpack.h)
if(UMFPACK_H)
	get_filename_component(SUITESPARSE_INCLUDE_DIRS "${UMFPACK_H}" PATH)
endif()
find_library(UMFPACK_LIB umfpack
		HINTS ENV LIBRARY_PATH
		DOC "The UMFPACK library")
	if(UMFPACK_LIB)
		list(APPEND SUITESPARSE_LIBRARIES ${UMFPACK_LIB})
	else()
		message("Could not find the UMFPACK library")
		set(SuiteSparse_found false)
	endif()
    find_package(BLAS)
    if(BLAS_FOUND)
        list(APPEND SUITESPARSE_LIBRARIES ${BLAS_LIBRARIES})
    else()
        message(STATUS "Could not find the BLAS library. Please set the variable BLAS_LIBRARY to the blas library with full path")
    endif()


	find_library(AMD_LIB amd
		HINTS ENV LIBRARY_PATH
		DOC "The AMD library")
	if(AMD_LIB)
		list(APPEND SUITESPARSE_LIBRARIES ${AMD_LIB})
	else()
		message("Could not find the AMD library.")
		set(SuiteSparse_found false)
	endif()
	#check for if we need cholmod
	set(_CHOLMOD_TEST_DIR ${CMAKE_BINARY_DIR}/CMakeFiles/cholmodTest/)
	file(WRITE ${_CHOLMOD_TEST_DIR}/CMakeLists.txt "project(cholmodTest)
			cmake_minimum_required(VERSION 2.8)
			include_directories(${SUITESPARSE_INCLUDE_DIRS})
			add_executable(cholmodTest cholmodTest.cpp)
			target_link_libraries(cholmodTest ${SUITESPARSE_LIBRARIES})")
	file(WRITE ${_CHOLMOD_TEST_DIR}/cholmodTest.cpp "#include <stdio.h>

#include \"umfpack.h\"

int n = 5 ;

int Ap [ ] = {0, 2, 5, 9, 10, 12} ;

int Ai [ ] = { 0, 1, 0, 2, 4, 1, 2, 3, 4, 2, 1, 4} ;

double Ax [ ] = {2., 3., 3., -1., 4., 4., -3., 1., 2., 2., 6., 1.} ;

double b [ ] = {8., 45., -3., 3., 19.} ;

double x [5] ;

int main (void)

{

double *null = (double *) NULL ;

int i ;

void *Symbolic, *Numeric ;

double stats [2];
umfpack_tic (stats);

(void) umfpack_di_symbolic (n, n, Ap, Ai, Ax, &Symbolic, null, null) ;

(void) umfpack_di_numeric (Ap, Ai, Ax, Symbolic, &Numeric, null, null) ;

umfpack_di_free_symbolic (&Symbolic) ;

(void) umfpack_di_solve (UMFPACK_A, Ap, Ai, Ax, x, b, Numeric, null, null) ;

umfpack_di_free_numeric (&Numeric) ;

umfpack_toc (stats);


return (0) ;

}")
# "#include <umfpack.h>
#			int main(int , char* argv[]) { double c[UMFPACK_CONTROL]; umfpack_dl_defaults(c); return 0;}")
	try_compile(CHOLMOD_TEST ${_CHOLMOD_TEST_DIR}/build ${_CHOLMOD_TEST_DIR} cholmodTest
			OUTPUT_VARIABLE CHOLMOD_OUT)
	if(NOT CHOLMOD_TEST)
	  file(APPEND ${CMAKE_BINARY_DIR}/CMakeFiles/CMakeError.log "cholmodTest-output: \n ${CHOLMOD_OUT}")
	  find_library(CHOLMOD_LIB cholmod)
	  find_library(COLAMD_LIB colamd)

	  if(CHOLMOD_LIB)
	    list(APPEND SUITESPARSE_LIBRARIES ${CHOLMOD_LIB})
	  else()
	    message("your umfpack seems to need cholmod, but cmake could not find it")
	    set(SuiteSparse_found false)
	  endif()
	  if(COLAMD_LIB)
	    list(APPEND SUITESPARSE_LIBRARIES ${COLAMD_LIB})
	  else()
	    message("your umfpack seems to need colamd, but cmake could not find it")
	    set(SuiteSparse_found false)
	  endif()

	  #test with cholmod and colamd..
	  file(WRITE ${_CHOLMOD_TEST_DIR}/CMakeLists.txt "project(cholmodTest)
			cmake_minimum_required(VERSION 2.8)
			include_directories(${AMDIS_INCLUDE_DIRS})
			add_executable(cholmodTest cholmodTest.cpp)
			target_link_libraries(cholmodTest ${AMDIS_LIBRARIES})")
	  try_compile(CHOLMOD_TEST2 ${_CHOLMOD_TEST_DIR}/build ${_CHOLMOD_TEST_DIR} cholmodTest
		  OUTPUT_VARIABLE CHOLMOD_OUT)
	  if(NOT CHOLMOD_TEST2)
	    file(APPEND ${CMAKE_BINARY_DIR}/CMakeFiles/CMakeError.log "cholmodTest2-output: \n ${CHOLMOD_OUT}")
	    find_library(SUITESPARSECONFIG_LIB suitesparseconfig)
	    if(SUITESPARSECONFIG_LIB)
	      list(APPEND SUITESPARSE_LIBRARIES ${SUITESPARSECONFIG_LIB})
	    else()
	      message(STATUS "your umfpack seems to need suitesparseconfig, but cmake could not find it")
	      set(SuiteSparse_found false)
	    endif()
	  endif()
	endif()

