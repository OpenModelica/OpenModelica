/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package Flags
" file:        Flags.mo
  package:     Flags
  description: Tools for using compiler flags.

  This package contains function for using compiler flags. There are two types
  of flags, debug flag and configuration flags. The flags are stored and
  retrieved with set/getGlobalRoot so that they can be accessed everywhere in
  the compiler.

  Configuration flags are flags such as --std which affects the behaviour of the
  compiler. These flags can have different types, see the FlagData uniontype
  below, and they also have a default value. There is also another package,
  Config, which acts as a wrapper for many of these flags.

  Debug flags are boolean flags specified with -d, which can be used together
  with the Debug package. They are typically used to enable printing of extra
  information that helps debugging, such as the failtrace flag. Unlike
  configuration flags they are only on or off, i.e. true or false.

  To add a new flag, simply add a new constant of either DebugFlag or ConfigFlag
  type below, and then add it to either the allDebugFlags or allConfigFlags list
  (in FlagsUtil.mo),  depending on which type it is.
  "

public
protected
import Global;

public uniontype DebugFlag
  record DEBUG_FLAG
    Integer index "Unique index.";
    String name "The name of the flag used by -d";
    Boolean default "Default enabled or not";
    String description "A description of the flag.";
  end DEBUG_FLAG;
end DebugFlag;

public uniontype ConfigFlag
  record CONFIG_FLAG
    Integer index "Unique index.";
    String name "The whole name of the flag.";
    Option<String> shortname "A short name one-character name for the flag.";
    FlagVisibility visibility "Whether the flag is visible to the user or not.";
    FlagData defaultValue "The default value of the flag.";
    Option<ValidOptions> validOptions "The valid options for the flag.";
    String description "A description of the flag.";
  end CONFIG_FLAG;
end ConfigFlag;

public uniontype FlagData
  "This uniontype is used to store the values of configuration flags."

  record EMPTY_FLAG
    "Only used to initialize the flag array."
  end EMPTY_FLAG;

  record BOOL_FLAG
    Boolean data "Value of a boolean flag.";
  end BOOL_FLAG;

  record INT_FLAG
    Integer data "Value of an integer flag.";
  end INT_FLAG;

  record INT_LIST_FLAG
    list<Integer> data "Value of an integer flag that can have multiple values.";
  end INT_LIST_FLAG;

  record REAL_FLAG
    Real data "Value of a real flag.";
  end REAL_FLAG;

  record STRING_FLAG
    String data "Value of a string flag.";
  end STRING_FLAG;

  record STRING_LIST_FLAG
    list<String> data "Values of a string flag that can have multiple values.";
  end STRING_LIST_FLAG;

  record ENUM_FLAG
    Integer data "Value of an enumeration flag.";
    list<tuple<String, Integer>> validValues "The valid values of the enum.";
  end ENUM_FLAG;
end FlagData;

public uniontype FlagVisibility
  "This uniontype is used to specify the visibility of a configuration flag."
  record INTERNAL "An internal flag that is hidden to the user." end INTERNAL;
  record EXTERNAL "An external flag that is visible to the user." end EXTERNAL;
end FlagVisibility;

public uniontype Flag
  "The structure which stores the flags."
  record FLAGS
    array<Boolean> debugFlags;
    array<FlagData> configFlags;
  end FLAGS;

  record NO_FLAGS end NO_FLAGS;
end Flag;

public uniontype ValidOptions
  "Specifies valid options for a flag."

  record STRING_OPTION
    list<String> options "Options for a string flag.";
  end STRING_OPTION;

  record STRING_DESC_OPTION
    list<tuple<String, String>> options
      "Options for a string flag, with a description for each option.";
  end STRING_DESC_OPTION;
end ValidOptions;

// Change this to a proper enum when we have support for them.
public constant Integer MODELICA = 1;
public constant Integer METAMODELICA = 2;
public constant Integer PARMODELICA = 3;
public constant Integer OPTIMICA = 4;
public constant Integer PDEMODELICA = 5;

// FMI-ModelDescription-ENUM-FLAGS
public constant Integer FMI_NONE = 1;
public constant Integer FMI_INTERNAL = 2;
public constant Integer FMI_PROTECTED = 3;
public constant Integer FMI_BLACKBOX = 4;

constant String collapseArrayExpressionsText = "Simplifies {x[1],x[2],x[3]} → x for arrays of whole variable references (simplifies code generation).";

// DEBUG FLAGS
public
constant DebugFlag FAILTRACE = DEBUG_FLAG(1, "failtrace", false,
  "Sets whether to print a failtrace or not.");
constant DebugFlag CEVAL = DEBUG_FLAG(2, "ceval", false,
  "Prints extra information from Ceval.");
constant DebugFlag CHECK_BACKEND_DAE = DEBUG_FLAG(3, "checkBackendDae", false,
  "Do some simple analyses on the datastructure from the frontend to check if it is consistent.");
constant DebugFlag PTHREADS = DEBUG_FLAG(4, "pthreads", false,
  "Experimental: Unused parallelization.");
constant DebugFlag EVENTS = DEBUG_FLAG(5, "events", true,
  "Turns on/off events handling.");
constant DebugFlag DUMP_INLINE_SOLVER = DEBUG_FLAG(6, "dumpInlineSolver", false,
  "Dumps the inline solver equation system.");
constant DebugFlag EVAL_FUNC = DEBUG_FLAG(7, "evalfunc", true,
  "Turns on/off symbolic function evaluation.");
constant DebugFlag GEN = DEBUG_FLAG(8, "gen", false,
  "Turns on/off dynamic loading of functions that are compiled during translation. Only enable this if external functions are needed to calculate structural parameters or constants.");
constant DebugFlag DYN_LOAD = DEBUG_FLAG(9, "dynload", false,
  "Display debug information about dynamic loading of compiled functions.");
constant DebugFlag GENERATE_CODE_CHEAT = DEBUG_FLAG(10, "generateCodeCheat", false,
  "Used to generate code for the bootstrapped compiler.");
constant DebugFlag CGRAPH_GRAPHVIZ_FILE = DEBUG_FLAG(11, "cgraphGraphVizFile", false,
  "Generates a graphviz file of the connection graph.");
constant DebugFlag CGRAPH_GRAPHVIZ_SHOW = DEBUG_FLAG(12, "cgraphGraphVizShow", false,
  "Displays the connection graph with the GraphViz lefty tool.");
constant DebugFlag GC_PROF = DEBUG_FLAG(13, "gcProfiling", false,
  "Prints garbage collection stats to standard output.");
constant DebugFlag CHECK_DAE_CREF_TYPE = DEBUG_FLAG(14, "checkDAECrefType", false,
  "Enables extra type checking for cref expressions.");
constant DebugFlag CHECK_ASUB = DEBUG_FLAG(15, "checkASUB", false,
  "Prints out a warning if an ASUB is created from a CREF expression.");
constant DebugFlag INSTANCE = DEBUG_FLAG(16, "instance", false,
  "Prints extra failtrace from InstanceHierarchy.");
constant DebugFlag CACHE = DEBUG_FLAG(17, "Cache", true,
  "Turns off the instantiation cache.");
constant DebugFlag RML = DEBUG_FLAG(18, "rml", false,
  "Converts Modelica-style arrays to lists.");
constant DebugFlag TAIL = DEBUG_FLAG(19, "tail", false,
  "Prints out a notification if tail recursion optimization has been applied.");
constant DebugFlag LOOKUP = DEBUG_FLAG(20, "lookup", false,
  "Print extra failtrace from lookup.");
constant DebugFlag PATTERNM_SKIP_FILTER_UNUSED_AS_BINDINGS = DEBUG_FLAG(21, "patternmSkipFilterUnusedBindings", false,
  "");
constant DebugFlag PATTERNM_ALL_INFO = DEBUG_FLAG(22, "patternmAllInfo", false,
  "Adds notifications of all pattern-matching optimizations that are performed.");
constant DebugFlag PATTERNM_DCE = DEBUG_FLAG(23, "patternmDeadCodeElimination", true,
  "Performs dead code elimination in match-expressions.");
constant DebugFlag PATTERNM_MOVE_LAST_EXP = DEBUG_FLAG(24, "patternmMoveLastExp", true,
  "Optimization that moves the last assignment(s) into the result of a match-expression. For example: equation c = fn(b); then c; => then fn(b);");
constant DebugFlag EXPERIMENTAL_REDUCTIONS = DEBUG_FLAG(25, "experimentalReductions", false,
  "Turns on custom reduction functions (OpenModelica extension).");
constant DebugFlag EVAL_PARAM = DEBUG_FLAG(26, "evaluateAllParameters", false,
  "Evaluates all parameters if set, except the ones that have annotation(Evaluate = false).");
constant DebugFlag TYPES = DEBUG_FLAG(27, "types", false,
  "Prints extra failtrace from Types.");
constant DebugFlag SHOW_STATEMENT = DEBUG_FLAG(28, "showStatement", false,
  "Shows the statement that is currently being evaluated when evaluating a script.");
constant DebugFlag DUMP = DEBUG_FLAG(29, "dump", false,
  "Dumps the absyn representation of a program.");
constant DebugFlag DUMP_GRAPHVIZ = DEBUG_FLAG(30, "graphviz", false,
  "Dumps the absyn representation of a program in graphviz format.");
constant DebugFlag EXEC_STAT = DEBUG_FLAG(31, "execstat", false,
  "Prints out execution statistics for the compiler.");
constant DebugFlag TRANSFORMS_BEFORE_DUMP = DEBUG_FLAG(32, "transformsbeforedump", false,
  "Applies transformations required for code generation before dumping flat code.");
constant DebugFlag DAE_DUMP_GRAPHV = DEBUG_FLAG(33, "daedumpgraphv", false,
  "Dumps the DAE in graphviz format.");
constant DebugFlag INTERACTIVE_TCP = DEBUG_FLAG(34, "interactive", false,
  "Starts omc as a server listening on the socket interface.");
constant DebugFlag INTERACTIVE_CORBA = DEBUG_FLAG(35, "interactiveCorba", false,
  "Starts omc as a server listening on the Corba interface.");
constant DebugFlag INTERACTIVE_DUMP = DEBUG_FLAG(36, "interactivedump", false,
  "Prints out debug information for the interactive server.");
constant DebugFlag RELIDX = DEBUG_FLAG(37, "relidx", false,
  "Prints out debug information about relations, that are used as zero crossings.");
constant DebugFlag DUMP_REPL = DEBUG_FLAG(38, "dumprepl", false,
  "Dump the found replacements for simple equation removal.");
constant DebugFlag DUMP_FP_REPL = DEBUG_FLAG(39, "dumpFPrepl", false,
  "Dump the found replacements for final parameters.");
constant DebugFlag DUMP_PARAM_REPL = DEBUG_FLAG(40, "dumpParamrepl", false,
  "Dump the found replacements for remove parameters.");
constant DebugFlag DUMP_PP_REPL = DEBUG_FLAG(41, "dumpPPrepl", false,
  "Dump the found replacements for protected parameters.");
constant DebugFlag DUMP_EA_REPL = DEBUG_FLAG(42, "dumpEArepl", false,
  "Dump the found replacements for evaluate annotations (evaluate=true) parameters.");
constant DebugFlag DEBUG_ALIAS = DEBUG_FLAG(43, "debugAlias", false,
  "Dumps some information about the process of removeSimpleEquations.");
constant DebugFlag TEARING_DUMP = DEBUG_FLAG(44, "tearingdump", false,
  "Dumps tearing information.");
constant DebugFlag JAC_DUMP = DEBUG_FLAG(45, "symjacdump", false,
  "Dumps information about symbolic Jacobians.");
constant DebugFlag JAC_DUMP2 = DEBUG_FLAG(46, "symjacdumpverbose", false,
  "Dumps information in verbose mode about symbolic Jacobians.");
constant DebugFlag DUMP_BINDINGS = DEBUG_FLAG(47, "dumpBindings", false,
  "Dumps information about the equations created from bindings.");
constant DebugFlag DUMP_SORTING = DEBUG_FLAG(48, "dumpSorting", false,
  "Dumps information about the process of sorting.");
constant DebugFlag DUMP_SPARSE = DEBUG_FLAG(49, "dumpSparsePattern", false,
  "Dumps sparse pattern with coloring used for simulation.");
constant DebugFlag DUMP_SPARSE_VERBOSE = DEBUG_FLAG(50, "dumpSparsePatternVerbose", false,
  "Dumps in verbose mode sparse pattern with coloring used for simulation.");
constant DebugFlag BLT_DUMP = DEBUG_FLAG(51, "bltdump", false,
  "Dumps information from index reduction.");
constant DebugFlag DUMMY_SELECT = DEBUG_FLAG(52, "dummyselect", false,
  "Dumps information from dummy state selection heuristic.");
constant DebugFlag DUMP_DAE_LOW = DEBUG_FLAG(53, "dumpdaelow", false,
  "Dumps the equation system at the beginning of the back end.");
constant DebugFlag DUMP_INDX_DAE = DEBUG_FLAG(54, "dumpindxdae", false,
  "Dumps the equation system after index reduction and optimization.");
constant DebugFlag OPT_DAE_DUMP = DEBUG_FLAG(55, "optdaedump", false,
  "Dumps information from the optimization modules.");
constant DebugFlag EXEC_HASH = DEBUG_FLAG(56, "execHash", false,
  "Measures the time it takes to hash all simcode variables before code generation.");
constant DebugFlag PARAM_DLOW_DUMP = DEBUG_FLAG(57, "paramdlowdump", false,
  "Enables dumping of the parameters in the order they are calculated.");
