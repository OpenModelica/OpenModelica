# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC 

# OMDEV PATH
IF(NOT OMDEV)
  SET(OMDEV $ENV{OMDEV})
ENDIF(NOT OMDEV)

INCLUDE_DIRECTORIES(${OMDEV}/lib/expat-win32-msvc)
link_directories(${OMDEV}/lib/expat-win32-msvc)

# OMC Compiler
SET(OMC_DEBUG ${OMCTRUNCHOME}/build/bin/omcd.exe)
MESSAGE(" omc is " ${OMC_DEBUG})

# includes
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/linearization)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/math-support)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/meta)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/ModelicaExternalC)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/simulation)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/simulation/libf2c)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/simulation/results)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/simulation/solver)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/util)

# Subdirectorys
ADD_SUBDIRECTORY(math-support)
ADD_SUBDIRECTORY(meta)
ADD_SUBDIRECTORY(ModelicaExternalC)
ADD_SUBDIRECTORY(simulation)
ADD_SUBDIRECTORY(util)


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
MACRO(BUILDMODEL model mo dir Flags CSRC)


  # includes
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/linearization)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/math-support)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/meta)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/ModelicaExternalC)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation/libf2c)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation/results)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation/solver)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/util) 
  
  # OMDEV PATH
  IF(NOT OMDEV)
    SET(OMDEV $ENV{OMDEV})
  ENDIF(NOT OMDEV)

  INCLUDE_DIRECTORIES(${OMDEV}/lib/expat-win32-msvc)
  link_directories(${OMDEV}/lib/expat-win32-msvc)
  
  # Variablen fuer openmodelica2sarturis
  SET(OMC_CODE   ${CMAKE_CURRENT_BINARY_DIR}/${model}.c
                 ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.c
                 ${CMAKE_CURRENT_BINARY_DIR}/${model}_init.txt)
  SET(OMC_OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/${model}.c
  #               ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.cpp
				  ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.h
				  ${CMAKE_CURRENT_BINARY_DIR}/${model}_records.c)

  # custom command fuer openmodelicacompiler
  ADD_CUSTOM_COMMAND(OUTPUT ${OMC_OUTPUT}
                     COMMAND ${OMC_DEBUG} ${Flags} +s ${dir}/${mo} Modelica ModelicaServices 												  
                     WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                     COMMENT "Erzeuge Code fuer ${model} with ${OMC_DEBUG}")

  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${model}codegen ALL DEPENDS ${OMC_OUTPUT})

  ADD_EXECUTABLE(${model} ${OMC_OUTPUT} ${CSRC})
  TARGET_LINK_LIBRARIES(${model} simulation util math-support results solver f2c meta ModelicaExternalC libexpat)

  # Dependencies
  ADD_DEPENDENCIES(${model} ${model}codegen)
  
  IF(MODELS_INSTALL)
    INSTALL(TARGETS ${model} RUNTIME DESTINATION ${MODELS_INSTALL_PATH})
    INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/${model}_init.txt DESTINATION ${MODELS_INSTALL_PATH})
  ENDIF(MODELS_INSTALL)
#ENDFOREACH(model ${model_sources})
ENDMACRO(BUILDMODEL)

# MACRO BUILDMODEL
MACRO(BUILDMODELMOS model mos dir Flags CSRC)

  # includes
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/linearization)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/math-support)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/meta)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/ModelicaExternalC)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation/libf2c)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation/results)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation/solver)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/util)   

  INCLUDE_DIRECTORIES(${dir})    
  
  # OMDEV PATH
  IF(NOT OMDEV)
    SET(OMDEV $ENV{OMDEV})
  ENDIF(NOT OMDEV)

  INCLUDE_DIRECTORIES(${OMDEV}/lib/expat-win32-msvc)
  link_directories(${OMDEV}/lib/expat-win32-msvc)  
  
  # custom command to copy xml file
  SET(expat_CODE   ${OMDEV}/lib/expat-win32-msvc/libexpat.dll)
  SET(expat_OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/RelWithDebInfo/libexpat.dll)
  ADD_CUSTOM_COMMAND(OUTPUT ${expat_OUTPUT}
                     COMMAND cp ${expat_CODE} ${expat_OUTPUT}
                     WORKING_DIRECTORY ${dir}
                     COMMENT "copy file ${expat_CODE} to ${expat_OUTPUT}")
  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(expat${model} ALL DEPENDS ${expat_OUTPUT})  
  
  SET(OMC_MODELNAME ${model})  
  # generate model.mos 
  
  # Variablen fuer openmodelica2sarturis
  SET(OMC_CODE   ${dir}/${model}.c
                 ${dir}/${model}_functions.c
                 ${dir}/${model}_init.txt)
  SET(OMC_OUTPUT  ${dir}/${model}.c
  #                ${dir}/${model}_functions.cpp
				  ${dir}/${model}_functions.h
				  ${dir}/${model}_records.c)
  # custom command fuer openmodelicacompiler
  ADD_CUSTOM_COMMAND(OUTPUT ${OMC_OUTPUT}
                     COMMAND ${OMC_DEBUG} ${Flags} ${mos}
                     WORKING_DIRECTORY ${dir}
                     COMMENT "Erzeuge Code fuer ${model} with ${OMC_DEBUG}")
  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${model}codegen ALL DEPENDS ${OMC_OUTPUT})


  ADD_DEFINITIONS(/TP ${dir}/${model}.c)
  ADD_EXECUTABLE(${model} ${OMC_OUTPUT} ${CSRC})
  TARGET_LINK_LIBRARIES(${model} simulation util math-support results solver f2c meta ModelicaExternalC libexpat)

  # custom command to copy xml file
  SET(XML_CODE   ${dir}/${model}_init.xml)
  SET(XML_OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/RelWithDebInfo/${model}_init.xml)
  ADD_CUSTOM_COMMAND(OUTPUT ${XML_OUTPUT}
                     COMMAND cp ${XML_CODE} ${XML_OUTPUT}
                     WORKING_DIRECTORY ${dir}
                     COMMENT "copy file ${XML_CODE} to ${XML_OUTPUT}")
  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${model}cp_xml ALL DEPENDS ${XML_OUTPUT})

  # Dependencies
  ADD_DEPENDENCIES(${model}cp_xml ${model}codegen expat)
  ADD_DEPENDENCIES(${model} ${model}cp_xml)
  
