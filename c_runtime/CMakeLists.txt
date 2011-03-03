# includes
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})

# OMC Compiler
SET(OMC_DEBUG ${OMCTRUNCHOME}/build/bin/omcd.exe)
MESSAGE(" omc is " ${OMC_DEBUG})

ADD_SUBDIRECTORY(libf2c)
ADD_SUBDIRECTORY(sendData)
ADD_SUBDIRECTORY(ModelicaExternalC)

# -------------------------------------------------------------
# MACRO definitions
# -------------------------------------------------------------

# Macros to hide/show cached variables.
# These two macros can be used to "hide" or "show" in the
# list of cached variables various variables and/or options 
# that depend on other options.
# Note that once a variable is modified, it will preserve its
# value (hidding it merely makes it internal)

MACRO(HIDE_VARIABLE var)
  IF(DEFINED ${var})
    SET(${var} "${${var}}" CACHE INTERNAL "")
  ENDIF(DEFINED ${var})
ENDMACRO(HIDE_VARIABLE)

MACRO(SHOW_VARIABLE var type doc default)
  IF(DEFINED ${var})
    SET(${var} "${${var}}" CACHE "${type}" "${doc}" FORCE)
  ELSE(DEFINED ${var})
    SET(${var} "${default}" CACHE "${type}" "${doc}")
  ENDIF(DEFINED ${var})
ENDMACRO(SHOW_VARIABLE)

# MACRO BUILDMODEL
MACRO(BUILDMODEL model dir Flags CSRC)

  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/c_runtime)

  # Variablen fuer openmodelica2sarturis
  SET(OMC_CODE   ${CMAKE_CURRENT_BINARY_DIR}/${model}.cpp
                 ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.cpp
                 ${CMAKE_CURRENT_BINARY_DIR}/${model}_init.txt)
  SET(OMC_OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/${model}.cpp
                  ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.cpp
				  ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.h
				  ${CMAKE_CURRENT_BINARY_DIR}/${model}_records.c)

  # custom command fuer openmodelicacompiler
  ADD_CUSTOM_COMMAND(OUTPUT ${OMC_OUTPUT}
                     COMMAND ${OMC_DEBUG} ${Flags} +s ${dir}/${model}.mo Modelica ModelicaServices 												  
                     WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                     COMMENT "Erzeuge Code fuer ${model} with ${OMC_DEBUG}")

  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${model}codegen ALL DEPENDS ${OMC_OUTPUT})

  ADD_EXECUTABLE(${model} ${OMC_OUTPUT} ${CSRC})
  TARGET_LINK_LIBRARIES(${model} sim c_runtime f2c sendData ModelicaExternalC)

  # Dependencies
  ADD_DEPENDENCIES(${model} ${model}codegen)
  
  IF(MODELS_INSTALL)
    INSTALL(TARGETS ${model} RUNTIME DESTINATION ${MODELS_INSTALL_PATH})
    INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/${model}_init.txt DESTINATION ${MODELS_INSTALL_PATH})
  ENDIF(MODELS_INSTALL)
#ENDFOREACH(model ${model_sources})
ENDMACRO(BUILDMODEL)

# MACRO BUILDMODEL
MACRO(BUILDMODELFMU model dir Flags CSRC)

  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/c_runtime)

  SET(OMC_MODELNAME ${model})  
  SET(OMC_MODELDIR ${dir})  
  # generate model.mos 
  FIND_FILE(MOSFILE_IN model_fmu.in PATHS ${OMCTRUNCHOME}/c_runtime)
  CONFIGURE_FILE(${MOSFILE_IN} ${dir}/${model}_FMU.mos)
  
  # Variablen fuer openmodelica2sarturis
  SET(OMC_CODE   ${CMAKE_CURRENT_BINARY_DIR}/${model}.cpp
                 ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.cpp
                 ${CMAKE_CURRENT_BINARY_DIR}/${model}_init.txt)
  SET(OMC_OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/${model}.cpp
                  ${CMAKE_CURRENT_BINARY_DIR}/${model}_FMU.cpp
                  ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.cpp
				  ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.h
				  ${CMAKE_CURRENT_BINARY_DIR}/${model}_records.c)
  # custom command fuer openmodelicacompiler
  ADD_CUSTOM_COMMAND(OUTPUT ${OMC_OUTPUT}
                     COMMAND ${OMC_DEBUG} ${Flags} ${dir}/${model}_FMU.mos
                     WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                     COMMENT "Erzeuge Code fuer ${model} with ${OMC_DEBUG}")
  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${model}codegen ALL DEPENDS ${OMC_OUTPUT})

  SET(OMC_FMU_CODE ${OMCTRUNCHOME}/c_runtime/fmu_model_interface.h
                   ${OMCTRUNCHOME}/c_runtime/fmiModelFunctions.h
				   ${OMCTRUNCHOME}/c_runtime/fmiModelTypes.h)
  
  ADD_LIBRARY(${model} ${OMC_OUTPUT} ${CSRC} ${OMC_FMU_CODE})
  TARGET_LINK_LIBRARIES(${model} sim c_runtime f2c sendData ModelicaExternalC)

  # Dependencies
  ADD_DEPENDENCIES(${model} ${model}codegen)
  
  IF(MODELS_INSTALL)
    INSTALL(TARGETS ${model} ARCHIVE DESTINATION ${MODELS_INSTALL_PATH})
    INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/${model}_init.txt DESTINATION ${MODELS_INSTALL_PATH})
  ENDIF(MODELS_INSTALL)
