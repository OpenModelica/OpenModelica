# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC

# CMAKE
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

# PROJECT
PROJECT(SimulationRuntimeC)

SET(OPENMODELICAHOME $ENV{OPENMODELICAHOME})
SET(OMC_DEBUG ${OPENMODELICAHOME}/bin/omc.exe)

# Global Variables
IF(NOT OMCTRUNCHOME)
  SET(OMCTRUNCHOME ${CMAKE_CURRENT_SOURCE_DIR}/../../../)
ENDIF (NOT OMCTRUNCHOME)

# OMDEV PATH
IF(NOT OMDEV)
  SET(OMDEV $ENV{OMDEV})
ENDIF(NOT OMDEV)

INCLUDE_DIRECTORIES(${OMDEV}/lib/expat-win32-msvc ${OMDEV}/include/lis ${OMDEV}/include/pthread)
link_directories(${OMDEV}/lib/expat-win32-msvc)
link_directories(${OMDEV}/lib/lapack-win32-msvc)

IF(MSVC)
  SET(Sundials_Path ${OMCTRUNCHOME}/OMCompiler/3rdParty/sundials/build_msvc)
ELSEIF(MSVC)
  SET(Sundials_Path ${OMCTRUNCHOME}/OMCompiler/3rdParty/sundials/build)
ENDIF(MSVC)

MESSAGE(STATUS "Sundials path:")
MESSAGE(STATUS "${Sundials_Path}")

# SUNDIALS Header
FIND_PATH(SUNDIALS_INCLUDE_DIR sundials/sundials_config.h /usr/include /usr/local/include $ENV{INCLUDE} ${Sundials_Path}/include)

MESSAGE(STATUS "Sundials include:")
MESSAGE(STATUS "${SUNDIALS_INCLUDE_DIR}")

# SUNDIALS Libraires
if(MSVC)
FIND_LIBRARY(SUNDIALS_LIBRARY_CVODE      NAMES sundials_cvode      PATHS /usr/lib /usr/local/lib $ENV{LIB} $(Sundials_Path)/lib)
FIND_LIBRARY(SUNDIALS_LIBRARY_IDA        NAMES sundials_ida        PATHS /usr/lib /usr/local/lib $ENV{LIB} $(Sundials_Path)/lib)
FIND_LIBRARY(SUNDIALS_LIBRARY_NVEC       NAMES sundials_nvecserial        PATHS /usr/lib /usr/local/lib $ENV{LIB} $(Sundials_Path)/lib)
FIND_LIBRARY(SUNDIALS_KINSOL       NAMES sundials_kinsol        PATHS /usr/lib /usr/local/lib $ENV{LIB} $(Sundials_Path)/lib)
else(MSVC)
FIND_LIBRARY(SUNDIALS_LIBRARY_CVODE      NAMES libsundials_cvode      PATHS /usr/lib /usr/local/lib $ENV{LIB} $(Sundials_Path)/lib)
FIND_LIBRARY(SUNDIALS_LIBRARY_IDA        NAMES libsundials_ida        PATHS /usr/lib /usr/local/lib $ENV{LIB} $(Sundials_Path)/lib)
FIND_LIBRARY(SUNDIALS_LIBRARY_NVEC       NAMES libsundials_nvecserial        PATHS /usr/lib /usr/local/lib $ENV{LIB} $(Sundials_Path)/lib)
FIND_LIBRARY(SUNDIALS_KINSOL       NAMES libsundials_kinsol        PATHS /usr/lib /usr/local/lib $ENV{LIB} $(Sundials_Path)/lib)
endif(MSVC)

IF(SUNDIALS_INCLUDE_DIR)

  INCLUDE_DIRECTORIES(${SUNDIALS_INCLUDE_DIR})

  if(SUNDIALS_LIBRARY_CVODE AND
   SUNDIALS_LIBRARY_IDA AND
   SUNDIALS_LIBRARY_NVEC AND
   SUNDIALS_KINSOL)

  SET(SUNDIALS_LIBRARIES ${SUNDIALS_LIBRARY_CVODE} ${SUNDIALS_LIBRARY_IDA} ${SUNDIALS_LIBRARY_NVEC} ${SUNDIALS_KINSOL})

  ENDIF(SUNDIALS_LIBRARY_CVODE AND
        SUNDIALS_LIBRARY_IDA AND
        SUNDIALS_LIBRARY_NVEC AND
        SUNDIALS_KINSOL)

ENDIF(SUNDIALS_INCLUDE_DIR)

# Defines for Visual Studio
if(MSVC)
  add_definitions(-D_CRT_SECURE_NO_WARNINGS -DNOMINMAX -D_COMPLEX_DEFINED)
    # GC shall not use a dll
    add_definitions(-DGC_NOT_DLL)
