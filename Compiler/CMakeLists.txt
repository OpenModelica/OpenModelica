
# The MO sources
SET(SRCMO Absyn.mo AbsynDep.mo Algorithm.mo Builtin.mo 
          Ceval.mo CevalScript.mo Cevalfunc.mo ClassInf.mo
		  ClassLoader.mo Codegen.mo Connect.mo ExpandableConnectors.mo 
		  ConnectionGraph.mo Convert.mo DAE.mo DAELow.mo 
		  DAEUtil.mo Derive.mo Debug.mo	DFA.mo Dump.mo 
		  DumpGraphviz.mo Constants.mo Env.mo Error.mo 
		  Exp.mo SCode.mo SCodeUtil.mo Graphviz.mo HashTable.mo 
		  HashTable2.mo HashTable3.mo HashTable4.mo HashTable5.mo 
		  HashTable6.mo HashTableCG.mo HashTableStringToPath.mo 
		  Inline.mo Inst.mo InstExtends.mo Interactive.mo 
		  Lookup.mo Main.mo MMath.mo MetaUtil.mo Mod.mo ModUtil.mo 
		  PartFn.mo Patternm.mo Prefix.mo PrefixUtil.mo Static.mo 
		  SimCode.mo SimCodeC.mo SimCodeCSharp.mo 
		  Types.mo TaskGraph.mo Tpl.mo TplAbsyn.mo TplCodegen.mo 
		  TplParser.mo TplMain.mo Util.mo UnitAbsyn.mo 
		  UnitAbsynBuilder.mo UnitChecker.mo Values.mo ValuesUtil.mo 
		  VarTransform.mo BackendVarTransform.mo Refactor.mo 
		  DAEQuery.mo XMLDump.mo InstanceHierarchy.mo InnerOuter.mo 
		  ConnectUtil.mo Dependency.mo)

SET(ALLMO ${SRCMO} DAEEXT.mo DynLoad.mo Print.mo RTOpts.mo System.mo Parser.mo 
		TaskGraphExt.mo Corba.mo Socket.mo ErrorExt.mo Settings.mo 
		OptManager.mo UnitParserExt.mo SimulationResults.mo)
		  
# RML
IF(NOT RML)
  FIND_PROGRAM(RML rml DOC "Location of the RML executable"
               PATHS ENV OMDEV ${RMLHOME}/bin
               PATH_SUFFIXES bin tools/rml/bin)
  MESSAGE(STATUS "-- rml is " ${RML})
ENDIF(NOT RML)		  

#copy all to CODEGENDIR
FOREACH(DEP ${ALLMO})

	# Datei- und Pfadname
    GET_FILENAME_COMPONENT(DF ${DEP} NAME)
    GET_FILENAME_COMPONENT(DFWE ${DEP} NAME_WE)
    GET_FILENAME_COMPONENT(DP ${DEP} PATH)

	# Suchen
	FIND_FILE(${DEP}_FILE ${DF} PATHS ${DP} ${CMAKE_CURRENT_SOURCE_DIR})

	# Wenn nicht gefunden, dann Original nehmen
	STRING(COMPARE EQUAL ${${DEP}_FILE} ${DEP}_FILE-NOTFOUND FF)
	IF(${FF})
		SET(${DEP}_FILE "\"${DEP}\"")
	ENDIF(${FF})
 
 	SET(COPY_DEP  ${${DEP}_FILE})

	SET(COPY_OUTPUT  ${CODEGENDIR}/${DEP})
	# custom command for copy
	ADD_CUSTOM_COMMAND(OUTPUT ${COPY_OUTPUT}
                     COMMAND ${CMAKE_COMMAND} -E copy ${COPY_DEP} ${COPY_OUTPUT}
					 DEPENDS ${COPY_DEP}
                     WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                     COMMENT "copy ${COPY_DEP} to ${COPY_OUTPUT}")

  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${DFWE}_cp ALL DEPENDS ${COPY_OUTPUT})
  
  # remember
  SET(COPY_ALL ${COPY_ALL} ${COPY_OUTPUT})
ENDFOREACH(DEP)

#.depend:
SET(DEPENDT_OUTPUT  ${CODEGENDIR}/.depend)
# custom command for rml to sig
ADD_CUSTOM_COMMAND(OUTPUT ${DEPENDT_OUTPUT}
                   COMMAND ${RML} -fdump-depends ${SRCMO} > .depend 	
                   DEPENDS ${COPY_ALL}
                   WORKING_DIRECTORY ${CODEGENDIR}
                   COMMENT "Generate .depend")

# target fuer OM_OUTPUT
ADD_CUSTOM_TARGET(depend ALL DEPENDS ${DEPENDT_OUTPUT})
  

