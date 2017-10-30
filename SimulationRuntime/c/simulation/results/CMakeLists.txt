# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC

# Quellen und Header
SET(results_sources
simulation_result.cpp      simulation_result_ia.cpp   simulation_result_plt.cpp
simulation_result_csv.cpp  simulation_result_mat4.cpp  simulation_result_wall.cpp    MatVer4.cpp
)

SET(results_headers ../../util/read_csv.h
simulation_result.h      simulation_result_ia.h   simulation_result_plt.h
simulation_result_csv.h  simulation_result_mat4.h  simulation_result_wall.h  MatVer4.h
)

# Library util
ADD_LIBRARY(results ${results_sources} ${results_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS results
		ARCHIVE DESTINATION lib/omc)

#INSTALL(FILES ${results_headers} DESTINATION include)