endif(MSVC)

# includes
INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/)
INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/3rdParty/gc/include)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/linearization)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/math-support)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/meta)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/meta/gc)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/simulation)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/optimization)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/simulation/results)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/simulation/solver)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/simulation/solver/initialization)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/util)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/dataReconciliation)

# Subdirectorys
ADD_SUBDIRECTORY(math-support)
ADD_SUBDIRECTORY(meta)
ADD_SUBDIRECTORY(simulation)
ADD_SUBDIRECTORY(util)
ADD_SUBDIRECTORY(fmi)

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
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/linearization)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/math-support)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/meta)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/meta/gc)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation/results)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation/solver)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation/solver/initialization)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/util)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/dataReconciliation)


  # OMDEV PATH
  IF(NOT OMDEV)
    SET(OMDEV $ENV{OMDEV})
  ENDIF(NOT OMDEV)

  INCLUDE_DIRECTORIES(${OMDEV}/lib/expat-win32-msvc)
  link_directories(${OMDEV}/lib/expat-win32-msvc)
  link_directories(${OMDEV}/lib/lapack-win32-msvc)

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
  TARGET_LINK_LIBRARIES(${model} simulation util math-support results solver meta ModelicaExternalC libexpat initialization lapack_win32_MT)

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

IF(WIN32)
  SET(COPY copy)
else(WIN32)
  SET(COPY cp)
endif(WIN32)

IF(SUNDIALS_INCLUDE_DIR AND
   SUNDIALS_LIBRARY_CVODE AND
   SUNDIALS_LIBRARY_IDA AND
   SUNDIALS_LIBRARY_NVEC AND
   SUNDIALS_KINSOL)

  INCLUDE_DIRECTORIES(${SUNDIALS_INCLUDE_DIR})
  SET(SUNDIALS_LIBRARIES ${SUNDIALS_LIBRARY_CVODE} ${SUNDIALS_LIBRARY_IDA} ${SUNDIALS_LIBRARY_NVEC} ${SUNDIALS_KINSOL})

