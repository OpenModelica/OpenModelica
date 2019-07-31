  module Flags


    using MetaModelica
    #= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
    using ExportAll
    #= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#

    @UniontypeDecl DebugFlag
    @UniontypeDecl ConfigFlag
    @UniontypeDecl FlagData
    @UniontypeDecl FlagVisibility
    @UniontypeDecl Flag
    @UniontypeDecl ValidOptions

         #= /*
         * This file is part of OpenModelica.
         *
         * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
         * c/o Linköpings universitet, Department of Computer and Information Science,
         * SE-58183 Linköping, Sweden.
         *
         * All rights reserved.
         *
         * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
         * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
         * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
         * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
         * ACCORDING TO RECIPIENTS CHOICE.
         *
         * The OpenModelica software and the Open Source Modelica
         * Consortium (OSMC) Public License (OSMC-PL) are obtained
         * from OSMC, either from the above address,
         * from the URLs: http:www.ida.liu.se/projects/OpenModelica or
         * http:www.openmodelica.org, and in the OpenModelica distribution.
         * GNU version 3 is obtained from: http:www.gnu.org/copyleft/gpl.html.
         *
         * This program is distributed WITHOUT ANY WARRANTY; without
         * even the implied warranty of  MERCHANTABILITY or FITNESS
         * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
         * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
         *
         * See the full OSMC Public License conditions for more details.
         *
         */ =#

        import Util

        import Corba

        import ZeroMQ

        import Error

        import ErrorExt

        import Global

        import MetaModelica.ListUtil

        import Print

        import Settings

        import StringUtil

        import System

         @Uniontype DebugFlag begin
              @Record DEBUG_FLAG begin

                       index #= Unique index. =#::ModelicaInteger
                       name #= The name of the flag used by -d =#::String
                       default #= Default enabled or not =#::Bool
                       description #= A description of the flag. =#::Util.TranslatableContent
              end
         end

         @Uniontype ConfigFlag begin
              @Record CONFIG_FLAG begin

                       index #= Unique index. =#::ModelicaInteger
                       name #= The whole name of the flag. =#::String
                       shortname #= A short name one-character name for the flag. =#::Option{String}
                       visibility #= Whether the flag is visible to the user or not. =#::FlagVisibility
                       defaultValue #= The default value of the flag. =#::FlagData
                       validOptions #= The valid options for the flag. =#::Option{ValidOptions}
                       description #= A description of the flag. =#::Util.TranslatableContent
              end
         end

          #= This uniontype is used to store the values of configuration flags. =#
         @Uniontype FlagData begin
              @Record EMPTY_FLAG begin

              end

              @Record BOOL_FLAG begin

                       data::Bool
              end

              @Record INT_FLAG begin

                       data::ModelicaInteger
              end

              @Record INT_LIST_FLAG begin

                       data::List{ModelicaInteger}
              end

              @Record REAL_FLAG begin

                       data::ModelicaReal
              end

              @Record STRING_FLAG begin

                       data::String
              end

              @Record STRING_LIST_FLAG begin

                       data::List{String}
              end

              @Record ENUM_FLAG begin

                       data::ModelicaInteger
                       validValues #= The valid values of the enum. =#::List{Tuple{String, ModelicaInteger}}
              end
         end

          #= This uniontype is used to specify the visibility of a configuration flag. =#
         @Uniontype FlagVisibility begin
              @Record INTERNAL begin

              end

              @Record EXTERNAL begin

              end
         end

          #= The structure which stores the flags. =#
         @Uniontype Flag begin
              @Record FLAGS begin

                       debugFlags::Array{Bool}
                       configFlags::Array{FlagData}
              end

              @Record NO_FLAGS begin

              end
         end

          #= Specifies valid options for a flag. =#
         @Uniontype ValidOptions begin
              @Record STRING_OPTION begin

                       options::List{String}
              end

              @Record STRING_DESC_OPTION begin

                       options::List{Tuple{String, Util.TranslatableContent}}
              end
         end

         #=  Change this to a proper enum when we have support for them.
         =#

         MODELICA = 1::ModelicaInteger

         METAMODELICA = 2::ModelicaInteger

         PARMODELICA = 3::ModelicaInteger

         OPTIMICA = 4::ModelicaInteger

         PDEMODELICA = 5::ModelicaInteger
         collapseArrayExpressionsText = Util.gettext("Simplifies {x[1],x[2],x[3]} → x for arrays of whole variable references (simplifies code generation).")::Util.TranslatableContent
         #=  DEBUG FLAGS
         =#

         FAILTRACE = DEBUG_FLAG(1, "failtrace", false, Util.gettext("Sets whether to print a failtrace or not."))::DebugFlag
         CEVAL = DEBUG_FLAG(2, "ceval", false, Util.gettext("Prints extra information from Ceval."))::DebugFlag
         CHECK_BACKEND_DAE = DEBUG_FLAG(3, "checkBackendDae", false, Util.gettext("Do some simple analyses on the datastructure from the frontend to check if it is consistent."))::DebugFlag
         PARMODAUTO = DEBUG_FLAG(4, "parmodauto", false, Util.gettext("Experimental: Enable parallelization of independent systems of equations in the translated model."))::DebugFlag
         PTHREADS = DEBUG_FLAG(5, "pthreads", false, Util.gettext("Experimental: Unused parallelization."))::DebugFlag
         EVENTS = DEBUG_FLAG(6, "events", true, Util.gettext("Turns on/off events handling."))::DebugFlag
         DUMP_INLINE_SOLVER = DEBUG_FLAG(7, "dumpInlineSolver", false, Util.gettext("Dumps the inline solver equation system."))::DebugFlag
         EVAL_FUNC = DEBUG_FLAG(8, "evalfunc", true, Util.gettext("Turns on/off symbolic function evaluation."))::DebugFlag
         GEN = DEBUG_FLAG(9, "gen", false, Util.gettext("Turns on/off dynamic loading of functions that are compiled during translation. Only enable this if external functions are needed to calculate structural parameters or constants."))::DebugFlag
         DYN_LOAD = DEBUG_FLAG(10, "dynload", false, Util.gettext("Display debug information about dynamic loading of compiled functions."))::DebugFlag
         GENERATE_CODE_CHEAT = DEBUG_FLAG(11, "generateCodeCheat", false, Util.gettext("Used to generate code for the bootstrapped compiler."))::DebugFlag
         CGRAPH_GRAPHVIZ_FILE = DEBUG_FLAG(12, "cgraphGraphVizFile", false, Util.gettext("Generates a graphviz file of the connection graph."))::DebugFlag
         CGRAPH_GRAPHVIZ_SHOW = DEBUG_FLAG(13, "cgraphGraphVizShow", false, Util.gettext("Displays the connection graph with the GraphViz lefty tool."))::DebugFlag
         GC_PROF = DEBUG_FLAG(14, "gcProfiling", false, Util.gettext("Prints garbage collection stats to standard output."))::DebugFlag
         CHECK_DAE_CREF_TYPE = DEBUG_FLAG(15, "checkDAECrefType", false, Util.gettext("Enables extra type checking for cref expressions."))::DebugFlag
         CHECK_ASUB = DEBUG_FLAG(16, "checkASUB", false, Util.gettext("Prints out a warning if an ASUB is created from a CREF expression."))::DebugFlag
         INSTANCE = DEBUG_FLAG(17, "instance", false, Util.gettext("Prints extra failtrace from InstanceHierarchy."))::DebugFlag
         CACHE = DEBUG_FLAG(18, "Cache", true, Util.gettext("Turns off the instantiation cache."))::DebugFlag
         RML = DEBUG_FLAG(19, "rml", false, Util.gettext("Converts Modelica-style arrays to lists."))::DebugFlag
         TAIL = DEBUG_FLAG(20, "tail", false, Util.gettext("Prints out a notification if tail recursion optimization has been applied."))::DebugFlag
         LOOKUP = DEBUG_FLAG(21, "lookup", false, Util.gettext("Print extra failtrace from lookup."))::DebugFlag
         PATTERNM_SKIP_FILTER_UNUSED_AS_BINDINGS = DEBUG_FLAG(22, "patternmSkipFilterUnusedBindings", false, Util.notrans(""))::DebugFlag
         PATTERNM_ALL_INFO = DEBUG_FLAG(23, "patternmAllInfo", false, Util.gettext("Adds notifications of all pattern-matching optimizations that are performed."))::DebugFlag
         PATTERNM_DCE = DEBUG_FLAG(24, "patternmDeadCodeElimination", true, Util.gettext("Performs dead code elimination in match-expressions."))::DebugFlag
         PATTERNM_MOVE_LAST_EXP = DEBUG_FLAG(25, "patternmMoveLastExp", true, Util.gettext("Optimization that moves the last assignment(s) into the result of a match-expression. For example: equation c = fn(b); then c; => then fn(b);"))::DebugFlag
         EXPERIMENTAL_REDUCTIONS = DEBUG_FLAG(26, "experimentalReductions", false, Util.gettext("Turns on custom reduction functions (OpenModelica extension)."))::DebugFlag
         EVAL_PARAM = DEBUG_FLAG(27, "evaluateAllParameters", false, Util.gettext("Evaluates all parameters if set."))::DebugFlag
         TYPES = DEBUG_FLAG(28, "types", false, Util.gettext("Prints extra failtrace from Types."))::DebugFlag
         SHOW_STATEMENT = DEBUG_FLAG(29, "showStatement", false, Util.gettext("Shows the statement that is currently being evaluated when evaluating a script."))::DebugFlag
         DUMP = DEBUG_FLAG(30, "dump", false, Util.gettext("Dumps the absyn representation of a program."))::DebugFlag
         DUMP_GRAPHVIZ = DEBUG_FLAG(31, "graphviz", false, Util.gettext("Dumps the absyn representation of a program in graphviz format."))::DebugFlag
         EXEC_STAT = DEBUG_FLAG(32, "execstat", false, Util.gettext("Prints out execution statistics for the compiler."))::DebugFlag
         TRANSFORMS_BEFORE_DUMP = DEBUG_FLAG(33, "transformsbeforedump", false, Util.gettext("Applies transformations required for code generation before dumping flat code."))::DebugFlag
         DAE_DUMP_GRAPHV = DEBUG_FLAG(34, "daedumpgraphv", false, Util.gettext("Dumps the DAE in graphviz format."))::DebugFlag
         INTERACTIVE_TCP = DEBUG_FLAG(35, "interactive", false, Util.gettext("Starts omc as a server listening on the socket interface."))::DebugFlag
         INTERACTIVE_CORBA = DEBUG_FLAG(36, "interactiveCorba", false, Util.gettext("Starts omc as a server listening on the Corba interface."))::DebugFlag
         INTERACTIVE_DUMP = DEBUG_FLAG(37, "interactivedump", false, Util.gettext("Prints out debug information for the interactive server."))::DebugFlag
         RELIDX = DEBUG_FLAG(38, "relidx", false, Util.notrans("Prints out debug information about relations, that are used as zero crossings."))::DebugFlag
         DUMP_REPL = DEBUG_FLAG(39, "dumprepl", false, Util.gettext("Dump the found replacements for simple equation removal."))::DebugFlag
         DUMP_FP_REPL = DEBUG_FLAG(40, "dumpFPrepl", false, Util.gettext("Dump the found replacements for final parameters."))::DebugFlag
         DUMP_PARAM_REPL = DEBUG_FLAG(41, "dumpParamrepl", false, Util.gettext("Dump the found replacements for remove parameters."))::DebugFlag
         DUMP_PP_REPL = DEBUG_FLAG(42, "dumpPPrepl", false, Util.gettext("Dump the found replacements for protected parameters."))::DebugFlag
         DUMP_EA_REPL = DEBUG_FLAG(43, "dumpEArepl", false, Util.gettext("Dump the found replacements for evaluate annotations (evaluate=true) parameters."))::DebugFlag
         DEBUG_ALIAS = DEBUG_FLAG(44, "debugAlias", false, Util.gettext("Dumps some information about the process of removeSimpleEquations."))::DebugFlag
         TEARING_DUMP = DEBUG_FLAG(45, "tearingdump", false, Util.gettext("Dumps tearing information."))::DebugFlag
         JAC_DUMP = DEBUG_FLAG(46, "symjacdump", false, Util.gettext("Dumps information about symbolic Jacobians. Can be used only with postOptModules: generateSymbolicJacobian, generateSymbolicLinearization."))::DebugFlag
         JAC_DUMP2 = DEBUG_FLAG(47, "symjacdumpverbose", false, Util.gettext("Dumps information in verbose mode about symbolic Jacobians. Can be used only with postOptModules: generateSymbolicJacobian, generateSymbolicLinearization."))::DebugFlag
         JAC_DUMP_EQN = DEBUG_FLAG(48, "symjacdumpeqn", false, Util.gettext("Dump for debug purpose of symbolic Jacobians. (deactivated now)."))::DebugFlag
         JAC_WARNINGS = DEBUG_FLAG(49, "symjacwarnings", false, Util.gettext("Prints warnings regarding symoblic jacbians."))::DebugFlag
         DUMP_SPARSE = DEBUG_FLAG(50, "dumpSparsePattern", false, Util.gettext("Dumps sparse pattern with coloring used for simulation."))::DebugFlag
         DUMP_SPARSE_VERBOSE = DEBUG_FLAG(51, "dumpSparsePatternVerbose", false, Util.gettext("Dumps in verbose mode sparse pattern with coloring used for simulation."))::DebugFlag
         BLT_DUMP = DEBUG_FLAG(52, "bltdump", false, Util.gettext("Dumps information from index reduction."))::DebugFlag
         DUMMY_SELECT = DEBUG_FLAG(53, "dummyselect", false, Util.gettext("Dumps information from dummy state selection heuristic."))::DebugFlag
         DUMP_DAE_LOW = DEBUG_FLAG(54, "dumpdaelow", false, Util.gettext("Dumps the equation system at the beginning of the back end."))::DebugFlag
         DUMP_INDX_DAE = DEBUG_FLAG(55, "dumpindxdae", false, Util.gettext("Dumps the equation system after index reduction and optimization."))::DebugFlag
         OPT_DAE_DUMP = DEBUG_FLAG(56, "optdaedump", false, Util.gettext("Dumps information from the optimization modules."))::DebugFlag
         EXEC_HASH = DEBUG_FLAG(57, "execHash", false, Util.gettext("Measures the time it takes to hash all simcode variables before code generation."))::DebugFlag
         PARAM_DLOW_DUMP = DEBUG_FLAG(58, "paramdlowdump", false, Util.gettext("Enables dumping of the parameters in the order they are calculated."))::DebugFlag
         DUMP_ENCAPSULATECONDITIONS = DEBUG_FLAG(59, "dumpEncapsulateConditions", false, Util.gettext("Dumps the results of the preOptModule encapsulateWhenConditions."))::DebugFlag
         ON_RELAXATION = DEBUG_FLAG(60, "onRelaxation", false, Util.gettext("Perform O(n) relaxation.\\nDeprecated flag: Use --postOptModules+=relaxSystem instead."))::DebugFlag
         SHORT_OUTPUT = DEBUG_FLAG(61, "shortOutput", false, Util.gettext("Enables short output of the simulate() command. Useful for tools like OMNotebook."))::DebugFlag
         COUNT_OPERATIONS = DEBUG_FLAG(62, "countOperations", false, Util.gettext("Count operations."))::DebugFlag
         CGRAPH = DEBUG_FLAG(63, "cgraph", false, Util.gettext("Prints out connection graph information."))::DebugFlag
         UPDMOD = DEBUG_FLAG(64, "updmod", false, Util.gettext("Prints information about modification updates."))::DebugFlag
         STATIC = DEBUG_FLAG(65, "static", false, Util.gettext("Enables extra debug output from the static elaboration."))::DebugFlag
         TPL_PERF_TIMES = DEBUG_FLAG(66, "tplPerfTimes", false, Util.gettext("Enables output of template performance data for rendering text to file."))::DebugFlag
         CHECK_SIMPLIFY = DEBUG_FLAG(67, "checkSimplify", false, Util.gettext("Enables checks for expression simplification and prints a notification whenever an undesirable transformation has been performed."))::DebugFlag
         SCODE_INST = DEBUG_FLAG(68, "newInst", false, Util.gettext("Enables experimental new instantiation phase."))::DebugFlag
         WRITE_TO_BUFFER = DEBUG_FLAG(69, "writeToBuffer", false, Util.gettext("Enables writing simulation results to buffer."))::DebugFlag
         DUMP_BACKENDDAE_INFO = DEBUG_FLAG(70, "backenddaeinfo", false, Util.gettext("Enables dumping of back-end information about system (Number of equations before back-end,...)."))::DebugFlag
         GEN_DEBUG_SYMBOLS = DEBUG_FLAG(71, "gendebugsymbols", false, Util.gettext("Generate code with debugging symbols."))::DebugFlag
         DUMP_STATESELECTION_INFO = DEBUG_FLAG(72, "stateselection", false, Util.gettext("Enables dumping of selected states. Extends -d=backenddaeinfo."))::DebugFlag
         DUMP_EQNINORDER = DEBUG_FLAG(73, "dumpeqninorder", false, Util.gettext("Enables dumping of the equations in the order they are calculated."))::DebugFlag
         SEMILINEAR = DEBUG_FLAG(74, "semiLinear", false, Util.gettext("Enables dumping of the optimization information when optimizing calls to semiLinear."))::DebugFlag
         UNCERTAINTIES = DEBUG_FLAG(75, "uncertainties", false, Util.gettext("Enables dumping of status when calling modelEquationsUC."))::DebugFlag
         SHOW_START_ORIGIN = DEBUG_FLAG(76, "showStartOrigin", false, Util.gettext("Enables dumping of the DAE startOrigin attribute of the variables."))::DebugFlag
         DUMP_SIMCODE = DEBUG_FLAG(77, "dumpSimCode", false, Util.gettext("Dumps the simCode model used for code generation."))::DebugFlag
         DUMP_INITIAL_SYSTEM = DEBUG_FLAG(78, "dumpinitialsystem", false, Util.gettext("Dumps the initial equation system."))::DebugFlag
         GRAPH_INST = DEBUG_FLAG(79, "graphInst", false, Util.gettext("Do graph based instantiation."))::DebugFlag
         GRAPH_INST_RUN_DEP = DEBUG_FLAG(80, "graphInstRunDep", false, Util.gettext("Run scode dependency analysis. Use with -d=graphInst"))::DebugFlag
         GRAPH_INST_GEN_GRAPH = DEBUG_FLAG(81, "graphInstGenGraph", false, Util.gettext("Dumps a graph of the program. Use with -d=graphInst"))::DebugFlag
         GRAPH_INST_SHOW_GRAPH = DEBUG_FLAG(82, "graphInstShowGraph", false, Util.gettext("Display a graph of the program interactively. Use with -d=graphInst"))::DebugFlag
         DUMP_CONST_REPL = DEBUG_FLAG(83, "dumpConstrepl", false, Util.gettext("Dump the found replacements for constants."))::DebugFlag
         SHOW_EQUATION_SOURCE = DEBUG_FLAG(84, "showEquationSource", false, Util.gettext("Display the element source information in the dumped DAE for easier debugging."))::DebugFlag
         LS_ANALYTIC_JACOBIAN = DEBUG_FLAG(85, "LSanalyticJacobian", false, Util.gettext("Enables analytical jacobian for linear strong components. Defaults to false"))::DebugFlag
         NLS_ANALYTIC_JACOBIAN = DEBUG_FLAG(86, "NLSanalyticJacobian", true, Util.gettext("Enables analytical jacobian for non-linear strong components without user-defined function calls, for that see forceNLSanalyticJacobian"))::DebugFlag
         INLINE_SOLVER = DEBUG_FLAG(87, "inlineSolver", false, Util.gettext("Generates code for inline solver."))::DebugFlag
         HPCOM = DEBUG_FLAG(88, "hpcom", false, Util.gettext("Enables parallel calculation based on task-graphs."))::DebugFlag
         INITIALIZATION = DEBUG_FLAG(89, "initialization", false, Util.gettext("Shows additional information from the initialization process."))::DebugFlag
         INLINE_FUNCTIONS = DEBUG_FLAG(90, "inlineFunctions", true, Util.gettext("Controls if function inlining should be performed."))::DebugFlag
         DUMP_SCC_GRAPHML = DEBUG_FLAG(91, "dumpSCCGraphML", false, Util.gettext("Dumps graphml files with the strongly connected components."))::DebugFlag
         TEARING_DUMPVERBOSE = DEBUG_FLAG(92, "tearingdumpV", false, Util.gettext("Dumps verbose tearing information."))::DebugFlag
         DISABLE_SINGLE_FLOW_EQ = DEBUG_FLAG(93, "disableSingleFlowEq", false, Util.gettext("Disables the generation of single flow equations."))::DebugFlag
         DUMP_DISCRETEVARS_INFO = DEBUG_FLAG(94, "discreteinfo", false, Util.gettext("Enables dumping of discrete variables. Extends -d=backenddaeinfo."))::DebugFlag
         ADDITIONAL_GRAPHVIZ_DUMP = DEBUG_FLAG(95, "graphvizDump", false, Util.gettext("Activates additional graphviz dumps (as .dot files). It can be used in addition to one of the following flags: {dumpdaelow|dumpinitialsystems|dumpindxdae}."))::DebugFlag
         INFO_XML_OPERATIONS = DEBUG_FLAG(96, "infoXmlOperations", false, Util.gettext("Enables output of the operations in the _info.xml file when translating models."))::DebugFlag
         HPCOM_DUMP = DEBUG_FLAG(97, "hpcomDump", false, Util.gettext("Dumps additional information on the parallel execution with hpcom."))::DebugFlag
         RESOLVE_LOOPS_DUMP = DEBUG_FLAG(98, "resolveLoopsDump", false, Util.gettext("Debug Output for ResolveLoops Module."))::DebugFlag
         DISABLE_WINDOWS_PATH_CHECK_WARNING = DEBUG_FLAG(99, "disableWindowsPathCheckWarning", false, Util.gettext("Disables warnings on Windows if OPENMODELICAHOME/MinGW is missing."))::DebugFlag
         DISABLE_RECORD_CONSTRUCTOR_OUTPUT = DEBUG_FLAG(100, "disableRecordConstructorOutput", false, Util.gettext("Disables output of record constructors in the flat code."))::DebugFlag
         DUMP_TRANSFORMED_MODELICA_MODEL = DEBUG_FLAG(101, "dumpTransformedModelica", false, Util.gettext("Dumps the back-end DAE to a Modelica-like model after all symbolic transformations are applied."))::DebugFlag
         EVALUATE_CONST_FUNCTIONS = DEBUG_FLAG(102, "evalConstFuncs", true, Util.gettext("Evaluates functions complete and partially and checks for constant output.\\nDeprecated flag: Use --preOptModules+=evalFunc instead."))::DebugFlag
         IMPL_ODE = DEBUG_FLAG(103, "implOde", false, Util.gettext("activates implicit codegen"))::DebugFlag
         EVAL_FUNC_DUMP = DEBUG_FLAG(104, "evalFuncDump", false, Util.gettext("dumps debug information about the function evaluation"))::DebugFlag
         PRINT_STRUCTURAL = DEBUG_FLAG(105, "printStructuralParameters", false, Util.gettext("Prints the structural parameters identified by the front-end"))::DebugFlag
         ITERATION_VARS = DEBUG_FLAG(106, "iterationVars", false, Util.gettext("Shows a list of all iteration variables."))::DebugFlag
         ALLOW_RECORD_TOO_MANY_FIELDS = DEBUG_FLAG(107, "acceptTooManyFields", false, Util.gettext("Accepts passing records with more fields than expected to a function. This is not allowed, but is used in Fluid.Dissipation. See https://trac.modelica.org/Modelica/ticket/1245 for details."))::DebugFlag
         HPCOM_MEMORY_OPT = DEBUG_FLAG(108, "hpcomMemoryOpt", false, Util.gettext("Optimize the memory structure regarding the selected scheduler"))::DebugFlag
         DUMP_SYNCHRONOUS = DEBUG_FLAG(109, "dumpSynchronous", false, Util.gettext("Dumps information of the clock partitioning."))::DebugFlag
         STRIP_PREFIX = DEBUG_FLAG(110, "stripPrefix", true, Util.gettext("Strips the environment prefix from path/crefs. Defaults to true."))::DebugFlag
         DO_SCODE_DEP = DEBUG_FLAG(111, "scodeDep", true, Util.gettext("Does scode dependency analysis prior to instantiation. Defaults to true."))::DebugFlag
         SHOW_INST_CACHE_INFO = DEBUG_FLAG(112, "showInstCacheInfo", false, Util.gettext("Prints information about instantiation cache hits and additions. Defaults to false."))::DebugFlag
         DUMP_UNIT = DEBUG_FLAG(113, "dumpUnits", false, Util.gettext("Dumps all the calculated units."))::DebugFlag
         DUMP_EQ_UNIT = DEBUG_FLAG(114, "dumpEqInUC", false, Util.gettext("Dumps all equations handled by the unit checker."))::DebugFlag
         DUMP_EQ_UNIT_STRUCT = DEBUG_FLAG(115, "dumpEqUCStruct", false, Util.gettext("Dumps all the equations handled by the unit checker as tree-structure."))::DebugFlag
         SHOW_DAE_GENERATION = DEBUG_FLAG(116, "showDaeGeneration", false, Util.gettext("Show the dae variable declarations as they happen."))::DebugFlag
         RESHUFFLE_POST = DEBUG_FLAG(117, "reshufflePost", false, Util.gettext("Reshuffles the systems of equations."))::DebugFlag
         SHOW_EXPANDABLE_INFO = DEBUG_FLAG(118, "showExpandableInfo", false, Util.gettext("Show information about expandable connector handling."))::DebugFlag
         DUMP_HOMOTOPY = DEBUG_FLAG(119, "dumpHomotopy", false, Util.gettext("Dumps the results of the postOptModule optimizeHomotopyCalls."))::DebugFlag
         OMC_RELOCATABLE_FUNCTIONS = DEBUG_FLAG(120, "relocatableFunctions", false, Util.gettext("Generates relocatable code: all functions become function pointers and can be replaced at run-time."))::DebugFlag
         GRAPHML = DEBUG_FLAG(121, "graphml", false, Util.gettext("Dumps .graphml files for the bipartite graph after Index Reduction and a task graph for the SCCs. Can be displayed with yEd. "))::DebugFlag
         USEMPI = DEBUG_FLAG(122, "useMPI", false, Util.gettext("Add MPI init and finalize to main method (CPPruntime). "))::DebugFlag
         DUMP_CSE = DEBUG_FLAG(123, "dumpCSE", false, Util.gettext("Additional output for CSE module."))::DebugFlag
         DUMP_CSE_VERBOSE = DEBUG_FLAG(124, "dumpCSE_verbose", false, Util.gettext("Additional output for CSE module."))::DebugFlag
         ADD_DER_ALIASES = DEBUG_FLAG(125, "addDerAliases", false, Util.gettext("Adds for every der-call an alias equation e.g. dx = der(x). It's a work-a-round flag,\n                which helps in some cases to simulate the models e.g.\n                Modelica.Fluid.Examples.HeatExchanger.HeatExchangerSimulation.\n                Deprecated flag: Use --preOptModules+=introduceDerAlias instead."))::DebugFlag
         DISABLE_COMSUBEXP = DEBUG_FLAG(126, "disableComSubExp", false, Util.gettext("Deactivates module 'comSubExp'\\nDeprecated flag: Use --preOptModules-=comSubExp instead."))::DebugFlag
         NO_START_CALC = DEBUG_FLAG(127, "disableStartCalc", false, Util.gettext("Deactivates the pre-calculation of start values during compile-time."))::DebugFlag
         NO_PARTITIONING = DEBUG_FLAG(128, "disablePartitioning", false, Util.gettext("Deactivates partitioning of entire equation system.\\nDeprecated flag: Use --preOptModules-=clockPartitioning instead."))::DebugFlag
         CONSTJAC = DEBUG_FLAG(129, "constjac", false, Util.gettext("solves linear systems with constant Jacobian and variable b-Vector symbolically"))::DebugFlag
         REDUCE_DYN_OPT = DEBUG_FLAG(130, "reduceDynOpt", false, Util.gettext("remove eqs which not need for the calculations of cost and constraints\\nDeprecated flag: Use --postOptModules+=reduceDynamicOptimization instead."))::DebugFlag
         VISUAL_XML = DEBUG_FLAG(131, "visxml", false, Util.gettext("Outputs a xml-file that contains information for visualization."))::DebugFlag
         ADD_SCALED_VARS = DEBUG_FLAG(132, "addScaledVars", false, Util.gettext("Adds an alias equation var_nrom = var/nominal where var is state\\nDeprecated flag: Use --postOptModules+=addScaledVars_states instead."))::DebugFlag
         ADD_SCALED_VARS_INPUT = DEBUG_FLAG(133, "addScaledVarsInput", false, Util.gettext("Adds an alias equation var_nrom = var/nominal where var is input\\nDeprecated flag: Use --postOptModules+=addScaledVars_inputs instead."))::DebugFlag
         VECTORIZE = DEBUG_FLAG(134, "vectorize", false, Util.gettext("Activates vectorization in the backend."))::DebugFlag
         CHECK_EXT_LIBS = DEBUG_FLAG(135, "buildExternalLibs", true, Util.gettext("Use the autotools project in the Resources folder of the library to build missing external libraries."))::DebugFlag
         RUNTIME_STATIC_LINKING = DEBUG_FLAG(136, "runtimeStaticLinking", false, Util.gettext("Use the static simulation runtime libraries (C++ simulation runtime)."))::DebugFlag
         SORT_EQNS_AND_VARS = DEBUG_FLAG(137, "dumpSortEqnsAndVars", false, Util.gettext("Dumps debug output for the modules sortEqnsVars."))::DebugFlag
         DUMP_SIMPLIFY_LOOPS = DEBUG_FLAG(138, "dumpSimplifyLoops", false, Util.gettext("Dump between steps of simplifyLoops"))::DebugFlag
         DUMP_RTEARING = DEBUG_FLAG(139, "dumpRecursiveTearing", false, Util.gettext("Dump between steps of recursiveTearing"))::DebugFlag
         DIS_SIMP_FUN = DEBUG_FLAG(140, "disableSimplifyComplexFunction", false, Util.gettext("disable simplifyComplexFunction\\nDeprecated flag: Use --postOptModules-=simplifyComplexFunction/--initOptModules-=simplifyComplexFunction instead."))::DebugFlag
         DIS_SYMJAC_FMI20 = DEBUG_FLAG(141, "disableDirectionalDerivatives", true, Util.gettext("For FMI 2.0 only dependecy analysis will be perform."))::DebugFlag
         EVAL_OUTPUT_ONLY = DEBUG_FLAG(142, "evalOutputOnly", false, Util.gettext("Generates equations to calculate outputs only."))::DebugFlag
         HARDCODED_START_VALUES = DEBUG_FLAG(143, "hardcodedStartValues", false, Util.gettext("Embed the start values of variables and parameters into the c++ code and do not read it from xml file."))::DebugFlag
         DUMP_FUNCTIONS = DEBUG_FLAG(144, "dumpFunctions", false, Util.gettext("Add functions to backend dumps."))::DebugFlag
         DEBUG_DIFFERENTIATION = DEBUG_FLAG(145, "debugDifferentiation", false, Util.gettext("Dumps debug output for the differentiation process."))::DebugFlag
         DEBUG_DIFFERENTIATION_VERBOSE = DEBUG_FLAG(146, "debugDifferentiationVerbose", false, Util.gettext("Dumps verbose debug output for the differentiation process."))::DebugFlag
         FMU_EXPERIMENTAL = DEBUG_FLAG(147, "fmuExperimental", false, Util.gettext("Include an extra function in the FMU fmi2GetSpecificDerivatives."))::DebugFlag
         DUMP_DGESV = DEBUG_FLAG(148, "dumpdgesv", false, Util.gettext("Enables dumping of the information whether DGESV is used to solve linear systems."))::DebugFlag
         MULTIRATE_PARTITION = DEBUG_FLAG(149, "multirate", false, Util.gettext("The solver can switch partitions in the system."))::DebugFlag
         DUMP_EXCLUDED_EXP = DEBUG_FLAG(150, "dumpExcludedSymJacExps", false, Util.gettext("This flags dumps all expression that are excluded from differentiation of a symbolic Jacobian."))::DebugFlag
         DEBUG_ALGLOOP_JACOBIAN = DEBUG_FLAG(151, "debugAlgebraicLoopsJacobian", false, Util.gettext("Dumps debug output while creating symbolic jacobians for non-linear systems."))::DebugFlag
         DISABLE_JACSCC = DEBUG_FLAG(152, "disableJacsforSCC", false, Util.gettext("Disables calculation of jacobians to detect if a SCC is linear or non-linear. By disabling all SCC will handled like non-linear."))::DebugFlag
         FORCE_NLS_ANALYTIC_JACOBIAN = DEBUG_FLAG(153, "forceNLSanalyticJacobian", false, Util.gettext("Forces calculation analytical jacobian also for non-linear strong components with user-defined functions."))::DebugFlag
         DUMP_LOOPS = DEBUG_FLAG(154, "dumpLoops", false, Util.gettext("Dumps loop equation."))::DebugFlag
         SKIP_INPUT_OUTPUT_SYNTACTIC_SUGAR = DEBUG_FLAG(155, "skipInputOutputSyntacticSugar", false, Util.gettext("Used when bootstrapping to preserve the input output parsing of the code output by the list command."))::DebugFlag
         OMC_RECORD_ALLOC_WORDS = DEBUG_FLAG(156, "metaModelicaRecordAllocWords", false, Util.gettext("Instrument the source code to record memory allocations (requires run-time and generated files compiled with -DOMC_RECORD_ALLOC_WORDS)."))::DebugFlag
         TOTAL_TEARING_DUMP = DEBUG_FLAG(157, "totaltearingdump", false, Util.gettext("Dumps total tearing information."))::DebugFlag
         TOTAL_TEARING_DUMPVERBOSE = DEBUG_FLAG(158, "totaltearingdumpV", false, Util.gettext("Dumps verbose total tearing information."))::DebugFlag
         PARALLEL_CODEGEN = DEBUG_FLAG(159, "parallelCodegen", true, Util.gettext("Enables code generation in parallel (disable this if compiling a model causes you to run out of RAM)."))::DebugFlag
         SERIALIZED_SIZE = DEBUG_FLAG(160, "reportSerializedSize", false, Util.gettext("Reports serialized sizes of various data structures used in the compiler."))::DebugFlag
         BACKEND_KEEP_ENV_GRAPH = DEBUG_FLAG(161, "backendKeepEnv", true, Util.gettext("When enabled, the environment is kept when entering the backend, which enables CevalFunction (function interpretation) to work. This module not essential for the backend to function in most cases, but can improve simulation performance by evaluating functions. The drawback to keeping the environment graph in memory is that it is huge (~80% of the total memory in use when returning the frontend DAE)."))::DebugFlag
         DUMPBACKENDINLINE = DEBUG_FLAG(162, "dumpBackendInline", false, Util.gettext("Dumps debug output while inline function."))::DebugFlag
         DUMPBACKENDINLINE_VERBOSE = DEBUG_FLAG(163, "dumpBackendInlineVerbose", false, Util.gettext("Dumps debug output while inline function."))::DebugFlag
         BLT_MATRIX_DUMP = DEBUG_FLAG(164, "bltmatrixdump", false, Util.gettext("Dumps the blt matrix in html file. IE seems to be very good in displaying large matrices."))::DebugFlag
         LIST_REVERSE_WRONG_ORDER = DEBUG_FLAG(165, "listAppendWrongOrder", true, Util.gettext("Print notifications about bad usage of listAppend."))::DebugFlag
         PARTITION_INITIALIZATION = DEBUG_FLAG(166, "partitionInitialization", true, Util.gettext("This flag controls if partitioning is applied to the initialization system."))::DebugFlag
         EVAL_PARAM_DUMP = DEBUG_FLAG(167, "evalParameterDump", false, Util.gettext("Dumps information for evaluating parameters."))::DebugFlag
         NF_UNITCHECK = DEBUG_FLAG(168, "frontEndUnitCheck", false, Util.gettext("Checks the consistency of units in equation."))::DebugFlag
         DISABLE_COLORING = DEBUG_FLAG(169, "disableColoring", false, Util.gettext("Disables coloring algorithm while spasity detection."))::DebugFlag
         MERGE_ALGORITHM_SECTIONS = DEBUG_FLAG(170, "mergeAlgSections", false, Util.gettext("Disables coloring algorithm while sparsity detection."))::DebugFlag
         WARN_NO_NOMINAL = DEBUG_FLAG(171, "warnNoNominal", false, Util.gettext("Prints the iteration variables in the initialization and simulation DAE, which do not have a nominal value."))::DebugFlag
         REDUCE_DAE = DEBUG_FLAG(172, "backendReduceDAE", false, Util.gettext("Prints all Reduce DAE debug information."))::DebugFlag
         IGNORE_CYCLES = DEBUG_FLAG(173, "ignoreCycles", false, Util.gettext("Ignores cycles between constant/parameter components."))::DebugFlag
         ALIAS_CONFLICTS = DEBUG_FLAG(174, "aliasConflicts", false, Util.gettext("Dumps alias sets with different start or nominal values."))::DebugFlag
         SUSAN_MATCHCONTINUE_DEBUG = DEBUG_FLAG(175, "susanDebug", false, Util.gettext("Makes Susan generate code using try/else to better debug which function broke the expected match semantics."))::DebugFlag
         OLD_FE_UNITCHECK = DEBUG_FLAG(176, "oldFrontEndUnitCheck", false, Util.gettext("Checks the consistency of units in equation (for the old front-end)."))::DebugFlag
         EXEC_STAT_EXTRA_GC = DEBUG_FLAG(177, "execstatGCcollect", false, Util.gettext("When running execstat, also perform an extra full garbage collection."))::DebugFlag
         DEBUG_DAEMODE = DEBUG_FLAG(178, "debugDAEmode", false, Util.gettext("Dump debug output for the DAEmode."))::DebugFlag
         NF_SCALARIZE = DEBUG_FLAG(179, "nfScalarize", true, Util.gettext("Run scalarization in NF, default true."))::DebugFlag
         NF_EVAL_CONST_ARG_FUNCS = DEBUG_FLAG(180, "nfEvalConstArgFuncs", true, Util.gettext("Evaluate all functions with constant arguments in the new frontend."))::DebugFlag
         NF_EXPAND_OPERATIONS = DEBUG_FLAG(181, "nfExpandOperations", true, Util.gettext("Expand all unary/binary operations to scalar expressions in the new frontend."))::DebugFlag
         NF_API = DEBUG_FLAG(182, "nfAPI", false, Util.gettext("Enables experimental new instantiation use in the OMC API."))::DebugFlag
         NF_API_DYNAMIC_SELECT = DEBUG_FLAG(183, "nfAPIDynamicSelect", false, Util.gettext("Show DynamicSelect(static, dynamic) in annotations. Default to false and will select the first (static) expression"))::DebugFlag
         NF_API_NOISE = DEBUG_FLAG(184, "nfAPINoise", false, Util.gettext("Enables error display for the experimental new instantiation use in the OMC API."))::DebugFlag
         FMI20_DEPENDENCIES = DEBUG_FLAG(185, "disableFMIDependency", false, Util.gettext("Disables the dependency analysis and generation for FMI 2.0."))::DebugFlag
         WARNING_MINMAX_ATTRIBUTES = DEBUG_FLAG(186, "warnMinMax", true, Util.gettext("Makes a warning assert from min/max variable attributes instead of error."))::DebugFlag
         NF_EXPAND_FUNC_ARGS = DEBUG_FLAG(187, "nfExpandFuncArgs", false, Util.gettext("Expand all function arguments in the new frontend."))::DebugFlag
         DUMP_JL = DEBUG_FLAG(188, "dumpJL", false, Util.gettext("Dumps the absyn representation of a program as a Julia representation"))::DebugFlag
         #=  This is a list of all debug flags, to keep track of which flags are used. A
         =#
         #=  flag can not be used unless it's in this list, and the list is checked at
         =#
         #=  initialization so that all flags are sorted by index (and thus have unique
         =#
         #=  indices).
         =#

         allDebugFlags = list(FAILTRACE, CEVAL, CHECK_BACKEND_DAE, PARMODAUTO, PTHREADS, EVENTS, DUMP_INLINE_SOLVER, EVAL_FUNC, GEN, DYN_LOAD, GENERATE_CODE_CHEAT, CGRAPH_GRAPHVIZ_FILE, CGRAPH_GRAPHVIZ_SHOW, GC_PROF, CHECK_DAE_CREF_TYPE, CHECK_ASUB, INSTANCE, CACHE, RML, TAIL, LOOKUP, PATTERNM_SKIP_FILTER_UNUSED_AS_BINDINGS, PATTERNM_ALL_INFO, PATTERNM_DCE, PATTERNM_MOVE_LAST_EXP, EXPERIMENTAL_REDUCTIONS, EVAL_PARAM, TYPES, SHOW_STATEMENT, DUMP, DUMP_GRAPHVIZ, EXEC_STAT, TRANSFORMS_BEFORE_DUMP, DAE_DUMP_GRAPHV, INTERACTIVE_TCP, INTERACTIVE_CORBA, INTERACTIVE_DUMP, RELIDX, DUMP_REPL, DUMP_FP_REPL, DUMP_PARAM_REPL, DUMP_PP_REPL, DUMP_EA_REPL, DEBUG_ALIAS, TEARING_DUMP, JAC_DUMP, JAC_DUMP2, JAC_DUMP_EQN, JAC_WARNINGS, DUMP_SPARSE, DUMP_SPARSE_VERBOSE, BLT_DUMP, DUMMY_SELECT, DUMP_DAE_LOW, DUMP_INDX_DAE, OPT_DAE_DUMP, EXEC_HASH, PARAM_DLOW_DUMP, DUMP_ENCAPSULATECONDITIONS, ON_RELAXATION, SHORT_OUTPUT, COUNT_OPERATIONS, CGRAPH, UPDMOD, STATIC, TPL_PERF_TIMES, CHECK_SIMPLIFY, SCODE_INST, WRITE_TO_BUFFER, DUMP_BACKENDDAE_INFO, GEN_DEBUG_SYMBOLS, DUMP_STATESELECTION_INFO, DUMP_EQNINORDER, SEMILINEAR, UNCERTAINTIES, SHOW_START_ORIGIN, DUMP_SIMCODE, DUMP_INITIAL_SYSTEM, GRAPH_INST, GRAPH_INST_RUN_DEP, GRAPH_INST_GEN_GRAPH, GRAPH_INST_SHOW_GRAPH, DUMP_CONST_REPL, SHOW_EQUATION_SOURCE, LS_ANALYTIC_JACOBIAN, NLS_ANALYTIC_JACOBIAN, INLINE_SOLVER, HPCOM, INITIALIZATION, INLINE_FUNCTIONS, DUMP_SCC_GRAPHML, TEARING_DUMPVERBOSE, DISABLE_SINGLE_FLOW_EQ, DUMP_DISCRETEVARS_INFO, ADDITIONAL_GRAPHVIZ_DUMP, INFO_XML_OPERATIONS, HPCOM_DUMP, RESOLVE_LOOPS_DUMP, DISABLE_WINDOWS_PATH_CHECK_WARNING, DISABLE_RECORD_CONSTRUCTOR_OUTPUT, DUMP_TRANSFORMED_MODELICA_MODEL, EVALUATE_CONST_FUNCTIONS, IMPL_ODE, EVAL_FUNC_DUMP, PRINT_STRUCTURAL, ITERATION_VARS, ALLOW_RECORD_TOO_MANY_FIELDS, HPCOM_MEMORY_OPT, DUMP_SYNCHRONOUS, STRIP_PREFIX, DO_SCODE_DEP, SHOW_INST_CACHE_INFO, DUMP_UNIT, DUMP_EQ_UNIT, DUMP_EQ_UNIT_STRUCT, SHOW_DAE_GENERATION, RESHUFFLE_POST, SHOW_EXPANDABLE_INFO, DUMP_HOMOTOPY, OMC_RELOCATABLE_FUNCTIONS, GRAPHML, USEMPI, DUMP_CSE, DUMP_CSE_VERBOSE, ADD_DER_ALIASES, DISABLE_COMSUBEXP, NO_START_CALC, NO_PARTITIONING, CONSTJAC, REDUCE_DYN_OPT, VISUAL_XML, ADD_SCALED_VARS, ADD_SCALED_VARS_INPUT, VECTORIZE, CHECK_EXT_LIBS, RUNTIME_STATIC_LINKING, SORT_EQNS_AND_VARS, DUMP_SIMPLIFY_LOOPS, DUMP_RTEARING, DIS_SIMP_FUN, DIS_SYMJAC_FMI20, EVAL_OUTPUT_ONLY, HARDCODED_START_VALUES, DUMP_FUNCTIONS, DEBUG_DIFFERENTIATION, DEBUG_DIFFERENTIATION_VERBOSE, FMU_EXPERIMENTAL, DUMP_DGESV, MULTIRATE_PARTITION, DUMP_EXCLUDED_EXP, DEBUG_ALGLOOP_JACOBIAN, DISABLE_JACSCC, FORCE_NLS_ANALYTIC_JACOBIAN, DUMP_LOOPS, SKIP_INPUT_OUTPUT_SYNTACTIC_SUGAR, OMC_RECORD_ALLOC_WORDS, TOTAL_TEARING_DUMP, TOTAL_TEARING_DUMPVERBOSE, PARALLEL_CODEGEN, SERIALIZED_SIZE, BACKEND_KEEP_ENV_GRAPH, DUMPBACKENDINLINE, DUMPBACKENDINLINE_VERBOSE, BLT_MATRIX_DUMP, LIST_REVERSE_WRONG_ORDER, PARTITION_INITIALIZATION, EVAL_PARAM_DUMP, NF_UNITCHECK, DISABLE_COLORING, MERGE_ALGORITHM_SECTIONS, WARN_NO_NOMINAL, REDUCE_DAE, IGNORE_CYCLES, ALIAS_CONFLICTS, SUSAN_MATCHCONTINUE_DEBUG, OLD_FE_UNITCHECK, EXEC_STAT_EXTRA_GC, DEBUG_DAEMODE, NF_SCALARIZE, NF_EVAL_CONST_ARG_FUNCS, NF_EXPAND_OPERATIONS, NF_API, NF_API_DYNAMIC_SELECT, NF_API_NOISE, FMI20_DEPENDENCIES, WARNING_MINMAX_ATTRIBUTES, NF_EXPAND_FUNC_ARGS, DUMP_JL)::List{<:DebugFlag}

         #=  CONFIGURATION FLAGS
         =#
         DEBUG = CONFIG_FLAG(1, "debug", SOME("d"), EXTERNAL(), STRING_LIST_FLAG(list()), NONE(), Util.gettext("Sets debug flags. Use --help=debug to see available flags."))::ConfigFlag
         HELP = CONFIG_FLAG(2, "help", SOME("h"), EXTERNAL(), STRING_FLAG(""), NONE(), Util.gettext("Displays the help text. Use --help=topics for more information."))::ConfigFlag
         RUNNING_TESTSUITE = CONFIG_FLAG(3, "running-testsuite", NONE(), INTERNAL(), STRING_FLAG(""), NONE(), Util.gettext("Used when running the testsuite."))::ConfigFlag
         SHOW_VERSION = CONFIG_FLAG(4, "version", SOME("-v"), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Print the version and exit."))::ConfigFlag
         TARGET = CONFIG_FLAG(5, "target", NONE(), EXTERNAL(), STRING_FLAG("gcc"), SOME(STRING_OPTION(list("gcc", "msvc", "msvc10", "msvc12", "msvc13", "msvc15", "vxworks69", "debugrt"))), Util.gettext("Sets the target compiler to use."))::ConfigFlag
         GRAMMAR = CONFIG_FLAG(6, "grammar", SOME("g"), EXTERNAL(), ENUM_FLAG(MODELICA, list(("Modelica", MODELICA), ("MetaModelica", METAMODELICA), ("ParModelica", PARMODELICA), ("Optimica", OPTIMICA), ("PDEModelica", PDEMODELICA))), SOME(STRING_OPTION(list("Modelica", "MetaModelica", "ParModelica", "Optimica", "PDEModelica"))), Util.gettext("Sets the grammar and semantics to accept."))::ConfigFlag
         ANNOTATION_VERSION = CONFIG_FLAG(7, "annotationVersion", NONE(), EXTERNAL(), STRING_FLAG("3.x"), SOME(STRING_OPTION(list("1.x", "2.x", "3.x"))), Util.gettext("Sets the annotation version that should be used."))::ConfigFlag
         LANGUAGE_STANDARD = CONFIG_FLAG(8, "std", NONE(), EXTERNAL(), ENUM_FLAG(1000, list(("1.x", 10), ("2.x", 20), ("3.0", 30), ("3.1", 31), ("3.2", 32), ("3.3", 33), ("latest", 1000))), SOME(STRING_OPTION(list("1.x", "2.x", "3.1", "3.2", "3.3", "latest"))), Util.gettext("Sets the language standard that should be used."))::ConfigFlag
         SHOW_ERROR_MESSAGES = CONFIG_FLAG(9, "showErrorMessages", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Show error messages immediately when they happen."))::ConfigFlag
         SHOW_ANNOTATIONS = CONFIG_FLAG(10, "showAnnotations", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Show annotations in the flattened code."))::ConfigFlag
         NO_SIMPLIFY = CONFIG_FLAG(11, "noSimplify", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Do not simplify expressions if set."))::ConfigFlag
         removeSimpleEquationDesc = Util.gettext("Performs alias elimination and removes constant variables from the DAE, replacing all occurrences of the old variable reference with the new value (constants) or variable reference (alias elimination).")::Util.TranslatableContent

         PRE_OPT_MODULES = CONFIG_FLAG(12, "preOptModules", NONE(), EXTERNAL(), STRING_LIST_FLAG(list("normalInlineFunction", "evaluateParameters", "simplifyIfEquations", "expandDerOperator", "clockPartitioning", "findStateOrder", "replaceEdgeChange", "inlineArrayEqn", "removeEqualRHS", "removeSimpleEquations", "comSubExp", "resolveLoops", "evalFunc", "encapsulateWhenConditions")), SOME(STRING_DESC_OPTION(list(("introduceOutputAliases", Util.gettext("Introduces aliases for top-level outputs.")), ("clockPartitioning", Util.gettext("Does the clock partitioning.")), ("collapseArrayExpressions", collapseArrayExpressionsText), ("comSubExp", Util.gettext("Introduces alias assignments for variables which are assigned to simple terms i.e. a = b/c; d = b/c; --> a=d")), ("dumpDAE", Util.gettext("dumps the DAE representation of the current transformation state")), ("dumpDAEXML", Util.gettext("dumps the DAE as xml representation of the current transformation state")), ("encapsulateWhenConditions", Util.gettext("This module replaces each when condition with a boolean variable.")), ("evalFunc", Util.gettext("evaluates functions partially")), ("evaluateParameters", Util.gettext("Evaluates parameters with annotation(Evaluate=true). Use '--evaluateFinalParameters=true' or '--evaluateProtectedParameters=true' to specify additional parameters to be evaluated. Use '--replaceEvaluatedParameters=true' if the evaluated parameters should be replaced in the DAE. To evaluate all parameters in the Frontend use -d=evaluateAllParameters.")), ("expandDerOperator", Util.notrans("Expands der(expr) using Derive.differentiteExpTime.")), ("findStateOrder", Util.notrans("Sets derivative information to states.")), ("inlineArrayEqn", Util.gettext("This module expands all array equations to scalar equations.")), ("normalInlineFunction", Util.gettext("Perform function inlining for function with annotation Inline=true.")), ("inputDerivativesForDynOpt", Util.gettext("Allowed derivatives of inputs in dyn. optimization.")), ("introduceDerAlias", Util.notrans("Adds for every der-call an alias equation e.g. dx = der(x).")), ("removeEqualRHS", Util.notrans("Detects equal expressions of the form a=<exp> and b=<exp> and substitutes them to get speed up.")), ("removeProtectedParameters", Util.gettext("Replace all parameters with protected=true in the system.")), ("removeSimpleEquations", removeSimpleEquationDesc), ("removeUnusedParameter", Util.gettext("Strips all parameter not present in the equations from the system.")), ("removeUnusedVariables", Util.gettext("Strips all variables not present in the equations from the system.")), ("removeVerySimpleEquations", Util.gettext("[Experimental] Like removeSimpleEquations, but less thorough. Note that this always uses the experimental new alias elimination, --removeSimpleEquations=new, which makes it unstable. In particular, MultiBody systems fail to translate correctly. It can be used for simple (but large) systems of equations.")), ("replaceEdgeChange", Util.gettext("Replace edge(b) = b and not pre(b) and change(b) = v <> pre(v).")), ("residualForm", Util.gettext("Transforms simple equations x=y to zero-sum equations 0=y-x.")), ("resolveLoops", Util.gettext("resolves linear equations in loops")), ("simplifyAllExpressions", Util.notrans("Does simplifications on all expressions.")), ("simplifyIfEquations", Util.gettext("Tries to simplify if equations by use of information from evaluated parameters.")), ("sortEqnsVars", Util.notrans("Heuristic sorting for equations and variables.")), ("unitChecking", Util.gettext("Does advanced unit checking which consists of two parts: 1. calculation of unspecified unit information for variables; 2. consistency check for all equations based on unit information. Please note: This module is still experimental.")), ("wrapFunctionCalls", Util.gettext("This module introduces variables for each function call and substitutes all these calls with the newly introduced variables."))))), Util.gettext("Sets the pre optimization modules to use in the back end. See --help=optmodules for more info."))::ConfigFlag
         CHEAPMATCHING_ALGORITHM = CONFIG_FLAG(13, "cheapmatchingAlgorithm", NONE(), EXTERNAL(), INT_FLAG(3), SOME(STRING_DESC_OPTION(list(("0", Util.gettext("No cheap matching.")), ("1", Util.gettext("Cheap matching, traverses all equations and match the first free variable.")), ("3", Util.gettext("Random Karp-Sipser: R. M. Karp and M. Sipser. Maximum matching in sparse random graphs."))))), Util.gettext("Sets the cheap matching algorithm to use. A cheap matching algorithm gives a jump start matching by heuristics."))::ConfigFlag
         MATCHING_ALGORITHM = CONFIG_FLAG(14, "matchingAlgorithm", NONE(), EXTERNAL(), STRING_FLAG("PFPlusExt"), SOME(STRING_DESC_OPTION(list(("BFSB", Util.gettext("Breadth First Search based algorithm.")), ("DFSB", Util.gettext("Depth First Search based algorithm.")), ("MC21A", Util.gettext("Depth First Search based algorithm with look ahead feature.")), ("PF", Util.gettext("Depth First Search based algorithm with look ahead feature.")), ("PFPlus", Util.gettext("Depth First Search based algorithm with look ahead feature and fair row traversal.")), ("HK", Util.gettext("Combined BFS and DFS algorithm.")), ("HKDW", Util.gettext("Combined BFS and DFS algorithm.")), ("ABMP", Util.gettext("Combined BFS and DFS algorithm.")), ("PR", Util.gettext("Matching algorithm using push relabel mechanism.")), ("DFSBExt", Util.gettext("Depth First Search based Algorithm external c implementation.")), ("BFSBExt", Util.gettext("Breadth First Search based Algorithm external c implementation.")), ("MC21AExt", Util.gettext("Depth First Search based Algorithm with look ahead feature external c implementation.")), ("PFExt", Util.gettext("Depth First Search based Algorithm with look ahead feature external c implementation.")), ("PFPlusExt", Util.gettext("Depth First Search based Algorithm with look ahead feature and fair row traversal external c implementation.")), ("HKExt", Util.gettext("Combined BFS and DFS algorithm external c implementation.")), ("HKDWExt", Util.gettext("Combined BFS and DFS algorithm external c implementation.")), ("ABMPExt", Util.gettext("Combined BFS and DFS algorithm external c implementation.")), ("PRExt", Util.gettext("Matching algorithm using push relabel mechanism external c implementation.")), ("BB", Util.gettext("BBs try."))))), Util.gettext("Sets the matching algorithm to use. See --help=optmodules for more info."))::ConfigFlag
         INDEX_REDUCTION_METHOD = CONFIG_FLAG(15, "indexReductionMethod", NONE(), EXTERNAL(), STRING_FLAG("dynamicStateSelection"), SOME(STRING_DESC_OPTION(list(("none", Util.gettext("Skip index reduction")), ("uode", Util.gettext("Use the underlying ODE without the constraints.")), ("dynamicStateSelection", Util.gettext("Simple index reduction method, select (dynamic) dummy states based on analysis of the system.")), ("dummyDerivatives", Util.gettext("Simple index reduction method, select (static) dummy states based on heuristic."))))), Util.gettext("Sets the index reduction method to use. See --help=optmodules for more info."))::ConfigFlag
         POST_OPT_MODULES = CONFIG_FLAG(16, "postOptModules", NONE(), EXTERNAL(), STRING_LIST_FLAG(list("lateInlineFunction", "wrapFunctionCalls", "inlineArrayEqn", "constantLinearSystem", "simplifysemiLinear", "removeSimpleEquations", "simplifyComplexFunction", "solveSimpleEquations", "tearingSystem", "inputDerivativesUsed", "calculateStrongComponentJacobians", "calculateStateSetsJacobians", "symbolicJacobian", "removeConstants", "simplifyTimeIndepFuncCalls", "simplifyAllExpressions", "findZeroCrossings", "collapseArrayExpressions")), SOME(STRING_DESC_OPTION(list(("addScaledVars_states", Util.notrans("added var_norm = var/nominal, where var is state")), ("addScaledVars_inputs", Util.notrans("added var_norm = var/nominal, where var is input")), ("addTimeAsState", Util.gettext("Experimental feature: this replaces each occurrence of variable time with a new introduced state time with equation der(time) = 1.0")), ("calculateStateSetsJacobians", Util.gettext("Generates analytical jacobian for dynamic state selection sets.")), ("calculateStrongComponentJacobians", Util.gettext("Generates analytical jacobian for torn linear and non-linear strong components. By default linear components and non-linear components with user-defined function calls are skipped. See also debug flags: LSanalyticJacobian, NLSanalyticJacobian and forceNLSanalyticJacobian")), ("collapseArrayExpressions", collapseArrayExpressionsText), ("constantLinearSystem", Util.gettext("Evaluates constant linear systems (a*x+b*y=c; d*x+e*y=f; a,b,c,d,e,f are constants) at compile-time.")), ("countOperations", Util.gettext("Count the mathematical operations of the system.")), ("cseBinary", Util.gettext("Common Sub-expression Elimination")), ("dumpComponentsGraphStr", Util.notrans("Dumps the assignment graph used to determine strong components to format suitable for Mathematica")), ("dumpDAE", Util.gettext("dumps the DAE representation of the current transformation state")), ("dumpDAEXML", Util.gettext("dumps the DAE as xml representation of the current transformation state")), ("evaluateParameters", Util.gettext("Evaluates parameters with annotation(Evaluate=true). Use '--evaluateFinalParameters=true' or '--evaluateProtectedParameters=true' to specify additional parameters to be evaluated. Use '--replaceEvaluatedParameters=true' if the evaluated parameters should be replaced in the DAE. To evaluate all parameters in the Frontend use -d=evaluateAllParameters.")), ("extendDynamicOptimization", Util.gettext("Move loops to constraints.")), ("generateSymbolicLinearization", Util.gettext("Generates symbolic linearization matrices A,B,C,D for linear model:\\n\\t:math:`\\\\dot{x} = Ax + Bu `\\n\\t:math:`y = Cx +Du`")), ("generateSymbolicSensitivities", Util.gettext("Generates symbolic Sensivities matrix, where der(x) is differentiated w.r.t. param.")), ("inlineArrayEqn", Util.gettext("This module expands all array equations to scalar equations.")), ("inputDerivativesUsed", Util.gettext("Checks if derivatives of inputs are need to calculate the model.")), ("lateInlineFunction", Util.gettext("Perform function inlining for function with annotation LateInline=true.")), ("partlintornsystem", Util.notrans("partitions linear torn systems.")), ("recursiveTearing", Util.notrans("inline and repeat tearing")), ("reduceDynamicOptimization", Util.notrans("Removes equations which are not needed for the calculations of cost and constraints. This module requires -d=reduceDynOpt.")), ("relaxSystem", Util.notrans("relaxation from gausian elemination")), ("removeConstants", Util.gettext("Remove all constants in the system.")), ("removeEqualRHS", Util.notrans("Detects equal function calls of the form a=f(b) and c=f(b) and substitutes them to get speed up.")), ("removeSimpleEquations", removeSimpleEquationDesc), ("removeUnusedParameter", Util.gettext("Strips all parameter not present in the equations from the system to get speed up for compilation of target code.")), ("removeUnusedVariables", Util.notrans("Strips all variables not present in the equations from the system to get speed up for compilation of target code.")), ("reshufflePost", Util.gettext("Reshuffles algebraic loops.")), ("simplifyAllExpressions", Util.notrans("Does simplifications on all expressions.")), ("simplifyComplexFunction", Util.notrans("Some simplifications on complex functions (complex refers to the internal data structure)")), ("simplifyConstraints", Util.notrans("Rewrites nonlinear constraints into box constraints if possible. This module requires +gDynOpt.")), ("simplifyLoops", Util.notrans("Simplifies algebraic loops. This modules requires +simplifyLoops.")), ("simplifyTimeIndepFuncCalls", Util.gettext("Simplifies time independent built in function calls like pre(param) -> param, der(param) -> 0.0, change(param) -> false, edge(param) -> false.")), ("simplifysemiLinear", Util.gettext("Simplifies calls to semiLinear.")), ("solveLinearSystem", Util.notrans("solve linear system with newton step")), ("solveSimpleEquations", Util.notrans("Solves simple equations")), ("symSolver", Util.notrans("Rewrites the ode system for implicit Euler method. This module requires +symSolver.")), ("symbolicJacobian", Util.notrans("Detects the sparse pattern of the ODE system and calculates also the symbolic Jacobian if flag '--generateSymbolicJacobian' is enabled.")), ("tearingSystem", Util.notrans("For method selection use flag tearingMethod.")), ("wrapFunctionCalls", Util.gettext("This module introduces variables for each function call and substitutes all these calls with the newly introduced variables."))))), Util.gettext("Sets the post optimization modules to use in the back end. See --help=optmodules for more info."))::ConfigFlag
         SIMCODE_TARGET = CONFIG_FLAG(17, "simCodeTarget", NONE(), EXTERNAL(), STRING_FLAG("C"), SOME(STRING_OPTION(list("None", "Adevs", "C", "Cpp", "CSharp", "ExperimentalEmbeddedC", "Java", "JavaScript", "omsic", "sfmi", "XML", "MidC"))), Util.gettext("Sets the target language for the code generation."))::ConfigFlag
         ORDER_CONNECTIONS = CONFIG_FLAG(18, "orderConnections", NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(), Util.gettext("Orders connect equations alphabetically if set."))::ConfigFlag
         TYPE_INFO = CONFIG_FLAG(19, "typeinfo", SOME("t"), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Prints out extra type information if set."))::ConfigFlag
         KEEP_ARRAYS = CONFIG_FLAG(20, "keepArrays", SOME("a"), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Sets whether to split arrays or not."))::ConfigFlag
         MODELICA_OUTPUT = CONFIG_FLAG(21, "modelicaOutput", SOME("m"), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Enables valid modelica output for flat modelica."))::ConfigFlag
         SILENT = CONFIG_FLAG(22, "silent", SOME("q"), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Turns on silent mode."))::ConfigFlag
         CORBA_SESSION = CONFIG_FLAG(23, "corbaSessionName", SOME("c"), EXTERNAL(), STRING_FLAG(""), NONE(), Util.gettext("Sets the name of the corba session if -d=interactiveCorba or --interactive=corba is used."))::ConfigFlag
         NUM_PROC = CONFIG_FLAG(24, "numProcs", SOME("n"), EXTERNAL(), INT_FLAG(0), NONE(), Util.gettext("Sets the number of processors to use (0=default=auto)."))::ConfigFlag
         LATENCY = CONFIG_FLAG(25, "latency", SOME("l"), EXTERNAL(), INT_FLAG(0), NONE(), Util.gettext("Sets the latency for parallel execution."))::ConfigFlag
         BANDWIDTH = CONFIG_FLAG(26, "bandwidth", SOME("b"), EXTERNAL(), INT_FLAG(0), NONE(), Util.gettext("Sets the bandwidth for parallel execution."))::ConfigFlag
         INST_CLASS = CONFIG_FLAG(27, "instClass", SOME("i"), EXTERNAL(), STRING_FLAG(""), NONE(), Util.gettext("Instantiate the class given by the fully qualified path."))::ConfigFlag
         VECTORIZATION_LIMIT = CONFIG_FLAG(28, "vectorizationLimit", SOME("v"), EXTERNAL(), INT_FLAG(0), NONE(), Util.gettext("Sets the vectorization limit, arrays and matrices larger than this will not be vectorized."))::ConfigFlag
         SIMULATION_CG = CONFIG_FLAG(29, "simulationCg", SOME("s"), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Turns on simulation code generation."))::ConfigFlag
         EVAL_PARAMS_IN_ANNOTATIONS = CONFIG_FLAG(30, "evalAnnotationParams", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Sets whether to evaluate parameters in annotations or not."))::ConfigFlag
         CHECK_MODEL = CONFIG_FLAG(31, "checkModel", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Set when checkModel is used to turn on specific features for checking."))::ConfigFlag
         CEVAL_EQUATION = CONFIG_FLAG(32, "cevalEquation", NONE(), INTERNAL(), BOOL_FLAG(true), NONE(), Util.notrans(""))::ConfigFlag
         UNIT_CHECKING = CONFIG_FLAG(33, "unitChecking", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.notrans(""))::ConfigFlag
         TRANSLATE_DAE_STRING = CONFIG_FLAG(34, "translateDAEString", NONE(), INTERNAL(), BOOL_FLAG(true), NONE(), Util.notrans(""))::ConfigFlag
         GENERATE_LABELED_SIMCODE = CONFIG_FLAG(35, "generateLabeledSimCode", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Turns on labeled SimCode generation for reduction algorithms."))::ConfigFlag
         REDUCE_TERMS = CONFIG_FLAG(36, "reduceTerms", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Turns on reducing terms for reduction algorithms."))::ConfigFlag
         REDUCTION_METHOD = CONFIG_FLAG(37, "reductionMethod", NONE(), EXTERNAL(), STRING_FLAG("deletion"), SOME(STRING_OPTION(list("deletion", "substitution", "linearization"))), Util.gettext("Sets the reduction method to be used."))::ConfigFlag
         DEMO_MODE = CONFIG_FLAG(38, "demoMode", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Disable Warning/Error Massages."))::ConfigFlag
         LOCALE_FLAG = CONFIG_FLAG(39, "locale", NONE(), EXTERNAL(), STRING_FLAG(""), NONE(), Util.gettext("Override the locale from the environment."))::ConfigFlag
         DEFAULT_OPENCL_DEVICE = CONFIG_FLAG(40, "defaultOCLDevice", SOME("o"), EXTERNAL(), INT_FLAG(0), NONE(), Util.gettext("Sets the default OpenCL device to be used for parallel execution."))::ConfigFlag
         MAXTRAVERSALS = CONFIG_FLAG(41, "maxTraversals", NONE(), EXTERNAL(), INT_FLAG(2), NONE(), Util.gettext("Maximal traversals to find simple equations in the acausal system."))::ConfigFlag
         DUMP_TARGET = CONFIG_FLAG(42, "dumpTarget", NONE(), EXTERNAL(), STRING_FLAG(""), NONE(), Util.gettext("Redirect the dump to file. If the file ends with .html HTML code is generated."))::ConfigFlag
         DELAY_BREAK_LOOP = CONFIG_FLAG(43, "delayBreakLoop", NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(), Util.gettext("Enables (very) experimental code to break algebraic loops using the delay() operator. Probably messes with initialization."))::ConfigFlag
         TEARING_METHOD = CONFIG_FLAG(44, "tearingMethod", NONE(), EXTERNAL(), STRING_FLAG("cellier"), SOME(STRING_DESC_OPTION(list(("noTearing", Util.gettext("Skip tearing.")), ("omcTearing", Util.gettext("Tearing method developed by TU Dresden: Frenkel, Schubert.")), ("cellier", Util.gettext("Tearing based on Celliers method, revised by FH Bielefeld: Täuber, Patrick"))))), Util.gettext("Sets the tearing method to use. Select no tearing or choose tearing method."))::ConfigFlag
         TEARING_HEURISTIC = CONFIG_FLAG(45, "tearingHeuristic", NONE(), EXTERNAL(), STRING_FLAG("MC3"), SOME(STRING_DESC_OPTION(list(("MC1", Util.gettext("Original cellier with consideration of impossible assignments and discrete Vars.")), ("MC2", Util.gettext("Modified cellier, drop first step.")), ("MC11", Util.gettext("Modified MC1, new last step 'count impossible assignments'.")), ("MC21", Util.gettext("Modified MC2, new last step 'count impossible assignments'.")), ("MC12", Util.gettext("Modified MC1, step 'count impossible assignments' before last step.")), ("MC22", Util.gettext("Modified MC2, step 'count impossible assignments' before last step.")), ("MC13", Util.gettext("Modified MC1, build sum of impossible assignment and causalizable equations, choose var with biggest sum.")), ("MC23", Util.gettext("Modified MC2, build sum of impossible assignment and causalizable equations, choose var with biggest sum.")), ("MC231", Util.gettext("Modified MC23, Two rounds, choose better potentials-set.")), ("MC3", Util.gettext("Modified cellier, build sum of impossible assignment and causalizable equations for all vars, choose var with biggest sum.")), ("MC4", Util.gettext("Modified cellier, use all heuristics, choose var that occurs most in potential sets"))))), Util.gettext("Sets the tearing heuristic to use for Cellier-tearing."))::ConfigFlag
         DISABLE_LINEAR_TEARING = CONFIG_FLAG(46, "disableLinearTearing", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Disables the tearing of linear systems. That might improve the performance of large linear systems(N>1000) in combination with a sparse solver (e.g. umfpack) at runtime (usage with: -ls umfpack).\\nDeprecated flag: Use --maxSizeLinearTearing=0 instead."))::ConfigFlag
         SCALARIZE_MINMAX = CONFIG_FLAG(47, "scalarizeMinMax", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Scalarizes the builtin min/max reduction operators if true."))::ConfigFlag
         RUNNING_WSM_TESTSUITE = CONFIG_FLAG(48, "wsm-testsuite", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Used when running the WSM testsuite."))::ConfigFlag
         SCALARIZE_BINDINGS = CONFIG_FLAG(49, "scalarizeBindings", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Always scalarizes bindings if set."))::ConfigFlag
         CORBA_OBJECT_REFERENCE_FILE_PATH = CONFIG_FLAG(50, "corbaObjectReferenceFilePath", NONE(), EXTERNAL(), STRING_FLAG(""), NONE(), Util.gettext("Sets the path for corba object reference file if -d=interactiveCorba is used."))::ConfigFlag
         HPCOM_SCHEDULER = CONFIG_FLAG(51, "hpcomScheduler", NONE(), EXTERNAL(), STRING_FLAG("level"), NONE(), Util.gettext("Sets the scheduler for task graph scheduling (list | listr | level | levelfix | ext | metis | mcp | taskdep | tds | bls | rand | none). Default: level."))::ConfigFlag
         HPCOM_CODE = CONFIG_FLAG(52, "hpcomCode", NONE(), EXTERNAL(), STRING_FLAG("openmp"), NONE(), Util.gettext("Sets the code-type produced by hpcom (openmp | pthreads | pthreads_spin | tbb | mpi). Default: openmp."))::ConfigFlag
         REWRITE_RULES_FILE = CONFIG_FLAG(53, "rewriteRulesFile", NONE(), EXTERNAL(), STRING_FLAG(""), NONE(), Util.gettext("Activates user given rewrite rules for Absyn expressions. The rules are read from the given file and are of the form rewrite(fromExp, toExp);"))::ConfigFlag
         REPLACE_HOMOTOPY = CONFIG_FLAG(54, "replaceHomotopy", NONE(), EXTERNAL(), STRING_FLAG("none"), SOME(STRING_DESC_OPTION(list(("none", Util.gettext("Default, do not replace homotopy.")), ("actual", Util.gettext("Replace homotopy(actual, simplified) with actual.")), ("simplified", Util.gettext("Replace homotopy(actual, simplified) with simplified."))))), Util.gettext("Replaces homotopy(actual, simplified) with the actual expression or the simplified expression. Good for debugging models which use homotopy. The default is to not replace homotopy."))::ConfigFlag
         GENERATE_SYMBOLIC_JACOBIAN = CONFIG_FLAG(55, "generateSymbolicJacobian", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Generates symbolic Jacobian matrix, where der(x) is differentiated w.r.t. x. This matrix can be used by dassl or ida solver with simulation flag '-jacobian'."))::ConfigFlag
         GENERATE_SYMBOLIC_LINEARIZATION = CONFIG_FLAG(56, "generateSymbolicLinearization", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Generates symbolic linearization matrices A,B,C,D for linear model:\\n\\t\\t:math:`\\\\dot x = Ax + Bu`\\n\\t\\t:math:`y = Cx +Du`"))::ConfigFlag
         INT_ENUM_CONVERSION = CONFIG_FLAG(57, "intEnumConversion", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Allow Integer to enumeration conversion."))::ConfigFlag
         PROFILING_LEVEL = CONFIG_FLAG(58, "profiling", NONE(), EXTERNAL(), STRING_FLAG("none"), SOME(STRING_DESC_OPTION(list(("none", Util.gettext("Generate code without profiling")), ("blocks", Util.gettext("Generate code for profiling function calls as well as linear and non-linear systems of equations")), ("blocks+html", Util.gettext("Like blocks, but also run xsltproc and gnuplot to generate an html report")), ("all", Util.gettext("Generate code for profiling of all functions and equations")), ("all_perf", Util.gettext("Generate code for profiling of all functions and equations with additional performance data using the papi-interface (cpp-runtime)")), ("all_stat", Util.gettext("Generate code for profiling of all functions and equations with additional statistics (cpp-runtime)"))))), Util.gettext("Sets the profiling level to use. Profiled equations and functions record execution time and count for each time step taken by the integrator."))::ConfigFlag
         RESHUFFLE = CONFIG_FLAG(59, "reshuffle", NONE(), EXTERNAL(), INT_FLAG(1), NONE(), Util.gettext("sets tolerance of reshuffling algorithm: 1: conservative, 2: more tolerant, 3 resolve all"))::ConfigFlag
         GENERATE_DYN_OPTIMIZATION_PROBLEM = CONFIG_FLAG(60, "gDynOpt", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Generate dynamic optimization problem based on annotation approach."))::ConfigFlag
         CSE_CALL = CONFIG_FLAG(61, "cseCall", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Deprecated flag: Use --postOptModules+=wrapFunctionCalls instead."))::ConfigFlag
         CSE_BINARY = CONFIG_FLAG(62, "cseBinary", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Deprecated flag: Use --postOptModules+=cseBinary instead."))::ConfigFlag
         CSE_EACHCALL = CONFIG_FLAG(63, "cseEachCall", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Deprecated flag: Use --postOptModules+=wrapFunctionCalls instead."))::ConfigFlag
         MAX_SIZE_FOR_SOLVE_LINIEAR_SYSTEM = CONFIG_FLAG(64, "maxSizeSolveLinearSystem", NONE(), EXTERNAL(), INT_FLAG(0), NONE(), Util.gettext("Max size for solveLinearSystem."))::ConfigFlag
         CPP_FLAGS = CONFIG_FLAG(65, "cppFlags", NONE(), EXTERNAL(), STRING_LIST_FLAG(list("")), NONE(), Util.gettext("Sets extra flags for compilation with the C++ compiler (e.g. +cppFlags=-O3,-Wall)"))::ConfigFlag
         REMOVE_SIMPLE_EQUATIONS = CONFIG_FLAG(66, "removeSimpleEquations", NONE(), EXTERNAL(), STRING_FLAG("default"), SOME(STRING_DESC_OPTION(list(("none", Util.gettext("Disables module")), ("default", Util.gettext("Performs alias elimination and removes constant variables. Default case uses in preOpt phase the fastAcausal and in postOpt phase the causal implementation.")), ("causal", Util.gettext("Performs alias elimination and removes constant variables. Causal implementation.")), ("fastAcausal", Util.gettext("Performs alias elimination and removes constant variables. fastImplementation fastAcausal.")), ("allAcausal", Util.gettext("Performs alias elimination and removes constant variables. Implementation allAcausal.")), ("new", Util.gettext("New implementation (experimental)"))))), Util.gettext("Specifies method that removes simple equations."))::ConfigFlag
         DYNAMIC_TEARING = CONFIG_FLAG(67, "dynamicTearing", NONE(), EXTERNAL(), STRING_FLAG("false"), SOME(STRING_DESC_OPTION(list(("false", Util.gettext("No dynamic tearing.")), ("true", Util.gettext("Dynamic tearing for linear and nonlinear systems.")), ("linear", Util.gettext("Dynamic tearing only for linear systems.")), ("nonlinear", Util.gettext("Dynamic tearing only for nonlinear systems."))))), Util.gettext("Activates dynamic tearing (TearingSet can be changed automatically during runtime, strict set vs. casual set.)"))::ConfigFlag
         SYM_SOLVER = CONFIG_FLAG(68, "symSolver", NONE(), EXTERNAL(), ENUM_FLAG(0, list(("none", 0), ("impEuler", 1), ("expEuler", 2))), SOME(STRING_OPTION(list("none", "impEuler", "expEuler"))), Util.gettext("Activates symbolic implicit solver (original system is not changed)."))::ConfigFlag
         ADD_TIME_AS_STATE = CONFIG_FLAG(69, "addTimeAsState", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Experimental feature: this replaces each occurrence of variable time with a new introduced state time with equation der(time) = 1.0\\nDeprecated flag: Use --postOptModules+=addTimeAsState instead."))::ConfigFlag
         LOOP2CON = CONFIG_FLAG(70, "loop2con", NONE(), EXTERNAL(), STRING_FLAG("none"), SOME(STRING_DESC_OPTION(list(("none", Util.gettext("Disables module")), ("lin", Util.gettext("linear loops --> constraints")), ("noLin", Util.gettext("no linear loops --> constraints")), ("all", Util.gettext("loops --> constraints"))))), Util.gettext("Specifies method that transform loops in constraints. hint: using initial guess from file!"))::ConfigFlag
         FORCE_TEARING = CONFIG_FLAG(71, "forceTearing", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Use tearing set even if it is not smaller than the original component."))::ConfigFlag
         SIMPLIFY_LOOPS = CONFIG_FLAG(72, "simplifyLoops", NONE(), EXTERNAL(), INT_FLAG(0), SOME(STRING_DESC_OPTION(list(("0", Util.gettext("do nothing")), ("1", Util.gettext("special modification of residual expressions")), ("2", Util.gettext("special modification of residual expressions with helper variables"))))), Util.gettext("Simplify algebraic loops."))::ConfigFlag
         RTEARING = CONFIG_FLAG(73, "recursiveTearing", NONE(), EXTERNAL(), INT_FLAG(0), SOME(STRING_DESC_OPTION(list(("0", Util.gettext("do nothing")), ("1", Util.gettext("linear tearing set of size 1")), ("2", Util.gettext("linear tearing"))))), Util.gettext("Inline and repeat tearing."))::ConfigFlag
         FLOW_THRESHOLD = CONFIG_FLAG(74, "flowThreshold", NONE(), EXTERNAL(), REAL_FLAG(1e-7), NONE(), Util.gettext("Sets the minium threshold for stream flow rates"))::ConfigFlag
         MATRIX_FORMAT = CONFIG_FLAG(75, "matrixFormat", NONE(), EXTERNAL(), STRING_FLAG("dense"), NONE(), Util.gettext("Sets the matrix format type in cpp runtime which should be used (dense | sparse ). Default: dense."))::ConfigFlag
         PARTLINTORN = CONFIG_FLAG(76, "partlintorn", NONE(), EXTERNAL(), INT_FLAG(0), NONE(), Util.gettext("Sets the limit for partitionin of linear torn systems."))::ConfigFlag
         INIT_OPT_MODULES = CONFIG_FLAG(77, "initOptModules", NONE(), EXTERNAL(), STRING_LIST_FLAG(list("simplifyComplexFunction", "tearingSystem", "solveSimpleEquations", "calculateStrongComponentJacobians", "simplifyAllExpressions", "collapseArrayExpressions")), SOME(STRING_DESC_OPTION(list(("calculateStrongComponentJacobians", Util.gettext("Generates analytical jacobian for torn linear and non-linear strong components. By default linear components and non-linear components with user-defined function calls are skipped. See also debug flags: LSanalyticJacobian, NLSanalyticJacobian and forceNLSanalyticJacobian")), ("collapseArrayExpressions", collapseArrayExpressionsText), ("constantLinearSystem", Util.gettext("Evaluates constant linear systems (a*x+b*y=c; d*x+e*y=f; a,b,c,d,e,f are constants) at compile-time.")), ("extendDynamicOptimization", Util.gettext("Move loops to constraints.")), ("generateHomotopyComponents", Util.gettext("Finds the parts of the DAE that have to be handled by the homotopy solver and creates a strong component out of it.")), ("inlineHomotopy", Util.gettext("Experimental: Inlines the homotopy expression to allow symbolic simplifications.")), ("inputDerivativesUsed", Util.gettext("Checks if derivatives of inputs are need to calculate the model.")), ("recursiveTearing", Util.notrans("inline and repeat tearing")), ("reduceDynamicOptimization", Util.notrans("Removes equations which are not needed for the calculations of cost and constraints. This module requires -d=reduceDynOpt.")), ("replaceHomotopyWithSimplified", Util.notrans("Replaces the homotopy expression homotopy(actual, simplified) with the simplified part.")), ("simplifyAllExpressions", Util.notrans("Does simplifications on all expressions.")), ("simplifyComplexFunction", Util.notrans("Some simplifications on complex functions (complex refers to the internal data structure)")), ("simplifyConstraints", Util.notrans("Rewrites nonlinear constraints into box constraints if possible. This module requires +gDynOpt.")), ("simplifyLoops", Util.notrans("Simplifies algebraic loops. This modules requires +simplifyLoops.")), ("solveSimpleEquations", Util.notrans("Solves simple equations")), ("tearingSystem", Util.notrans("For method selection use flag tearingMethod.")), ("wrapFunctionCalls", Util.gettext("This module introduces variables for each function call and substitutes all these calls with the newly introduced variables."))))), Util.gettext("Sets the initialization optimization modules to use in the back end. See --help=optmodules for more info."))::ConfigFlag
         MAX_MIXED_DETERMINED_INDEX = CONFIG_FLAG(78, "maxMixedDeterminedIndex", NONE(), EXTERNAL(), INT_FLAG(10), NONE(), Util.gettext("Sets the maximum mixed-determined index that is handled by the initialization."))::ConfigFlag
         USE_LOCAL_DIRECTION = CONFIG_FLAG(79, "useLocalDirection", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Keeps the input/output prefix for all variables in the flat model, not only top-level ones."))::ConfigFlag
         DEFAULT_OPT_MODULES_ORDERING = CONFIG_FLAG(80, "defaultOptModulesOrdering", NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(), Util.gettext("If this is activated, then the specified pre-/post-/init-optimization modules will be rearranged to the recommended ordering."))::ConfigFlag
         PRE_OPT_MODULES_ADD = CONFIG_FLAG(81, "preOptModules+", NONE(), EXTERNAL(), STRING_LIST_FLAG(list()), NONE(), Util.gettext("Enables additional pre-optimization modules, e.g. --preOptModules+=module1,module2 would additionally enable module1 and module2. See --help=optmodules for more info."))::ConfigFlag
         PRE_OPT_MODULES_SUB = CONFIG_FLAG(82, "preOptModules-", NONE(), EXTERNAL(), STRING_LIST_FLAG(list()), NONE(), Util.gettext("Disables a list of pre-optimization modules, e.g. --preOptModules-=module1,module2 would disable module1 and module2. See --help=optmodules for more info."))::ConfigFlag
         POST_OPT_MODULES_ADD = CONFIG_FLAG(83, "postOptModules+", NONE(), EXTERNAL(), STRING_LIST_FLAG(list()), NONE(), Util.gettext("Enables additional post-optimization modules, e.g. --postOptModules+=module1,module2 would additionally enable module1 and module2. See --help=optmodules for more info."))::ConfigFlag
         POST_OPT_MODULES_SUB = CONFIG_FLAG(84, "postOptModules-", NONE(), EXTERNAL(), STRING_LIST_FLAG(list()), NONE(), Util.gettext("Disables a list of post-optimization modules, e.g. --postOptModules-=module1,module2 would disable module1 and module2. See --help=optmodules for more info."))::ConfigFlag
         INIT_OPT_MODULES_ADD = CONFIG_FLAG(85, "initOptModules+", NONE(), EXTERNAL(), STRING_LIST_FLAG(list()), NONE(), Util.gettext("Enables additional init-optimization modules, e.g. --initOptModules+=module1,module2 would additionally enable module1 and module2. See --help=optmodules for more info."))::ConfigFlag
         INIT_OPT_MODULES_SUB = CONFIG_FLAG(86, "initOptModules-", NONE(), EXTERNAL(), STRING_LIST_FLAG(list()), NONE(), Util.gettext("Disables a list of init-optimization modules, e.g. --initOptModules-=module1,module2 would disable module1 and module2. See --help=optmodules for more info."))::ConfigFlag
         PERMISSIVE = CONFIG_FLAG(87, "permissive", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Disables some error checks to allow erroneous models to compile."))::ConfigFlag
         HETS = CONFIG_FLAG(88, "hets", NONE(), INTERNAL(), STRING_FLAG("none"), SOME(STRING_DESC_OPTION(list(("none", Util.gettext("do nothing")), ("derCalls", Util.gettext("sort terms based on der-calls"))))), Util.gettext("Heuristic equation terms sort"))::ConfigFlag
         DEFAULT_CLOCK_PERIOD = CONFIG_FLAG(89, "defaultClockPeriod", NONE(), INTERNAL(), REAL_FLAG(1.0), NONE(), Util.gettext("Sets the default clock period (in seconds) for state machines (default: 1.0)."))::ConfigFlag
         INST_CACHE_SIZE = CONFIG_FLAG(90, "instCacheSize", NONE(), EXTERNAL(), INT_FLAG(25343), NONE(), Util.gettext("Sets the size of the internal hash table used for instantiation caching."))::ConfigFlag
         MAX_SIZE_LINEAR_TEARING = CONFIG_FLAG(91, "maxSizeLinearTearing", NONE(), EXTERNAL(), INT_FLAG(200), NONE(), Util.gettext("Sets the maximum system size for tearing of linear systems (default 200)."))::ConfigFlag
         MAX_SIZE_NONLINEAR_TEARING = CONFIG_FLAG(92, "maxSizeNonlinearTearing", NONE(), EXTERNAL(), INT_FLAG(10000), NONE(), Util.gettext("Sets the maximum system size for tearing of nonlinear systems (default 10000)."))::ConfigFlag
         NO_TEARING_FOR_COMPONENT = CONFIG_FLAG(93, "noTearingForComponent", NONE(), EXTERNAL(), INT_LIST_FLAG(list()), NONE(), Util.gettext("Deactivates tearing for the specified components.\\nUse '-d=tearingdump' to find out the relevant indexes."))::ConfigFlag
         CT_STATE_MACHINES = CONFIG_FLAG(94, "ctStateMachines", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Experimental: Enable continuous-time state machine prototype"))::ConfigFlag
         DAE_MODE = CONFIG_FLAG(95, "daeMode", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Generates code to simulate models in DAE mode. The whole system is passed directly to the DAE solver SUNDIALS/IDA and no algebraic solver is involved in the simulation process."))::ConfigFlag
         INLINE_METHOD = CONFIG_FLAG(96, "inlineMethod", NONE(), EXTERNAL(), ENUM_FLAG(1, list(("replace", 1), ("append", 2))), SOME(STRING_OPTION(list("replace", "append"))), Util.gettext("Sets the inline method to use.\\n" * "replace : This method inlines by replacing in place all expressions. Might lead to very long expression.\\n" * "append  : This method inlines by adding additional variables to the whole system. Might lead to much bigger system."))::ConfigFlag
         SET_TEARING_VARS = CONFIG_FLAG(97, "setTearingVars", NONE(), EXTERNAL(), INT_LIST_FLAG(list()), NONE(), Util.gettext("Sets the tearing variables by its strong component indexes. Use '-d=tearingdump' to find out the relevant indexes.\\nUse following format: '--setTearingVars=(sci,n,t1,...,tn)*', with sci = strong component index, n = number of tearing variables, t1,...tn = tearing variables.\\nE.g.: '--setTearingVars=4,2,3,5' would select variables 3 and 5 in strong component 4."))::ConfigFlag
         SET_RESIDUAL_EQNS = CONFIG_FLAG(98, "setResidualEqns", NONE(), EXTERNAL(), INT_LIST_FLAG(list()), NONE(), Util.gettext("Sets the residual equations by its strong component indexes. Use '-d=tearingdump' to find out the relevant indexes for the collective equations.\\nUse following format: '--setResidualEqns=(sci,n,r1,...,rn)*', with sci = strong component index, n = number of residual equations, r1,...rn = residual equations.\\nE.g.: '--setResidualEqns=4,2,3,5' would select equations 3 and 5 in strong component 4.\\nOnly works in combination with 'setTearingVars'."))::ConfigFlag
         IGNORE_COMMAND_LINE_OPTIONS_ANNOTATION = CONFIG_FLAG(99, "ignoreCommandLineOptionsAnnotation", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Ignores the command line options specified as annotation in the class."))::ConfigFlag
         CALCULATE_SENSITIVITIES = CONFIG_FLAG(100, "calculateSensitivities", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Generates sensitivities variables and matrixes."))::ConfigFlag
         ALARM = CONFIG_FLAG(101, "alarm", SOME("r"), EXTERNAL(), INT_FLAG(0), NONE(), Util.gettext("Sets the number seconds until omc timeouts and exits. Used by the testing framework to terminate infinite running processes."))::ConfigFlag
         TOTAL_TEARING = CONFIG_FLAG(102, "totalTearing", NONE(), EXTERNAL(), INT_LIST_FLAG(list()), NONE(), Util.gettext("Activates total tearing (determination of all possible tearing sets) for the specified components.\\nUse '-d=tearingdump' to find out the relevant indexes."))::ConfigFlag
         IGNORE_SIMULATION_FLAGS_ANNOTATION = CONFIG_FLAG(103, "ignoreSimulationFlagsAnnotation", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Ignores the simulation flags specified as annotation in the class."))::ConfigFlag
         DYNAMIC_TEARING_FOR_INITIALIZATION = CONFIG_FLAG(104, "dynamicTearingForInitialization", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Enable Dynamic Tearing also for the initialization system."))::ConfigFlag
         PREFER_TVARS_WITH_START_VALUE = CONFIG_FLAG(105, "preferTVarsWithStartValue", NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(), Util.gettext("Prefer tearing variables with start value for initialization."))::ConfigFlag
         EQUATIONS_PER_FILE = CONFIG_FLAG(106, "equationsPerFile", NONE(), EXTERNAL(), INT_FLAG(2000), NONE(), Util.gettext("Generate code for at most this many equations per C-file (partially implemented in the compiler)."))::ConfigFlag
         EVALUATE_FINAL_PARAMS = CONFIG_FLAG(107, "evaluateFinalParameters", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Evaluates all the final parameters in addition to parameters with annotation(Evaluate=true)."))::ConfigFlag
         EVALUATE_PROTECTED_PARAMS = CONFIG_FLAG(108, "evaluateProtectedParameters", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Evaluates all the protected parameters in addition to parameters with annotation(Evaluate=true)."))::ConfigFlag
         REPLACE_EVALUATED_PARAMS = CONFIG_FLAG(109, "replaceEvaluatedParameters", NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(), Util.gettext("Replaces all the evaluated parameters in the DAE."))::ConfigFlag
         CONDENSE_ARRAYS = CONFIG_FLAG(110, "condenseArrays", NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(), Util.gettext("Sets whether array expressions containing function calls are condensed or not."))::ConfigFlag
         WFC_ADVANCED = CONFIG_FLAG(111, "wfcAdvanced", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("wrapFunctionCalls ignores more then default cases, e.g. exp, sin, cos, log, (experimental flag)"))::ConfigFlag
         GRAPHICS_EXP_MODE = CONFIG_FLAG(112, "graphicsExpMode", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Sets whether we are in graphics exp mode (evaluating icons)."))::ConfigFlag
         TEARING_STRICTNESS = CONFIG_FLAG(113, "tearingStrictness", NONE(), EXTERNAL(), STRING_FLAG("strict"), SOME(STRING_DESC_OPTION(list(("casual", Util.gettext("Loose tearing rules using ExpressionSolve to determine the solvability instead of considering the partial derivative. Allows to solve for everything that is analytically possible. This could lead to singularities during simulation.")), ("strict", Util.gettext("Robust tearing rules by consideration of the partial derivative. Allows to divide by parameters that are not equal to or close to zero.")), ("veryStrict", Util.gettext("Very strict tearing rules that do not allow to divide by any parameter. Use this if you aim at overriding parameters after compilation with values equal to or close to zero."))))), Util.gettext("Sets the strictness of the tearing method regarding the solvability restrictions."))::ConfigFlag
         INTERACTIVE = CONFIG_FLAG(114, "interactive", NONE(), EXTERNAL(), STRING_FLAG("none"), SOME(STRING_DESC_OPTION(list(("none", Util.gettext("do nothing")), ("corba", Util.gettext("Starts omc as a server listening on the socket interface.")), ("tcp", Util.gettext("Starts omc as a server listening on the Corba interface.")), ("zmq", Util.gettext("Starts omc as a ZeroMQ server listening on the socket interface."))))), Util.gettext("Sets the interactive mode for omc."))::ConfigFlag
         ZEROMQ_FILE_SUFFIX = CONFIG_FLAG(115, "zeroMQFileSuffix", SOME("z"), EXTERNAL(), STRING_FLAG(""), NONE(), Util.gettext("Sets the file suffix for zeroMQ port file if --interactive=zmq is used."))::ConfigFlag
         HOMOTOPY_APPROACH = CONFIG_FLAG(116, "homotopyApproach", NONE(), EXTERNAL(), STRING_FLAG("equidistantGlobal"), SOME(STRING_DESC_OPTION(list(("equidistantLocal", Util.gettext("Local homotopy approach with equidistant lambda steps. The homotopy parameter only effects the local strongly connected component.")), ("adaptiveLocal", Util.gettext("Local homotopy approach with adaptive lambda steps. The homotopy parameter only effects the local strongly connected component.")), ("equidistantGlobal", Util.gettext("Default, global homotopy approach with equidistant lambda steps. The homotopy parameter effects the entire initialization system.")), ("adaptiveGlobal", Util.gettext("Global homotopy approach with adaptive lambda steps. The homotopy parameter effects the entire initialization system."))))), Util.gettext("Sets the homotopy approach."))::ConfigFlag
         IGNORE_REPLACEABLE = CONFIG_FLAG(117, "ignoreReplaceable", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Sets whether to ignore replaceability or not when redeclaring."))::ConfigFlag
         LABELED_REDUCTION = CONFIG_FLAG(118, "labeledReduction", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Turns on labeling and reduce terms to do whole process of reduction."))::ConfigFlag
         DISABLE_EXTRA_LABELING = CONFIG_FLAG(119, "disableExtraLabeling", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Disable adding extra label into the whole experssion with more than one term and +,- operations."))::ConfigFlag
         LOAD_MSL_MODEL = CONFIG_FLAG(120, "loadMSLModel", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Used to know loadFile doesn't need to be called in cpp-runtime (for labeled model reduction)."))::ConfigFlag
         Load_PACKAGE_FILE = CONFIG_FLAG(121, "loadPackageFile", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("used when the outside name is different with the inside name of the packge, in cpp-runtime (for labeled model reduction)."))::ConfigFlag
         BUILDING_FMU = CONFIG_FLAG(122, "", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Is true when building an FMU (so the compiler can look for URIs to package as FMI resources)."))::ConfigFlag
         BUILDING_MODEL = CONFIG_FLAG(123, "", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Is true when building a model (as opposed to running a Modelica script)."))::ConfigFlag
         POST_OPT_MODULES_DAE = CONFIG_FLAG(124, "postOptModulesDAE", NONE(), EXTERNAL(), STRING_LIST_FLAG(list("lateInlineFunction", "wrapFunctionCalls", "simplifysemiLinear", "simplifyComplexFunction", "removeConstants", "simplifyTimeIndepFuncCalls", "simplifyAllExpressions", "findZeroCrossings", "createDAEmodeBDAE", "detectDAEmodeSparsePattern", "setEvaluationStage")), NONE(), Util.gettext("Sets the optimization modules for the DAEmode in the back end. See --help=optmodules for more info."))::ConfigFlag
         #= \"replaceDerCalls\",
         =#
         EVAL_LOOP_LIMIT = CONFIG_FLAG(125, "evalLoopLimit", NONE(), EXTERNAL(), INT_FLAG(100000), NONE(), Util.gettext("The loop iteration limit used when evaluating constant function calls."))::ConfigFlag
         EVAL_RECURSION_LIMIT = CONFIG_FLAG(126, "evalRecursionLimit", NONE(), EXTERNAL(), INT_FLAG(256), NONE(), Util.gettext("The recursion limit used when evaluating constant function calls."))::ConfigFlag
         SINGLE_INSTANCE_AGLSOLVER = CONFIG_FLAG(127, "singleInstanceAglSolver", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Sets to instantiate only  one algebraic loop solver all algebraic loops"))::ConfigFlag
         SHOW_STRUCTURAL_ANNOTATIONS = CONFIG_FLAG(128, "showStructuralAnnotations", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Show annotations affecting the solution process in the flattened code."))::ConfigFlag
         INITIAL_STATE_SELECTION = CONFIG_FLAG(129, "initialStateSelection", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Activates the state selection inside initialization to avoid singularities."))::ConfigFlag
         STRICT = CONFIG_FLAG(130, "strict", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(), Util.gettext("Enables stricter enforcement of Modelica language rules."))::ConfigFlag

         #=  This is a list of all configuration flags. A flag can not be used unless it's
         =#
         #=  in this list, and the list is checked at initialization so that all flags are
         =#
         #=  sorted by index (and thus have unique indices).
         =#
         allConfigFlags = list(DEBUG, HELP, RUNNING_TESTSUITE, SHOW_VERSION, TARGET, GRAMMAR, ANNOTATION_VERSION, LANGUAGE_STANDARD, SHOW_ERROR_MESSAGES, SHOW_ANNOTATIONS, NO_SIMPLIFY, PRE_OPT_MODULES, CHEAPMATCHING_ALGORITHM, MATCHING_ALGORITHM, INDEX_REDUCTION_METHOD, POST_OPT_MODULES, SIMCODE_TARGET, ORDER_CONNECTIONS, TYPE_INFO, KEEP_ARRAYS, MODELICA_OUTPUT, SILENT, CORBA_SESSION, NUM_PROC, LATENCY, BANDWIDTH, INST_CLASS, VECTORIZATION_LIMIT, SIMULATION_CG, EVAL_PARAMS_IN_ANNOTATIONS, CHECK_MODEL, CEVAL_EQUATION, UNIT_CHECKING, TRANSLATE_DAE_STRING, GENERATE_LABELED_SIMCODE, REDUCE_TERMS, REDUCTION_METHOD, DEMO_MODE, LOCALE_FLAG, DEFAULT_OPENCL_DEVICE, MAXTRAVERSALS, DUMP_TARGET, DELAY_BREAK_LOOP, TEARING_METHOD, TEARING_HEURISTIC, DISABLE_LINEAR_TEARING, SCALARIZE_MINMAX, RUNNING_WSM_TESTSUITE, SCALARIZE_BINDINGS, CORBA_OBJECT_REFERENCE_FILE_PATH, HPCOM_SCHEDULER, HPCOM_CODE, REWRITE_RULES_FILE, REPLACE_HOMOTOPY, GENERATE_SYMBOLIC_JACOBIAN, GENERATE_SYMBOLIC_LINEARIZATION, INT_ENUM_CONVERSION, PROFILING_LEVEL, RESHUFFLE, GENERATE_DYN_OPTIMIZATION_PROBLEM, CSE_CALL, CSE_BINARY, CSE_EACHCALL, MAX_SIZE_FOR_SOLVE_LINIEAR_SYSTEM, CPP_FLAGS, REMOVE_SIMPLE_EQUATIONS, DYNAMIC_TEARING, SYM_SOLVER, ADD_TIME_AS_STATE, LOOP2CON, FORCE_TEARING, SIMPLIFY_LOOPS, RTEARING, FLOW_THRESHOLD, MATRIX_FORMAT, PARTLINTORN, INIT_OPT_MODULES, MAX_MIXED_DETERMINED_INDEX, USE_LOCAL_DIRECTION, DEFAULT_OPT_MODULES_ORDERING, PRE_OPT_MODULES_ADD, PRE_OPT_MODULES_SUB, POST_OPT_MODULES_ADD, POST_OPT_MODULES_SUB, INIT_OPT_MODULES_ADD, INIT_OPT_MODULES_SUB, PERMISSIVE, HETS, DEFAULT_CLOCK_PERIOD, INST_CACHE_SIZE, MAX_SIZE_LINEAR_TEARING, MAX_SIZE_NONLINEAR_TEARING, NO_TEARING_FOR_COMPONENT, CT_STATE_MACHINES, DAE_MODE, INLINE_METHOD, SET_TEARING_VARS, SET_RESIDUAL_EQNS, IGNORE_COMMAND_LINE_OPTIONS_ANNOTATION, CALCULATE_SENSITIVITIES, ALARM, TOTAL_TEARING, IGNORE_SIMULATION_FLAGS_ANNOTATION, DYNAMIC_TEARING_FOR_INITIALIZATION, PREFER_TVARS_WITH_START_VALUE, EQUATIONS_PER_FILE, EVALUATE_FINAL_PARAMS, EVALUATE_PROTECTED_PARAMS, REPLACE_EVALUATED_PARAMS, CONDENSE_ARRAYS, WFC_ADVANCED, GRAPHICS_EXP_MODE, TEARING_STRICTNESS, INTERACTIVE, ZEROMQ_FILE_SUFFIX, HOMOTOPY_APPROACH, IGNORE_REPLACEABLE, LABELED_REDUCTION, DISABLE_EXTRA_LABELING, LOAD_MSL_MODEL, Load_PACKAGE_FILE, BUILDING_FMU, BUILDING_MODEL, POST_OPT_MODULES_DAE, EVAL_LOOP_LIMIT, EVAL_RECURSION_LIMIT, SINGLE_INSTANCE_AGLSOLVER, SHOW_STRUCTURAL_ANNOTATIONS, INITIAL_STATE_SELECTION, STRICT)::List{<:ConfigFlag}

         #= Create a new flags structure and read the given arguments. =#
        function new(inArgs::List{<:String})::List{<:String}
              local outArgs::List{<:String}

              _ = loadFlags()
              outArgs = readArgs(inArgs)
          outArgs
        end

         #= Saves the flags with setGlobalRoot. =#
        function saveFlags(inFlags::Flag)
              setGlobalRoot(Global.flagsIndex, inFlags)
        end

        function createConfigFlags()::Array{<:FlagData}
              local configFlags::Array{<:FlagData}

              local count::ModelicaInteger
              local index::ModelicaInteger = 0

              configFlags = listArray(list(flag.defaultValue for flag in allConfigFlags))
          configFlags
        end

        function createDebugFlags()::Array{<:Bool}
              local debugFlags::Array{<:Bool}

              debugFlags = listArray(list(flag.default for flag in allDebugFlags))
          debugFlags
        end

         #= Loads the flags with getGlobalRoot. Creates a new flags structure if it
           hasn't been created yet. =#
        function loadFlags(initialize::Bool = true)::Flag
              local flags::Flag

              local debug_flags::Array{<:Bool}
              local config_flags::Array{<:FlagData}

              try
                flags = getGlobalRoot(Global.flagsIndex)
              catch
                if initialize
                  checkDebugFlags()
                  checkConfigFlags()
                  flags = FLAGS(createDebugFlags(), createConfigFlags())
                  saveFlags(flags)
                else
                  print("Flag loading failed!\\n")
                  flags = Flags.NO_FLAGS()
                end
              end
          flags
        end

         #= Creates a copy of the existing flags. =#
        function backupFlags()::Flag
              local outFlags::Flag

              local debug_flags::Array{<:Bool}
              local config_flags::Array{<:FlagData}

              @match FLAGS(debug_flags, config_flags) = loadFlags()
              outFlags = FLAGS(arrayCopy(debug_flags), arrayCopy(config_flags))
          outFlags
        end

         #= Resets all debug flags to their default values. =#
        function resetDebugFlags()
              local debug_flags::Array{<:Bool}
              local config_flags::Array{<:FlagData}

              @match FLAGS(_, config_flags) = loadFlags()
              debug_flags = createDebugFlags()
              saveFlags(FLAGS(debug_flags, config_flags))
        end

         #= Resets all configuration flags to their default values. =#
        function resetConfigFlags()
              local debug_flags::Array{<:Bool}
              local config_flags::Array{<:FlagData}

              @match FLAGS(debug_flags, _) = loadFlags()
              config_flags = createConfigFlags()
              saveFlags(FLAGS(debug_flags, config_flags))
        end

         #= Checks that the flags listed in allDebugFlags have sequential and unique indices. =#
        function checkDebugFlags()
              local index::ModelicaInteger = 0
              local err_str::String

              for flag in allDebugFlags
                index = index + 1
                if flag.index != index
                  err_str = "Invalid flag '" + flag.name + "' with index " + String(flag.index) + " (expected " + String(index) + ") in Flags.allDebugFlags. Make sure that all flags are present and ordered correctly!"
                  Error.terminateError(err_str, sourceInfo())
                end
              end
               #=  If the flag indices are borked, print an error and terminate the compiler.
               =#
               #=  Only failing here could cause an infinite loop of trying to load the flags.
               =#
        end

         #= Checks that the flags listed in allConfigFlags have sequential and unique indices. =#
        function checkConfigFlags()
              local index::ModelicaInteger = 0
              local err_str::String

              for flag in allConfigFlags
                index = index + 1
                if flag.index != index
                  err_str = "Invalid flag '" + flag.name + "' with index " + String(flag.index) + " (expected " + String(index) + ") in Flags.allConfigFlags. Make sure that all flags are present and ordered correctly!"
                  Error.terminateError(err_str, sourceInfo())
                end
              end
               #=  If the flag indices are borked, print an error and terminate the compiler.
               =#
               #=  Only failing here could cause an infinite loop of trying to load the flags.
               =#
        end

         #= Sets the value of a debug flag, and returns the old value. =#
        function set(inFlag::DebugFlag, inValue::Bool)::Bool
              local outOldValue::Bool

              local debug_flags::Array{<:Bool}
              local config_flags::Array{<:FlagData}
              local flags::Flag

              @match FLAGS(debug_flags, config_flags) = loadFlags()
              (debug_flags, outOldValue) = updateDebugFlagArray(debug_flags, inValue, inFlag)
              saveFlags(FLAGS(debug_flags, config_flags))
          outOldValue
        end

         #= Checks if a debug flag is set. =#
        function isSet(inFlag::DebugFlag)::Bool
              local outValue::Bool

              local debug_flags::Array{<:Bool}
              local flags::Flag
              local index::ModelicaInteger

              @match DEBUG_FLAG(index = index) = inFlag
              flags = loadFlags()
              @match FLAGS(debugFlags = debug_flags) = flags
              outValue = arrayGet(debug_flags, index)
          outValue
        end

         #= Enables a debug flag. =#
        function enableDebug(inFlag::DebugFlag)::Bool
              local outOldValue::Bool

              outOldValue = set(inFlag, true)
          outOldValue
        end

         #= Disables a debug flag. =#
        function disableDebug(inFlag::DebugFlag)::Bool
              local outOldValue::Bool

              outOldValue = set(inFlag, false)
          outOldValue
        end

         #= Updates the value of a debug flag in the debug flag array. =#
        function updateDebugFlagArray(inFlags::Array{<:Bool}, inValue::Bool, inFlag::DebugFlag)::Tuple{Array{<:Bool}, Bool}
              local outOldValue::Bool
              local outFlags::Array{<:Bool}

              local index::ModelicaInteger

              @match DEBUG_FLAG(index = index) = inFlag
              outOldValue = arrayGet(inFlags, index)
              outFlags = arrayUpdate(inFlags, index, inValue)
          (outFlags, outOldValue)
        end

         #= Updates the value of a configuration flag in the configuration flag array. =#
        function updateConfigFlagArray(inFlags::Array{<:FlagData}, inValue::FlagData, inFlag::ConfigFlag)::Array{<:FlagData}
              local outFlags::Array{<:FlagData}

              local index::ModelicaInteger

              @match CONFIG_FLAG(index = index) = inFlag
              outFlags = arrayUpdate(inFlags, index, inValue)
              applySideEffects(inFlag, inValue)
          outFlags
        end

         #= Reads the command line arguments to the compiler and sets the flags
          accordingly. Returns a list of arguments that were not consumed, such as the
          model filename. =#
        function readArgs(inArgs::List{<:String})::List{<:String}
              local outArgs::List{<:String} = list()

              local flags::Flag
              local numError::ModelicaInteger
              local arg::String
              local rest_args::List{<:String} = inArgs

              numError = Error.getNumErrorMessages()
              flags = loadFlags()
              while ! listEmpty(rest_args)
                @match arg <| rest_args = rest_args
                if arg == "--"
                  break
                else
                  if ! readArg(arg, flags)
                    outArgs = arg <| outArgs
                  end
                end
              end
               #=  Stop parsing arguments if -- is encountered.
               =#
              outArgs = ListUtil.append_reverse(outArgs, rest_args)
              _ = ListUtil.map2(outArgs, System.iconv, "UTF-8", "UTF-8")
              Error.assertionOrAddSourceMessage(numError == Error.getNumErrorMessages(), Error.UTF8_COMMAND_LINE_ARGS, list(), Util.dummyInfo)
              saveFlags(flags)
          outArgs
        end

         #= Reads a single command line argument. Returns true if the argument was not
          consumed, otherwise false. =#
        function readArg(inArg::String, inFlags::Flag)::Bool
              local outConsumed::Bool

              local flagtype::String
              local len::ModelicaInteger
              local pos::ModelicaInteger

              flagtype = stringGetStringChar(inArg, 1)
              len = stringLength(inArg)
               #=  Flags beginning with + can be both short and long, i.e. +h or +help.
               =#
              if flagtype == "+"
                if len == 1
                  parseFlag(inArg, NO_FLAGS())
                else
                  parseFlag(System.substring(inArg, 2, len), inFlags, flagtype)
                end
                outConsumed = true
              elseif flagtype == "-"
                if len == 1
                  parseFlag(inArg, NO_FLAGS())
                elseif len == 2
                  parseFlag(System.substring(inArg, 2, 2), inFlags, flagtype)
                elseif stringGetStringChar(inArg, 2) == "-"
                  if len < 4 || stringGetStringChar(inArg, 4) == "="
                    parseFlag(inArg, NO_FLAGS())
                  else
                    parseFlag(System.substring(inArg, 3, len), inFlags, "--")
                  end
                else
                  if stringGetStringChar(inArg, 3) == "="
                    parseFlag(System.substring(inArg, 2, len), inFlags, flagtype)
                  else
                    parseFlag(inArg, NO_FLAGS())
                  end
                end
                outConsumed = true
              else
                outConsumed = false
              end
               #=  + alone is not a valid flag.
               =#
               #=  Flags beginning with - must have another - for long flags, i.e. -h or --help.
               =#
               #=  - alone is not a valid flag.
               =#
               #=  Short flag without argument, i.e. -h.
               =#
               #=  Short flags may not be used with --, i.e. --h or --h=debug.
               =#
               #=  Long flag, i.e. --help or --help=debug.
               =#
               #=  Short flag with argument, i.e. -h=debug.
               =#
               #=  Long flag used with -, i.e. -help, which is not allowed.
               =#
               #=  Arguments that don't begin with + or - are not flags, ignore them.
               =#
          outConsumed
        end

         #= Parses a single flag. =#
        function parseFlag(inFlag::String, inFlags::Flag, inFlagPrefix::String = "")
              local flag::String
              local values::List{<:String}

              @match flag <| values = System.strtok(inFlag, "=")
              values = ListUtil.flatten(ListUtil.map1(values, System.strtok, ","))
              parseConfigFlag(flag, values, inFlags, inFlagPrefix)
        end

         #= Tries to look up the flag with the given name, and set it to the given value. =#
        function parseConfigFlag(inFlag::String, inValues::List{<:String}, inFlags::Flag, inFlagPrefix::String)
              local config_flag::ConfigFlag

              config_flag = lookupConfigFlag(inFlag, inFlagPrefix)
              evaluateConfigFlag(config_flag, inValues, inFlags)
        end

         #= Lookup up the flag with the given name in the list of configuration flags. =#
        function lookupConfigFlag(inFlag::String, inFlagPrefix::String)::ConfigFlag
              local outFlag::ConfigFlag

              try
                outFlag = ListUtil.getMemberOnTrue(inFlag, allConfigFlags, matchConfigFlag)
              catch
                Error.addMessage(Error.UNKNOWN_OPTION, list(inFlagPrefix + inFlag))
                fail()
              end
          outFlag
        end

        function configFlagEq(inFlag1::ConfigFlag, inFlag2::ConfigFlag)::Bool
              local eq::Bool

              eq = begin
                  local index1::ModelicaInteger
                  local index2::ModelicaInteger
                @match (inFlag1, inFlag2) begin
                  (CONFIG_FLAG(index = index1), CONFIG_FLAG(index = index2))  => begin
                    index1 == index2
                  end
                end
              end
          eq
        end

        function setAdditionalOptModules(inFlag::ConfigFlag, inOppositeFlag::ConfigFlag, inValues::List{<:String})
              local values::List{<:String}

              for value in inValues
                values = getConfigStringList(inOppositeFlag)
                values = ListUtil.removeOnTrue(value, stringEq, values)
                setConfigStringList(inOppositeFlag, values)
                values = getConfigStringList(inFlag)
                values = ListUtil.removeOnTrue(value, stringEq, values)
                setConfigStringList(inFlag, value <| values)
              end
               #=  remove value from inOppositeFlag
               =#
               #=  add value to inFlag
               =#
        end

         #= Evaluates a given flag and it's arguments. =#
        function evaluateConfigFlag(inFlag::ConfigFlag, inValues::List{<:String}, inFlags::Flag)
              _ = begin
                  local debug_flags::Array{<:Bool}
                  local config_flags::Array{<:FlagData}
                  local values::List{<:String}
                   #=  Special case for +d, +debug, set the given debug flags.
                   =#
                @match (inFlag, inFlags) begin
                  (CONFIG_FLAG(index = 1), FLAGS(debugFlags = debug_flags))  => begin
                      ListUtil.map1_0(inValues, setDebugFlag, debug_flags)
                    ()
                  end

                  (CONFIG_FLAG(index = 2), _)  => begin
                      values = ListUtil.map(inValues, System.tolower)
                      System.gettextInit(if getConfigString(RUNNING_TESTSUITE) == ""
                            getConfigString(LOCALE_FLAG)
                          else
                            "C"
                          end)
                      print(printHelp(values))
                      setConfigString(HELP, "omc")
                    ()
                  end

                  (_, _) where (configFlagEq(inFlag, PRE_OPT_MODULES_ADD))  => begin
                      setAdditionalOptModules(PRE_OPT_MODULES_ADD, PRE_OPT_MODULES_SUB, inValues)
                    ()
                  end

                  (_, _) where (configFlagEq(inFlag, PRE_OPT_MODULES_SUB))  => begin
                      setAdditionalOptModules(PRE_OPT_MODULES_SUB, PRE_OPT_MODULES_ADD, inValues)
                    ()
                  end

                  (_, _) where (configFlagEq(inFlag, POST_OPT_MODULES_ADD))  => begin
                      setAdditionalOptModules(POST_OPT_MODULES_ADD, POST_OPT_MODULES_SUB, inValues)
                    ()
                  end

                  (_, _) where (configFlagEq(inFlag, POST_OPT_MODULES_SUB))  => begin
                      setAdditionalOptModules(POST_OPT_MODULES_SUB, POST_OPT_MODULES_ADD, inValues)
                    ()
                  end

                  (_, _) where (configFlagEq(inFlag, INIT_OPT_MODULES_ADD))  => begin
                      setAdditionalOptModules(INIT_OPT_MODULES_ADD, INIT_OPT_MODULES_SUB, inValues)
                    ()
                  end

                  (_, _) where (configFlagEq(inFlag, INIT_OPT_MODULES_SUB))  => begin
                      setAdditionalOptModules(INIT_OPT_MODULES_SUB, INIT_OPT_MODULES_ADD, inValues)
                    ()
                  end

                  (_, FLAGS(configFlags = config_flags))  => begin
                      setConfigFlag(inFlag, config_flags, inValues)
                    ()
                  end
                end
              end
               #=  Special case for +h, +help, show help text.
               =#
               #=  Special case for --preOptModules+=<value>
               =#
               #=  Special case for --preOptModules-=<value>
               =#
               #=  Special case for --postOptModules+=<value>
               =#
               #=  Special case for --postOptModules-=<value>
               =#
               #=  Special case for --initOptModules+=<value>
               =#
               #=  Special case for --initOptModules-=<value>
               =#
               #=  All other configuration flags, set the flag to the given values.
               =#
        end

         #= Enables a debug flag given as a string, or disables it if it's prefixed with -. =#
        function setDebugFlag(inFlag::String, inFlags::Array{<:Bool})
              local negated::Bool
              local neg1::Bool
              local neg2::Bool
              local flag_str::String

              neg1 = stringEq(stringGetStringChar(inFlag, 1), "-")
              neg2 = System.strncmp("no", inFlag, 2) == 0
              negated = neg1 || neg2
              flag_str = if negated
                    Util.stringRest(inFlag)
                  else
                    inFlag
                  end
              flag_str = if neg2
                    Util.stringRest(flag_str)
                  else
                    flag_str
                  end
              setDebugFlag2(flag_str, ! negated, inFlags)
        end

        function setDebugFlag2(inFlag::String, inValue::Bool, inFlags::Array{<:Bool})
              _ = begin
                  local flag::DebugFlag
                @matchcontinue (inFlag, inValue, inFlags) begin
                  (_, _, _)  => begin
                      flag = ListUtil.getMemberOnTrue(inFlag, allDebugFlags, matchDebugFlag)
                      (_, _) = updateDebugFlagArray(inFlags, inValue, flag)
                    ()
                  end

                  _  => begin
                        Error.addMessage(Error.UNKNOWN_DEBUG_FLAG, list(inFlag))
                      fail()
                  end
                end
              end
        end

         #= Returns true if the given flag has the given name, otherwise false. =#
        function matchDebugFlag(inFlagName::String, inFlag::DebugFlag)::Bool
              local outMatches::Bool

              local name::String

              @match DEBUG_FLAG(name = name) = inFlag
              outMatches = stringEq(inFlagName, name)
          outMatches
        end

         #= Returns true if the given flag has the given name, otherwise false. =#
        function matchConfigFlag(inFlagName::String, inFlag::ConfigFlag)::Bool
              local outMatches::Bool

              local opt_shortname::Option{<:String}
              local name::String
              local shortname::String

               #=  A configuration flag may have two names, one long and one short.
               =#
              @match CONFIG_FLAG(name = name, shortname = opt_shortname) = inFlag
              shortname = Util.getOptionOrDefault(opt_shortname, "")
              outMatches = stringEq(inFlagName, shortname) || stringEq(System.tolower(inFlagName), System.tolower(name))
          outMatches
        end

         #= Sets the value of a configuration flag, where the value is given as a list of
          strings. =#
        function setConfigFlag(inFlag::ConfigFlag, inConfigData::Array{<:FlagData}, inValues::List{<:String})
              local data::FlagData
              local default_value::FlagData
              local name::String
              local validOptions::Option{<:ValidOptions}

              @match CONFIG_FLAG(name = name, defaultValue = default_value, validOptions = validOptions) = inFlag
              data = stringFlagData(inValues, default_value, validOptions, name)
              _ = updateConfigFlagArray(inConfigData, data, inFlag)
        end

         #= Converts a list of strings into a FlagData value. The expected type is also
           given so that the value can be typechecked. =#
        function stringFlagData(inValues::List{<:String}, inExpectedType::FlagData, validOptions::Option{<:ValidOptions}, inName::String)::FlagData
              local outValue::FlagData

              outValue = begin
                  local b::Bool
                  local i::ModelicaInteger
                  local ilst::List{<:ModelicaInteger}
                  local s::String
                  local et::String
                  local at::String
                  local enums::List{<:Tuple{<:String, ModelicaInteger}}
                  local flags::List{<:String}
                  local slst::List{<:String}
                  local options::ValidOptions
                   #=  A boolean value.
                   =#
                @matchcontinue (inValues, inExpectedType, validOptions, inName) begin
                  (s <|  nil(), BOOL_FLAG(), _, _)  => begin
                      b = Util.stringBool(s)
                    BOOL_FLAG(b)
                  end

                  ( nil(), BOOL_FLAG(), _, _)  => begin
                    BOOL_FLAG(true)
                  end

                  (s <|  nil(), INT_FLAG(), _, _)  => begin
                      i = stringInt(s)
                      @match true = stringEq(intString(i), s)
                    INT_FLAG(i)
                  end

                  (slst, INT_LIST_FLAG(), _, _)  => begin
                      ilst = ListUtil.map(slst, stringInt)
                    INT_LIST_FLAG(ilst)
                  end

                  (s <|  nil(), REAL_FLAG(), _, _)  => begin
                    REAL_FLAG(System.stringReal(s))
                  end

                  (s <|  nil(), STRING_FLAG(), SOME(options), _)  => begin
                      flags = getValidStringOptions(options)
                      @match true = listMember(s, flags)
                    STRING_FLAG(s)
                  end

                  (s <|  nil(), STRING_FLAG(), NONE(), _)  => begin
                    STRING_FLAG(s)
                  end

                  (_, STRING_LIST_FLAG(), _, _)  => begin
                    STRING_LIST_FLAG(inValues)
                  end

                  (s <|  nil(), ENUM_FLAG(validValues = enums), _, _)  => begin
                      i = Util.assoc(s, enums)
                    ENUM_FLAG(i, enums)
                  end

                  (_, _, NONE(), _)  => begin
                      et = printExpectedTypeStr(inExpectedType)
                      at = printActualTypeStr(inValues)
                      Error.addMessage(Error.INVALID_FLAG_TYPE, list(inName, et, at))
                    fail()
                  end

                  (_, _, SOME(options), _)  => begin
                      flags = getValidStringOptions(options)
                      et = stringDelimitList(flags, ", ")
                      at = printActualTypeStr(inValues)
                      Error.addMessage(Error.INVALID_FLAG_TYPE_STRINGS, list(inName, et, at))
                    fail()
                  end
                end
              end
               #=  No value, but a boolean flag => enable the flag.
               =#
               #=  An integer value.
               =#
               #=  integer list.
               =#
               #=  A real value.
               =#
               #=  A string value.
               =#
               #=  A multiple-string value.
               =#
               #=  An enumeration value.
               =#
               #=  Type mismatch, print error.
               =#
          outValue
        end

         #= Prints the expected type as a string. =#
        function printExpectedTypeStr(inType::FlagData)::String
              local outTypeStr::String

              outTypeStr = begin
                  local enums::List{<:Tuple{<:String, ModelicaInteger}}
                  local enum_strs::List{<:String}
                @match inType begin
                  BOOL_FLAG()  => begin
                    "a boolean value"
                  end

                  INT_FLAG()  => begin
                    "an integer value"
                  end

                  REAL_FLAG()  => begin
                    "a floating-point value"
                  end

                  STRING_FLAG()  => begin
                    "a string"
                  end

                  STRING_LIST_FLAG()  => begin
                    "a comma-separated list of strings"
                  end

                  ENUM_FLAG(validValues = enums)  => begin
                      enum_strs = ListUtil.map(enums, Util.tuple21)
                    "one of the values {" + stringDelimitList(enum_strs, ", ") + "}"
                  end
                end
              end
          outTypeStr
        end

         #= Prints the actual type as a string. =#
        function printActualTypeStr(inType::List{<:String})::String
              local outTypeStr::String

              outTypeStr = begin
                  local s::String
                  local i::ModelicaInteger
                @matchcontinue inType begin
                   nil()  => begin
                    "nothing"
                  end

                  s <|  nil()  => begin
                      Util.stringBool(s)
                    "the boolean value " + s
                  end

                  s <|  nil()  => begin
                      i = stringInt(s)
                      @match true = stringEq(intString(i), s)
                    "the number " + intString(i)
                  end

                  s <|  nil()  => begin
                    "the string \\" + s + "\\"
                  end

                  _  => begin
                      "a list of values."
                  end
                end
              end
               #=  intString returns 0 on failure, so this is to make sure that it
               =#
               #=  actually succeeded.
               =#
               #= case {s}
               =#
               #=   equation
               =#
               #=     System.stringReal(s);
               =#
               #=   then
               =#
               #=     \"the number \" + intString(i);
               =#
          outTypeStr
        end

         #= Checks if two config flags have the same index. =#
        function configFlagsIsEqualIndex(inFlag1::ConfigFlag, inFlag2::ConfigFlag)::Bool
              local outEqualIndex::Bool

              local index1::ModelicaInteger
              local index2::ModelicaInteger

              @match CONFIG_FLAG(index = index1) = inFlag1
              @match CONFIG_FLAG(index = index2) = inFlag2
              outEqualIndex = intEq(index1, index2)
          outEqualIndex
        end

         #= Some flags have side effects, which are handled by this function. =#
        function applySideEffects(inFlag::ConfigFlag, inValue::FlagData)
              _ = begin
                  local value::Bool
                  local corba_name::String
                  local corba_objid_path::String
                  local zeroMQFileSuffix::String
                   #=  +showErrorMessages needs to be sent to the C runtime.
                   =#
                @matchcontinue (inFlag, inValue) begin
                  (_, _)  => begin
                      @match true = configFlagsIsEqualIndex(inFlag, SHOW_ERROR_MESSAGES)
                      @match BOOL_FLAG(data = value) = inValue
                      ErrorExt.setShowErrorMessages(value)
                    ()
                  end

                  (_, _)  => begin
                      @match true = configFlagsIsEqualIndex(inFlag, CORBA_OBJECT_REFERENCE_FILE_PATH)
                      @match STRING_FLAG(data = corba_objid_path) = inValue
                      Corba.setObjectReferenceFilePath(corba_objid_path)
                    ()
                  end

                  (_, _)  => begin
                      @match true = configFlagsIsEqualIndex(inFlag, CORBA_SESSION)
                      @match STRING_FLAG(data = corba_name) = inValue
                      Corba.setSessionName(corba_name)
                    ()
                  end

                  _  => begin
                      ()
                  end
                end
              end
               #=  The corba object reference file path needs to be sent to the C runtime.
               =#
               #=  The corba session name needs to be sent to the C runtime.
               =#
        end

         #= Sets the value of a configuration flag. =#
        function setConfigValue(inFlag::ConfigFlag, inValue::FlagData)
              local debug_flags::Array{<:Bool}
              local config_flags::Array{<:FlagData}
              local flags::Flag

              flags = loadFlags()
              @match FLAGS(debug_flags, config_flags) = flags
              config_flags = updateConfigFlagArray(config_flags, inValue, inFlag)
              saveFlags(FLAGS(debug_flags, config_flags))
        end

         #= Sets the value of a boolean configuration flag. =#
        function setConfigBool(inFlag::ConfigFlag, inValue::Bool)
              setConfigValue(inFlag, BOOL_FLAG(inValue))
        end

         #= Sets the value of an integer configuration flag. =#
        function setConfigInt(inFlag::ConfigFlag, inValue::ModelicaInteger)
              setConfigValue(inFlag, INT_FLAG(inValue))
        end

         #= Sets the value of a real configuration flag. =#
        function setConfigReal(inFlag::ConfigFlag, inValue::ModelicaReal)
              setConfigValue(inFlag, REAL_FLAG(inValue))
        end

         #= Sets the value of a string configuration flag. =#
        function setConfigString(inFlag::ConfigFlag, inValue::String)
              setConfigValue(inFlag, STRING_FLAG(inValue))
        end

         #= Sets the value of a multiple-string configuration flag. =#
        function setConfigStringList(inFlag::ConfigFlag, inValue::List{<:String})
              setConfigValue(inFlag, STRING_LIST_FLAG(inValue))
        end

         #= Sets the value of an enumeration configuration flag. =#
        function setConfigEnum(inFlag::ConfigFlag, inValue::ModelicaInteger)
              local valid_values::List{<:Tuple{<:String, ModelicaInteger}}

              @match CONFIG_FLAG(defaultValue = ENUM_FLAG(validValues = valid_values)) = inFlag
              setConfigValue(inFlag, ENUM_FLAG(inValue, valid_values))
        end

         #= Returns the value of a configuration flag. =#
        function getConfigValue(inFlag::ConfigFlag)::FlagData
              local outValue::FlagData

              local config_flags::Array{<:FlagData}
              local index::ModelicaInteger
              local flags::Flag
              local name::String

              @match CONFIG_FLAG(name = name, index = index) = inFlag
              flags = loadFlags()
              @match FLAGS(configFlags = config_flags) = flags
              outValue = arrayGet(config_flags, index)
          outValue
        end

         #= Returns the value of a boolean configuration flag. =#
        function getConfigBool(inFlag::ConfigFlag)::Bool
              local outValue::Bool

              @match BOOL_FLAG(data = outValue) = getConfigValue(inFlag)
          outValue
        end

         #= Returns the value of an integer configuration flag. =#
        function getConfigInt(inFlag::ConfigFlag)::ModelicaInteger
              local outValue::ModelicaInteger

              @match INT_FLAG(data = outValue) = getConfigValue(inFlag)
          outValue
        end

         #= Returns the value of an integer configuration flag. =#
        function getConfigIntList(inFlag::ConfigFlag)::List{<:ModelicaInteger}
              local outValue::List{<:ModelicaInteger}

              @match INT_LIST_FLAG(data = outValue) = getConfigValue(inFlag)
          outValue
        end

         #= Returns the value of a real configuration flag. =#
        function getConfigReal(inFlag::ConfigFlag)::ModelicaReal
              local outValue::ModelicaReal

              @match REAL_FLAG(data = outValue) = getConfigValue(inFlag)
          outValue
        end

         #= Returns the value of a string configuration flag. =#
        function getConfigString(inFlag::ConfigFlag)::String
              local outValue::String

              @match STRING_FLAG(data = outValue) = getConfigValue(inFlag)
          outValue
        end

         #= Returns the value of a multiple-string configuration flag. =#
        function getConfigStringList(inFlag::ConfigFlag)::List{<:String}
              local outValue::List{<:String}

              @match STRING_LIST_FLAG(data = outValue) = getConfigValue(inFlag)
          outValue
        end

         #= Returns the valid options of a single-string configuration flag. =#
        function getConfigOptionsStringList(inFlag::ConfigFlag)::Tuple{List{<:String}, List{<:String}}
              local outComments::List{<:String}
              local outOptions::List{<:String}

              (outOptions, outComments) = begin
                  local options::List{<:Tuple{<:String, Util.TranslatableContent}}
                  local flags::List{<:String}
                @match inFlag begin
                  CONFIG_FLAG(validOptions = SOME(STRING_DESC_OPTION(options)))  => begin
                    (ListUtil.map(options, Util.tuple21), ListUtil.mapMap(options, Util.tuple22, Util.translateContent))
                  end

                  CONFIG_FLAG(validOptions = SOME(STRING_OPTION(flags)))  => begin
                    (flags, ListUtil.fill("", listLength(flags)))
                  end
                end
              end
          (outOptions, outComments)
        end

         #= Returns the value of an enumeration configuration flag. =#
        function getConfigEnum(inFlag::ConfigFlag)::ModelicaInteger
              local outValue::ModelicaInteger

              @match ENUM_FLAG(data = outValue) = getConfigValue(inFlag)
          outValue
        end

         #=  Used by the print functions below to indent descriptions.
         =#

         descriptionIndent = "                            "::String

         #= Prints out help for the given list of topics. =#
        function printHelp(inTopics::List{<:String})::String
              local help::String

              help = begin
                  local desc::Util.TranslatableContent
                  local rest_topics::List{<:String}
                  local strs::List{<:String}
                  local data::List{<:String}
                  local str::String
                  local name::String
                  local str1::String
                  local str1a::String
                  local str1b::String
                  local str2::String
                  local str3::String
                  local str3a::String
                  local str3b::String
                  local str4::String
                  local str5::String
                  local str5a::String
                  local str5b::String
                  local str6::String
                  local str7::String
                  local str7a::String
                  local str7b::String
                  local str8::String
                  local str9::String
                  local str9a::String
                  local str9b::String
                  local str10::String
                  local config_flag::ConfigFlag
                  local topics::List{<:Tuple{<:String, String}}
                @matchcontinue inTopics begin
                   nil()  => begin
                    printUsage()
                  end

                  "omc" <|  nil()  => begin
                    printUsage()
                  end

                  "omcall-sphinxoutput" <|  nil()  => begin
                    printUsageSphinxAll()
                  end

                  "topics" <|  nil()  => begin
                      topics = list(("omc", System.gettext("The command-line options available for omc.")), ("debug", System.gettext("Flags that enable debugging, diagnostics, and research prototypes.")), ("optmodules", System.gettext("Flags that determine which symbolic methods are used to produce the causalized equation system.")), ("simulation", System.gettext("The command-line options available for simulation executables generated by OpenModelica.")), ("<flagname>", System.gettext("Displays option descriptions for multi-option flag <flagname>.")), ("topics", System.gettext("This help-text.")))
                      str = System.gettext("The available topics (help(\\topics\\)) are as follows:\\n")
                      strs = ListUtil.map(topics, makeTopicString)
                      help = str + stringDelimitList(strs, "\\n") + "\\n"
                    help
                  end

                  "simulation" <|  nil()  => begin
                      help = System.gettext("The simulation executable takes the following flags:\\n\\n") + System.getSimulationHelpText(true)
                    help
                  end

                  "simulation-sphinxoutput" <|  nil()  => begin
                      help = System.gettext("The simulation executable takes the following flags:\\n\\n") + System.getSimulationHelpText(true, sphinx = true)
                    help
                  end

                  "debug" <|  nil()  => begin
                      str1 = System.gettext("The debug flag takes a comma-separated list of flags which are used by the\\ncompiler for debugging or experimental purposes.\\nFlags prefixed with \\-\\ or \\no\\ will be disabled.\\n")
                      str2 = System.gettext("The available flags are (+ are enabled by default, - are disabled):\\n\\n")
                      strs = list(printDebugFlag(flag) for flag in ListUtil.sort(allDebugFlags, compareDebugFlags))
                      help = stringAppendList(str1 <| str2 <| strs)
                    help
                  end

                  "optmodules" <|  nil()  => begin
                      str1 = System.gettext("The --preOptModules flag sets the optimization modules which are used before the\\nmatching and index reduction in the back end. These modules are specified as a comma-separated list.")
                      str1 = stringAppendList(StringUtil.wordWrap(str1, System.getTerminalWidth(), "\\n"))
                      @match CONFIG_FLAG(defaultValue = STRING_LIST_FLAG(data = data)) = PRE_OPT_MODULES
                      str1a = System.gettext("The modules used by default are:") + "\\n--preOptModules=" + stringDelimitList(data, ",")
                      str1b = System.gettext("The valid modules are:")
                      str2 = printFlagValidOptionsDesc(PRE_OPT_MODULES)
                      str3 = System.gettext("The --matchingAlgorithm sets the method that is used for the matching algorithm, after the pre optimization modules.")
                      str3 = stringAppendList(StringUtil.wordWrap(str3, System.getTerminalWidth(), "\\n"))
                      @match CONFIG_FLAG(defaultValue = STRING_FLAG(data = str3a)) = MATCHING_ALGORITHM
                      str3a = System.gettext("The method used by default is:") + "\\n--matchingAlgorithm=" + str3a
                      str3b = System.gettext("The valid methods are:")
                      str4 = printFlagValidOptionsDesc(MATCHING_ALGORITHM)
                      str5 = System.gettext("The --indexReductionMethod sets the method that is used for the index reduction, after the pre optimization modules.")
                      str5 = stringAppendList(StringUtil.wordWrap(str5, System.getTerminalWidth(), "\\n"))
                      @match CONFIG_FLAG(defaultValue = STRING_FLAG(data = str5a)) = INDEX_REDUCTION_METHOD
                      str5a = System.gettext("The method used by default is:") + "\\n--indexReductionMethod=" + str5a
                      str5b = System.gettext("The valid methods are:")
                      str6 = printFlagValidOptionsDesc(INDEX_REDUCTION_METHOD)
                      str7 = System.gettext("The --initOptModules then sets the optimization modules which are used after the index reduction to optimize the system for initialization, specified as a comma-separated list.")
                      str7 = stringAppendList(StringUtil.wordWrap(str7, System.getTerminalWidth(), "\\n"))
                      @match CONFIG_FLAG(defaultValue = STRING_LIST_FLAG(data = data)) = INIT_OPT_MODULES
                      str7a = System.gettext("The modules used by default are:") + "\\n--initOptModules=" + stringDelimitList(data, ",")
                      str7b = System.gettext("The valid modules are:")
                      str8 = printFlagValidOptionsDesc(INIT_OPT_MODULES)
                      str9 = System.gettext("The --postOptModules then sets the optimization modules which are used after the index reduction to optimize the system for simulation, specified as a comma-separated list.")
                      str9 = stringAppendList(StringUtil.wordWrap(str9, System.getTerminalWidth(), "\\n"))
                      @match CONFIG_FLAG(defaultValue = STRING_LIST_FLAG(data = data)) = POST_OPT_MODULES
                      str9a = System.gettext("The modules used by default are:") + "\\n--postOptModules=" + stringDelimitList(data, ",")
                      str9b = System.gettext("The valid modules are:")
                      str10 = printFlagValidOptionsDesc(POST_OPT_MODULES)
                      help = stringAppendList(list(str1, "\\n\\n", str1a, "\\n\\n", str1b, "\\n", str2, "\\n", str3, "\\n\\n", str3a, "\\n\\n", str3b, "\\n", str4, "\\n", str5, "\\n\\n", str5a, "\\n\\n", str5b, "\\n", str6, "\\n", str7, "\\n\\n", str7a, "\\n\\n", str7b, "\\n", str8, "\\n", str9, "\\n\\n", str9a, "\\n\\n", str9b, "\\n", str10, "\\n"))
                    help
                  end

                  str <|  nil()  => begin
                      @match (@match CONFIG_FLAG(name = name, description = desc) = config_flag) = ListUtil.getMemberOnTrue(str, allConfigFlags, matchConfigFlag)
                      str1 = "-" + name
                      str2 = stringAppendList(StringUtil.wordWrap(Util.translateContent(desc), System.getTerminalWidth(), "\\n"))
                      str = printFlagValidOptionsDesc(config_flag)
                      help = stringAppendList(list(str1, "\\n", str2, "\\n", str))
                    help
                  end

                  str <|  nil()  => begin
                    "I'm sorry, I don't know what " + str + " is.\\n"
                  end

                  str <| rest_topics && _ <| _  => begin
                      str = printHelp(list(str)) + "\\n"
                      help = printHelp(rest_topics)
                    str + help
                  end
                end
              end
               #= case {\"mos\"} then System.gettext(\"TODO: Write help-text\");
               =#
               #= (\"mos\",System.gettext(\"Help on the command-line and scripting environments, including OMShell and OMNotebook.\")),
               =#
               #=  pre-optimization
               =#
               #=  matching
               =#
               #=  index reduction
               =#
               #=  post-optimization (initialization)
               =#
               #=  post-optimization (simulation)
               =#
          help
        end

        function getValidOptionsAndDescription(flagName::String)::Tuple{List{<:String}, String, List{<:String}}
              local descriptions::List{<:String}
              local mainDescriptionStr::String
              local validStrings::List{<:String}

              local validOptions::ValidOptions
              local mainDescription::Util.TranslatableContent

              @match CONFIG_FLAG(description = mainDescription, validOptions = SOME(validOptions)) = ListUtil.getMemberOnTrue(flagName, allConfigFlags, matchConfigFlag)
              mainDescriptionStr = Util.translateContent(mainDescription)
              (validStrings, descriptions) = getValidOptionsAndDescription2(validOptions)
          (validStrings, mainDescriptionStr, descriptions)
        end

        function getValidOptionsAndDescription2(validOptions::ValidOptions)::Tuple{List{<:String}, List{<:String}}
              local descriptions::List{<:String}
              local validStrings::List{<:String}

              (validStrings, descriptions) = begin
                  local options::List{<:Tuple{<:String, Util.TranslatableContent}}
                @match validOptions begin
                  STRING_OPTION(validStrings)  => begin
                    (validStrings, list())
                  end

                  STRING_DESC_OPTION(options)  => begin
                      validStrings = ListUtil.map(options, Util.tuple21)
                      descriptions = ListUtil.mapMap(options, Util.tuple22, Util.translateContent)
                    (validStrings, descriptions)
                  end
                end
              end
          (validStrings, descriptions)
        end

        function compareDebugFlags(flag1::DebugFlag, flag2::DebugFlag)::Bool
              local b::Bool

              local name1::String
              local name2::String

              @match DEBUG_FLAG(name = name1) = flag1
              @match DEBUG_FLAG(name = name2) = flag2
              b = stringCompare(name1, name2) > 0
          b
        end

        function makeTopicString(topic::Tuple{<:String, String})::String
              local str::String

              local str1::String
              local str2::String

              (str1, str2) = topic
              str1 = Util.stringPadRight(str1, 13, " ")
              str = stringAppendList(StringUtil.wordWrap(str1 + str2, System.getTerminalWidth(), "\\n               "))
          str
        end

         #= Prints out the usage text for the compiler. =#
        function printUsage()::String
              local usage::String

              Print.clearBuf()
              Print.printBuf("OpenModelica Compiler ")
              Print.printBuf(Settings.getVersionNr())
              Print.printBuf("\\n")
              Print.printBuf(System.gettext("Copyright © 2019 Open Source Modelica Consortium (OSMC)\\n"))
              Print.printBuf(System.gettext("Distributed under OMSC-PL and GPL, see www.openmodelica.org\\n\\n"))
               #= Print.printBuf(\"Please check the System Guide for full information about flags.\\n\");
               =#
              Print.printBuf(System.gettext("Usage: omc [Options] (Model.mo | Script.mos) [Libraries | .mo-files] \\n* Libraries: Fully qualified names of libraries to load before processing Model or Script.\\n             The libraries should be separated by spaces: Lib1 Lib2 ... LibN.\\n"))
              Print.printBuf(System.gettext("\\n* Options:\\n"))
              Print.printBuf(printAllConfigFlags())
              Print.printBuf(System.gettext("\\nFor more details on a specific topic, use --help=topics or help(\\topics\\)\\n\\n"))
              Print.printBuf(System.gettext("* Examples:\\n"))
              Print.printBuf(System.gettext("  omc Model.mo             will produce flattened Model on standard output.\\n"))
              Print.printBuf(System.gettext("  omc -s Model.mo          will produce simulation code for the model:\\n"))
              Print.printBuf(System.gettext("                            * Model.c           The model C code.\\n"))
              Print.printBuf(System.gettext("                            * Model_functions.c The model functions C code.\\n"))
              Print.printBuf(System.gettext("                            * Model.makefile    The makefile to compile the model.\\n"))
              Print.printBuf(System.gettext("                            * Model_init.xml    The initial values.\\n"))
               #= Print.printBuf(\"\\tomc Model.mof            will produce flattened Model on standard output\\n\");
               =#
              Print.printBuf(System.gettext("  omc Script.mos           will run the commands from Script.mos.\\n"))
              Print.printBuf(System.gettext("  omc Model.mo Modelica    will first load the Modelica library and then produce \\n                            flattened Model on standard output.\\n"))
              Print.printBuf(System.gettext("  omc Model1.mo Model2.mo  will load both Model1.mo and Model2.mo, and produce \\n                            flattened Model1 on standard output.\\n"))
              Print.printBuf(System.gettext("  *.mo (Modelica files) \\n"))
               #= Print.printBuf(\"\\t*.mof (Flat Modelica files) \\n\");
               =#
              Print.printBuf(System.gettext("  *.mos (Modelica Script files)\\n\\n"))
              Print.printBuf(System.gettext("For available simulation flags, use --help=simulation.\\n\\n"))
              Print.printBuf(System.gettext("Documentation is available in the built-in package OpenModelica.Scripting or\\nonline <https://build.openmodelica.org/Documentation/OpenModelica.Scripting.html>.\\n"))
              usage = Print.getString()
              Print.clearBuf()
          usage
        end

         #= Prints out the usage text for the compiler. =#
        function printUsageSphinxAll()::String
              local usage::String

              local s::String

              Print.clearBuf()
              s = "OpenModelica Compiler Flags"
              Print.printBuf(s)
              Print.printBuf("\\n")
              Print.printBuf(sum("=" for e in 1:stringLength(s)))
              Print.printBuf("\\n")
              Print.printBuf(System.gettext("Usage: omc [Options] (Model.mo | Script.mos) [Libraries | .mo-files]\\n\\n* Libraries: Fully qualified names of libraries to load before processing Model or Script.\\n  The libraries should be separated by spaces: Lib1 Lib2 ... LibN.\\n"))
              Print.printBuf("\\n.. _omcflags-options :\\n\\n")
              s = System.gettext("Options")
              Print.printBuf(s)
              Print.printBuf("\\n")
              Print.printBuf(sum("-" for e in 1:stringLength(s)))
              Print.printBuf("\\n\\n")
              for flag in allConfigFlags
                Print.printBuf(printConfigFlagSphinx(flag))
              end
              Print.printBuf("\\n.. _omcflag-debug-section:\\n\\n")
              s = System.gettext("Debug flags")
              Print.printBuf(s)
              Print.printBuf("\\n")
              Print.printBuf(sum("-" for e in 1:stringLength(s)))
              Print.printBuf("\\n\\n")
              Print.printBuf(System.gettext("The debug flag takes a comma-separated list of flags which are used by the\\ncompiler for debugging or experimental purposes.\\nFlags prefixed with \\-\\ or \\no\\ will be disabled.\\n"))
              Print.printBuf(System.gettext("The available flags are (+ are enabled by default, - are disabled):\\n\\n"))
              for flag in ListUtil.sort(allDebugFlags, compareDebugFlags)
                Print.printBuf(printDebugFlag(flag, sphinx = true))
              end
              Print.printBuf("\\n.. _omcflag-optmodules-section:\\n\\n")
              s = System.gettext("Flags for Optimization Modules")
              Print.printBuf(s)
              Print.printBuf("\\n")
              Print.printBuf(sum("-" for e in 1:stringLength(s)))
              Print.printBuf("\\n\\n")
              Print.printBuf("Flags that determine which symbolic methods are used to produce the causalized equation system.\\n\\n")
              Print.printBuf(System.gettext("The :ref:`--preOptModules <omcflag-preOptModules>` flag sets the optimization modules which are used before the\\nmatching and index reduction in the back end. These modules are specified as a comma-separated list."))
              Print.printBuf("\\n\\n")
              Print.printBuf(System.gettext("The :ref:`--matchingAlgorithm <omcflag-matchingAlgorithm>` sets the method that is used for the matching algorithm, after the pre optimization modules."))
              Print.printBuf("\\n\\n")
              Print.printBuf(System.gettext("The :ref:`--indexReductionMethod <omcflag-indexReductionMethod>` sets the method that is used for the index reduction, after the pre optimization modules."))
              Print.printBuf("\\n\\n")
              Print.printBuf(System.gettext("The :ref:`--initOptModules <omcflag-initOptModules>` then sets the optimization modules which are used after the index reduction to optimize the system for initialization, specified as a comma-separated list."))
              Print.printBuf("\\n\\n")
              Print.printBuf(System.gettext("The :ref:`--postOptModules <omcflag-postOptModules>` then sets the optimization modules which are used after the index reduction to optimize the system for simulation, specified as a comma-separated list."))
              Print.printBuf("\\n\\n")
              usage = Print.getString()
              Print.clearBuf()
          usage
        end

         #= Prints all configuration flags to a string. =#
        function printAllConfigFlags()::String
              local outString::String

              outString = stringAppendList(ListUtil.map(allConfigFlags, printConfigFlag))
          outString
        end

         #= Prints a configuration flag to a string. =#
        function printConfigFlag(inFlag::ConfigFlag)::String
              local outString::String

              outString = begin
                  local desc::Util.TranslatableContent
                  local name::String
                  local desc_str::String
                  local flag_str::String
                  local delim_str::String
                  local opt_str::String
                  local wrapped_str::List{<:String}
                @match inFlag begin
                  CONFIG_FLAG(visibility = INTERNAL())  => begin
                    ""
                  end

                  CONFIG_FLAG(description = desc)  => begin
                      desc_str = Util.translateContent(desc)
                      name = Util.stringPadRight(printConfigFlagName(inFlag), 28, " ")
                      flag_str = stringAppendList(list(name, " ", desc_str))
                      delim_str = descriptionIndent + "  "
                      wrapped_str = StringUtil.wordWrap(flag_str, System.getTerminalWidth(), delim_str)
                      opt_str = printValidOptions(inFlag)
                      flag_str = stringDelimitList(wrapped_str, "\\n") + opt_str + "\\n"
                    flag_str
                  end
                end
              end
          outString
        end

         #= Prints a configuration flag to a restructured text string. =#
        function printConfigFlagSphinx(inFlag::ConfigFlag)::String
              local outString::String

              outString = begin
                  local desc::Util.TranslatableContent
                  local name::String
                  local longName::String
                  local desc_str::String
                  local flag_str::String
                  local delim_str::String
                  local opt_str::String
                  local wrapped_str::List{<:String}
                @match inFlag begin
                  CONFIG_FLAG(visibility = INTERNAL())  => begin
                    ""
                  end

                  CONFIG_FLAG(description = desc)  => begin
                      desc_str = Util.translateContent(desc)
                      desc_str = System.stringReplace(desc_str, "--help=debug", ":ref:`--help=debug <omcflag-debug-section>`")
                      desc_str = System.stringReplace(desc_str, "--help=optmodules", ":ref:`--help=optmodules <omcflag-optmodules-section>`")
                      (name, longName) = printConfigFlagName(inFlag, sphinx = true)
                      opt_str = printValidOptionsSphinx(inFlag)
                      flag_str = stringAppendList(list(".. _omcflag-", longName, ":\\n\\n:ref:`", name, "<omcflag-", longName, ">`\\n\\n", desc_str, "\\n", opt_str + "\\n"))
                    flag_str
                  end
                end
              end
          outString
        end

         #= Prints out the name of a configuration flag, formatted for use by
           printConfigFlag. =#
        function printConfigFlagName(inFlag::ConfigFlag, sphinx::Bool = false)::Tuple{String, String}
              local longName::String
              local outString::String

              (outString, longName) = begin
                  local name::String
                  local shortname::String
                @match inFlag begin
                  CONFIG_FLAG(name = name, shortname = SOME(shortname))  => begin
                      shortname = if sphinx
                            "-" + shortname
                          else
                            Util.stringPadLeft("-" + shortname, 4, " ")
                          end
                    (stringAppendList(list(shortname, ", --", name)), name)
                  end

                  CONFIG_FLAG(name = name, shortname = NONE())  => begin
                    ((if sphinx
                          "--"
                        else
                          "      --"
                        end) + name, name)
                  end
                end
              end
          (outString, longName)
        end

         #= Prints out the valid options of a configuration flag to a string. =#
        function printValidOptions(inFlag::ConfigFlag)::String
              local outString::String

              outString = begin
                  local strl::List{<:String}
                  local opt_str::String
                  local descl::List{<:Tuple{<:String, Util.TranslatableContent}}
                @match inFlag begin
                  CONFIG_FLAG(validOptions = NONE())  => begin
                    ""
                  end

                  CONFIG_FLAG(validOptions = SOME(STRING_OPTION(options = strl)))  => begin
                      opt_str = descriptionIndent + "   " + System.gettext("Valid options:") + " " + stringDelimitList(strl, ", ")
                      strl = StringUtil.wordWrap(opt_str, System.getTerminalWidth(), descriptionIndent + "     ")
                      opt_str = stringDelimitList(strl, "\\n")
                      opt_str = "\\n" + opt_str
                    opt_str
                  end

                  CONFIG_FLAG(validOptions = SOME(STRING_DESC_OPTION(options = descl)))  => begin
                      opt_str = "\\n" + descriptionIndent + "   " + System.gettext("Valid options:") + "\\n" + stringAppendList(list(printFlagOptionDescShort(d) for d in descl))
                    opt_str
                  end
                end
              end
          outString
        end

         #= Prints out the valid options of a configuration flag to a string. =#
        function printValidOptionsSphinx(inFlag::ConfigFlag)::String
              local outString::String

              outString = begin
                  local strl::List{<:String}
                  local opt_str::String
                  local descl::List{<:Tuple{<:String, Util.TranslatableContent}}
                @match inFlag begin
                  CONFIG_FLAG(validOptions = NONE())  => begin
                    "\\n" + defaultFlagSphinx(inFlag.defaultValue) + "\\n"
                  end

                  CONFIG_FLAG(validOptions = SOME(STRING_OPTION(options = strl)))  => begin
                      opt_str = "\\n" + defaultFlagSphinx(inFlag.defaultValue) + " " + System.gettext("Valid options") + ":\\n\\n" + sum("* " + s + "\\n" for s in strl)
                    opt_str
                  end

                  CONFIG_FLAG(validOptions = SOME(STRING_DESC_OPTION(options = descl)))  => begin
                      opt_str = "\\n" + defaultFlagSphinx(inFlag.defaultValue) + " " + System.gettext("Valid options") + ":\\n\\n" + sum(printFlagOptionDesc(s, sphinx = true) for s in descl)
                    opt_str
                  end
                end
              end
          outString
        end

        function defaultFlagSphinx(flag::FlagData)::String
              local str::String

              str = begin
                  local i::ModelicaInteger
                @match flag begin
                  BOOL_FLAG()  => begin
                    System.gettext("Boolean (default") + " ``" + boolString(flag.data) + "``)."
                  end

                  INT_FLAG()  => begin
                    System.gettext("Integer (default") + " ``" + intString(flag.data) + "``)."
                  end

                  REAL_FLAG()  => begin
                    System.gettext("Real (default") + " ``" + realString(flag.data) + "``)."
                  end

                  STRING_FLAG("")  => begin
                    System.gettext("String (default *empty*).")
                  end

                  STRING_FLAG()  => begin
                    System.gettext("String (default") + " " + flag.data + ")."
                  end

                  STRING_LIST_FLAG(data =  nil())  => begin
                    System.gettext("String list (default *empty*).")
                  end

                  STRING_LIST_FLAG()  => begin
                    System.gettext("String list (default") + " " + stringDelimitList(flag.data, ",") + ")."
                  end

                  ENUM_FLAG()  => begin
                      for f in flag.validValues
                        (str, i) = f
                        if i == flag.data
                          str = System.gettext("String (default ") + " " + str + ")."
                          return
                        end
                      end
                    "#ENUM_FLAG Failed#" + anyString(flag)
                  end

                  _  => begin
                      "Unknown default value" + anyString(flag)
                  end
                end
              end
          str
        end

         #= Prints out the name of a flag option. =#
        function printFlagOptionDescShort(inOption::Tuple{<:String, Util.TranslatableContent}, sphinx::Bool = false)::String
              local outString::String

              local name::String

              (name, _) = inOption
              outString = (if sphinx
                    "* "
                  else
                    descriptionIndent + "    * "
                  end) + name + "\\n"
          outString
        end

         #= Prints out the names and descriptions of the valid options for a
           configuration flag. =#
        function printFlagValidOptionsDesc(inFlag::ConfigFlag)::String
              local outString::String

              local options::List{<:Tuple{<:String, Util.TranslatableContent}}

              @match CONFIG_FLAG(validOptions = SOME(STRING_DESC_OPTION(options = options))) = inFlag
              outString = sum(printFlagOptionDesc(o) for o in options)
          outString
        end

        function sphinxMathMode(s::String)::String
              local o::String = s

              local i::ModelicaInteger
              local strs::List{<:String}
              local s1::String
              local s2::String
              local s3::String

              (i, strs) = System.regex(o, "^(.*)[]([^]*)[](.*)", 4, extended = true)
              if i == 4
                @match _ <| s1 <| s2 <| s3 <| _ = strs
                o = s1 + " :math:`" + s2 + "` " + s3
              end
          o
        end

        function removeSphinxMathMode(s::String)::String
              local o::String = s

              local i::ModelicaInteger
              local strs::List{<:String}
              local s1::String
              local s2::String
              local s3::String

              (i, strs) = System.regex(o, "^(.*):math:`([^`]*)[`](.*)", 4, extended = true)
              if i == 4
                o = removeSphinxMathMode(stringAppendList(listRest(strs)))
              end
          o
        end

         #= Helper function to printFlagValidOptionsDesc. =#
        function printFlagOptionDesc(inOption::Tuple{<:String, Util.TranslatableContent}, sphinx::Bool = false)::String
              local outString::String

              local desc::Util.TranslatableContent
              local name::String
              local desc_str::String
              local str::String

              (name, desc) = inOption
              desc_str = Util.translateContent(desc)
              if sphinx
                desc_str = sum(System.trim(s) for s in System.strtok(desc_str, "\\n"))
                outString = "* " + name + " (" + desc_str + ")\\n"
              else
                str = Util.stringPadRight(" * " + name + " ", 30, " ") + removeSphinxMathMode(desc_str)
                outString = stringDelimitList(StringUtil.wordWrap(str, System.getTerminalWidth(), descriptionIndent + "    "), "\\n") + "\\n"
              end
          outString
        end

         #= Prints out name and description of a debug flag. =#
        function printDebugFlag(inFlag::DebugFlag, sphinx::Bool = false)::String
              local outString::String

              local desc::Util.TranslatableContent
              local name::String
              local desc_str::String
              local default::Bool

              @match DEBUG_FLAG(default = default, name = name, description = desc) = inFlag
              desc_str = Util.translateContent(desc)
              if sphinx
                desc_str = stringDelimitList(list(System.trim(s) for s in System.strtok(desc_str, "\\n")), "\\n  ")
                outString = "\\n.. _omcflag-debug-" + name + ":\\n\\n" + ":ref:`" + name + " <omcflag-debug-" + name + ">`" + " (default: " + (if default
                      "on"
                    else
                      "off"
                    end) + ")\\n  " + desc_str + "\\n"
              else
                outString = Util.stringPadRight((if default
                      " + "
                    else
                      " - "
                    end) + name + " ", 26, " ") + removeSphinxMathMode(desc_str)
                outString = stringDelimitList(StringUtil.wordWrap(outString, System.getTerminalWidth(), descriptionIndent), "\\n") + "\\n"
              end
          outString
        end

         #= Prints out name of a debug flag. =#
        function debugFlagName(inFlag::DebugFlag)::String
              local name::String

              @match DEBUG_FLAG(name = name) = inFlag
          name
        end

         #= Prints out name of a debug flag. =#
        function configFlagName(inFlag::ConfigFlag)::String
              local name::String

              @match CONFIG_FLAG(name = name) = inFlag
          name
        end

        function getValidStringOptions(inOptions::ValidOptions)::List{<:String}
              local validOptions::List{<:String}

              validOptions = begin
                  local options::List{<:Tuple{<:String, Util.TranslatableContent}}
                @match inOptions begin
                  STRING_OPTION(validOptions)  => begin
                    validOptions
                  end

                  STRING_DESC_OPTION(options)  => begin
                    ListUtil.map(options, Util.tuple21)
                  end
                end
              end
          validOptions
        end

        function flagDataEq(data1::FlagData, data2::FlagData)::Bool
              local eq::Bool

              eq = begin
                @match (data1, data2) begin
                  (EMPTY_FLAG(), EMPTY_FLAG())  => begin
                    true
                  end

                  (BOOL_FLAG(), BOOL_FLAG())  => begin
                    data1.data == data2.data
                  end

                  (INT_FLAG(), INT_FLAG())  => begin
                    data1.data == data2.data
                  end

                  (INT_LIST_FLAG(), INT_LIST_FLAG())  => begin
                    ListUtil.isEqualOnTrue(data1.data, data2.data, intEq)
                  end

                  (REAL_FLAG(), REAL_FLAG())  => begin
                    data1.data == data2.data
                  end

                  (STRING_FLAG(), STRING_FLAG())  => begin
                    data1.data == data2.data
                  end

                  (STRING_LIST_FLAG(), STRING_LIST_FLAG())  => begin
                    ListUtil.isEqualOnTrue(data1.data, data2.data, stringEq)
                  end

                  (ENUM_FLAG(), ENUM_FLAG())  => begin
                    referenceEq(data1.validValues, data2.validValues) && data1.data == data2.data
                  end

                  _  => begin
                      false
                  end
                end
              end
          eq
        end

        function flagDataString(flagData::FlagData)::String
              local str::String

              str = begin
                @match flagData begin
                  BOOL_FLAG()  => begin
                    boolString(flagData.data)
                  end

                  INT_FLAG()  => begin
                    intString(flagData.data)
                  end

                  INT_LIST_FLAG()  => begin
                    ListUtil.toString(flagData.data, intString, "", "", ",", "", false)
                  end

                  REAL_FLAG()  => begin
                    realString(flagData.data)
                  end

                  STRING_FLAG()  => begin
                    flagData.data
                  end

                  STRING_LIST_FLAG()  => begin
                    stringDelimitList(flagData.data, ",")
                  end

                  ENUM_FLAG()  => begin
                    Util.tuple21(listGet(flagData.validValues, flagData.data))
                  end

                  _  => begin
                      ""
                  end
                end
              end
          str
        end

         #= Goes through all the existing flags, and returns a list of all flags with
           values that differ from the default. The format of each string is flag=value. =#
        function unparseFlags()::List{<:String}
              local flagStrings::List{<:String} = list()

              local flags::Flag
              local debug_flags::Array{<:Bool}
              local config_flags::Array{<:FlagData}
              local name::String
              local strl::List{<:String} = list()

              try
                @match FLAGS(debugFlags = debug_flags, configFlags = config_flags) = loadFlags(false)
              catch
                return flagStrings
              end
              for f in allConfigFlags
                if ! flagDataEq(f.defaultValue, config_flags[f.index])
                  name = begin
                    @match f.shortname begin
                      SOME(name)  => begin
                        "-" + name
                      end

                      _  => begin
                          "--" + f.name
                      end
                    end
                  end
                  flagStrings = name + "=" + flagDataString(config_flags[f.index]) <| flagStrings
                end
              end
              for f in allDebugFlags
                if f.default != debug_flags[f.index]
                  strl = f.name <| strl
                end
              end
              if ! listEmpty(strl)
                flagStrings = "-d=" + stringDelimitList(strl, ",") <| flagStrings
              end
          flagStrings
        end

    #= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
    @exportAll()
  end
