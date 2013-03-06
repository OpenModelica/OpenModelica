# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC

# Quellen und Header
SET(results_sources read_csv.cpp simulation_result_csv.c simulation_result.c
                    simulation_result_mat.cpp simulation_result_plt.c  )

SET(results_headers read_csv.h simulation_result_csv.h
                    simulation_result_mat.h simulation_result_plt.h
					simulation_result.h)

# Library util
ADD_LIBRARY(results ${results_sources} ${results_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS results
		ARCHIVE DESTINATION lib/omc)

#INSTALL(FILES ${results_headers} DESTINATION include)