ENDIF(SUNDIALS_INCLUDE_DIR AND
      SUNDIALS_LIBRARY_CVODE AND
      SUNDIALS_LIBRARY_IDA AND
   SUNDIALS_LIBRARY_NVEC AND
   SUNDIALS_KINSOL)

  # includes
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/linearization)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/math-support)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/meta)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/meta/gc)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/ModelicaExternalC)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation/results)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation/solver)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation/solver/initialization)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/util)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/dataReconciliation)

  INCLUDE_DIRECTORIES(${dir})

  # OMDEV PATH
  IF(NOT OMDEV)
    SET(OMDEV $ENV{OMDEV})
  ENDIF(NOT OMDEV)

  INCLUDE_DIRECTORIES(${OMDEV}/lib/expat-win32-msvc)
  link_directories(${OMDEV}/lib/expat-win32-msvc)
  link_directories(${OMDEV}/lib/lapack-win32-msvc)

  # custom command to copy expat.dll file
  SET(expat_CODE   ${OMDEV}/lib/expat-win32-msvc/libexpat.dll)
  STRING(REGEX REPLACE "/" "\\\\" expat_CODE_NEU ${expat_CODE})
  SET(expat_OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/RelWithDebInfo/libexpat.dll)
  STRING(REGEX REPLACE "/" "\\\\" expat_OUTPUT_NEU ${expat_OUTPUT})

    ADD_CUSTOM_COMMAND(OUTPUT ${expat_OUTPUT}
                     COMMAND ${COPY} ${expat_CODE_NEU} ${expat_OUTPUT_NEU}
                     WORKING_DIRECTORY ${dir}
                     COMMENT "copy file ${expat_CODE_NEU} to ${expat_OUTPUT_NEU}")
  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(expat${model} ALL DEPENDS ${expat_OUTPUT})


  SET(lapack_CODE   ${OMDEV}/lib/lapack-win32-msvc/lapack_win32_MT.dll)
  STRING(REGEX REPLACE "/" "\\\\" lapack_CODE_NEU ${lapack_CODE})
  SET(lapack_OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/RelWithDebInfo/lapack_win32_MT.dll)
  STRING(REGEX REPLACE "/" "\\\\" lapack_OUTPUT_NEU ${lapack_OUTPUT})

  ADD_CUSTOM_COMMAND(OUTPUT ${lapack_OUTPUT} ${blas_OUTPUT} ${lapack_OUTPUT}
                     COMMAND ${COPY} ${lapack_CODE_NEU} ${lapack_OUTPUT_NEU}
                     WORKING_DIRECTORY ${dir}
                     COMMENT "copy file ${lapack_CODE_NEU} to ${lapack_OUTPUT_NEU}")
  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(lapack${model} ALL DEPENDS ${lapack_OUTPUT})


  SET(blas_CODE   ${OMDEV}/lib/lapack-win32-msvc/blas_win32_MT.dll)
  STRING(REGEX REPLACE "/" "\\\\" blas_CODE_NEU ${blas_CODE})
  SET(blas_OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/RelWithDebInfo/blas_win32_MT.dll)
  STRING(REGEX REPLACE "/" "\\\\" blas_OUTPUT_NEU ${blas_OUTPUT})

  ADD_CUSTOM_COMMAND(OUTPUT ${blas_OUTPUT} ${blas_OUTPUT} ${lapack_OUTPUT}
                     COMMAND ${COPY} ${blas_CODE_NEU} ${blas_OUTPUT_NEU}
                     WORKING_DIRECTORY ${dir}
                     COMMENT "copy file ${blas_CODE_NEU} to ${blas_OUTPUT_NEU}")
  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(blas${model} ALL DEPENDS ${blas_OUTPUT})

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
                     COMMENT "Generating code for ${model} with ${OMC_DEBUG}")
  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${model}codegen ALL DEPENDS ${OMC_OUTPUT})

  ADD_CUSTOM_TARGET(${model}codegencpp ALL DEPENDS ${OMC_OUTPUT})

  ADD_DEFINITIONS(/TP)
  set_source_files_properties(${OMC_OUTPUT} PROPERTIES LANGUAGE CXX)
  ADD_EXECUTABLE(${model} ${OMC_OUTPUT} ${CSRC})
  TARGET_LINK_LIBRARIES(${model} simulation util math-support results solver meta ModelicaExternalC libexpat initialization lapack_win32_MT ${SUNDIALS_LIBRARIES})

  # custom command to copy xml file
  SET(XML_CODE   ${dir}/${model}_init.xml)
  STRING(REGEX REPLACE "/" "\\\\" XML_CODE_NEU ${XML_CODE})
  SET(XML_OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/RelWithDebInfo/${model}_init.xml)
  STRING(REGEX REPLACE "/" "\\\\" XML_OUTPUT_NEU ${XML_OUTPUT})
  ADD_CUSTOM_COMMAND(OUTPUT ${XML_OUTPUT}
                     COMMAND ${COPY} ${XML_CODE_NEU} ${XML_OUTPUT_NEU}
                     WORKING_DIRECTORY ${dir}
                     COMMENT "copy file ${XML_CODE_NEU} to ${XML_OUTPUT_NEU}")
  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${model}cp_xml ALL DEPENDS ${XML_OUTPUT})

  # Dependencies
  ADD_DEPENDENCIES(${model}cp_xml ${model}codegen expat${model} lapack${model} blas${model})
  ADD_DEPENDENCIES(${model} ${model}cp_xml)

#ENDFOREACH(model ${model_sources})
ENDMACRO(BUILDMODELMOS)

# MACRO BUILDMODEL
MACRO(BUILDMODELFMU model dir Flags CSRC)

IF(WIN32)
  SET(COPY copy)
else(WIN32)
  SET(COPY cp)
endif(WIN32)

IF(SUNDIALS_INCLUDE_DIR AND
   SUNDIALS_LIBRARY_CVODE AND
   SUNDIALS_LIBRARY_IDA AND
   SUNDIALS_LIBRARY_NVEC AND
   SUNDIALS_KINSOL)

  INCLUDE_DIRECTORIES(${SUNDIALS_INCLUDE_DIR})
  SET(SUNDIALS_LIBRARIES ${SUNDIALS_LIBRARY_CVODE} ${SUNDIALS_LIBRARY_IDA} ${SUNDIALS_LIBRARY_NVEC} ${SUNDIALS_KINSOL})

