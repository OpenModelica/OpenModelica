

# ar
IF(NOT AR)
  FIND_PROGRAM(AR ar DOC "Location of the ar executable"
               PATHS ENV OMDEV
               PATH_SUFFIXES bin tools/mingw/bin)
  MESSAGE(STATUS "-- ar is " ${AR})
ENDIF(NOT AR)

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

SET(ANTLR_FILES walker.g)

# Includes
INCLUDE_DIRECTORIES($ENV{OMDEV}/include)

# generate antlr files
FOREACH(DEP ${ANTLR_FILES})

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

  SET(ANTLR_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${DF_WE}.cpp ${CMAKE_CURRENT_BINARY_DIR}/${DF_WE}.hpp)
  # custom command for ar
  ADD_CUSTOM_COMMAND(OUTPUT ${ANTLR_OUTPUT}
                     COMMAND ${ANTLR} ${ANTLRFLAGS} ${${DEP}_FILE}												  
                     WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                     COMMENT "Generate antlr from ${DEP}")

  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${DEP}_antlr ALL DEPENDS ${ANTLR_DEP})

ENDFOREACH(DEP)

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

  SET(ANTLR_WOUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${WDF_WE}.cpp ${CMAKE_CURRENT_BINARY_DIR}/${WDF_WE}.hpp)
  # custom command for ar
  ADD_CUSTOM_COMMAND(OUTPUT ${ANTLR_WOUTPUT}
                     COMMAND ${ANTLR} -glib ${CMAKE_CURRENT_SOURCE_DIR}/../../modelica_parser/src/modelica_parser.g ${ANTLRFLAGS} ${${WDEP}_FILE}												  
                     WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                     COMMENT "Generate antlr from ${WDEP}")

  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${WDEP}_antlr ALL DEPENDS ${ANTLR_WDEP})

# source
SET(helperobjs parse.cpp)

SET(OBJS ${helperobjs} ${ANTLR_OUTPUT} ${ANTLR_WOUTPUT} ${ANTLR_FILES})

ADD_LIBRARY(absyn_builder ${OBJS})
IF(WIN32)
  SET(ANTLR_LIB $ENV{OMDEV}/lib/antlr-win32-msvc/antlr)
ELSE(WIN32)
  SET(ANTLR_LIB $ENV{OMDEV}/lib/antlr-msys-mingw/libantlr)
ENDIF(WIN32)
TARGET_LINK_LIBRARIES(absyn_builder ${ANTLR_LIB} libmodelica_parser libflat_modelica_parser)
