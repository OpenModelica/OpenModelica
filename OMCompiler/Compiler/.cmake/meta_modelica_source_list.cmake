set(OMC_MM_ALWAYS_SOURCES
# Only files needed for compiling MetaModelica
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/File.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Absyn.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/AbsynToSCode.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/AbsynUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Algorithm.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/BackendInterface.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Builtin.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/CevalFunction.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Ceval.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ClassInf.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ClassLoader.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ComponentReference.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ConnectionGraph.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ConnectUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/DAEDump.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/DAE.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/DAEUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Dump.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ElementSource.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ExpressionDump.mo
  # Remember: Only files needed for compiling MetaModelica
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Expression.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ExpressionSimplify.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ExpressionSimplifyTypes.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Graphviz.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Inline.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/InnerOuter.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Inst.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/InstVar.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/InstDAE.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/InstBinding.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/InstFunction.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/InstHashTable.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/InstMeta.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/InstUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/InstExtends.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/InstSection.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/InstTypes.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Lookup.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/MetaUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/MMath.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Mod.mo
  # Remember: Only files needed for compiling MetaModelica
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/OperatorOverloading.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Parser.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ParserExt.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Patternm.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/PrefixUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/SCode.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/SCodeDump.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/SCodeInstUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/SCodeUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Static.mo
    #${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/SCodeSimplify.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/StateMachineFlatten.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Types.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/UnitAbsyn.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/UnitParserExt.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/Values.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/ValuesUtil.mo

  # Only files needed for compiling MetaModelica
  # "FFrontEnd";
    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FBuiltin.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FCore.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FExpand.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FGraph.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FGraphBuild.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FGraphBuildEnv.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FLookup.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FMod.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FNode.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FResolve.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FTraverse.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FVisit.mo

   # NF files required for bootstrapping are put in the FrontEnd folder
   # NF files not required for bootstrapping are put together with the backend files

  # Only files needed for compiling MetaModelica
  # "BackEnd";
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BackendDAE.mo

  # Only files needed for compiling MetaModelica
  # "SimCode";
    ${CMAKE_CURRENT_SOURCE_DIR}/SimCode/HpcOmSimCode.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/SimCode/SimCodeFunction.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/SimCode/SimCodeFunctionUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/SimCode/SimCodeVar.mo

  # Only files needed for compiling MetaModelica
  # "Script";
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/CevalScript.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/GlobalScript.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/GlobalScriptDump.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/GlobalScriptUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/Interactive.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/StaticScript.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/SymbolTable.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/InteractiveUtil.mo

# Only files needed for compiling MetaModelica
# "Template";
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/AbsynDumpTpl.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCFunctions.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/DAEDumpTpl.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/ExpressionDumpTpl.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/GenerateAPIFunctionsTpl.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/SCodeDumpTpl.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/TplAbsyn.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/susan_codegen/TplCodegen.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/TplMain.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/Tpl.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/TplParser.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/Unparsing.mo

  # Only files needed for compiling MetaModelica
  # "Global";
    ${CMAKE_CURRENT_SOURCE_DIR}/Global/Global.mo

  # Only files needed for compiling MetaModelica
  # "Main";
    ${CMAKE_CURRENT_SOURCE_DIR}/Main/Main.mo

  # Only files needed for compiling MetaModelica
  # "Util";
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Array.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/AvlSetCR.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/AvlSetPath.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/AvlSetString.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/AvlTreeStringString.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/AvlTreeCRToInt.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/BaseAvlTree.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/BaseAvlSet.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/BaseHashTable.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/BaseHashSet.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/ClockIndexes.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Config.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Corba.mo
    #${CMAKE_CURRENT_SOURCE_DIR}/Util/Database.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Debug.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/DoubleEnded.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/DynLoad.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/ErrorExt.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Error.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/ErrorTypes.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/ExecStat.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Flags.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/FlagsUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/GCExt.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Gettext.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Graph.mo
  # Remember: Only files needed for compiling MetaModelica
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashSet.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashSetExp.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashSetString.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTable2.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTable3.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTable5.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableCG.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableCrefSimVar.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableCrILst.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableCrIListArray.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableCrToExpOption.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTable.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableExpToIndex.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableStringToPath.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableStringToProgram.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/IOStreamExt.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/IOStream.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Lapack.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/List.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Mutable.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Pointer.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Print.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/SemanticVersion.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Settings.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/StackOverflow.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/StringUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Socket.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/System.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Testsuite.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Util.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/VarTransform.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/ZeroMQ.mo
)


