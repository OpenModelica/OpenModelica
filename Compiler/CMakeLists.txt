
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
		  SimCode.mo SimCodeC.mo SimCodeCSharp.mo SimCodegen.mo 
		  Types.mo TaskGraph.mo Tpl.mo TplAbsyn.mo TplCodegen.mo 
		  TplParser.mo TplMain.mo Util.mo UnitAbsyn.mo 
		  UnitAbsynBuilder.mo UnitChecker.mo Values.mo ValuesUtil.mo 
		  VarTransform.mo BackendVarTransform.mo Refactor.mo 
		  DAEQuery.mo XMLDump.mo InstanceHierarchy.mo InnerOuter.mo 
		  ConnectUtil.mo)

SET(ALLMO ${SRCMO} DAEEXT.mo DynLoad.mo Print.mo RTOpts.mo System.mo Parser.mo 
		TaskGraphExt.mo Corba.mo Socket.mo ErrorExt.mo Settings.mo 
		OptManager.mo UnitParserExt.mo SimulationResults.mo)
		  
# RML
IF(NOT RML)
  FIND_PROGRAM(RML rml DOC "Location of the RML executable"
               PATHS ENV OMDEV
               PATH_SUFFIXES bin tools/rml/bin)
  MESSAGE(STATUS "-- rml is " ${RML})
ENDIF(NOT RML)		  
		  

# generate sig files
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
 
	# Merken
	SET(SIG_DEP ${DFWE}.sig)
  
  SET(SIGX_OUTPUT  ${SIG_DEP})
  # custom command for rml to sig
  ADD_CUSTOM_COMMAND(OUTPUT ${SIGX_OUTPUT}
                     COMMAND ${RML} -fdump-interface ${${DEP}_FILE} > ${SIG_DEP}  												  
                     WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                     COMMENT "Generate Sigx from ${DF}")

  # target fuer OM_OUTPUT
  ADD_CUSTOM_TARGET(${SIG_DEP} ALL DEPENDS ${SIGX_OUTPUT})
ENDFOREACH(DEP)

ADD_SUBDIRECTORY(runtime)
ADD_SUBDIRECTORY(absyn_builder)
ADD_SUBDIRECTORY(modpar)