#ENDFOREACH(model ${model_sources})
ENDMACRO(BUILDMODELFMU)


# Check if example files are to be exported
SHOW_VARIABLE(MODELS_INSTALL BOOL "Install models" ON)

# If MODELS are to be exported, check where we should install them.
IF(MODELS_INSTALL)

  SHOW_VARIABLE(MODELS_INSTALL_PATH STRING
    "Output directory for installing models files" "${CMAKE_INSTALL_PREFIX}")
    
  IF(NOT MODELS_INSTALL_PATH)
    PRINT_WARNING("The example installation path is empty"
      "Example installation path was reset to its default value")
    SET(MODELS_INSTALL_PATH "${CMAKE_INSTALL_PREFIX}" CACHE STRING
      "Output directory for installing example files" FORCE)
  ENDIF(NOT MODELS_INSTALL_PATH)

ELSE(MODELS_INSTALL)
   HIDE_VARIABLE(MODELS_INSTALL_PATH)
ENDIF(MODELS_INSTALL)

# Quellen und Header
SET(c_runtime_sources  boolean_array.c index_spec.c integer_array.c
                       memory_pool.c base_array.c real_array.c
					   string_array.c read_write.c utility.c
					   modelica_string.c bigden.c ddasrt.c  dlinpk.c
					   enorm.c   hybrd1.c  nelmead.c  qform.c
					   r1updt.c biglag.c  ddassl.c  dogleg.c
					   fdjac1.c  hybrj.c   newuoa.c   qrfac.c
					   trsapp.c daux.c    dlamch.c  dpmpar.c
					   hybrd.c   lsame.c   newuob.c   r1mpyq.c
					   update.c division.c java_interface.c
					   meta_modelica.c 
#					   meta_modelica_builtin.cpp
#					   meta_modelica_real.cpp meta_modelica_string_lit.c
					   rtclock.c ModelicaUtilities.c simulation_varinfo.c
					   read_matlab4.c)

SET(c_runtime_headers  blaswrap.h f2c.h integer_array.h memory_pool.h
                       modelica_string.h base_array.h inline.h real_array.h
					   string_array.h boolean_array.h index_spec.h matrix.h
					   modelica.h read_write.h utility.h meta_modelica.h
					   meta_modelica_builtin.h java_interface.h jni.h division.h
					   jni_md.h jni_md_solaris.h jni_md_windows.h fortran_types.h
#					   meta_modelica_builtin.h meta_modelica_real.h meta_modelica_string_lit.h
					   rtclock.h ModelicaUtilities.h simulation_varinfo.h read_matlab4.h
					   sendData/sendData.h)				 
						 
SET(sim_sources simulation_runtime.cpp simulation_init.cpp simulation_input.cpp 
                simulation_events.cpp linearize.cpp solver_dasrt.cpp solver_main.cpp
				simulation_result_plt.cpp simulation_result_csv.cpp 
				simulation_result_mat.cpp simulation_delay.cpp tables.cpp options.cpp
				dgesv_aux.c  simulation_modelinfo.c)
	
SET(sim_headers simulation_runtime.h simulation_init.h simulation_input.h
                simulation_events.h linearize.h solver_dasrt.h solver_main.h 
				simulation_result.h simulation_result_plt.h simulation_result_mat.h
				simulation_result_empty.h simulation_result_csv.h 
				simulation_delay.h tables.h options.h  
				simulation_inline_solver.h simulation_modelinfo.h )


# Library c_runtime
#ADD_DEFINITIONS(/Wall /O3  /ansi /pedantic)
ADD_DEFINITIONS(/DNO_INTERACTIVE_DEPENDENCY)
if(WIN32)
#add_definitions(/MT)
endif(WIN32)
ADD_LIBRARY(c_runtime ${c_runtime_sources} ${c_runtime_headers})
TARGET_LINK_LIBRARIES(c_runtime f2c)
# Library sim
if(WIN32)
#add_definitions(/MT)
endif(WIN32)
ADD_LIBRARY(sim ${sim_sources} ${sim_headers})
TARGET_LINK_LIBRARIES(sim c_runtime f2c ModelicaExternalC)

# Install
INSTALL(TARGETS c_runtime sim
		ARCHIVE DESTINATION lib)
		
INSTALL(FILES ${c_runtime_headers} DESTINATION include)