constant DebugFlag DUMP_ENCAPSULATECONDITIONS = DEBUG_FLAG(58, "dumpEncapsulateConditions", false,
  "Dumps the results of the preOptModule encapsulateWhenConditions.");
constant DebugFlag SHORT_OUTPUT = DEBUG_FLAG(59, "shortOutput", false,
  "Enables short output of the simulate() command. Useful for tools like OMNotebook.");
constant DebugFlag COUNT_OPERATIONS = DEBUG_FLAG(60, "countOperations", false,
  "Count operations.");
constant DebugFlag CGRAPH = DEBUG_FLAG(61, "cgraph", false,
  "Prints out connection graph information.");
constant DebugFlag UPDMOD = DEBUG_FLAG(62, "updmod", false,
  "Prints information about modification updates.");
constant DebugFlag STATIC = DEBUG_FLAG(63, "static", false,
  "Enables extra debug output from the static elaboration.");
constant DebugFlag TPL_PERF_TIMES = DEBUG_FLAG(64, "tplPerfTimes", false,
  "Enables output of template performance data for rendering text to file.");
constant DebugFlag CHECK_SIMPLIFY = DEBUG_FLAG(65, "checkSimplify", false,
  "Enables checks for expression simplification and prints a notification whenever an undesirable transformation has been performed.");
constant DebugFlag SCODE_INST = DEBUG_FLAG(66, "newInst", true,
  "Enables new instantiation phase.");
constant DebugFlag WRITE_TO_BUFFER = DEBUG_FLAG(67, "writeToBuffer", false,
  "Enables writing simulation results to buffer.");
constant DebugFlag DUMP_BACKENDDAE_INFO = DEBUG_FLAG(68, "backenddaeinfo", false,
  "Enables dumping of back-end information about system (Number of equations before back-end,...).");
constant DebugFlag GEN_DEBUG_SYMBOLS = DEBUG_FLAG(69, "gendebugsymbols", false,
  "Generate code with debugging symbols.");
constant DebugFlag DUMP_STATESELECTION_INFO = DEBUG_FLAG(70, "stateselection", false,
  "Enables dumping of selected states. Extends -d=backenddaeinfo.");
constant DebugFlag DUMP_EQNINORDER = DEBUG_FLAG(71, "dumpeqninorder", false,
  "Enables dumping of the equations in the order they are calculated.");
constant DebugFlag SEMILINEAR = DEBUG_FLAG(72, "semiLinear", false,
  "Enables dumping of the optimization information when optimizing calls to semiLinear.");
constant DebugFlag UNCERTAINTIES = DEBUG_FLAG(73, "uncertainties", false,
  "Enables dumping of status when calling modelEquationsUC.");
constant DebugFlag SHOW_START_ORIGIN = DEBUG_FLAG(74, "showStartOrigin", false,
  "Enables dumping of the DAE startOrigin attribute of the variables.");
constant DebugFlag DUMP_SIMCODE = DEBUG_FLAG(75, "dumpSimCode", false,
  "Dumps the simCode model used for code generation.");
constant DebugFlag DUMP_INITIAL_SYSTEM = DEBUG_FLAG(76, "dumpinitialsystem", false,
  "Dumps the initial equation system.");
constant DebugFlag GRAPH_INST = DEBUG_FLAG(77, "graphInst", false,
  "Do graph based instantiation.");
constant DebugFlag GRAPH_INST_RUN_DEP = DEBUG_FLAG(78, "graphInstRunDep", false,
  "Run scode dependency analysis. Use with -d=graphInst");
constant DebugFlag GRAPH_INST_GEN_GRAPH = DEBUG_FLAG(79, "graphInstGenGraph", false,
  "Dumps a graph of the program. Use with -d=graphInst");
constant DebugFlag DUMP_CONST_REPL = DEBUG_FLAG(80, "dumpConstrepl", false,
  "Dump the found replacements for constants.");
constant DebugFlag SHOW_EQUATION_SOURCE = DEBUG_FLAG(81, "showEquationSource", false,
  "Display the element source information in the dumped DAE for easier debugging.");
constant DebugFlag LS_ANALYTIC_JACOBIAN = DEBUG_FLAG(82, "LSanalyticJacobian", false,
  "Enables analytical jacobian for linear strong components. Defaults to false");
constant DebugFlag NLS_ANALYTIC_JACOBIAN = DEBUG_FLAG(83, "NLSanalyticJacobian", true,
  "Enables analytical jacobian for non-linear strong components without user-defined function calls, for that see forceNLSanalyticJacobian");
constant DebugFlag INLINE_SOLVER = DEBUG_FLAG(84, "inlineSolver", false,
  "Generates code for inline solver.");
constant DebugFlag HPCOM = DEBUG_FLAG(85, "hpcom", false,
  "Enables parallel calculation based on task-graphs.");
constant DebugFlag INITIALIZATION = DEBUG_FLAG(86, "initialization", false,
  "Shows additional information from the initialization process.");
constant DebugFlag INLINE_FUNCTIONS = DEBUG_FLAG(87, "inlineFunctions", true,
  "Controls if function inlining should be performed.");
constant DebugFlag DUMP_SCC_GRAPHML = DEBUG_FLAG(88, "dumpSCCGraphML", false,
  "Dumps graphml files with the strongly connected components.");
constant DebugFlag TEARING_DUMPVERBOSE = DEBUG_FLAG(89, "tearingdumpV", false,
  "Dumps verbose tearing information.");
constant DebugFlag DISABLE_SINGLE_FLOW_EQ = DEBUG_FLAG(90, "disableSingleFlowEq", false,
  "Disables the generation of single flow equations.");
constant DebugFlag DUMP_DISCRETEVARS_INFO = DEBUG_FLAG(91, "discreteinfo", false,
  "Enables dumping of discrete variables. Extends -d=backenddaeinfo.");
constant DebugFlag ADDITIONAL_GRAPHVIZ_DUMP = DEBUG_FLAG(92, "graphvizDump", false,
  "Activates additional graphviz dumps (as .dot files). It can be used in addition to one of the following flags: {dumpdaelow|dumpinitialsystems|dumpindxdae}.");
constant DebugFlag INFO_XML_OPERATIONS = DEBUG_FLAG(93, "infoXmlOperations", false,
  "Enables output of the operations in the _info.xml file when translating models.");
constant DebugFlag HPCOM_DUMP = DEBUG_FLAG(94, "hpcomDump", false,
  "Dumps additional information on the parallel execution with hpcom.");
constant DebugFlag RESOLVE_LOOPS_DUMP = DEBUG_FLAG(95, "resolveLoopsDump", false,
  "Debug Output for ResolveLoops Module.");
constant DebugFlag DISABLE_WINDOWS_PATH_CHECK_WARNING = DEBUG_FLAG(96, "disableWindowsPathCheckWarning", false,
  "Disables warnings on Windows if OPENMODELICAHOME/MinGW is missing.");
constant DebugFlag DISABLE_RECORD_CONSTRUCTOR_OUTPUT = DEBUG_FLAG(97, "disableRecordConstructorOutput", false,
  "Disables output of record constructors in the flat code.");
constant DebugFlag IMPL_ODE = DEBUG_FLAG(98, "implOde", false,
  "activates implicit codegen");
constant DebugFlag EVAL_FUNC_DUMP = DEBUG_FLAG(99, "evalFuncDump", false,
  "dumps debug information about the function evaluation");
constant DebugFlag PRINT_STRUCTURAL = DEBUG_FLAG(100, "printStructuralParameters", false,
  "Prints the structural parameters identified by the front-end");
constant DebugFlag ITERATION_VARS = DEBUG_FLAG(101, "iterationVars", false,
  "Shows a list of all iteration variables.");
constant DebugFlag ALLOW_RECORD_TOO_MANY_FIELDS = DEBUG_FLAG(102, "acceptTooManyFields", false,
  "Accepts passing records with more fields than expected to a function. This is not allowed, but is used in Fluid.Dissipation. See https://trac.modelica.org/Modelica/ticket/1245 for details.");
constant DebugFlag HPCOM_MEMORY_OPT = DEBUG_FLAG(103, "hpcomMemoryOpt", false,
  "Optimize the memory structure regarding the selected scheduler");
constant DebugFlag DUMP_SYNCHRONOUS = DEBUG_FLAG(104, "dumpSynchronous", false,
  "Dumps information of the clock partitioning.");
constant DebugFlag STRIP_PREFIX = DEBUG_FLAG(105, "stripPrefix", true,
  "Strips the environment prefix from path/crefs. Defaults to true.");
constant DebugFlag DO_SCODE_DEP = DEBUG_FLAG(106, "scodeDep", true,
  "Does scode dependency analysis prior to instantiation. Defaults to true.");
constant DebugFlag SHOW_INST_CACHE_INFO = DEBUG_FLAG(107, "showInstCacheInfo", false,
  "Prints information about instantiation cache hits and additions. Defaults to false.");
constant DebugFlag DUMP_UNIT = DEBUG_FLAG(108, "dumpUnits", false,
  "Dumps all the calculated units.");
constant DebugFlag DUMP_EQ_UNIT = DEBUG_FLAG(109, "dumpEqInUC", false,
  "Dumps all equations handled by the unit checker.");
constant DebugFlag DUMP_EQ_UNIT_STRUCT = DEBUG_FLAG(110, "dumpEqUCStruct", false,
  "Dumps all the equations handled by the unit checker as tree-structure.");
constant DebugFlag SHOW_DAE_GENERATION = DEBUG_FLAG(111, "showDaeGeneration", false,
  "Show the dae variable declarations as they happen.");
constant DebugFlag RESHUFFLE_POST = DEBUG_FLAG(112, "reshufflePost", false,
  "Reshuffles the systems of equations.");
constant DebugFlag SHOW_EXPANDABLE_INFO = DEBUG_FLAG(113, "showExpandableInfo", false,
  "Show information about expandable connector handling.");
constant DebugFlag DUMP_HOMOTOPY = DEBUG_FLAG(114, "dumpHomotopy", false,
  "Dumps the results of the postOptModule optimizeHomotopyCalls.");
constant DebugFlag OMC_RELOCATABLE_FUNCTIONS = DEBUG_FLAG(115, "relocatableFunctions", false,
  "Generates relocatable code: all functions become function pointers and can be replaced at run-time.");
constant DebugFlag GRAPHML = DEBUG_FLAG(116, "graphml", false,
  "Dumps .graphml files for the bipartite graph after Index Reduction and a task graph for the SCCs. Can be displayed with yEd. ");
constant DebugFlag USEMPI = DEBUG_FLAG(117, "useMPI", false,
  "Add MPI init and finalize to main method (CPPruntime). ");
constant DebugFlag DUMP_CSE = DEBUG_FLAG(118, "dumpCSE", false,
  "Additional output for CSE module.");
constant DebugFlag DUMP_CSE_VERBOSE = DEBUG_FLAG(119, "dumpCSE_verbose", false,
  "Additional output for CSE module.");
constant DebugFlag NO_START_CALC = DEBUG_FLAG(120, "disableStartCalc", false,
  "Deactivates the pre-calculation of start values during compile-time.");
constant DebugFlag CONSTJAC = DEBUG_FLAG(121, "constjac", false,
  "solves linear systems with constant Jacobian and variable b-Vector symbolically");
constant DebugFlag VISUAL_XML = DEBUG_FLAG(122, "visxml", false,
  "Outputs a xml-file that contains information for visualization.");
constant DebugFlag VECTORIZE = DEBUG_FLAG(123, "vectorize", false,
  "Activates vectorization in the backend.");
constant DebugFlag CHECK_EXT_LIBS = DEBUG_FLAG(124, "buildExternalLibs", true,
  "Use the autotools project in the Resources folder of the library to build missing external libraries.");
constant DebugFlag RUNTIME_STATIC_LINKING = DEBUG_FLAG(125, "runtimeStaticLinking", false,
  "Use the static simulation runtime libraries (C++ simulation runtime).");
constant DebugFlag SORT_EQNS_AND_VARS = DEBUG_FLAG(126, "dumpSortEqnsAndVars", false,
  "Dumps debug output for the modules sortEqnsVars.");
constant DebugFlag DUMP_SIMPLIFY_LOOPS = DEBUG_FLAG(127, "dumpSimplifyLoops", false,
  "Dump between steps of simplifyLoops");
constant DebugFlag DUMP_RTEARING = DEBUG_FLAG(128, "dumpRecursiveTearing", false,
  "Dump between steps of recursiveTearing");
constant DebugFlag DIS_SYMJAC_FMI20 = DEBUG_FLAG(129, "disableDirectionalDerivatives", true,
  "For FMI 2.0 only dependecy analysis will be perform.");
constant DebugFlag EVAL_OUTPUT_ONLY = DEBUG_FLAG(130, "evalOutputOnly", false,
  "Generates equations to calculate top level outputs only.");
constant DebugFlag HARDCODED_START_VALUES = DEBUG_FLAG(131, "hardcodedStartValues", false,
  "Embed the start values of variables and parameters into the c++ code and do not read it from xml file.");
constant DebugFlag DUMP_FUNCTIONS = DEBUG_FLAG(132, "dumpFunctions", false,
  "Add functions to backend dumps.");
constant DebugFlag DEBUG_DIFFERENTIATION = DEBUG_FLAG(133, "debugDifferentiation", false,
  "Dumps debug output for the differentiation process.");