set(OMC_MM_BACKEND_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/AdjacencyMatrix.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BackendDAEFunc.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BackendDAECreate.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BackendDAEEXT.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BackendDAEOptimize.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BackendDAETransform.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BackendDAEUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BackendDump.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BackendEquation.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BackendInline.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BackendUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BackendVariable.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BackendVarTransform.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BinaryTree.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/BinaryTreeInt.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/Causalize.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/CommonSubExpression.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/DAEQuery.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/DAEMode.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/DataReconciliation.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/Differentiate.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/DumpGraphML.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/DumpHTML.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/DynamicOptimization.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/EvaluateFunctions.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/EvaluateParameter.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/ExpressionSolve.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/FindZeroCrossings.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/HpcOmBenchmark.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/HpcOmBenchmarkExt.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/HpcOmEqSystems.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/HpcOmMemory.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/HpcOmScheduler.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/HpcOmSchedulerExt.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/HpcOmTaskGraph.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/IndexReduction.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/InlineArrayEquations.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/Initialization.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/Matching.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/MathematicaDump.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/OnRelaxation.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/RemoveSimpleEquations.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/ResolveLoops.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/Sorting.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/SymbolicImplicitSolver.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/SymbolicJacobian.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/SynchronousFeatures.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/Tearing.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/Uncertainties.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/Vectorization.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/VisualXML.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/XMLDump.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/BackEnd/ZeroCrossings.mo

    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FGraphDump.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FFrontEnd/FInst.mo

    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/CheckModel.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/DumpGraphviz.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/InstStateMachineUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/FUnit.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/FUnitCheck.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/FHashTableCrToUnit.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/FHashTableStringToUnit.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/FHashTableUnitToString.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/NFEnvExtends.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/NFInstDump.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/NFInstPrefix.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/NFInstTypes.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/NFSCodeDependency.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/NFSCodeEnv.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/NFSCodeFlattenImports.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/NFSCodeFlatten.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/NFSCodeFlattenRedeclare.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/NFSCodeLookup.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/NFSCodeCheck.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/UnitAbsynBuilder.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/FrontEnd/UnitChecker.mo

    # "MidCode";
    ${CMAKE_CURRENT_SOURCE_DIR}/MidCode/MidCode.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/MidCode/DAEToMid.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/MidCode/MidToMid.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/MidCode/HashTableMidVar.mo

    # "NBackend Classes";
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Classes/NBackendDAE.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Classes/NBEquation.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Classes/NBPartition.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Classes/NBStrongComponent.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Classes/NBVariable.mo
    # "NBackend Modules";
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/NBModule.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/1_Main/NBCausalize.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/1_Main/NBDAEMode.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/1_Main/NBInitialization.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/1_Main/NBMatching.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/1_Main/NBPartitioning.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/1_Main/NBResolveSingularities.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/1_Main/NBSorting.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/2_Pre/NBAlias.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/2_Pre/NBBindings.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/2_Pre/NBDetectStates.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/2_Pre/NBEvents.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/2_Pre/NBFunctionAlias.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/2_Pre/NBInline.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/3_Post/NBJacobian.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/3_Post/NBSolve.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/3_Post/NBTearing.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Modules/3_Post/NBEvaluation.mo
    # "NBackend Util";
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Util/NBAdjacency.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Util/NBASSC.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Util/NBBackendUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Util/NBDifferentiate.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Util/NBReplacements.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Util/NBResizable.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NBackEnd/Util/NBSlice.mo

    # "NFFrontEnd";
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/BaseModelica.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFAlgorithm.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFArrayConnections.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFAttributes.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFBackendExtension.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFBinding.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFBuiltinCall.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFBuiltinFuncs.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFBuiltin.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFCallAttributes.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFCall.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFCallParameterTree.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFCardinalityTable.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFCeval.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFCheckModel.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFClass.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFClassTree.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFClockKind.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFComplexType.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFComponent.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFComponentRef.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFConnectEquations.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFConnection.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFConnectionSets.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFConnections.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFConnector.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFConvertDAE.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFDimension.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFDuplicateTree.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFEquation.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFEvalConstants.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFEvalFunctionExt.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFEvalFunction.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFExpandableConnectors.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFExpandExp.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFExpressionIterator.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFExpression.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFFlatModel.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFFlatModelicaUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFFlatten.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFFunctionDerivative.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFFunctionInverse.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFFunction.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFImport.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFInline.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFInstContext.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFInst.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFInstNode.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFInstUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFLookup.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFLookupState.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFLookupTree.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFModifier.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFOCConnectionGraph.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFOperator.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFOperatorOverloading.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFPackage.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFPrefixes.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFRangeIterator.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFRecord.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFRestriction.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFSBGraphUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFScalarize.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFSections.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFSimplifyExp.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFSimplifyModel.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFStatement.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFStructural.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFSubscript.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFTypeCheck.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFType.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFTyping.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFUnitCheck.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFUnit.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFVariable.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NFFrontEnd/NFVerifyModel.mo

    # "NSimCode";
    ${CMAKE_CURRENT_SOURCE_DIR}/NSimCode/NSimCode.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NSimCode/NSimCodeUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NSimCode/NSimGenericCall.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NSimCode/NSimJacobian.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NSimCode/NSimPartition.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NSimCode/NSimStrongComponent.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/NSimCode/NSimVar.mo

    ${CMAKE_CURRENT_SOURCE_DIR}/Lexers/LexerJSON.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Lexers/LexerModelicaDiff.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Parsers/JSON.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Parsers/SimpleModelicaParser.mo

    ${CMAKE_CURRENT_SOURCE_DIR}/Script/CevalScriptOMSimulator.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/Refactor.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/RewriteRules.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/Figaro.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/BlockCallRewrite.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/Binding.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/OpenModelicaScriptingAPI.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/CevalScriptBackend.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/PackageManagement.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/MMToJuliaUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/MMToJuliaKeywords.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/NFApi.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/Conversion.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/Obfuscate.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Script/TotalModelDebug.mo

    ${CMAKE_CURRENT_SOURCE_DIR}/SimCode/HpcOmSimCodeMain.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/SimCode/SerializeInitXML.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/SimCode/SerializeModelInfo.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/SimCode/SerializeSparsityPattern.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/SimCode/SerializeTaskSystemInfo.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/SimCode/SimCode.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/SimCode/SimCodeMain.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/SimCode/SimCodeUtil.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/SimCode/ReduceDAE.mo

    ${CMAKE_CURRENT_SOURCE_DIR}/Template/AbsynToJulia.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/AbsynJLDumpTpl.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenC.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenEmbeddedC.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppCommon.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCpp.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppOMSI.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppHpcom.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppHpcomOMSI.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenCppInit.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU1.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMU2.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCommon.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCpp.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCppOMSI.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenOMSI_common.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenOMSIC.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenOMSIC_Equations.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenOMSICpp.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCppHpcom.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenFMUCppHpcomOMSI.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenJS.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenMidToC.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenUtilSimulation.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/CodegenXML.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/GraphvizDump.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/GraphMLDumpTpl.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/NFInstDumpTpl.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/SimCodeDump.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Template/VisualXMLTpl.mo

    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Autoconf.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/AvlTree.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/AvlTreeString.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/AvlSetInt.mo

    # ${CMAKE_CURRENT_SOURCE_DIR}/Util/BasePVector.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Curl.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/DiffAlgorithm.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/DisjointSets.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/ExpandableArray.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/FFI.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/FMI.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/FMIExt.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/GraphML.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/JSONExt.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableCrToExp.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableExpToExp.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableCrIntToExp.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableCrToExpSourceTpl.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableCrToCrEqLst.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableSimCodeEqCache.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/HashTableSM1.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/OMSimulatorExt.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/PriorityQueue.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/SBAtomicSet.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/SBFunctions.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/SBGraph.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/SBInterval.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/SBLinearMap.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/SBMultiInterval.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/SBPWAtomicLinearMap.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/SBPWLinearMap.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/SBSet.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/SimulationResults.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/TaskGraphResults.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/UnorderedMap.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/UnorderedSet.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Unzip.mo
    ${CMAKE_CURRENT_SOURCE_DIR}/Util/Vector.mo

    ${CMAKE_CURRENT_SOURCE_DIR}/../SimulationRuntime/c/RuntimeSources.mo
)
