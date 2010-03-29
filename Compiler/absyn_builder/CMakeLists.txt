# java
IF(NOT JAVA)
  FIND_PROGRAM(JAVA java DOC "Location of the java executable"
               PATHS ENV
               PATH_SUFFIXES bin)
  MESSAGE(STATUS "-- java is " ${JAVA})
ENDIF(NOT JAVA)

# antlr 
SET(ANTLR ${JAVA} -cp $ENV{OMDEV}/bin/antlr/antlr.jar antlr.Tool)
SET(ANTLRFLAGS ) #-traceParser")


# Includes
INCLUDE_DIRECTORIES($ENV{OMDEV}/include)
INCLUDE_DIRECTORIES($ENV{OMDEV}/tools/rml/include/plain)
INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/modelica_parser/src)
INCLUDE_DIRECTORIES(${CODEGENDIR}/absyn_builder)

GET_PROPERTY(modelica_parser GLOBAL PROPERTY  MODELICA_parser_BUILD)
INCLUDE_DIRECTORIES(${modelica_parser})
GET_PROPERTY(modelica_flat_parser GLOBAL PROPERTY  MODELICA_flat_parser_BUILD)
INCLUDE_DIRECTORIES(${modelica_flat_parser})


  SET(MPTT_OUTPUT ${CODEGENDIR}/absyn_builder/modelica_parserTokenTypes.txt)
  # custom command for ar
  ADD_CUSTOM_COMMAND(OUTPUT ${MPTT_OUTPUT}
                     COMMAND ${CMAKE_COMMAND} -E copy ${modelica_parser}/modelica_parserTokenTypes.txt ${CODEGENDIR}/absyn_builder/modelica_parserTokenTypes.txt
					 DEPENDS modelica_parser.g_antlr
                     WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                     COMMENT "copy ${modelica_parser}/modelica_parserTokenTypes.txt to  ${CODEGENDIR}/absyn_builder/modelica_parserTokenTypes.txt")

  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(MPTT_cp ALL DEPENDS modelica_parser.g_antlr)

# generate antlr files
SET(DEP  walker.g)

	# Datei- und Pfadname
    GET_FILENAME_COMPONENT(DF ${DEP} NAME)
    GET_FILENAME_COMPONENT(DF_WE ${DEP} NAME_WE)
    GET_FILENAME_COMPONENT(DP ${DEP} PATH)

	# Suchen
	FIND_FILE(${DEP}_FILE ${DF} PATHS ${DP} ${CMAKE_CURRENT_SOURCE_DIR})

	# Wenn nicht gefunden, dann Original nehmen
	STRING(COMPARE EQUAL ${${DEP}_FILE} ${DEP}_FILE-NOTFOUND FF)
	IF(${FF})
		SET(${DEP}_FILE "\"${DEP}\"")
	ENDIF(${FF})
 
	# Merken
	SET(ANTLR_DEP ${${DEP}_FILE})

  SET(ANTLR_OUTPUT ${CODEGENDIR}/absyn_builder/modelica_tree_parser.cpp ${CODEGENDIR}/absyn_builder/modelica_tree_parser.hpp 
	               ${CODEGENDIR}/absyn_builder/modelica_tree_parserTokenTypes.hpp ${CODEGENDIR}/absyn_builder/modelica_tree_parserTokenTypes.txt)
  # custom command for ar
  ADD_CUSTOM_COMMAND(OUTPUT ${ANTLR_OUTPUT}
                     COMMAND ${ANTLR} ${ANTLRFLAGS} ${ANTLR_DEP} 
					 DEPENDS MPTT_cp ${ANTLR_DEP} ${MOCH_ALL}
                     WORKING_DIRECTORY ${CODEGENDIR}/absyn_builder
                     COMMENT "Generate antlr from ${DEP}")

  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${DEP}_antlr ALL DEPENDS ${ANTLR_DEP})

# Datei- und Pfadname
SET(WDEP expression_parser.g)
    GET_FILENAME_COMPONENT(WDF ${WDEP} NAME)
    GET_FILENAME_COMPONENT(WDF_WE ${WDEP} NAME_WE)
    GET_FILENAME_COMPONENT(WDP ${WDEP} PATH)

	# Suchen
	FIND_FILE(${WDEP}_FILE ${WDF} PATHS ${WDP} ${CMAKE_CURRENT_SOURCE_DIR})

	# Wenn nicht gefunden, dann Original nehmen
	STRING(COMPARE EQUAL ${${WDEP}_FILE} ${WDEP}_FILE-NOTFOUND FF)
	IF(${FF})
		SET(${WDEP}_FILE "\"${WDEP}\"")
	ENDIF(${FF})
 
	# Merken
	SET(ANTLR_WDEP ${${WDEP}_FILE})

  SET(ANTLR_WOUTPUT ${CODEGENDIR}/absyn_builder/modelica_expression_parser.cpp ${CODEGENDIR}/absyn_builder/modelica_expression_parser.hpp
                    ${CODEGENDIR}/absyn_builder/modelica_expression_parserTokenTypes.hpp ${CODEGENDIR}/absyn_builder/modelica_expression_parserTokenTypes.txt)

  SET(EP_OUTPUT ${CODEGENDIR}/absyn_builder/${WDEP})
  # custom command for ar
  ADD_CUSTOM_COMMAND(OUTPUT ${EP_OUTPUT}
                     COMMAND ${CMAKE_COMMAND} -E copy ${ANTLR_WDEP} ${EP_OUTPUT}
					 DEPENDS MPTT_cp ${MOCH_ALL}
                     WORKING_DIRECTORY ${CODEGENDIR}/absyn_builder
                     COMMENT "copy ${ANTLR_WDEP} to ${EP_OUTPUT}")

  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${WDEP}_cp ALL DEPENDS ${EP_OUTPUT})					

  # custom command for ar
  ADD_CUSTOM_COMMAND(OUTPUT ${ANTLR_WOUTPUT}
                     COMMAND ${ANTLR} -glib ${OMCTRUNCHOME}/modelica_parser/src/modelica_parser.g ${ANTLRFLAGS} ${WDEP}
					 DEPENDS ${WDEP}_cp  ${MPTT_OUTPUT} ${ANTLR_WDEP} modelica_parser.g_antlr ${MOCH_ALL}					 
                     WORKING_DIRECTORY ${CODEGENDIR}/absyn_builder
                     COMMENT "Generate antlr from ${ANTLR_WDEP}")

  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${WDEP}_antlr ALL DEPENDS ${EP_OUTPUT} ${ANTLR_WDEP})
  
  
# source
SET(ANTLR_FILES ${DEP} ${WDEP})
SET(helperobjs parse.cpp)

SET(OBJS ${helperobjs} ${ANTLR_OUTPUT} ${ANTLR_WOUTPUT} ${ANTLR_FILES})

#add_definitions(/Ob2 /Ox /O2 /Ot /Oy /D "WIN32" /D "NDEBUG" /D "_LIB" /D "_MBCS" /FD /EHsc /MT /GS /Fd"antlr.pdb" /W3 /nologo /c /Zi /TP)
add_definitions(/MT)
ADD_LIBRARY(absyn_builder ${OBJS})
TARGET_LINK_LIBRARIES(absyn_builder antlr libmodelica_parser libflat_modelica_parser runtime)