constant DebugFlag DEBUG_DIFFERENTIATION_VERBOSE = DEBUG_FLAG(134, "debugDifferentiationVerbose", false,
  "Dumps verbose debug output for the differentiation process.");
constant DebugFlag FMU_EXPERIMENTAL = DEBUG_FLAG(135, "fmuExperimental", false,
  "Adds features to the FMI export that are considered experimental as of now: fmi2GetSpecificDerivatives, canGetSetFMUState, canSerializeFMUstate");
constant DebugFlag DUMP_DGESV = DEBUG_FLAG(136, "dumpdgesv", false,
  "Enables dumping of the information whether DGESV is used to solve linear systems.");
constant DebugFlag MULTIRATE_PARTITION = DEBUG_FLAG(137, "multirate", false,
  "The solver can switch partitions in the system.");
constant DebugFlag DUMP_EXCLUDED_EXP = DEBUG_FLAG(138, "dumpExcludedSymJacExps", false,
  "This flags dumps all expression that are excluded from differentiation of a symbolic Jacobian.");
constant DebugFlag DEBUG_ALGLOOP_JACOBIAN = DEBUG_FLAG(139, "debugAlgebraicLoopsJacobian", false,
  "Dumps debug output while creating symbolic jacobians for non-linear systems.");
constant DebugFlag DISABLE_JACSCC = DEBUG_FLAG(140, "disableJacsforSCC", false,
  "Disables calculation of jacobians to detect if a SCC is linear or non-linear. By disabling all SCC will handled like non-linear.");
constant DebugFlag FORCE_NLS_ANALYTIC_JACOBIAN = DEBUG_FLAG(141, "forceNLSanalyticJacobian", false,
  "Forces calculation analytical jacobian also for non-linear strong components with user-defined functions.");
constant DebugFlag DUMP_LOOPS = DEBUG_FLAG(142, "dumpLoops", false,
  "Dumps loop equation.");
constant DebugFlag DUMP_LOOPS_VERBOSE = DEBUG_FLAG(143, "dumpLoopsVerbose", false,
  "Dumps loop equation and enhanced adjacency matrix.");
constant DebugFlag SKIP_INPUT_OUTPUT_SYNTACTIC_SUGAR = DEBUG_FLAG(144, "skipInputOutputSyntacticSugar", false,
  "Used when bootstrapping to preserve the input output parsing of the code output by the list command.");
constant DebugFlag OMC_RECORD_ALLOC_WORDS = DEBUG_FLAG(145, "metaModelicaRecordAllocWords", false,
  "Instrument the source code to record memory allocations (requires run-time and generated files compiled with -DOMC_RECORD_ALLOC_WORDS).");
constant DebugFlag TOTAL_TEARING_DUMP = DEBUG_FLAG(146, "totaltearingdump", false,
  "Dumps total tearing information.");
constant DebugFlag TOTAL_TEARING_DUMPVERBOSE = DEBUG_FLAG(147, "totaltearingdumpV", false,
  "Dumps verbose total tearing information.");
constant DebugFlag PARALLEL_CODEGEN = DEBUG_FLAG(148, "parallelCodegen", true,
  "Enables code generation in parallel (disable this if compiling a model causes you to run out of RAM).");
constant DebugFlag SERIALIZED_SIZE = DEBUG_FLAG(149, "reportSerializedSize", false,
  "Reports serialized sizes of various data structures used in the compiler.");
constant DebugFlag BACKEND_KEEP_ENV_GRAPH = DEBUG_FLAG(150, "backendKeepEnv", true,
  "When enabled, the environment is kept when entering the backend, which enables CevalFunction (function interpretation) to work. This module not essential for the backend to function in most cases, but can improve simulation performance by evaluating functions. The drawback to keeping the environment graph in memory is that it is huge (~80% of the total memory in use when returning the frontend DAE).");
constant DebugFlag DUMPBACKENDINLINE = DEBUG_FLAG(151, "dumpBackendInline", false,
  "Dumps debug output while inline function.");
constant DebugFlag DUMPBACKENDINLINE_VERBOSE = DEBUG_FLAG(152, "dumpBackendInlineVerbose", false,
  "Dumps debug output while inline function.");
constant DebugFlag BLT_MATRIX_DUMP = DEBUG_FLAG(153, "bltmatrixdump", false,
  "Dumps the blt matrix in html file. IE seems to be very good in displaying large matrices.");
constant DebugFlag LIST_REVERSE_WRONG_ORDER = DEBUG_FLAG(154, "listAppendWrongOrder", true,
  "Print notifications about bad usage of listAppend.");
constant DebugFlag PARTITION_INITIALIZATION = DEBUG_FLAG(155, "partitionInitialization", true,
  "This flag controls if partitioning is applied to the initialization system.");
constant DebugFlag EVAL_PARAM_DUMP = DEBUG_FLAG(156, "evalParameterDump", false,
  "Dumps information for evaluating parameters.");
constant DebugFlag NF_UNITCHECK = DEBUG_FLAG(157, "frontEndUnitCheck", false,
  "Checks the consistency of units in equation.");
constant DebugFlag DISABLE_COLORING = DEBUG_FLAG(158, "disableColoring", false,
  "Disables coloring algorithm while spasity detection.");
constant DebugFlag MERGE_ALGORITHM_SECTIONS = DEBUG_FLAG(159, "mergeAlgSections", false,
  "Disables coloring algorithm while sparsity detection.");
constant DebugFlag WARN_NO_NOMINAL = DEBUG_FLAG(160, "warnNoNominal", false,
  "Prints the iteration variables in the initialization and simulation DAE, which do not have a nominal value.");
constant DebugFlag REDUCE_DAE = DEBUG_FLAG(161, "backendReduceDAE", false,
  "Prints all Reduce DAE debug information.");
constant DebugFlag IGNORE_CYCLES = DEBUG_FLAG(162, "ignoreCycles", false,
  "Ignores cycles between constant/parameter components.");
constant DebugFlag ALIAS_CONFLICTS = DEBUG_FLAG(163, "aliasConflicts", false,
  "Dumps alias sets with different start or nominal values.");
constant DebugFlag SUSAN_MATCHCONTINUE_DEBUG = DEBUG_FLAG(164, "susanDebug", false,
  "Makes Susan generate code using try/else to better debug which function broke the expected match semantics.");
constant DebugFlag OLD_FE_UNITCHECK = DEBUG_FLAG(165, "oldFrontEndUnitCheck", false,
  "Checks the consistency of units in equation (for the old front-end).");
constant DebugFlag EXEC_STAT_EXTRA_GC = DEBUG_FLAG(166, "execstatGCcollect", false,
  "When running execstat, also perform an extra full garbage collection.");
constant DebugFlag DEBUG_DAEMODE = DEBUG_FLAG(167, "debugDAEmode", false,
  "Dump debug output for the DAEmode.");
constant DebugFlag NF_SCALARIZE = DEBUG_FLAG(168, "nfScalarize", true,
  "Run scalarization in NF, default true.");
constant DebugFlag NF_EVAL_CONST_ARG_FUNCS = DEBUG_FLAG(169, "nfEvalConstArgFuncs", true,
  "Evaluate all functions with constant arguments in the new frontend.");
constant DebugFlag NF_EXPAND_OPERATIONS = DEBUG_FLAG(170, "nfExpandOperations", true,
  "Expand all unary/binary operations to scalar expressions in the new frontend.");
constant DebugFlag NF_API = DEBUG_FLAG(171, "nfAPI", true,
  "Enables experimental new instantiation use in the OMC API.");
constant DebugFlag NF_API_DYNAMIC_SELECT = DEBUG_FLAG(172, "nfAPIDynamicSelect", false,
  "Show DynamicSelect(static, dynamic) in annotations. Default to false and will select the first (static) expression");
constant DebugFlag NF_API_NOISE = DEBUG_FLAG(173, "nfAPINoise", false,
  "Enables error display for the experimental new instantiation use in the OMC API.");
constant DebugFlag FMI20_DEPENDENCIES = DEBUG_FLAG(174, "disableFMIDependency", false,
  "Disables the dependency analysis and generation for FMI 2.0.");
constant DebugFlag WARNING_MINMAX_ATTRIBUTES = DEBUG_FLAG(175, "warnMinMax", true,
  "Makes a warning assert from min/max variable attributes instead of error.");
constant DebugFlag NF_EXPAND_FUNC_ARGS = DEBUG_FLAG(176, "nfExpandFuncArgs", false,
  "Expand all function arguments in the new frontend.");
constant DebugFlag DUMP_JL = DEBUG_FLAG(177, "dumpJL", false,
  "Dumps the absyn representation of a program as a Julia representation");
constant DebugFlag DUMP_ASSC = DEBUG_FLAG(178, "dumpASSC", false,
  "Dumps the conversion process of analytical to structural singularities.");
constant DebugFlag SPLIT_CONSTANT_PARTS_SYMJAC = DEBUG_FLAG(179, "symJacConstantSplit", false,
  "Generates all symbolic Jacobians with splitted constant parts.");
constant DebugFlag DUMP_FORCE_FMI_ATTRIBUTES = DEBUG_FLAG(180, "force-fmi-attributes", false,
  "Force to export all fmi attributes to the modelDescription.xml, including those which have default values");
constant DebugFlag DUMP_DATARECONCILIATION = DEBUG_FLAG(181, "dataReconciliation", false,
  "Dumps all the dataReconciliation extraction algorithm procedure");
constant DebugFlag ARRAY_CONNECT = DEBUG_FLAG(182, "arrayConnect", false,
  "Use experimental array connection handler.");
constant DebugFlag COMBINE_SUBSCRIPTS = DEBUG_FLAG(183, "combineSubscripts", false,
  "Move all subscripts to the end of component references.");
constant DebugFlag ZMQ_LISTEN_TO_ALL = DEBUG_FLAG(184, "zmqDangerousAcceptConnectionsFromAnywhere", false,
  "When opening a zmq connection, listen on all interfaces instead of only connections from 127.0.0.1.");
constant DebugFlag DUMP_CONVERSION_RULES = DEBUG_FLAG(185, "dumpConversionRules", false,
  "Dumps the rules when converting a package using a conversion script.");
constant DebugFlag PRINT_RECORD_TYPES = DEBUG_FLAG(186, "printRecordTypes", false,
  "Prints out record types as part of the flat code.");
constant DebugFlag DUMP_SIMPLIFY = DEBUG_FLAG(187, "dumpSimplify", false,
  "Dumps expressions before and after simplification.");
constant DebugFlag DUMP_BACKEND_CLOCKS = DEBUG_FLAG(188, "dumpBackendClocks", false,
  "Dumps times for each backend module (only new backend).");
constant DebugFlag DUMP_SET_BASED_GRAPHS = DEBUG_FLAG(189, "dumpSetBasedGraphs", false,
  "Dumps information about set based graphs for efficient array handling (only new frontend and new backend).");
constant DebugFlag MERGE_COMPONENTS = DEBUG_FLAG(190, "mergeComponents", false,
  "Enables automatic merging of components into arrays.");
constant DebugFlag DUMP_SLICE = DEBUG_FLAG(191, "dumpSlice", false,
  "Dumps information about the slicing process (pseudo-array causalization).");
constant DebugFlag VECTORIZE_BINDINGS = DEBUG_FLAG(192, "vectorizeBindings", false,
  "Turns on vectorization of bindings when scalarization is turned off.");
constant DebugFlag DUMP_EVENTS = DEBUG_FLAG(193, "dumpEvents", false,
  "Dumps information about the detected event functions.");
constant DebugFlag DUMP_RESIZABLE = DEBUG_FLAG(194, "dumpResizable", false,
  "Dumps information about resizable paremeter handling.");
constant DebugFlag DUMP_SOLVE = DEBUG_FLAG(195, "dumpSolve", false,
  "Dumps information about equation solving.");
constant DebugFlag FORCE_SCALARIZE = DEBUG_FLAG(196, "forceScalarize", false,
  "Forces scalarization to be done when it would normally be automatically disabled.");
constant DebugFlag DEBUG_ADJOINT = DEBUG_FLAG(197, "debugAdjoint", false,
  "Dumps debug output for the adjoint differentiation process in the new backend.");
constant DebugFlag FLOW_ALIAS_ELIMINATION = DEBUG_FLAG(198, "flowAliasElimination", false,
  "Enables simple alias elimination of flow variables in stream connectors.");
constant DebugFlag DUMP_CHECK_MODEL = DEBUG_FLAG(199, "dumpCheckModel", false,
  "Dumps the variables and equations found by checkModel.");
constant DebugFlag CHECK_DEF_USE = DEBUG_FLAG(200, "checkDefUse", false,
  "Warns about variables in functions that cannot statically be proven to be defined (given a value) before they are used, e.g. variables only assigned on some control flow paths. Per the Modelica specification using an uninitialized variable is an error.");
/* LLVM JIT flags (added on the LLVM revive branch) */
constant DebugFlag JIT_EVAL_FUNC = DEBUG_FLAG(201, "jit_eval_func", false,
  "Turns on/off JIT compilation of MetaModelica functions via the LLVM backend.");
constant DebugFlag JIT_DUMP_IR = DEBUG_FLAG(202, "jit_dump_ir", false,
  "Dumps LLVM-IR before JIT execution.");
constant DebugFlag JIT_NO_OPT = DEBUG_FLAG(203, "jit_no_opt", false,
  "Generates LLVM-IR without optimization passes.");
constant DebugFlag DUMP_MIDCODE = DEBUG_FLAG(204, "dumpMidCode", false,
  "Dumps MidCode after generation in a human-readable format.");