# generate sig files
FOREACH(DEP ${ALLMO})

	# Datei- und Pfadname
    GET_FILENAME_COMPONENT(DF ${DEP} NAME)
    GET_FILENAME_COMPONENT(DFWE ${DEP} NAME_WE)
 
	# Merken
	SET(SIG_DEP ${DFWE}.sig)
  
  SET(SIGX_OUTPUT  ${CODEGENDIR}/${SIG_DEP})
  # custom command for rml to sig
  ADD_CUSTOM_COMMAND(OUTPUT ${SIGX_OUTPUT}
                     COMMAND ${RML} -fdump-interface ${DEP} > ${SIG_DEP}  	
					 DEPENDS ${DEPENDT_OUTPUT}
                     WORKING_DIRECTORY ${CODEGENDIR}
                     COMMENT "Generate Sigx from ${DF}")

  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${DFWE}_sig ALL DEPENDS ${SIGX_OUTPUT})
  
    # remember
  SET(SIGX_ALL ${SIGX_ALL} ${SIGX_OUTPUT} )
ENDFOREACH(DEP)

# generate *.h and *.c from *.mo files
FOREACH(DEP ${SRCMO})

	# Datei- und Pfadname
    GET_FILENAME_COMPONENT(DF ${DEP} NAME)
    GET_FILENAME_COMPONENT(DFWE ${DEP} NAME_WE)
 
	# Merken
	SET(MOCH_DEP ${CODEGENDIR}/${DFWE}.h ${CODEGENDIR}/${DFWE}.c)
  
  SET(MOCH_OUTPUT  ${MOCH_DEP})
  # custom command for rml to sig
  ADD_CUSTOM_COMMAND(OUTPUT ${MOCH_OUTPUT}
                     COMMAND ${RML} -Eplain -ftrace ${RMLCFLAGS} ${DEP} 	
					 DEPENDS ${SIGX_ALL}
                     WORKING_DIRECTORY ${CODEGENDIR}
                     COMMENT "Generate *.h and *.c from ${DEP}")

  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${DFWE}_codegen ALL DEPENDS ${MOCH_OUTPUT})
  
  # remember
  SET(MOCH_ALL ${MOCH_ALL} ${MOCH_OUTPUT})
  SET(MOCH_codegen_ALL ${MOCH_codegen_ALL} ${DFWE}_codegen)
ENDFOREACH(DEP)

ADD_SUBDIRECTORY(runtime)
ADD_SUBDIRECTORY(absyn_builder)
ADD_SUBDIRECTORY(modpar)

if(WIN32)
INCLUDE_DIRECTORIES($ENV{OMDEV}/tools/rml/include/plain)
link_directories($ENV{OMDEV}/lib/antlr-win32-msvc/md-mdd ${OMCTRUNCHOME}/Compiler/runtime/lpsolve/lib/win32)
link_directories($ENV{OMDEV}/tools/rml/lib/plain)
#link_directories(D:/Programming/OPENMODELICA/buildmmc/runtime/plain/RelWithDebInfo)
else(WIN32)
INCLUDE_DIRECTORIES(${RMLHOME}/include/plain)
link_directories(${RMLHOME}/lib/plain)
endif(WIN32)
INCLUDE_DIRECTORIES(${CODEGENDIR})

# mico und benoetigte Bibliotheken
IF(WIN32)
  SET(platform_libs optimized mico2313 debug mico2313d optimized antlr debug antlrd)
ELSE(WIN32)
  SET(platform_libs mico2.3.13 optimized antlr debug antlrd) #ssl pthread)
ENDIF(WIN32)
# omc program

#add_definitions(/Ob2 /Ox /O2 /Ot /Oy /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_CRT_SECURE_NO_WARNINGS" /D "_MBCS" /FD /EHsc /MT /W3 /nologo /c /TC /wd4311 /wd4312)
if(WIN32)
add_definitions(/D "_CRT_SECURE_NO_WARNINGS" /D "_CONSOLE")
endif(WIN32)
ADD_EXECUTABLE(omc ${MOCH_ALL})
if(WIN32)
TARGET_LINK_LIBRARIES(omc absyn_builder libmodpar sendData c_runtime wsock32 shlwapi)
TARGET_LINK_LIBRARIES(omc  rml)
else(WIN32)
TARGET_LINK_LIBRARIES(omc absyn_builder libmodpar sendData c_runtime runtime optimized lpsolve55 debug lpsolve55d ${platform_libs})
TARGET_LINK_LIBRARIES(omc rml)
endif(WIN32)

# install
INSTALL(TARGETS omc 
        RUNTIME DESTINATION bin)