ENDIF(SUNDIALS_INCLUDE_DIR AND
      SUNDIALS_LIBRARY_CVODE AND
      SUNDIALS_LIBRARY_IDA AND
   SUNDIALS_LIBRARY_NVEC AND
   SUNDIALS_KINSOL)

  # includes
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/linearization)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/math-support)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/meta)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/meta/gc)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/ModelicaExternalC)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation/results)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation/solver)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation/solver/initialization)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/util)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/fmi/export/fmi1)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/dataReconciliation)

  # OMDEV PATH
  IF(NOT OMDEV)
    SET(OMDEV $ENV{OMDEV})
  ENDIF(NOT OMDEV)

  INCLUDE_DIRECTORIES(${OMDEV}/lib/expat-win32-msvc)
  link_directories(${OMDEV}/lib/expat-win32-msvc)
  link_directories(${OMDEV}/lib/lapack-win32-msvc)

  SET(OMC_MODELNAME ${model})
  SET(OMC_MODELDIR ${dir})
  # generate model.mos
  FIND_FILE(MOSFILE_IN model_fmu.in PATHS ${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c)
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

  SET(OMC_FMU_CODE ${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/fmi/export/fmi1/fmu1_model_interface.h
                   ${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/fmi/export/fmi1/fmiModelFunctions.h
           ${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/fmi/export/fmi1/fmiModelTypes.h)

  ADD_LIBRARY(${model} SHARED ${OMC_OUTPUT} ${CSRC} ${OMC_FMU_CODE})
  TARGET_LINK_LIBRARIES(${model} simulation util math-support results solver meta ModelicaExternalC libexpat initialization lapack_win32_MT)

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

IF(WIN32)
  SET(COPY copy)
else(WIN32)
  SET(COPY cp)
endif(WIN32)

IF(SUNDIALS_INCLUDE_DIR AND
   SUNDIALS_LIBRARY_CVODE AND
   SUNDIALS_LIBRARY_IDA AND
   SUNDIALS_LIBRARY_NVEC AND
   SUNDIALS_KINSOL)

  INCLUDE_DIRECTORIES(${SUNDIALS_INCLUDE_DIR})
  SET(SUNDIALS_LIBRARIES ${SUNDIALS_LIBRARY_CVODE} ${SUNDIALS_LIBRARY_IDA} ${SUNDIALS_LIBRARY_NVEC} ${SUNDIALS_KINSOL})

ENDIF(SUNDIALS_INCLUDE_DIR AND
      SUNDIALS_LIBRARY_CVODE AND
      SUNDIALS_LIBRARY_IDA AND
   SUNDIALS_LIBRARY_NVEC AND
   SUNDIALS_KINSOL)

  # includes
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/linearization)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/math-support)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/meta)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/meta/gc)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/ModelicaExternalC)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation/results)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation/solver)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/simulation/solver/initialization)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/util)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/fmi/export)
  INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/c/dataReconciliation)

  # OMDEV PATH
  IF(NOT OMDEV)
    SET(OMDEV $ENV{OMDEV})
  ENDIF(NOT OMDEV)

  INCLUDE_DIRECTORIES(${OMDEV}/lib/expat-win32-msvc)
  link_directories(${OMDEV}/lib/expat-win32-msvc)
  link_directories(${OMDEV}/lib/lapack-win32-msvc)

  STRING(REPLACE "." "_" FMU_MODELNAME ${model})
  # generate model.mos

  # Variablen fuer openmodelica2sarturis
  SET(OMC_CODE   ${CMAKE_CURRENT_BINARY_DIR}/${FMU_MODELNAME}.c
                 ${CMAKE_CURRENT_BINARY_DIR}/${FMU_MODELNAME}_functions.c
                 ${CMAKE_CURRENT_BINARY_DIR}/${FMU_MODELNAME}_init.txt)
  SET(OMC_OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/${FMU_MODELNAME}.c
                  ${CMAKE_CURRENT_BINARY_DIR}/${FMU_MODELNAME}_FMU.c
  #               ${CMAKE_CURRENT_BINARY_DIR}/${FMU_MODELNAME}_functions.cpp
          ${CMAKE_CURRENT_BINARY_DIR}/${FMU_MODELNAME}_functions.h
          ${CMAKE_CURRENT_BINARY_DIR}/${FMU_MODELNAME}_records.c)
  # custom command fuer openmodelicacompiler
  ADD_CUSTOM_COMMAND(OUTPUT ${OMC_OUTPUT}
                     COMMAND ${OMC_DEBUG} ${Flags} ${mos}
                     WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                     COMMENT "Erzeuge Code fuer ${model} with ${OMC_DEBUG} in ${CMAKE_CURRENT_BINARY_DIR}")
  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${model}codegen ALL DEPENDS ${OMC_OUTPUT})

  SET(OMC_FMU_CODE ${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/fmi/export/fmi1/fmu1_model_interface.h
                   ${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/fmi/export/fmi1/fmiModelFunctions.h
           ${OMCTRUNCHOME}/OMCompiler/SimulationRuntime/fmi/export/fmi1/fmiModelTypes.h)

  ADD_DEFINITIONS(/TP ${FMU_MODELNAME}.c)
  set_source_files_properties(${OMC_OUTPUT} PROPERTIES LANGUAGE CXX)
  ADD_LIBRARY(${model} SHARED ${OMC_OUTPUT} ${CSRC} ${OMC_FMU_CODE})
  TARGET_LINK_LIBRARIES(${model} simulation util math-support results solver meta ModelicaExternalC libexpat initialization lapack_win32_MT ${SUNDIALS_LIBRARIES})

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