constant DebugFlag JIT_SIMULATE = DEBUG_FLAG(205, "jitSimulate", false,
  "Simulate models by JIT-compiling the generated C via LLVM (ORC) and running it in-process, instead of building and running a native executable.");

public
// CONFIGURATION FLAGS
constant ConfigFlag DEBUG = CONFIG_FLAG(1, "debug",
  SOME("d"), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  "Sets debug flags. Use --help=debug to see available flags.");
constant ConfigFlag HELP = CONFIG_FLAG(2, "help",
  SOME("h"), EXTERNAL(), STRING_FLAG(""), NONE(),
  "Displays the help text. Use --help=topics for more information.");
constant ConfigFlag RUNNING_TESTSUITE = CONFIG_FLAG(3, "running-testsuite",
  NONE(), INTERNAL(), STRING_FLAG(""), NONE(),
  "Used when running the testsuite.");
constant ConfigFlag SHOW_VERSION = CONFIG_FLAG(4, "version",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Print the version and exit.");
constant ConfigFlag TARGET = CONFIG_FLAG(5, "target", NONE(), EXTERNAL(),
  STRING_FLAG("gcc"), SOME(STRING_OPTION({"gcc", "msvc","msvc10","msvc12","msvc13","msvc15","msvc19", "vxworks69", "debugrt"})),
  "Sets the target compiler to use.");
constant ConfigFlag GRAMMAR = CONFIG_FLAG(6, "grammar", SOME("g"), EXTERNAL(),
  ENUM_FLAG(MODELICA, {("Modelica", MODELICA), ("MetaModelica", METAMODELICA), ("ParModelica", PARMODELICA), ("Optimica", OPTIMICA), ("PDEModelica", PDEMODELICA)}),
  SOME(STRING_OPTION({"Modelica", "MetaModelica", "ParModelica", "Optimica", "PDEModelica"})),
  "Sets the grammar and semantics to accept.");
constant ConfigFlag ANNOTATION_VERSION = CONFIG_FLAG(7, "annotationVersion",
  NONE(), EXTERNAL(), STRING_FLAG("3.x"), SOME(STRING_OPTION({"1.x", "2.x", "3.x"})),
  "Sets the annotation version that should be used.");
constant ConfigFlag LANGUAGE_STANDARD = CONFIG_FLAG(8, "std", NONE(), EXTERNAL(),
  ENUM_FLAG(1000,
    {("1.x", 10), ("2.x", 20), ("3.0", 30), ("3.1", 31), ("3.2", 32), ("3.3", 33),
     ("3.4", 34), ("3.5", 35), ("3.6", 36), ("latest",1000), ("experimental", 9999)}),
  SOME(STRING_OPTION({"1.x", "2.x", "3.1", "3.2", "3.3", "3.4", "3.5", "3.6", "latest", "experimental"})),
  "Sets the language standard that should be used.");
constant ConfigFlag SHOW_ERROR_MESSAGES = CONFIG_FLAG(9, "showErrorMessages",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Show error messages immediately when they happen.");
constant ConfigFlag SHOW_ANNOTATIONS = CONFIG_FLAG(10, "showAnnotations",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Show annotations in the flattened code.");
constant ConfigFlag NO_SIMPLIFY = CONFIG_FLAG(11, "noSimplify",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Do not simplify expressions if set.");

constant String removeSimpleEquationDesc = "Performs alias elimination and removes constant variables from the DAE, replacing all occurrences of the old variable reference with the new value (constants) or variable reference (alias elimination).";

constant ConfigFlag PRE_OPT_MODULES = CONFIG_FLAG(12, "preOptModules",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({
    "normalInlineFunction",
    "evaluateParameters",
    "simplifyIfEquations",
    "expandDerOperator",
    "clockPartitioning",
    "findStateOrder",
    "replaceEdgeChange",
    "inlineArrayEqn",
    "removeEqualRHS",
    "removeSimpleEquations",
    "comSubExp",
    "resolveLoops",
    "evalFunc",
    "encapsulateWhenConditions"
    }),
  SOME(STRING_DESC_OPTION({
    ("introduceOutputAliases", "Introduces aliases for top-level outputs."),
    ("clockPartitioning", "Does the clock partitioning."),
    ("collapseArrayExpressions", collapseArrayExpressionsText),
    ("comSubExp", "Introduces alias assignments for variables which are assigned to simple terms i.e. a = b/c; d = b/c; --> a=d"),
    ("dumpDAE", "dumps the DAE representation of the current transformation state"),
    ("dumpDAEXML", "dumps the DAE as xml representation of the current transformation state"),
    ("encapsulateWhenConditions", "This module replaces each when condition with a boolean variable."),
    ("evalFunc", "evaluates functions partially"),
    ("evaluateParameters", "Evaluates parameters with annotation(Evaluate=true). Use '--evaluateFinalParameters=true' or '--evaluateProtectedParameters=true' to specify additional parameters to be evaluated. Use '--replaceEvaluatedParameters=true' if the evaluated parameters should be replaced in the DAE. To evaluate all parameters in the Frontend use -d=evaluateAllParameters."),
    ("expandDerOperator", "Expands der(expr) using Derive.differentiteExpTime."),
    ("findStateOrder", "Sets derivative information to states."),
    ("inlineArrayEqn", "This module expands all array equations to scalar equations."),
    ("normalInlineFunction", "Perform function inlining for function with annotation Inline=true."),
    ("inputDerivativesForDynOpt", "Allowed derivatives of inputs in dyn. optimization."),
    ("introduceDerAlias", "Adds for every der-call an alias equation e.g. dx = der(x)."),
    ("removeEqualRHS", "Detects equal expressions of the form a=<exp> and b=<exp> and substitutes them to get speed up."),
    ("removeProtectedParameters", "Replace all parameters with protected=true in the system."),
    ("removeSimpleEquations", removeSimpleEquationDesc),
    ("removeUnusedParameter", "Strips all parameter not present in the equations from the system."),
    ("removeUnusedVariables", "Strips all variables not present in the equations from the system."),
    ("removeVerySimpleEquations", "[Experimental] Like removeSimpleEquations, but less thorough. Note that this always uses the experimental new alias elimination, --removeSimpleEquations=new, which makes it unstable. In particular, MultiBody systems fail to translate correctly. It can be used for simple (but large) systems of equations."),
    ("replaceEdgeChange", "Replace edge(b) = b and not pre(b) and change(b) = v <> pre(v)."),
    ("residualForm", "Transforms simple equations x=y to zero-sum equations 0=y-x."),
    ("resolveLoops", "resolves linear equations in loops"),
    ("simplifyAllExpressions", "Does simplifications on all expressions."),
    ("simplifyIfEquations", "Tries to simplify if equations by use of information from evaluated parameters."),
    ("sortEqnsVars", "Heuristic sorting for equations and variables."),
    ("unitChecking", "This module is no longer available and its use is deprecated. Use --unitChecking instead."),
    ("wrapFunctionCalls", "This module introduces variables for each function call and substitutes all these calls with the newly introduced variables.")
    })),
  "Sets the pre optimization modules to use in the back end. See --help=optmodules for more info.");
constant ConfigFlag CHEAPMATCHING_ALGORITHM = CONFIG_FLAG(13, "cheapmatchingAlgorithm",
  NONE(), EXTERNAL(), INT_FLAG(3),
  SOME(STRING_DESC_OPTION({
    ("0", "No cheap matching."),
    ("1", "Cheap matching, traverses all equations and match the first free variable."),
    ("3", "Random Karp-Sipser: R. M. Karp and M. Sipser. Maximum matching in sparse random graphs.")})),
  "Sets the cheap matching algorithm to use. A cheap matching algorithm gives a jump start matching by heuristics.");
constant ConfigFlag MATCHING_ALGORITHM = CONFIG_FLAG(14, "matchingAlgorithm",
  NONE(), EXTERNAL(), STRING_FLAG("PFPlusExt"),
  SOME(STRING_DESC_OPTION({
    ("BFSB", "Breadth First Search based algorithm."),
    ("DFSB", "Depth First Search based algorithm."),
    ("MC21A", "Depth First Search based algorithm with look ahead feature."),
    ("PF", "Depth First Search based algorithm with look ahead feature."),
    ("PFPlus", "Depth First Search based algorithm with look ahead feature and fair row traversal."),
    ("HK", "Combined BFS and DFS algorithm."),
    ("HKDW", "Combined BFS and DFS algorithm."),
    ("ABMP", "Combined BFS and DFS algorithm."),
    ("PR", "Matching algorithm using push relabel mechanism."),
    ("DFSBExt", "Depth First Search based Algorithm external c implementation."),
    ("BFSBExt", "Breadth First Search based Algorithm external c implementation."),
    ("MC21AExt", "Depth First Search based Algorithm with look ahead feature external c implementation."),
    ("PFExt", "Depth First Search based Algorithm with look ahead feature external c implementation."),
    ("PFPlusExt", "Depth First Search based Algorithm with look ahead feature and fair row traversal external c implementation."),
    ("HKExt", "Combined BFS and DFS algorithm external c implementation."),
    ("HKDWExt", "Combined BFS and DFS algorithm external c implementation."),
    ("ABMPExt", "Combined BFS and DFS algorithm external c implementation."),
    ("PRExt", "Matching algorithm using push relabel mechanism external c implementation."),
    ("BB", "BBs try."),
    ("SBGraph", "Set-Based Graph matching algorithm for efficient array handling."),
    ("pseudo", "Pseudo array matching that uses scalar matching and reconstructs arrays afterwards as much as possible.")})),
  "Sets the matching algorithm to use. See --help=optmodules for more info.");
constant ConfigFlag INDEX_REDUCTION_METHOD = CONFIG_FLAG(15, "indexReductionMethod",
  NONE(), EXTERNAL(), STRING_FLAG("dynamicStateSelection"),
  SOME(STRING_DESC_OPTION({
    ("none", "Skip index reduction"),
    ("uode", "Use the underlying ODE without the constraints."),
    ("dynamicStateSelection", "Simple index reduction method, select (dynamic) dummy states based on analysis of the system."),
    ("dummyDerivatives", "Simple index reduction method, select (static) dummy states based on heuristic.")
    })),
  "Sets the index reduction method to use. See --help=optmodules for more info.");
constant ConfigFlag POST_OPT_MODULES = CONFIG_FLAG(16, "postOptModules",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({
    "lateInlineFunction",
    "wrapFunctionCalls",
    "inlineArrayEqn",
    "constantLinearSystem",
    "simplifysemiLinear",
    "removeSimpleEquations",
    "simplifyComplexFunction",
    "solveSimpleEquations",
    "tearingSystem",
    "inputDerivativesUsed",
    "calculateStrongComponentJacobians",
    "calculateStateSetsJacobians",
    "symbolicJacobian",
    "removeConstants",
    "simplifyTimeIndepFuncCalls",
    "simplifyAllExpressions",
    "findZeroCrossings",
    "collapseArrayExpressions"
    }),
  SOME(STRING_DESC_OPTION({
    ("addScaledVars_states", "added var_norm = var/nominal, where var is state"),
    ("addScaledVars_inputs", "added var_norm = var/nominal, where var is input"),
    ("addTimeAsState", "Experimental feature: this replaces each occurrence of variable time with a new introduced state $time with equation der($time) = 1.0"),
    ("calculateStateSetsJacobians", "Generates analytical jacobian for dynamic state selection sets."),
    ("calculateStrongComponentJacobians", "Generates analytical jacobian for torn linear and non-linear strong components. By default linear components and non-linear components with user-defined function calls are skipped. See also debug flags: LSanalyticJacobian, NLSanalyticJacobian and forceNLSanalyticJacobian"),
    ("collapseArrayExpressions", collapseArrayExpressionsText),
    ("constantLinearSystem", "Evaluates constant linear systems (a*x+b*y=c; d*x+e*y=f; a,b,c,d,e,f are constants) at compile-time."),
    ("countOperations", "Count the mathematical operations of the system."),
    ("cseBinary", "Common Sub-expression Elimination"),
    ("dumpComponentsGraphStr", "Dumps the assignment graph used to determine strong components to format suitable for Mathematica"),
    ("dumpDAE", "dumps the DAE representation of the current transformation state"),
    ("dumpDAEXML", "dumps the DAE as xml representation of the current transformation state"),
    ("evaluateParameters", "Evaluates parameters with annotation(Evaluate=true). Use '--evaluateFinalParameters=true' or '--evaluateProtectedParameters=true' to specify additional parameters to be evaluated. Use '--replaceEvaluatedParameters=true' if the evaluated parameters should be replaced in the DAE. To evaluate all parameters in the Frontend use -d=evaluateAllParameters."),
    ("extendDynamicOptimization", "Move loops to constraints."),
    ("generateSymbolicLinearization", "Generates symbolic linearization matrices A,B,C,D for linear model:\n\t:math:`\\dot{x} = Ax + Bu`\n\t:math:`y = Cx + Du`"),
    ("generateSymbolicSensitivities", "Generates symbolic Sensivities matrix, where der(x) is differentiated w.r.t. param."),
    ("inlineArrayEqn", "This module expands all array equations to scalar equations."),
    ("inputDerivativesUsed", "Checks if derivatives of inputs are need to calculate the model."),
    ("lateInlineFunction", "Perform function inlining for function with annotation LateInline=true."),
    ("partlintornsystem","partitions linear torn systems."),
    ("recursiveTearing", "inline and repeat tearing"),
    ("reduceDynamicOptimization", "Removes equations which are not needed for the calculations of cost and constraints. This module requires --postOptModules+=reduceDynamicOptimization."),
    ("relaxSystem", "relaxation from gausian elemination"),
    ("removeConstants", "Remove all constants in the system."),
    ("removeEqualRHS", "Detects equal function calls of the form a=f(b) and c=f(b) and substitutes them to get speed up."),
    ("removeSimpleEquations", removeSimpleEquationDesc),
    ("removeUnusedParameter", "Strips all parameter not present in the equations from the system to get speed up for compilation of target code."),
    ("removeUnusedVariables", "Strips all variables not present in the equations from the system to get speed up for compilation of target code."),
    ("reshufflePost", "Reshuffles algebraic loops."),
    ("simplifyAllExpressions", "Does simplifications on all expressions."),
    ("simplifyComplexFunction", "Some simplifications on complex functions (complex refers to the internal data structure)"),
    ("simplifyConstraints", "Rewrites nonlinear constraints into box constraints if possible. This module requires +gDynOpt."),
    ("simplifyLoops", "Simplifies algebraic loops. This modules requires +simplifyLoops."),
    ("simplifyTimeIndepFuncCalls", "Simplifies time independent built in function calls like pre(param) -> param, der(param) -> 0.0, change(param) -> false, edge(param) -> false."),
    ("simplifysemiLinear", "Simplifies calls to semiLinear."),
    ("solveLinearSystem", "solve linear system with newton step"),
    ("solveSimpleEquations", "Solves simple equations"),
    ("symSolver", "Rewrites the ode system for implicit Euler method. This module requires +symSolver."),
    ("symbolicJacobian", "Detects the sparse pattern of the ODE system and calculates also the symbolic Jacobian if flag '--generateDynamicJacobian=symbolic'."),
    ("tearingSystem", "For method selection use flag tearingMethod."),
    ("wrapFunctionCalls", "This module introduces variables for each function call and substitutes all these calls with the newly introduced variables.")
    })),
  "Sets the post optimization modules to use in the back end. See --help=optmodules for more info.");
constant ConfigFlag SIMCODE_TARGET = CONFIG_FLAG(17, "simCodeTarget",
  NONE(), EXTERNAL(), STRING_FLAG("C"),
  SOME(STRING_OPTION({"None", "C", "Cpp","omsicpp", "ExperimentalEmbeddedC", "JavaScript", "omsic", "XML", "MidC", "wasm-jit"})),
  "Sets the target language for the code generation.");
constant ConfigFlag ORDER_CONNECTIONS = CONFIG_FLAG(18, "orderConnections",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  "Orders connect equations alphabetically if set.");
constant ConfigFlag TYPE_INFO = CONFIG_FLAG(19, "typeinfo",
  SOME("t"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Prints out extra type information if set.");
constant ConfigFlag KEEP_ARRAYS = CONFIG_FLAG(20, "keepArrays",
  SOME("a"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Sets whether to split arrays or not.");
constant ConfigFlag MODELICA_OUTPUT = CONFIG_FLAG(21, "modelicaOutput",
  SOME("m"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Enables valid modelica output for flat modelica.");
constant ConfigFlag SILENT = CONFIG_FLAG(22, "silent",
  SOME("q"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Turns on silent mode.");
constant ConfigFlag CORBA_SESSION = CONFIG_FLAG(23, "corbaSessionName",
  SOME("c"), EXTERNAL(), STRING_FLAG(""), NONE(),
  "Sets the name of the corba session if -d=interactiveCorba or --interactive=corba is used.");
constant ConfigFlag NUM_PROC = CONFIG_FLAG(24, "numProcs",
  SOME("n"), EXTERNAL(), INT_FLAG(0), NONE(),
  "Sets the number of processors to use (0=default=auto).");
constant ConfigFlag INST_CLASS = CONFIG_FLAG(25, "instClass",
  SOME("i"), EXTERNAL(), STRING_FLAG(""), NONE(),
  "Instantiate the class given by the fully qualified path.");
constant ConfigFlag VECTORIZATION_LIMIT = CONFIG_FLAG(26, "vectorizationLimit",
  SOME("v"), EXTERNAL(), INT_FLAG(0), NONE(),
  "Sets the vectorization limit, arrays and matrices larger than this will not be vectorized.");
constant ConfigFlag SIMULATION_CG = CONFIG_FLAG(27, "simulationCg",
  SOME("s"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Turns on simulation code generation.");
constant ConfigFlag EVAL_PARAMS_IN_ANNOTATIONS = CONFIG_FLAG(28,
  "evalAnnotationParams", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Sets whether to evaluate parameters in annotations or not.");
constant ConfigFlag CHECK_MODEL = CONFIG_FLAG(29,
  "checkModel", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "Set when checkModel is used to turn on specific features for checking.");
constant ConfigFlag CEVAL_EQUATION = CONFIG_FLAG(30,
  "cevalEquation", NONE(), INTERNAL(), BOOL_FLAG(true), NONE(),
  "");
constant ConfigFlag UNIT_CHECKING = CONFIG_FLAG(31,
  "unitChecking", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Enable unit checking.");
constant ConfigFlag GENERATE_LABELED_SIMCODE = CONFIG_FLAG(32,
  "generateLabeledSimCode", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Turns on labeled SimCode generation for reduction algorithms.");
constant ConfigFlag REDUCE_TERMS = CONFIG_FLAG(33,
  "reduceTerms", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Turns on reducing terms for reduction algorithms.");
constant ConfigFlag REDUCTION_METHOD = CONFIG_FLAG(34, "reductionMethod",
  NONE(), EXTERNAL(), STRING_FLAG("deletion"),
  SOME(STRING_OPTION({"deletion","substitution","linearization"})),
  "Sets the reduction method to be used.");
constant ConfigFlag DEMO_MODE = CONFIG_FLAG(35, "demoMode",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Disable Warning/Error Massages.");
constant ConfigFlag LOCALE_FLAG = CONFIG_FLAG(36, "locale",
  NONE(), EXTERNAL(), STRING_FLAG(""), NONE(),
  "Override the locale from the environment.");
constant ConfigFlag DEFAULT_OPENCL_DEVICE = CONFIG_FLAG(37, "defaultOCLDevice",
  SOME("o"), EXTERNAL(), INT_FLAG(0), NONE(),
  "Sets the default OpenCL device to be used for parallel execution.");
constant ConfigFlag MAXTRAVERSALS = CONFIG_FLAG(38, "maxTraversals",
  NONE(), EXTERNAL(), INT_FLAG(2),NONE(),
  "Maximal traversals to find simple equations in the acausal system.");
constant ConfigFlag DUMP_TARGET = CONFIG_FLAG(39, "dumpTarget",
  NONE(), EXTERNAL(), STRING_FLAG(""), NONE(),
  "Redirect the dump to file. If the file ends with .html HTML code is generated.");
constant ConfigFlag DELAY_BREAK_LOOP = CONFIG_FLAG(40, "delayBreakLoop",
  NONE(), EXTERNAL(), BOOL_FLAG(true),NONE(),
  "Enables (very) experimental code to break algebraic loops using the delay() operator. Probably messes with initialization.");
constant ConfigFlag TEARING_METHOD = CONFIG_FLAG(41, "tearingMethod",
  NONE(), EXTERNAL(), STRING_FLAG("cellier"),
  SOME(STRING_DESC_OPTION({
    ("noTearing", "Deprecated, use minimalTearing."),
    ("minimalTearing", "Minimal tearing method to only tear discrete variables."),
    ("omcTearing", "Tearing method developed by TU Dresden: Frenkel, Schubert."),
    ("cellier", "Tearing based on Celliers method, revised by FH Bielefeld: Täuber, Patrick"),
    ("guruTearing", "Tearing based solely on TearingSelect annotation. Forces prefer/always variables to be iteration variables.")})),
  "Sets the tearing method to use. Select no tearing or choose tearing method.");
constant ConfigFlag TEARING_HEURISTIC = CONFIG_FLAG(42, "tearingHeuristic",
  NONE(), EXTERNAL(), STRING_FLAG("MC3"),
  SOME(STRING_DESC_OPTION({
    ("MC1", "Original cellier with consideration of impossible assignments and discrete Vars."),
    ("MC2", "Modified cellier, drop first step."),
    ("MC11", "Modified MC1, new last step 'count impossible assignments'."),
    ("MC21", "Modified MC2, new last step 'count impossible assignments'."),
    ("MC12", "Modified MC1, step 'count impossible assignments' before last step."),
    ("MC22", "Modified MC2, step 'count impossible assignments' before last step."),
    ("MC13", "Modified MC1, build sum of impossible assignment and causalizable equations, choose var with biggest sum."),
    ("MC23", "Modified MC2, build sum of impossible assignment and causalizable equations, choose var with biggest sum."),
    ("MC231", "Modified MC23, Two rounds, choose better potentials-set."),
    ("MC3", "Modified cellier, build sum of impossible assignment and causalizable equations for all vars, choose var with biggest sum."),
    ("MC4", "Modified cellier, use all heuristics, choose var that occurs most in potential sets")})),
  "Sets the tearing heuristic to use for Cellier-tearing.");
constant ConfigFlag SCALARIZE_MINMAX = CONFIG_FLAG(43, "scalarizeMinMax",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Scalarizes the builtin min/max reduction operators if true.");
constant ConfigFlag STRICT = CONFIG_FLAG(44, "strict",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Enables stricter enforcement of Modelica language rules.");
constant ConfigFlag SCALARIZE_BINDINGS = CONFIG_FLAG(45, "scalarizeBindings",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Always scalarizes bindings if set.");
constant ConfigFlag CORBA_OBJECT_REFERENCE_FILE_PATH = CONFIG_FLAG(46, "corbaObjectReferenceFilePath",
  NONE(), EXTERNAL(), STRING_FLAG(""), NONE(),
  "Sets the path for corba object reference file if -d=interactiveCorba is used.");
constant ConfigFlag HPCOM_SCHEDULER = CONFIG_FLAG(47, "hpcomScheduler",
  NONE(), EXTERNAL(), STRING_FLAG("level"), NONE(),
  "Sets the scheduler for task graph scheduling (list | listr | level | levelfix | ext | metis | mcp | taskdep | tds | bls | rand | none). Default: level.");
constant ConfigFlag HPCOM_CODE = CONFIG_FLAG(48, "hpcomCode",
  NONE(), EXTERNAL(), STRING_FLAG("openmp"), NONE(),
  "Sets the code-type produced by hpcom (openmp | pthreads | pthreads_spin | tbb | mpi). Default: openmp.");
constant ConfigFlag REWRITE_RULES_FILE = CONFIG_FLAG(49, "rewriteRulesFile", NONE(), EXTERNAL(),
  STRING_FLAG(""), NONE(),
  "Activates user given rewrite rules for Absyn expressions. The rules are read from the given file and are of the form rewrite(fromExp, toExp);");
constant ConfigFlag REPLACE_HOMOTOPY = CONFIG_FLAG(50, "replaceHomotopy",
  NONE(), EXTERNAL(), STRING_FLAG("none"),
  SOME(STRING_DESC_OPTION({
    ("none", "Default, do not replace homotopy."),
    ("actual", "Replace homotopy(actual, simplified) with actual."),
    ("simplified", "Replace homotopy(actual, simplified) with simplified.")
    })),
  "Replaces homotopy(actual, simplified) with the actual expression or the simplified expression. Good for debugging models which use homotopy. The default is to not replace homotopy.");
constant ConfigFlag GENERATE_DYNAMIC_JACOBIAN = CONFIG_FLAG(51, "generateDynamicJacobian",
  NONE(), EXTERNAL(), STRING_FLAG("numeric"),
  SOME(STRING_DESC_OPTION({
    ("none", "Does not generate Jacobian. For use with explicit solvers."),
    ("numeric", "Generates sparsity pattern for numeric Jacobian."),
    ("symbolic", "Generates symbolic Jacobian. Used by dassl or ida solver with simulation flag '-jacobian'."),
    ("symbolicadjoint", "Generates adjoint Jacobian symbolically.")
    })),
  "Select how Jacobian matrix is generated, where der(x) is differentiated w.r.t. x.");
constant ConfigFlag GENERATE_SYMBOLIC_LINEARIZATION = CONFIG_FLAG(52, "generateSymbolicLinearization",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Generates symbolic linearization matrices A,B,C,D for linear model:\n\t\t:math:`\\dot{x} = Ax + Bu`\n\t\t:math:`y = Cx + Du`");
constant ConfigFlag INT_ENUM_CONVERSION = CONFIG_FLAG(53, "intEnumConversion",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Allow Integer to enumeration conversion.");
constant ConfigFlag PROFILING_LEVEL = CONFIG_FLAG(54, "profiling",
  NONE(), EXTERNAL(), STRING_FLAG("none"), SOME(STRING_DESC_OPTION({
    ("none","Generate code without profiling"),
    ("blocks","Generate code for profiling function calls as well as linear and non-linear systems of equations"),
    ("blocks+html","Like blocks, but also run xsltproc and gnuplot to generate an html report"),
    ("all","Generate code for profiling of all functions and equations"),
    ("all_perf","Generate code for profiling of all functions and equations with additional performance data using the papi-interface (cpp-runtime)"),
    ("all_stat","Generate code for profiling of all functions and equations with additional statistics (cpp-runtime)")
    })),
  "Sets the profiling level to use. Profiled equations and functions record execution time and count for each time step taken by the integrator.");
constant ConfigFlag RESHUFFLE = CONFIG_FLAG(55, "reshuffle",
  NONE(), EXTERNAL(), INT_FLAG(1), NONE(),
  "sets tolerance of reshuffling algorithm: 1: conservative, 2: more tolerant, 3 resolve all");
constant ConfigFlag GENERATE_DYN_OPTIMIZATION_PROBLEM = CONFIG_FLAG(56, "gDynOpt",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Generate dynamic optimization problem based on annotation approach.");
constant ConfigFlag MAX_SIZE_FOR_SOLVE_LINIEAR_SYSTEM = CONFIG_FLAG(57, "maxSizeSolveLinearSystem",
  NONE(), EXTERNAL(), INT_FLAG(0), NONE(),
  "Max size for solveLinearSystem.");
constant ConfigFlag CPP_FLAGS = CONFIG_FLAG(58, "cppFlags",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({""}), NONE(),
  "Sets extra flags for compilation with the C++ compiler (e.g. +cppFlags=-O3,-Wall)");
constant ConfigFlag REMOVE_SIMPLE_EQUATIONS = CONFIG_FLAG(59, "removeSimpleEquations",
  NONE(), EXTERNAL(), STRING_FLAG("default"),
  SOME(STRING_DESC_OPTION({
    ("none", "Disables module"),
    ("default", "Performs alias elimination and removes constant variables. Default case uses in preOpt phase the fastAcausal and in postOpt phase the causal implementation."),
    ("causal", "Performs alias elimination and removes constant variables. Causal implementation."),
    ("fastAcausal", "Performs alias elimination and removes constant variables. fastImplementation fastAcausal."),
    ("allAcausal", "Performs alias elimination and removes constant variables. Implementation allAcausal."),
    ("new", "New implementation (experimental)")
    })),
  "Specifies method that removes simple equations.");
constant ConfigFlag DYNAMIC_TEARING = CONFIG_FLAG(60, "dynamicTearing",
  NONE(), EXTERNAL(), STRING_FLAG("false"),
  SOME(STRING_DESC_OPTION({
    ("false", "No dynamic tearing."),
    ("true", "Dynamic tearing for linear and nonlinear systems."),
    ("linear", "Dynamic tearing only for linear systems."),
    ("nonlinear", "Dynamic tearing only for nonlinear systems.")
  })),
  "Activates dynamic tearing (TearingSet can be changed automatically during runtime, strict set vs. casual set.)");
constant ConfigFlag SYM_SOLVER = CONFIG_FLAG(61, "symSolver",
  NONE(), EXTERNAL(), ENUM_FLAG(0, {("none",0), ("impEuler", 1), ("expEuler",2)}), SOME(STRING_OPTION({"none", "impEuler", "expEuler"})),
  "Activates symbolic implicit solver (original system is not changed).");
constant ConfigFlag LOOP2CON = CONFIG_FLAG(62, "loop2con",
  NONE(), EXTERNAL(), STRING_FLAG("none"),
  SOME(STRING_DESC_OPTION({
    ("none", "Disables module"),
    ("lin", "linear loops --> constraints"),
    ("noLin", "no linear loops --> constraints"),
    ("all", "loops --> constraints")})),
  "Specifies method that transform loops in constraints. hint: using initial guess from file!");
constant ConfigFlag FORCE_TEARING = CONFIG_FLAG(63, "forceTearing",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Use tearing set even if it is not smaller than the original component.");
constant ConfigFlag SIMPLIFY_LOOPS = CONFIG_FLAG(64, "simplifyLoops",
  NONE(), EXTERNAL(), INT_FLAG(0),
  SOME(STRING_DESC_OPTION({
    ("0", "do nothing"),
    ("1", "special modification of residual expressions"),
    ("2", "special modification of residual expressions with helper variables")
    })),
  "Simplify algebraic loops.");
constant ConfigFlag RTEARING = CONFIG_FLAG(65, "recursiveTearing",
  NONE(), EXTERNAL(), INT_FLAG(0),
  SOME(STRING_DESC_OPTION({
    ("0", "do nothing"),
    ("1", "linear tearing set of size 1"),
    ("2", "linear tearing")
    })),
  "Inline and repeat tearing.");
constant ConfigFlag FLOW_THRESHOLD = CONFIG_FLAG(66, "flowThreshold",
  NONE(), EXTERNAL(), REAL_FLAG(1e-7), NONE(),
  "Sets the minium threshold for stream flow rates");
constant ConfigFlag MATRIX_FORMAT = CONFIG_FLAG(67, "matrixFormat",
  NONE(), EXTERNAL(), STRING_FLAG("dense"), NONE(),
  "Sets the matrix format type in cpp runtime which should be used (dense | sparse ). Default: dense.");
constant ConfigFlag PARTLINTORN = CONFIG_FLAG(68, "partlintorn",
  NONE(), EXTERNAL(), INT_FLAG(0), NONE(),
  "Sets the limit for partitionin of linear torn systems.");
constant ConfigFlag INIT_OPT_MODULES = CONFIG_FLAG(69, "initOptModules",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({
    "simplifyComplexFunction",
    "tearingSystem",
    "solveSimpleEquations",
    "calculateStrongComponentJacobians",
    "simplifyAllExpressions",
    "collapseArrayExpressions"
    }),
  SOME(STRING_DESC_OPTION({
    ("calculateStrongComponentJacobians", "Generates analytical jacobian for torn linear and non-linear strong components. By default linear components and non-linear components with user-defined function calls are skipped. See also debug flags: LSanalyticJacobian, NLSanalyticJacobian and forceNLSanalyticJacobian"),
    ("collapseArrayExpressions", collapseArrayExpressionsText),
    ("inlineArrayEqn", "This module expands all array equations to scalar equations."),
    ("constantLinearSystem", "Evaluates constant linear systems (a*x+b*y=c; d*x+e*y=f; a,b,c,d,e,f are constants) at compile-time."),
    ("extendDynamicOptimization", "Move loops to constraints."),
    ("generateHomotopyComponents", "Finds the parts of the DAE that have to be handled by the homotopy solver and creates a strong component out of it."),
    ("inlineHomotopy", "Experimental: Inlines the homotopy expression to allow symbolic simplifications."),
    ("inputDerivativesUsed", "Checks if derivatives of inputs are need to calculate the model."),
    ("recursiveTearing", "inline and repeat tearing"),
    ("reduceDynamicOptimization", "Removes equations which are not needed for the calculations of cost and constraints. This module requires --postOptModules+=reduceDynamicOptimization."),
    ("replaceHomotopyWithSimplified", "Replaces the homotopy expression homotopy(actual, simplified) with the simplified part."),
    ("simplifyAllExpressions", "Does simplifications on all expressions."),
    ("simplifyComplexFunction", "Some simplifications on complex functions (complex refers to the internal data structure)"),
    ("simplifyConstraints", "Rewrites nonlinear constraints into box constraints if possible. This module requires +gDynOpt."),
    ("simplifyLoops", "Simplifies algebraic loops. This modules requires +simplifyLoops."),
    ("solveSimpleEquations", "Solves simple equations"),
    ("tearingSystem", "For method selection use flag tearingMethod."),
    ("wrapFunctionCalls", "This module introduces variables for each function call and substitutes all these calls with the newly introduced variables.")
    })),
  "Sets the initialization optimization modules to use in the back end. See --help=optmodules for more info.");
constant ConfigFlag MAX_MIXED_DETERMINED_INDEX = CONFIG_FLAG(70, "maxMixedDeterminedIndex",
  NONE(), EXTERNAL(), INT_FLAG(10), NONE(),
  "Sets the maximum mixed-determined index that is handled by the initialization.");
constant ConfigFlag USE_LOCAL_DIRECTION = CONFIG_FLAG(71, "useLocalDirection",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Keeps the input/output prefix for all variables in the flat model, not only top-level ones.");
constant ConfigFlag DEFAULT_OPT_MODULES_ORDERING = CONFIG_FLAG(72, "defaultOptModulesOrdering",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  "If this is activated, then the specified pre-/post-/init-optimization modules will be rearranged to the recommended ordering.");
constant ConfigFlag PRE_OPT_MODULES_ADD = CONFIG_FLAG(73, "preOptModules+",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  "Enables additional pre-optimization modules, e.g. --preOptModules+=module1,module2 would additionally enable module1 and module2. See --help=optmodules for more info.");
constant ConfigFlag PRE_OPT_MODULES_SUB = CONFIG_FLAG(74, "preOptModules-",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  "Disables a list of pre-optimization modules, e.g. --preOptModules-=module1,module2 would disable module1 and module2. See --help=optmodules for more info.");
constant ConfigFlag POST_OPT_MODULES_ADD = CONFIG_FLAG(75, "postOptModules+",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  "Enables additional post-optimization modules, e.g. --postOptModules+=module1,module2 would additionally enable module1 and module2. See --help=optmodules for more info.");
constant ConfigFlag POST_OPT_MODULES_SUB = CONFIG_FLAG(76, "postOptModules-",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  "Disables a list of post-optimization modules, e.g. --postOptModules-=module1,module2 would disable module1 and module2. See --help=optmodules for more info.");
constant ConfigFlag INIT_OPT_MODULES_ADD = CONFIG_FLAG(77, "initOptModules+",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  "Enables additional init-optimization modules, e.g. --initOptModules+=module1,module2 would additionally enable module1 and module2. See --help=optmodules for more info.");
constant ConfigFlag INIT_OPT_MODULES_SUB = CONFIG_FLAG(78, "initOptModules-",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  "Disables a list of init-optimization modules, e.g. --initOptModules-=module1,module2 would disable module1 and module2. See --help=optmodules for more info.");
constant ConfigFlag PERMISSIVE = CONFIG_FLAG(79, "permissive",
  NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "Disables some error checks to allow erroneous models to compile.");
constant ConfigFlag HETS = CONFIG_FLAG(80, "hets",
  NONE(), INTERNAL(), STRING_FLAG("none"),SOME(
    STRING_DESC_OPTION({
    ("none", "do nothing"),
    ("derCalls", "sort terms based on der-calls")
    })),
  "Heuristic equation terms sort");
constant ConfigFlag DEFAULT_CLOCK_PERIOD = CONFIG_FLAG(81, "defaultClockPeriod",
  NONE(), INTERNAL(), REAL_FLAG(1.0), NONE(),
  "Sets the default clock period (in seconds) for state machines (default: 1.0).");
constant ConfigFlag INST_CACHE_SIZE = CONFIG_FLAG(82, "instCacheSize",
  NONE(), EXTERNAL(), INT_FLAG(25343), NONE(),
  "Sets the size of the internal hash table used for instantiation caching.");
constant ConfigFlag MAX_SIZE_LINEAR_TEARING = CONFIG_FLAG(83, "maxSizeLinearTearing",
  NONE(), EXTERNAL(), INT_FLAG(200), NONE(),
  "Sets the maximum system size for tearing of linear systems (default 200).");
constant ConfigFlag MAX_SIZE_NONLINEAR_TEARING = CONFIG_FLAG(84, "maxSizeNonlinearTearing",
  NONE(), EXTERNAL(), INT_FLAG(10000), NONE(),
  "Sets the maximum system size for tearing of nonlinear systems (default 10000).");
constant ConfigFlag NO_TEARING_FOR_COMPONENT = CONFIG_FLAG(85, "noTearingForComponent",
  NONE(), EXTERNAL(), INT_LIST_FLAG({}), NONE(),
  "Deactivates tearing for the specified components.\nUse '-d=tearingdump' to find out the relevant indexes.");
constant ConfigFlag CT_STATE_MACHINES = CONFIG_FLAG(86, "ctStateMachines",
  NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "Experimental: Enable continuous-time state machine prototype");
constant ConfigFlag DAE_MODE = CONFIG_FLAG(87, "daeMode",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Generates code to simulate models in DAE mode. The whole system is passed directly to the DAE solver SUNDIALS/IDA and no algebraic solver is involved in the simulation process.");
constant ConfigFlag INLINE_METHOD = CONFIG_FLAG(88, "inlineMethod",
  NONE(), EXTERNAL(), ENUM_FLAG(1, {("replace",1), ("append",2)}),
  SOME(STRING_OPTION({"replace", "append"})),
  "Sets the inline method to use.\n"+
               "replace : This method inlines by replacing in place all expressions. Might lead to very long expression.\n"+
               "append  : This method inlines by adding additional variables to the whole system. Might lead to much bigger system.");
constant ConfigFlag SET_TEARING_VARS = CONFIG_FLAG(89, "setTearingVars",
  NONE(), EXTERNAL(), INT_LIST_FLAG({}), NONE(),
  "Sets the tearing variables by its strong component indexes. Use '-d=tearingdump' to find out the relevant indexes.\nUse following format: '--setTearingVars=(sci,n,t1,...,tn)*', with sci = strong component index, n = number of tearing variables, t1,...tn = tearing variables.\nE.g.: '--setTearingVars=4,2,3,5' would select variables 3 and 5 in strong component 4.");
constant ConfigFlag SET_RESIDUAL_EQNS = CONFIG_FLAG(90, "setResidualEqns",
  NONE(), EXTERNAL(), INT_LIST_FLAG({}), NONE(),
  "Sets the residual equations by its strong component indexes. Use '-d=tearingdump' to find out the relevant indexes for the collective equations.\nUse following format: '--setResidualEqns=(sci,n,r1,...,rn)*', with sci = strong component index, n = number of residual equations, r1,...rn = residual equations.\nE.g.: '--setResidualEqns=4,2,3,5' would select equations 3 and 5 in strong component 4.\nOnly works in combination with 'setTearingVars'.");
constant ConfigFlag IGNORE_COMMAND_LINE_OPTIONS_ANNOTATION = CONFIG_FLAG(91, "ignoreCommandLineOptionsAnnotation",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Ignores the command line options specified as annotation in the class.");
constant ConfigFlag CALCULATE_SENSITIVITIES = CONFIG_FLAG(92, "calculateSensitivities",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Generates sensitivities variables and matrices.");
constant ConfigFlag ALARM = CONFIG_FLAG(93, "alarm",
  SOME("r"), EXTERNAL(), INT_FLAG(0), NONE(),
  "Sets the number seconds until omc timeouts and exits. Used by the testing framework to terminate infinite running processes.");
constant ConfigFlag TOTAL_TEARING = CONFIG_FLAG(94, "totalTearing",
  NONE(), EXTERNAL(), INT_LIST_FLAG({}), NONE(),
  "Activates total tearing (determination of all possible tearing sets) for the specified components.\nUse '-d=tearingdump' to find out the relevant indexes.");
constant ConfigFlag IGNORE_SIMULATION_FLAGS_ANNOTATION = CONFIG_FLAG(95, "ignoreSimulationFlagsAnnotation",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Ignores the simulation flags specified as annotation in the class.");
constant ConfigFlag DYNAMIC_TEARING_FOR_INITIALIZATION = CONFIG_FLAG(96, "dynamicTearingForInitialization",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Enable Dynamic Tearing also for the initialization system.");
constant ConfigFlag PREFER_TVARS_WITH_START_VALUE = CONFIG_FLAG(97, "preferTVarsWithStartValue",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  "Prefer tearing variables with start value for initialization.");
constant ConfigFlag EQUATIONS_PER_FILE = CONFIG_FLAG(98, "equationsPerFile",
  NONE(), EXTERNAL(), INT_FLAG(500), NONE(),
  "Generate code for at most this many equations per C-file (partially implemented in the compiler).");
constant ConfigFlag EVALUATE_FINAL_PARAMS = CONFIG_FLAG(99, "evaluateFinalParameters",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Evaluates all the final parameters in addition to parameters with annotation(Evaluate=true).");
constant ConfigFlag EVALUATE_PROTECTED_PARAMS = CONFIG_FLAG(100, "evaluateProtectedParameters",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Evaluates all the protected parameters in addition to parameters with annotation(Evaluate=true).");
constant ConfigFlag REPLACE_EVALUATED_PARAMS = CONFIG_FLAG(101, "replaceEvaluatedParameters",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  "Replaces all the evaluated parameters in the DAE.");
constant ConfigFlag CONDENSE_ARRAYS = CONFIG_FLAG(102, "condenseArrays",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  "Sets whether array expressions containing function calls are condensed or not.");
constant ConfigFlag WFC_ADVANCED = CONFIG_FLAG(103, "wfcAdvanced",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "wrapFunctionCalls ignores more then default cases, e.g. exp, sin, cos, log, (experimental flag)");
constant ConfigFlag GRAPHICS_EXP_MODE = CONFIG_FLAG(104,
  "graphicsExpMode", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "Sets whether we are in graphics exp mode (evaluating icons).");
constant ConfigFlag TEARING_STRICTNESS = CONFIG_FLAG(105, "tearingStrictness",
  NONE(), EXTERNAL(), STRING_FLAG("strict"),SOME(
    STRING_DESC_OPTION({
    ("casual", "Loose tearing rules using ExpressionSolve to determine the solvability instead of considering the partial derivative. Allows to solve for everything that is analytically possible. This could lead to singularities during simulation."),
    ("strict", "Robust tearing rules by consideration of the partial derivative. Allows to divide by parameters that are not equal to or close to zero."),
    ("veryStrict", "Very strict tearing rules that do not allow to divide by any parameter. Use this if you aim at overriding parameters after compilation with values equal to or close to zero.")
    })),
  "Sets the strictness of the tearing method regarding the solvability restrictions.");
constant ConfigFlag INTERACTIVE = CONFIG_FLAG(106, "interactive",
  NONE(), EXTERNAL(), STRING_FLAG("none"),SOME(
    STRING_DESC_OPTION({
    ("none", "do nothing"),
    ("corba", "Starts omc as a server listening on the Corba interface."),
    ("tcp", "Starts omc as a server listening on the socket interface."),
    ("zmq", "Starts omc as a ZeroMQ server listening on the socket interface.")
    })),
  "Sets the interactive mode for omc.");
constant ConfigFlag ZEROMQ_FILE_SUFFIX = CONFIG_FLAG(107, "zeroMQFileSuffix",
  SOME("z"), EXTERNAL(), STRING_FLAG(""), NONE(),
  "Sets the file suffix for zeroMQ port file if --interactive=zmq is used.");
constant ConfigFlag HOMOTOPY_APPROACH = CONFIG_FLAG(108, "homotopyApproach",
  NONE(), EXTERNAL(), STRING_FLAG("equidistantGlobal"),
  SOME(STRING_DESC_OPTION({
    ("equidistantLocal", "Local homotopy approach with equidistant lambda steps. The homotopy parameter only effects the local strongly connected component."),
    ("adaptiveLocal", "Local homotopy approach with adaptive lambda steps. The homotopy parameter only effects the local strongly connected component."),
    ("equidistantGlobal", "Default, global homotopy approach with equidistant lambda steps. The homotopy parameter effects the entire initialization system."),
    ("adaptiveGlobal", "Global homotopy approach with adaptive lambda steps. The homotopy parameter effects the entire initialization system.")
    })),
  "Sets the homotopy approach.");
constant ConfigFlag IGNORE_REPLACEABLE = CONFIG_FLAG(109, "ignoreReplaceable",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Sets whether to ignore replaceability or not when redeclaring.");
constant ConfigFlag LABELED_REDUCTION = CONFIG_FLAG(110,
  "labeledReduction", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "Turns on labeling and reduce terms to do whole process of reduction.");
constant ConfigFlag DISABLE_EXTRA_LABELING = CONFIG_FLAG(111,
  "disableExtraLabeling", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "Disable adding extra label into the whole expression with more than one term and +,- operations.");
constant ConfigFlag LOAD_MSL_MODEL = CONFIG_FLAG(112,
  "loadMSLModel", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "Used to know loadFile doesn't need to be called in cpp-runtime (for labeled model reduction).");
constant ConfigFlag LOAD_PACKAGE_FILE = CONFIG_FLAG(113,
  "loadPackageFile", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "Used when the outside name is different with the inside name of the packge, in cpp-runtime (for labeled model reduction).");
constant ConfigFlag BUILDING_FMU = CONFIG_FLAG(114,
  "", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "Is true when building an FMU (so the compiler can look for URIs to package as FMI resources).");
constant ConfigFlag BUILDING_MODEL = CONFIG_FLAG(115,
  "", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "Is true when building a model (as opposed to running a Modelica script).");
constant ConfigFlag POST_OPT_MODULES_DAE = CONFIG_FLAG(116, "postOptModulesDAE",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({
    "lateInlineFunction",
    "wrapFunctionCalls",
    //"replaceDerCalls",
    "simplifysemiLinear",
    "simplifyComplexFunction",
    "removeConstants",
    "simplifyTimeIndepFuncCalls",
    "simplifyAllExpressions",
    "findZeroCrossings",
    "createDAEmodeBDAE",
    "symbolicJacobianDAE",
    "setEvaluationStage"
    }),NONE(),
  "Sets the optimization modules for the DAEmode in the back end. See --help=optmodules for more info.");
constant ConfigFlag EVAL_LOOP_LIMIT = CONFIG_FLAG(117,
  "evalLoopLimit", NONE(), EXTERNAL(), INT_FLAG(100000), NONE(),
  "The loop iteration limit used when evaluating constant function calls.");
constant ConfigFlag EVAL_RECURSION_LIMIT = CONFIG_FLAG(118,
  "evalRecursionLimit", NONE(), EXTERNAL(), INT_FLAG(256), NONE(),
  "The recursion limit used when evaluating constant function calls.");
constant ConfigFlag SINGLE_INSTANCE_AGLSOLVER = CONFIG_FLAG(119, "singleInstanceAglSolver",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Sets to instantiate only  one algebraic loop solver all algebraic loops");
constant ConfigFlag SHOW_STRUCTURAL_ANNOTATIONS = CONFIG_FLAG(120, "showStructuralAnnotations",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Show annotations affecting the solution process in the flattened code.");
constant ConfigFlag INITIAL_STATE_SELECTION = CONFIG_FLAG(121, "initialStateSelection",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Activates the state selection inside initialization to avoid singularities.");
constant ConfigFlag LINEARIZATION_DUMP_LANGUAGE = CONFIG_FLAG(122, "linearizationDumpLanguage",
  NONE(), EXTERNAL(), STRING_FLAG("none"),
  SOME(STRING_DESC_OPTION({
    ("none", "Don't generate code for linearization."),
    ("modelica", "Generate linearized Modelica model."),
    ("matlab", "Generate matlab function that returns linearization matrices A,B,C,D."),
    ("julia", "Generate julia function that returns linearization matrices A,B,C,D."),
    ("python", "Generate python function that returns linearization matrices A,B,C,D.")})),
  "Sets the target language for the produced code of linearization.");
constant ConfigFlag NO_ASSC = CONFIG_FLAG(123, "noASSC",
  NONE(), EXTERNAL(),  BOOL_FLAG(false), NONE(),
  "Disables analytical to structural singularity conversion.");
constant ConfigFlag FULL_ASSC = CONFIG_FLAG(124, "fullASSC",
  NONE(), EXTERNAL(),  BOOL_FLAG(false), NONE(),
  "Enables full equation replacement for BLT transformation from the ASSC algorithm.");
constant ConfigFlag REAL_ASSC = CONFIG_FLAG(125, "realASSC",
  NONE(), EXTERNAL(),  BOOL_FLAG(false), NONE(),
  "Enables the ASSC algorithm to evaluate real valued coefficients (usually only integers).");
constant ConfigFlag INIT_ASSC = CONFIG_FLAG(126, "initASSC",
  NONE(), EXTERNAL(),  BOOL_FLAG(false), NONE(),
  "Enables the ASSC algorithm for initialization.");
constant ConfigFlag MAX_SIZE_ASSC = CONFIG_FLAG(127, "maxSizeASSC",
  NONE(), EXTERNAL(), INT_FLAG(200), NONE(),
  "Sets the maximum system size for the analytical to structural conversion algorithm (default 200).");
constant ConfigFlag USE_ZEROMQ_IN_SIM = CONFIG_FLAG(128, "useZeroMQInSim",
  NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  "Configures to use zeroMQ in simulation runtime to exchange information via ZeroMQ with other applications");
constant ConfigFlag ZEROMQ_PUB_PORT = CONFIG_FLAG(129, "zeroMQPubPort",
  NONE(), INTERNAL(), INT_FLAG(3203), NONE(),
  "Configures port number for simulation runtime to send information via ZeroMQ");
constant ConfigFlag ZEROMQ_SUB_PORT = CONFIG_FLAG(130, "zeroMQSubPort",
  NONE(), INTERNAL(), INT_FLAG(3204), NONE(),
  "Configures port number for simulation runtime to receive information via ZeroMQ");
constant ConfigFlag ZEROMQ_JOB_ID = CONFIG_FLAG(131, "zeroMQJOBID",
  NONE(), INTERNAL(), STRING_FLAG("empty"), NONE(),
  "Configures the ID with which the omc api call is labelled for zeroMQ communication.");
constant ConfigFlag ZEROMQ_SERVER_ID = CONFIG_FLAG(132, "zeroMQServerID",
  NONE(), INTERNAL(), STRING_FLAG("empty"), NONE(),
  "Configures the ID with which server application is labelled for zeroMQ communication.");
constant ConfigFlag ZEROMQ_CLIENT_ID = CONFIG_FLAG(133, "zeroMQClientID",
  NONE(), INTERNAL(), STRING_FLAG("empty"), NONE(),
  "Configures the ID with which the client application is labelled for zeroMQ communication.");
constant ConfigFlag FMI_VERSION = CONFIG_FLAG(134,
  "", NONE(), INTERNAL(), STRING_FLAG(""), NONE(),
  "returns the FMI Version either 1.0 or 2.0.");
constant ConfigFlag BASE_MODELICA = CONFIG_FLAG(135, "baseModelica",
  SOME("f"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Outputs experimental Base Modelica.");
constant ConfigFlag FMI_FILTER = CONFIG_FLAG(136, "fmiFilter", NONE(), EXTERNAL(),
  ENUM_FLAG(FMI_PROTECTED, {("none", FMI_NONE), ("internal", FMI_INTERNAL), ("protected", FMI_PROTECTED), ("blackBox", FMI_BLACKBOX)}),
  SOME(STRING_DESC_OPTION({
    ("none", "All variables are exposed, even variables introduced by the symbolic transformations. This is mainly for debugging purposes."),
    ("internal", "All model variables are exposed, including protected ones. Variables introduced by the symbolic transformations are filtered out, with minor exceptions, e.g. for state sets."),
    ("protected", "All public model variables are exposed. Internal and protected variables are filtered out, with small exceptions, e.g. for state sets."),
    ("blackBox", "Only the interface is exposed. All other variables are hidden or exposed with concealed names.")
    })),
  "Specifies which model variables are exposed by the modelDescription.xml");
constant ConfigFlag FMI_SOURCES = CONFIG_FLAG(137, "fmiSources", NONE(), EXTERNAL(),
  BOOL_FLAG(true), NONE(),
  "Defines if FMUs will be exported with sources or not. --fmiFilter=blackBox might override this, because black box FMUs do never contain their source code.");
constant ConfigFlag FMI_FLAGS = CONFIG_FLAG(138, "fmiFlags", NONE(), EXTERNAL(),
  STRING_LIST_FLAG({}), NONE(),
  "Add simulation flags to FMU. Will create <fmiPrefix>_flags.json in resources folder with given flags. Use --fmiFlags or --fmiFlags=none to disable [default]. Use --fmiFlags=default for the default simulation flags. To pass flags use e.g. --fmiFlags=s:cvode,nls:homotopy or --fmiFlags=path/to/yourFlags.json.");
constant ConfigFlag FMU_CMAKE_BUILD = CONFIG_FLAG(139, "fmuCMakeBuild",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  "Configured and build FMU with CMake if true.");
constant ConfigFlag NEW_BACKEND = CONFIG_FLAG(140, "newBackend",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Activates experimental new backend for better array handling. This also activates the new frontend. [WIP]");
constant ConfigFlag PARMODAUTO = CONFIG_FLAG(141, "parmodauto",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Experimental: Enable parallelization of independent systems of equations in the translated model. Only works on Linux systems.");
constant ConfigFlag INTERACTIVE_PORT = CONFIG_FLAG(142, "interactivePort",
  NONE(), EXTERNAL(), INT_FLAG(0), NONE(),
  "Sets the port used by the interactive server.");
constant ConfigFlag ALLOW_NON_STANDARD_MODELICA = CONFIG_FLAG(143, "allowNonStandardModelica",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({
    }),
  SOME(STRING_DESC_OPTION({
    ("nonStdMultipleExternalDeclarations", "Allow several external declarations in functions.\nSee: https://specification.modelica.org/maint/3.5/functions.html#function-as-a-specialized-class"),
    ("nonStdEnumerationAsIntegers", "Allow enumeration as integer without casting via Integer(Enum).\nSee: https://specification.modelica.org/maint/3.5/class-predefined-types-and-declarations.html#type-conversion-of-enumeration-values-to-string-or-integer"),
    ("nonStdIntegersAsEnumeration", "Allow integer as enumeration without casting via Enum(Integer).\nSee: https://specification.modelica.org/maint/3.5/class-predefined-types-and-declarations.html#type-conversion-of-integer-to-enumeration-values"),
    ("nonStdDifferentCaseFileVsClassName", "Allow directory or file with different case in the name than the contained class name.\nSee: https://specification.modelica.org/maint/3.5/packages.html#mapping-package-class-structures-to-a-hierarchical-file-system"),
    ("nonStdTopLevelOuter", "Allow top level outer.\nSee: https://specification.modelica.org/maint/3.6/scoping-name-lookup-and-flattening.html#S4.p1"),
    ("protectedAccess", "Allow access of protected elements"),
    ("reinitInAlgorithms", "Allow reinit in algorithm sections"),
    ("unbalancedModel", "Allow models to be locally unbalanced and to have unbalanced connectors"),
    ("implicitParameterStartAttribute", "Allow fixed parameters with no binding or start attribute"),
    ("initialSimplified", "Allow use of experimental operator `initialSimplified()`"),
    ("illegalConditionalContext", "Allow use of components with false conditions in illegal contexts")
    })),
  "Flags to allow non-standard Modelica.");
constant ConfigFlag EXPORT_CLOCKS_IN_MODELDESCRIPTION = CONFIG_FLAG(144, "exportClocksInModelDescription",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "exports clocks in modeldescription.xml for fmus, The default is false.");
constant ConfigFlag LINK_TYPE = CONFIG_FLAG(145, "linkType",
  NONE(), EXTERNAL(), ENUM_FLAG(1, {("dynamic",1), ("static",2)}),
  SOME(STRING_OPTION({"dynamic", "static"})),
  "Sets the link type for the simulation executable.\n"+
               "dynamic: libraries are dynamically linked; the executable is built very fast but is not portable because of DLL dependencies.\n"+
               "static: libraries are statically linked; the executable is built more slowly but it is portable and dependency-free.\n");
constant ConfigFlag TEARING_ALWAYS_DERIVATIVES = CONFIG_FLAG(146, "tearingAlwaysDer",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Always choose state derivatives as iteration variables in strong components.");
constant ConfigFlag DUMP_FLAT_MODEL = CONFIG_FLAG(147, "dumpFlatModel",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({"all"}),
  SOME(STRING_DESC_OPTION({
    ("flatten", "After flattening but before connection handling."),
    ("connections", "After connection handling."),
    ("eval", "After evaluating constants."),
    ("simplify", "After model simplification."),
    ("scalarize", "After scalarizing arrays."),
    ("translateResidualsDAE", "Show the result of the translateResidualsDAE API.")
  })),
  "Dumps the flat model at the given stages of the frontend.");
constant ConfigFlag SIMULATION = CONFIG_FLAG(148, "simulation",
  SOME("u"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Simulates the last model in the given Modelica file.");
constant ConfigFlag OBFUSCATE = CONFIG_FLAG(149, "obfuscate",
  NONE(), EXTERNAL(), STRING_FLAG("none"),
  SOME(STRING_DESC_OPTION({
    ("none", "No obfuscation."),
    ("encrypted", "Obfuscates protected variables in encrypted models"),
    ("protected", "Obfuscates protected variables in all models."),
    ("full", "Obfuscates everything.")
  })),
  "Obfuscates identifiers in the simulation model");
constant ConfigFlag FMU_RUNTIME_DEPENDS = CONFIG_FLAG(150, "fmuRuntimeDepends",
  NONE(), EXTERNAL(), STRING_FLAG("default"),
  SOME(STRING_DESC_OPTION({
    ("default",  "Depending on CMake version. If CMake version >= 3.21 use  \"modelica\", otherwise use \"none\""),
    ("none",     "No runtime library dependencies are copied into the FMU."),
    ("modelica", "All modelica runtime library dependencies are copied into the FMU." +
                                 "System librarys located in '/lib*', '/usr/lib*' and '/usr/local/lib*' are excluded." +
                                 "Needs --fmuCMakeBuild=true and CMake version >= 3.21."),
    ("all",      "All runtime library dependencies are copied into the FMU." +
                                 "System librarys are copied as well." +
                                 "Needs --fmuCMakeBuild=true and CMake version >= 3.21.")
    })),
  "Defines if runtime library dependencies are included in the FMU. Only used when compiler flag fmuCMakeBuild=true.");
constant ConfigFlag FRONTEND_INLINE = CONFIG_FLAG(151, "frontendInline",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Enables inlining of functions in the frontend.");
constant ConfigFlag EXPOSE_LOCAL_IOS = CONFIG_FLAG(152, "exposeLocalIOs",
  NONE(), EXTERNAL(), INT_FLAG(0), NONE(),
  "Introduces top-level inputs/outputs for unconnected input/output connectors at requested levels, provided they are public, " +
                  "0 meaning top-level (standard Modelica), 1 inputs/outputs of top-level components, >1 going deeper. " +
                  "This flag is particularly useful for FMI export.");
constant ConfigFlag BASE_MODELICA_FORMAT = CONFIG_FLAG(153, "baseModelicaFormat",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), SOME(STRING_DESC_OPTION({
    ("scalarized", "Include subscripts in the quoted identifiers ('a[1].x[3]')."),
    ("partiallyScalarized", "Include subscripts in the quoted identifiers, except for the last name ('a[1].x'[3])."),
    ("nonScalarized", "Don't include subscripts in the quoted identifiers ('a'[1].'x'[3])."),
    ("withRecords", "Keep records and don't expand them."),
    ("withoutRecords", "Expand records into separate components."),
    ("showConfidence", "Add comments that show confidence numbers for binding equations.")
  })),
  "Formatting options for Base Modelica");
constant ConfigFlag BASE_MODELICA_OPTIONS = CONFIG_FLAG(154, "baseModelicaOptions",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), SOME(STRING_DESC_OPTION({
    ("moveBindings", "Moves movable binding equations to normal equations."),
    ("scalarize", "Fully scalarize the Base Modelica model."),
    ("inlineFunctions", "Inline all functions.")
    })),
  "Enables optional Base Modelica options.");
constant ConfigFlag DEBUG_FOLLOW_EQUATIONS = CONFIG_FLAG(155, "debugFollowEquations",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  "Takes a list of equation names and prints the corresponding equations after each stage of the backend process.");
constant ConfigFlag MAX_SIZE_LINEARIZATION = CONFIG_FLAG(156, "maxSizeLinearization",
  NONE(), EXTERNAL(), INT_FLAG(1000), NONE(),
  "Sets the maximum system size for which linearization code is generated.");
constant ConfigFlag RESIZABLE_ARRAYS = CONFIG_FLAG(157, "resizableArrays",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Assumes all arrays are resizable. Only works with the new backend --newBackend.");
constant ConfigFlag EVALUATE_STRUCTURAL_PARAMETERS = CONFIG_FLAG(158, "evaluateStructuralParameters",
  NONE(), EXTERNAL(), STRING_FLAG("all"),
  SOME(STRING_DESC_OPTION({
    ("all", "Evaluates all structural parameters"),
    ("strictlyNecessary", "Evaluates only structural parameters strictly required by the frontend")
  })),
  "Sets which structural parameters are evaluated by the frontend.");
constant ConfigFlag LOAD_MISSING_LIBRARIES = CONFIG_FLAG(159, "loadMissingLibraries",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  "Automatically try to load a matching library if a name can't be found during name lookup.");
constant ConfigFlag CAUSALIZE_DAE_MODE = CONFIG_FLAG(160, "causalizeDaeMode",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  "The system is partially causalized and simple assignments are generated for equations that can be solved explicitly. Only works with --daeMode.");
/* please remove me once this is supported */
constant ConfigFlag SIM_CODE_SCALARIZE = CONFIG_FLAG(161, "simCodeScalarize",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  "Scalarizes variables during simcode phase.");
constant ConfigFlag EXECUTE_COMMAND = CONFIG_FLAG(162, "cmd",
  NONE(), EXTERNAL(), STRING_FLAG(""), NONE(),
  "Executes the string argument as a script before any other operation.");
constant ConfigFlag MOO_DYNAMIC_OPTIMIZATION = CONFIG_FLAG(163, "moo",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  "Generate code for dynamic optimization library MOO.");
constant ConfigFlag FMI_EXTRA_ANNOTATIONS = CONFIG_FLAG(164, "fmiExtraAnnotations",
  NONE(), EXTERNAL(), STRING_FLAG(""), NONE(),
  "Export annotations matching the given regex to extra/org.openmodelica/modelAnnotations.json.");

function getFlags
  "Loads the flags with getGlobalRoot. Assumes flags have been loaded."
  input Boolean initialize = true;
  output Flag flags;
algorithm
  /* FlagsUtil.loadFlags does more, but depends on Error, which depends on Flags */
  flags := getGlobalRoot(Global.flagsIndex);
end getFlags;

function isSet
  "Checks if a debug flag is set."
  input DebugFlag inFlag;
  output Boolean outValue;
protected
  array<Boolean> debug_flags;
  Flag flags;
  Integer index;
algorithm
  DEBUG_FLAG(index = index) := inFlag;
  flags := getFlags();
  FLAGS(debugFlags = debug_flags) := flags;
  outValue := arrayGet(debug_flags, index);
end isSet;

function isConfigFlagSet
  "Checks if a string list config flag contains a certain string"
  input ConfigFlag inFlag "the flag with the list of strings";
  input String hasMember "the string to check for membership";
  output Boolean isMember;
algorithm
  isMember := listMember(hasMember, Flags.getConfigStringList(inFlag));
end isConfigFlagSet;

public function getConfigName
  "Returns name of configuration flag"
  input ConfigFlag inFlag;
  output String name;
algorithm
  CONFIG_FLAG(name = name) := inFlag;
end getConfigName;

public function getConfigValue
  "Returns the value of a configuration flag."
  input ConfigFlag inFlag;
  output FlagData outValue;
protected
  array<FlagData> config_flags;
  Integer index;
  Flag flags;
  String name;
algorithm
  CONFIG_FLAG(name = name, index = index) := inFlag;
  flags := getFlags();
  FLAGS(configFlags = config_flags) := flags;
  outValue := arrayGet(config_flags, index);
end getConfigValue;

function getConfigBool
  "Returns the value of a boolean configuration flag."
  input ConfigFlag inFlag;
  output Boolean outValue;
algorithm
  BOOL_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigBool;

function getConfigInt
  "Returns the value of an integer configuration flag."
  input ConfigFlag inFlag;
  output Integer outValue;
algorithm
  INT_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigInt;

function getConfigIntList
  "Returns the value of an integer configuration flag."
  input ConfigFlag inFlag;
  output list<Integer> outValue;
algorithm
  INT_LIST_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigIntList;

function getConfigReal
  "Returns the value of a real configuration flag."
  input ConfigFlag inFlag;
  output Real outValue;
algorithm
  REAL_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigReal;

function getConfigString
  "Returns the value of a string configuration flag."
  input ConfigFlag inFlag;
  output String outValue;
algorithm
  STRING_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigString;

function getConfigStringList
  "Returns the value of a multiple-string configuration flag."
  input ConfigFlag inFlag;
  output list<String> outValue;
algorithm
  STRING_LIST_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigStringList;

function getConfigEnum
  "Returns the value of an enumeration configuration flag."
  input ConfigFlag inFlag;
  output Integer outValue;
algorithm
  ENUM_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigEnum;

annotation(__OpenModelica_Interface="util");
end Flags;