#ENDFOREACH(model ${model_sources})
ENDMACRO(BUILDMODELMOS)

# MACRO BUILDMODEL
MACRO(BUILDMODELFMU model dir Flags CSRC)

  # includes
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/linearization)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/math-support)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/meta)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/ModelicaExternalC)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation/libf2c)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation/results)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation/solver)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/util) 
  
  # OMDEV PATH
  IF(NOT OMDEV)
    SET(OMDEV $ENV{OMDEV})
  ENDIF(NOT OMDEV)

  INCLUDE_DIRECTORIES(${OMDEV}/lib/expat-win32-msvc)
  link_directories(${OMDEV}/lib/expat-win32-msvc)  
  
  SET(OMC_MODELNAME ${model})  
  SET(OMC_MODELDIR ${dir})  
  # generate model.mos 
  FIND_FILE(MOSFILE_IN model_fmu.in PATHS ${OMCTRUNCHOME}/c_runtime)
  CONFIGURE_FILE(${MOSFILE_IN} ${dir}/${model}_FMU.mos)
  
  # Variablen fuer openmodelica2sarturis
  SET(OMC_CODE   ${CMAKE_CURRENT_BINARY_DIR}/${model}.c
                 ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.c
                 ${CMAKE_CURRENT_BINARY_DIR}/${model}_init.txt)
  SET(OMC_OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/${model}.c
                  ${CMAKE_CURRENT_BINARY_DIR}/${model}_FMU.c
  #               ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.cpp
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
  
  ADD_LIBRARY(${model} SHARED ${OMC_OUTPUT} ${CSRC} ${OMC_FMU_CODE})
  TARGET_LINK_LIBRARIES(${model} sim c_runtime f2c meta  ModelicaExternalC libexpat)

  # Dependencies
  ADD_DEPENDENCIES(${model} ${model}codegen)
  
  IF(MODELS_INSTALL)
    INSTALL(TARGETS ${model} ARCHIVE DESTINATION ${MODELS_INSTALL_PATH})
    INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/${model}_init.txt DESTINATION ${MODELS_INSTALL_PATH})
  ENDIF(MODELS_INSTALL)
#ENDFOREACH(model ${model_sources})
ENDMACRO(BUILDMODELFMU)

# MACRO BUILDMODEL
MACRO(BUILDMODELFMUMOS model mos Flags CSRC)

  # includes
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/linearization)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/math-support)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/meta)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/ModelicaExternalC)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation/libf2c)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation/results)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/simulation/solver)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/SimulationRuntime/c/util)

  # OMDEV PATH
  IF(NOT OMDEV)
    SET(OMDEV $ENV{OMDEV})
  ENDIF(NOT OMDEV)

  INCLUDE_DIRECTORIES(${OMDEV}/lib/expat-win32-msvc)
  link_directories(${OMDEV}/lib/expat-win32-msvc)  
 
  SET(OMC_MODELNAME ${model})  
  # generate model.mos 
  
  # Variablen fuer openmodelica2sarturis
  SET(OMC_CODE   ${CMAKE_CURRENT_BINARY_DIR}/${model}.c
                 ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.c
                 ${CMAKE_CURRENT_BINARY_DIR}/${model}_init.txt)
  SET(OMC_OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/${model}.c
                  ${CMAKE_CURRENT_BINARY_DIR}/${model}_FMU.c
  #               ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.cpp
				  ${CMAKE_CURRENT_BINARY_DIR}/${model}_functions.h
				  ${CMAKE_CURRENT_BINARY_DIR}/${model}_records.c)
  # custom command fuer openmodelicacompiler
  ADD_CUSTOM_COMMAND(OUTPUT ${OMC_OUTPUT}
                     COMMAND ${OMC_DEBUG} ${Flags} ${mos}
                     WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                     COMMENT "Erzeuge Code fuer ${model} with ${OMC_DEBUG}")
  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${model}codegen ALL DEPENDS ${OMC_OUTPUT})

  SET(OMC_FMU_CODE ${OMCTRUNCHOME}/c_runtime/fmu_model_interface.h
                   ${OMCTRUNCHOME}/c_runtime/fmiModelFunctions.h
				   ${OMCTRUNCHOME}/c_runtime/fmiModelTypes.h)
  
  ADD_DEFINITIONS(/TP ${model}.c)
  ADD_LIBRARY(${model} SHARED ${OMC_OUTPUT} ${CSRC} ${OMC_FMU_CODE})
  TARGET_LINK_LIBRARIES(${model} sim c_runtime f2c meta  ModelicaExternalC libexpat)

  # Dependencies
  ADD_DEPENDENCIES(${model} ${model}codegen)
  
  IF(MODELS_INSTALL)
    INSTALL(TARGETS ${model} ARCHIVE DESTINATION ${MODELS_INSTALL_PATH})
    INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/modelDescription.xml DESTINATION ${MODELS_INSTALL_PATH})
  ENDIF(MODELS_INSTALL)
#ENDFOREACH(model ${model_sources})
ENDMACRO(BUILDMODELFMUMOS)

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