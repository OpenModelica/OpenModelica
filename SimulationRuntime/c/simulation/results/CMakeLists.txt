# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC 

# Quellen und Header
SET(results_sources  read_csv.cpp read_matlab4.c simulation_result_csv.cpp
                    simulation_result_mat.cpp simulation_result_plt.cpp  )

SET(results_headers  read_csv.h read_matlab4.h simulation_result_csv.h 
                    simulation_result_mat.h simulation_result_plt.h 
					simulation_result.h simulation_result_empty.h)				 
						 
# Library util
ADD_LIBRARY(results ${results_sources} ${results_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS results
		ARCHIVE DESTINATION lib)
		
INSTALL(FILES ${results_headers} DESTINATION include)

