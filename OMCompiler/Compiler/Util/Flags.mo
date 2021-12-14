/*
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
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
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
  depending on which type it is.
  "

public
import Gettext;
protected
import Global;

public uniontype DebugFlag
  record DEBUG_FLAG
    Integer index "Unique index.";
    String name "The name of the flag used by -d";
    Boolean default "Default enabled or not";
    Gettext.TranslatableContent description "A description of the flag.";
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
    Gettext.TranslatableContent description "A description of the flag.";
  end CONFIG_FLAG;
end ConfigFlag;

public uniontype FlagData
  "This uniontype is used to store the values of configuration flags."

  record EMPTY_FLAG
    "Only used to initialize the flag array."
  end EMPTY_FLAG;

  record BOOL_FLAG
    "Value of a boolean flag."
    Boolean data;
  end BOOL_FLAG;

  record INT_FLAG
    "Value of an integer flag."
    Integer data;
  end INT_FLAG;

  record INT_LIST_FLAG
    "Value of an integer flag that can have multiple values."
    list<Integer> data;
  end INT_LIST_FLAG;

  record REAL_FLAG
    "Value of a real flag."
    Real data;
  end REAL_FLAG;

  record STRING_FLAG
    "Value of a string flag."
    String data;
  end STRING_FLAG;

  record STRING_LIST_FLAG
    "Values of a string flag that can have multiple values."
    list<String> data;
  end STRING_LIST_FLAG;

  record ENUM_FLAG
    "Value of an enumeration flag."
    Integer data;
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
    "Options for a string flag."
    list<String> options;
  end STRING_OPTION;

  record STRING_DESC_OPTION
    "Options for a string flag, with a description for each option."
    list<tuple<String, Gettext.TranslatableContent>> options;
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

constant Gettext.TranslatableContent collapseArrayExpressionsText = Gettext.gettext("Simplifies {x[1],x[2],x[3]} → x for arrays of whole variable references (simplifies code generation).");

// DEBUG FLAGS
public
constant DebugFlag FAILTRACE = DEBUG_FLAG(1, "failtrace", false,
  Gettext.gettext("Sets whether to print a failtrace or not."));
constant DebugFlag CEVAL = DEBUG_FLAG(2, "ceval", false,
  Gettext.gettext("Prints extra information from Ceval."));
constant DebugFlag CHECK_BACKEND_DAE = DEBUG_FLAG(3, "checkBackendDae", false,
  Gettext.gettext("Do some simple analyses on the datastructure from the frontend to check if it is consistent."));
constant DebugFlag PTHREADS = DEBUG_FLAG(4, "pthreads", false,
  Gettext.gettext("Experimental: Unused parallelization."));
constant DebugFlag EVENTS = DEBUG_FLAG(5, "events", true,
  Gettext.gettext("Turns on/off events handling."));
constant DebugFlag DUMP_INLINE_SOLVER = DEBUG_FLAG(6, "dumpInlineSolver", false,
  Gettext.gettext("Dumps the inline solver equation system."));
constant DebugFlag EVAL_FUNC = DEBUG_FLAG(7, "evalfunc", true,
  Gettext.gettext("Turns on/off symbolic function evaluation."));
constant DebugFlag GEN = DEBUG_FLAG(8, "gen", false,
  Gettext.gettext("Turns on/off dynamic loading of functions that are compiled during translation. Only enable this if external functions are needed to calculate structural parameters or constants."));
constant DebugFlag DYN_LOAD = DEBUG_FLAG(9, "dynload", false,
  Gettext.gettext("Display debug information about dynamic loading of compiled functions."));
constant DebugFlag GENERATE_CODE_CHEAT = DEBUG_FLAG(10, "generateCodeCheat", false,
  Gettext.gettext("Used to generate code for the bootstrapped compiler."));
constant DebugFlag CGRAPH_GRAPHVIZ_FILE = DEBUG_FLAG(11, "cgraphGraphVizFile", false,
  Gettext.gettext("Generates a graphviz file of the connection graph."));
constant DebugFlag CGRAPH_GRAPHVIZ_SHOW = DEBUG_FLAG(12, "cgraphGraphVizShow", false,
  Gettext.gettext("Displays the connection graph with the GraphViz lefty tool."));
constant DebugFlag GC_PROF = DEBUG_FLAG(13, "gcProfiling", false,
  Gettext.gettext("Prints garbage collection stats to standard output."));
constant DebugFlag CHECK_DAE_CREF_TYPE = DEBUG_FLAG(14, "checkDAECrefType", false,
  Gettext.gettext("Enables extra type checking for cref expressions."));
constant DebugFlag CHECK_ASUB = DEBUG_FLAG(15, "checkASUB", false,
  Gettext.gettext("Prints out a warning if an ASUB is created from a CREF expression."));
constant DebugFlag INSTANCE = DEBUG_FLAG(16, "instance", false,
  Gettext.gettext("Prints extra failtrace from InstanceHierarchy."));
constant DebugFlag CACHE = DEBUG_FLAG(17, "Cache", true,
  Gettext.gettext("Turns off the instantiation cache."));
constant DebugFlag RML = DEBUG_FLAG(18, "rml", false,
  Gettext.gettext("Converts Modelica-style arrays to lists."));
constant DebugFlag TAIL = DEBUG_FLAG(19, "tail", false,
  Gettext.gettext("Prints out a notification if tail recursion optimization has been applied."));
constant DebugFlag LOOKUP = DEBUG_FLAG(20, "lookup", false,
  Gettext.gettext("Print extra failtrace from lookup."));
constant DebugFlag PATTERNM_SKIP_FILTER_UNUSED_AS_BINDINGS = DEBUG_FLAG(21, "patternmSkipFilterUnusedBindings", false,
  Gettext.notrans(""));
constant DebugFlag PATTERNM_ALL_INFO = DEBUG_FLAG(22, "patternmAllInfo", false,
  Gettext.gettext("Adds notifications of all pattern-matching optimizations that are performed."));
constant DebugFlag PATTERNM_DCE = DEBUG_FLAG(23, "patternmDeadCodeElimination", true,
  Gettext.gettext("Performs dead code elimination in match-expressions."));
constant DebugFlag PATTERNM_MOVE_LAST_EXP = DEBUG_FLAG(24, "patternmMoveLastExp", true,
  Gettext.gettext("Optimization that moves the last assignment(s) into the result of a match-expression. For example: equation c = fn(b); then c; => then fn(b);"));
constant DebugFlag EXPERIMENTAL_REDUCTIONS = DEBUG_FLAG(25, "experimentalReductions", false,
  Gettext.gettext("Turns on custom reduction functions (OpenModelica extension)."));
constant DebugFlag EVAL_PARAM = DEBUG_FLAG(26, "evaluateAllParameters", false,
  Gettext.gettext("Evaluates all parameters if set."));
constant DebugFlag TYPES = DEBUG_FLAG(27, "types", false,
  Gettext.gettext("Prints extra failtrace from Types."));
constant DebugFlag SHOW_STATEMENT = DEBUG_FLAG(28, "showStatement", false,
  Gettext.gettext("Shows the statement that is currently being evaluated when evaluating a script."));
constant DebugFlag DUMP = DEBUG_FLAG(29, "dump", false,
  Gettext.gettext("Dumps the absyn representation of a program."));
constant DebugFlag DUMP_GRAPHVIZ = DEBUG_FLAG(30, "graphviz", false,
  Gettext.gettext("Dumps the absyn representation of a program in graphviz format."));
constant DebugFlag EXEC_STAT = DEBUG_FLAG(31, "execstat", false,
  Gettext.gettext("Prints out execution statistics for the compiler."));
constant DebugFlag TRANSFORMS_BEFORE_DUMP = DEBUG_FLAG(32, "transformsbeforedump", false,
  Gettext.gettext("Applies transformations required for code generation before dumping flat code."));
constant DebugFlag DAE_DUMP_GRAPHV = DEBUG_FLAG(33, "daedumpgraphv", false,
  Gettext.gettext("Dumps the DAE in graphviz format."));
constant DebugFlag INTERACTIVE_TCP = DEBUG_FLAG(34, "interactive", false,
  Gettext.gettext("Starts omc as a server listening on the socket interface."));
constant DebugFlag INTERACTIVE_CORBA = DEBUG_FLAG(35, "interactiveCorba", false,
  Gettext.gettext("Starts omc as a server listening on the Corba interface."));
constant DebugFlag INTERACTIVE_DUMP = DEBUG_FLAG(36, "interactivedump", false,
  Gettext.gettext("Prints out debug information for the interactive server."));
constant DebugFlag RELIDX = DEBUG_FLAG(37, "relidx", false,
  Gettext.notrans("Prints out debug information about relations, that are used as zero crossings."));
constant DebugFlag DUMP_REPL = DEBUG_FLAG(38, "dumprepl", false,
  Gettext.gettext("Dump the found replacements for simple equation removal."));
constant DebugFlag DUMP_FP_REPL = DEBUG_FLAG(39, "dumpFPrepl", false,
  Gettext.gettext("Dump the found replacements for final parameters."));
constant DebugFlag DUMP_PARAM_REPL = DEBUG_FLAG(40, "dumpParamrepl", false,
  Gettext.gettext("Dump the found replacements for remove parameters."));
constant DebugFlag DUMP_PP_REPL = DEBUG_FLAG(41, "dumpPPrepl", false,
  Gettext.gettext("Dump the found replacements for protected parameters."));
constant DebugFlag DUMP_EA_REPL = DEBUG_FLAG(42, "dumpEArepl", false,
  Gettext.gettext("Dump the found replacements for evaluate annotations (evaluate=true) parameters."));
constant DebugFlag DEBUG_ALIAS = DEBUG_FLAG(43, "debugAlias", false,
  Gettext.gettext("Dumps some information about the process of removeSimpleEquations."));
constant DebugFlag TEARING_DUMP = DEBUG_FLAG(44, "tearingdump", false,
  Gettext.gettext("Dumps tearing information."));
constant DebugFlag JAC_DUMP = DEBUG_FLAG(45, "symjacdump", false,
  Gettext.gettext("Dumps information about symbolic Jacobians. Can be used only with postOptModules: generateSymbolicJacobian, generateSymbolicLinearization."));
constant DebugFlag JAC_DUMP2 = DEBUG_FLAG(46, "symjacdumpverbose", false,
  Gettext.gettext("Dumps information in verbose mode about symbolic Jacobians. Can be used only with postOptModules: generateSymbolicJacobian, generateSymbolicLinearization."));
constant DebugFlag JAC_DUMP_EQN = DEBUG_FLAG(47, "symjacdumpeqn", false,
  Gettext.gettext("Dump for debug purpose of symbolic Jacobians. (deactivated now)."));
constant DebugFlag JAC_WARNINGS = DEBUG_FLAG(48, "symjacwarnings", false,
  Gettext.gettext("Prints warnings regarding symoblic jacbians."));
constant DebugFlag DUMP_SPARSE = DEBUG_FLAG(49, "dumpSparsePattern", false,
  Gettext.gettext("Dumps sparse pattern with coloring used for simulation."));
constant DebugFlag DUMP_SPARSE_VERBOSE = DEBUG_FLAG(50, "dumpSparsePatternVerbose", false,
  Gettext.gettext("Dumps in verbose mode sparse pattern with coloring used for simulation."));
constant DebugFlag BLT_DUMP = DEBUG_FLAG(51, "bltdump", false,
  Gettext.gettext("Dumps information from index reduction."));
constant DebugFlag DUMMY_SELECT = DEBUG_FLAG(52, "dummyselect", false,
  Gettext.gettext("Dumps information from dummy state selection heuristic."));
constant DebugFlag DUMP_DAE_LOW = DEBUG_FLAG(53, "dumpdaelow", false,
  Gettext.gettext("Dumps the equation system at the beginning of the back end."));
constant DebugFlag DUMP_INDX_DAE = DEBUG_FLAG(54, "dumpindxdae", false,
  Gettext.gettext("Dumps the equation system after index reduction and optimization."));
constant DebugFlag OPT_DAE_DUMP = DEBUG_FLAG(55, "optdaedump", false,
  Gettext.gettext("Dumps information from the optimization modules."));
constant DebugFlag EXEC_HASH = DEBUG_FLAG(56, "execHash", false,
  Gettext.gettext("Measures the time it takes to hash all simcode variables before code generation."));
constant DebugFlag PARAM_DLOW_DUMP = DEBUG_FLAG(57, "paramdlowdump", false,
  Gettext.gettext("Enables dumping of the parameters in the order they are calculated."));
constant DebugFlag DUMP_ENCAPSULATECONDITIONS = DEBUG_FLAG(58, "dumpEncapsulateConditions", false,
  Gettext.gettext("Dumps the results of the preOptModule encapsulateWhenConditions."));
constant DebugFlag SHORT_OUTPUT = DEBUG_FLAG(59, "shortOutput", false,
  Gettext.gettext("Enables short output of the simulate() command. Useful for tools like OMNotebook."));
constant DebugFlag COUNT_OPERATIONS = DEBUG_FLAG(60, "countOperations", false,
  Gettext.gettext("Count operations."));
constant DebugFlag CGRAPH = DEBUG_FLAG(61, "cgraph", false,
  Gettext.gettext("Prints out connection graph information."));
constant DebugFlag UPDMOD = DEBUG_FLAG(62, "updmod", false,
  Gettext.gettext("Prints information about modification updates."));
constant DebugFlag STATIC = DEBUG_FLAG(63, "static", false,
  Gettext.gettext("Enables extra debug output from the static elaboration."));
constant DebugFlag TPL_PERF_TIMES = DEBUG_FLAG(64, "tplPerfTimes", false,
  Gettext.gettext("Enables output of template performance data for rendering text to file."));
constant DebugFlag CHECK_SIMPLIFY = DEBUG_FLAG(65, "checkSimplify", false,
  Gettext.gettext("Enables checks for expression simplification and prints a notification whenever an undesirable transformation has been performed."));
constant DebugFlag SCODE_INST = DEBUG_FLAG(66, "newInst", true,
  Gettext.gettext("Enables new instantiation phase."));
constant DebugFlag WRITE_TO_BUFFER = DEBUG_FLAG(67, "writeToBuffer", false,
  Gettext.gettext("Enables writing simulation results to buffer."));
constant DebugFlag DUMP_BACKENDDAE_INFO = DEBUG_FLAG(68, "backenddaeinfo", false,
  Gettext.gettext("Enables dumping of back-end information about system (Number of equations before back-end,...)."));
constant DebugFlag GEN_DEBUG_SYMBOLS = DEBUG_FLAG(69, "gendebugsymbols", false,
  Gettext.gettext("Generate code with debugging symbols."));
constant DebugFlag DUMP_STATESELECTION_INFO = DEBUG_FLAG(70, "stateselection", false,
  Gettext.gettext("Enables dumping of selected states. Extends -d=backenddaeinfo."));
constant DebugFlag DUMP_EQNINORDER = DEBUG_FLAG(71, "dumpeqninorder", false,
  Gettext.gettext("Enables dumping of the equations in the order they are calculated."));
constant DebugFlag SEMILINEAR = DEBUG_FLAG(72, "semiLinear", false,
  Gettext.gettext("Enables dumping of the optimization information when optimizing calls to semiLinear."));
constant DebugFlag UNCERTAINTIES = DEBUG_FLAG(73, "uncertainties", false,
  Gettext.gettext("Enables dumping of status when calling modelEquationsUC."));
constant DebugFlag SHOW_START_ORIGIN = DEBUG_FLAG(74, "showStartOrigin", false,
  Gettext.gettext("Enables dumping of the DAE startOrigin attribute of the variables."));
constant DebugFlag DUMP_SIMCODE = DEBUG_FLAG(75, "dumpSimCode", false,
  Gettext.gettext("Dumps the simCode model used for code generation."));
constant DebugFlag DUMP_INITIAL_SYSTEM = DEBUG_FLAG(76, "dumpinitialsystem", false,
  Gettext.gettext("Dumps the initial equation system."));
constant DebugFlag GRAPH_INST = DEBUG_FLAG(77, "graphInst", false,
  Gettext.gettext("Do graph based instantiation."));
constant DebugFlag GRAPH_INST_RUN_DEP = DEBUG_FLAG(78, "graphInstRunDep", false,
  Gettext.gettext("Run scode dependency analysis. Use with -d=graphInst"));
constant DebugFlag GRAPH_INST_GEN_GRAPH = DEBUG_FLAG(79, "graphInstGenGraph", false,
  Gettext.gettext("Dumps a graph of the program. Use with -d=graphInst"));
constant DebugFlag GRAPH_INST_SHOW_GRAPH = DEBUG_FLAG(80, "graphInstShowGraph", false,
  Gettext.gettext("Display a graph of the program interactively. Use with -d=graphInst"));
constant DebugFlag DUMP_CONST_REPL = DEBUG_FLAG(81, "dumpConstrepl", false,
  Gettext.gettext("Dump the found replacements for constants."));
constant DebugFlag SHOW_EQUATION_SOURCE = DEBUG_FLAG(82, "showEquationSource", false,
  Gettext.gettext("Display the element source information in the dumped DAE for easier debugging."));
constant DebugFlag LS_ANALYTIC_JACOBIAN = DEBUG_FLAG(83, "LSanalyticJacobian", false,
  Gettext.gettext("Enables analytical jacobian for linear strong components. Defaults to false"));
constant DebugFlag NLS_ANALYTIC_JACOBIAN = DEBUG_FLAG(84, "NLSanalyticJacobian", true,
  Gettext.gettext("Enables analytical jacobian for non-linear strong components without user-defined function calls, for that see forceNLSanalyticJacobian"));
constant DebugFlag INLINE_SOLVER = DEBUG_FLAG(85, "inlineSolver", false,
  Gettext.gettext("Generates code for inline solver."));
constant DebugFlag HPCOM = DEBUG_FLAG(86, "hpcom", false,
  Gettext.gettext("Enables parallel calculation based on task-graphs."));
constant DebugFlag INITIALIZATION = DEBUG_FLAG(87, "initialization", false,
  Gettext.gettext("Shows additional information from the initialization process."));
constant DebugFlag INLINE_FUNCTIONS = DEBUG_FLAG(88, "inlineFunctions", true,
  Gettext.gettext("Controls if function inlining should be performed."));
constant DebugFlag DUMP_SCC_GRAPHML = DEBUG_FLAG(89, "dumpSCCGraphML", false,
  Gettext.gettext("Dumps graphml files with the strongly connected components."));
constant DebugFlag TEARING_DUMPVERBOSE = DEBUG_FLAG(90, "tearingdumpV", false,
  Gettext.gettext("Dumps verbose tearing information."));
constant DebugFlag DISABLE_SINGLE_FLOW_EQ = DEBUG_FLAG(91, "disableSingleFlowEq", false,
  Gettext.gettext("Disables the generation of single flow equations."));
constant DebugFlag DUMP_DISCRETEVARS_INFO = DEBUG_FLAG(92, "discreteinfo", false,
  Gettext.gettext("Enables dumping of discrete variables. Extends -d=backenddaeinfo."));
constant DebugFlag ADDITIONAL_GRAPHVIZ_DUMP = DEBUG_FLAG(93, "graphvizDump", false,
  Gettext.gettext("Activates additional graphviz dumps (as .dot files). It can be used in addition to one of the following flags: {dumpdaelow|dumpinitialsystems|dumpindxdae}."));
constant DebugFlag INFO_XML_OPERATIONS = DEBUG_FLAG(94, "infoXmlOperations", false,
  Gettext.gettext("Enables output of the operations in the _info.xml file when translating models."));
constant DebugFlag HPCOM_DUMP = DEBUG_FLAG(95, "hpcomDump", false,
  Gettext.gettext("Dumps additional information on the parallel execution with hpcom."));
constant DebugFlag RESOLVE_LOOPS_DUMP = DEBUG_FLAG(96, "resolveLoopsDump", false,
  Gettext.gettext("Debug Output for ResolveLoops Module."));
constant DebugFlag DISABLE_WINDOWS_PATH_CHECK_WARNING = DEBUG_FLAG(97, "disableWindowsPathCheckWarning", false,
  Gettext.gettext("Disables warnings on Windows if OPENMODELICAHOME/MinGW is missing."));
constant DebugFlag DISABLE_RECORD_CONSTRUCTOR_OUTPUT = DEBUG_FLAG(98, "disableRecordConstructorOutput", false,
  Gettext.gettext("Disables output of record constructors in the flat code."));
constant DebugFlag IMPL_ODE = DEBUG_FLAG(99, "implOde", false,
  Gettext.gettext("activates implicit codegen"));
constant DebugFlag EVAL_FUNC_DUMP = DEBUG_FLAG(100, "evalFuncDump", false,
  Gettext.gettext("dumps debug information about the function evaluation"));
constant DebugFlag PRINT_STRUCTURAL = DEBUG_FLAG(101, "printStructuralParameters", false,
  Gettext.gettext("Prints the structural parameters identified by the front-end"));
constant DebugFlag ITERATION_VARS = DEBUG_FLAG(102, "iterationVars", false,
  Gettext.gettext("Shows a list of all iteration variables."));
constant DebugFlag ALLOW_RECORD_TOO_MANY_FIELDS = DEBUG_FLAG(103, "acceptTooManyFields", false,
  Gettext.gettext("Accepts passing records with more fields than expected to a function. This is not allowed, but is used in Fluid.Dissipation. See https://trac.modelica.org/Modelica/ticket/1245 for details."));
constant DebugFlag HPCOM_MEMORY_OPT = DEBUG_FLAG(104, "hpcomMemoryOpt", false,
  Gettext.gettext("Optimize the memory structure regarding the selected scheduler"));
constant DebugFlag DUMP_SYNCHRONOUS = DEBUG_FLAG(105, "dumpSynchronous", false,
  Gettext.gettext("Dumps information of the clock partitioning."));
constant DebugFlag STRIP_PREFIX = DEBUG_FLAG(106, "stripPrefix", true,
  Gettext.gettext("Strips the environment prefix from path/crefs. Defaults to true."));
constant DebugFlag DO_SCODE_DEP = DEBUG_FLAG(107, "scodeDep", true,
  Gettext.gettext("Does scode dependency analysis prior to instantiation. Defaults to true."));
constant DebugFlag SHOW_INST_CACHE_INFO = DEBUG_FLAG(108, "showInstCacheInfo", false,
  Gettext.gettext("Prints information about instantiation cache hits and additions. Defaults to false."));
constant DebugFlag DUMP_UNIT = DEBUG_FLAG(109, "dumpUnits", false,
  Gettext.gettext("Dumps all the calculated units."));
constant DebugFlag DUMP_EQ_UNIT = DEBUG_FLAG(110, "dumpEqInUC", false,
  Gettext.gettext("Dumps all equations handled by the unit checker."));
constant DebugFlag DUMP_EQ_UNIT_STRUCT = DEBUG_FLAG(111, "dumpEqUCStruct", false,
  Gettext.gettext("Dumps all the equations handled by the unit checker as tree-structure."));
constant DebugFlag SHOW_DAE_GENERATION = DEBUG_FLAG(112, "showDaeGeneration", false,
  Gettext.gettext("Show the dae variable declarations as they happen."));
constant DebugFlag RESHUFFLE_POST = DEBUG_FLAG(113, "reshufflePost", false,
  Gettext.gettext("Reshuffles the systems of equations."));
constant DebugFlag SHOW_EXPANDABLE_INFO = DEBUG_FLAG(114, "showExpandableInfo", false,
  Gettext.gettext("Show information about expandable connector handling."));
constant DebugFlag DUMP_HOMOTOPY = DEBUG_FLAG(115, "dumpHomotopy", false,
  Gettext.gettext("Dumps the results of the postOptModule optimizeHomotopyCalls."));
constant DebugFlag OMC_RELOCATABLE_FUNCTIONS = DEBUG_FLAG(116, "relocatableFunctions", false,
  Gettext.gettext("Generates relocatable code: all functions become function pointers and can be replaced at run-time."));
constant DebugFlag GRAPHML = DEBUG_FLAG(117, "graphml", false,
  Gettext.gettext("Dumps .graphml files for the bipartite graph after Index Reduction and a task graph for the SCCs. Can be displayed with yEd. "));
constant DebugFlag USEMPI = DEBUG_FLAG(118, "useMPI", false,
  Gettext.gettext("Add MPI init and finalize to main method (CPPruntime). "));
constant DebugFlag DUMP_CSE = DEBUG_FLAG(119, "dumpCSE", false,
  Gettext.gettext("Additional output for CSE module."));
constant DebugFlag DUMP_CSE_VERBOSE = DEBUG_FLAG(120, "dumpCSE_verbose", false,
  Gettext.gettext("Additional output for CSE module."));
constant DebugFlag NO_START_CALC = DEBUG_FLAG(121, "disableStartCalc", false,
  Gettext.gettext("Deactivates the pre-calculation of start values during compile-time."));
constant DebugFlag CONSTJAC = DEBUG_FLAG(122, "constjac", false,
  Gettext.gettext("solves linear systems with constant Jacobian and variable b-Vector symbolically"));
constant DebugFlag VISUAL_XML = DEBUG_FLAG(123, "visxml", false,
  Gettext.gettext("Outputs a xml-file that contains information for visualization."));
constant DebugFlag VECTORIZE = DEBUG_FLAG(124, "vectorize", false,
  Gettext.gettext("Activates vectorization in the backend."));
constant DebugFlag CHECK_EXT_LIBS = DEBUG_FLAG(125, "buildExternalLibs", true,
  Gettext.gettext("Use the autotools project in the Resources folder of the library to build missing external libraries."));
constant DebugFlag RUNTIME_STATIC_LINKING = DEBUG_FLAG(126, "runtimeStaticLinking", false,
  Gettext.gettext("Use the static simulation runtime libraries (C++ simulation runtime)."));
constant DebugFlag SORT_EQNS_AND_VARS = DEBUG_FLAG(127, "dumpSortEqnsAndVars", false,
  Gettext.gettext("Dumps debug output for the modules sortEqnsVars."));
constant DebugFlag DUMP_SIMPLIFY_LOOPS = DEBUG_FLAG(128, "dumpSimplifyLoops", false,
  Gettext.gettext("Dump between steps of simplifyLoops"));
constant DebugFlag DUMP_RTEARING = DEBUG_FLAG(129, "dumpRecursiveTearing", false,
  Gettext.gettext("Dump between steps of recursiveTearing"));
constant DebugFlag DIS_SYMJAC_FMI20 = DEBUG_FLAG(130, "disableDirectionalDerivatives", true,
  Gettext.gettext("For FMI 2.0 only dependecy analysis will be perform."));
constant DebugFlag EVAL_OUTPUT_ONLY = DEBUG_FLAG(131, "evalOutputOnly", false,
  Gettext.gettext("Generates equations to calculate outputs only."));
constant DebugFlag HARDCODED_START_VALUES = DEBUG_FLAG(132, "hardcodedStartValues", false,
  Gettext.gettext("Embed the start values of variables and parameters into the c++ code and do not read it from xml file."));
constant DebugFlag DUMP_FUNCTIONS = DEBUG_FLAG(133, "dumpFunctions", false,
  Gettext.gettext("Add functions to backend dumps."));
constant DebugFlag DEBUG_DIFFERENTIATION = DEBUG_FLAG(134, "debugDifferentiation", false,
  Gettext.gettext("Dumps debug output for the differentiation process."));
constant DebugFlag DEBUG_DIFFERENTIATION_VERBOSE = DEBUG_FLAG(135, "debugDifferentiationVerbose", false,
  Gettext.gettext("Dumps verbose debug output for the differentiation process."));
constant DebugFlag FMU_EXPERIMENTAL = DEBUG_FLAG(136, "fmuExperimental", false,
  Gettext.gettext("Include an extra function in the FMU fmi2GetSpecificDerivatives."));
constant DebugFlag DUMP_DGESV = DEBUG_FLAG(137, "dumpdgesv", false,
  Gettext.gettext("Enables dumping of the information whether DGESV is used to solve linear systems."));
constant DebugFlag MULTIRATE_PARTITION = DEBUG_FLAG(138, "multirate", false,
  Gettext.gettext("The solver can switch partitions in the system."));
constant DebugFlag DUMP_EXCLUDED_EXP = DEBUG_FLAG(139, "dumpExcludedSymJacExps", false,
  Gettext.gettext("This flags dumps all expression that are excluded from differentiation of a symbolic Jacobian."));
constant DebugFlag DEBUG_ALGLOOP_JACOBIAN = DEBUG_FLAG(140, "debugAlgebraicLoopsJacobian", false,
  Gettext.gettext("Dumps debug output while creating symbolic jacobians for non-linear systems."));
constant DebugFlag DISABLE_JACSCC = DEBUG_FLAG(141, "disableJacsforSCC", false,
  Gettext.gettext("Disables calculation of jacobians to detect if a SCC is linear or non-linear. By disabling all SCC will handled like non-linear."));
constant DebugFlag FORCE_NLS_ANALYTIC_JACOBIAN = DEBUG_FLAG(142, "forceNLSanalyticJacobian", false,
  Gettext.gettext("Forces calculation analytical jacobian also for non-linear strong components with user-defined functions."));
constant DebugFlag DUMP_LOOPS = DEBUG_FLAG(143, "dumpLoops", false,
  Gettext.gettext("Dumps loop equation."));
constant DebugFlag DUMP_LOOPS_VERBOSE = DEBUG_FLAG(144, "dumpLoopsVerbose", false,
  Gettext.gettext("Dumps loop equation and enhanced adjacency matrix."));
constant DebugFlag SKIP_INPUT_OUTPUT_SYNTACTIC_SUGAR = DEBUG_FLAG(145, "skipInputOutputSyntacticSugar", false,
  Gettext.gettext("Used when bootstrapping to preserve the input output parsing of the code output by the list command."));
constant DebugFlag OMC_RECORD_ALLOC_WORDS = DEBUG_FLAG(146, "metaModelicaRecordAllocWords", false,
  Gettext.gettext("Instrument the source code to record memory allocations (requires run-time and generated files compiled with -DOMC_RECORD_ALLOC_WORDS)."));
constant DebugFlag TOTAL_TEARING_DUMP = DEBUG_FLAG(147, "totaltearingdump", false,
  Gettext.gettext("Dumps total tearing information."));
constant DebugFlag TOTAL_TEARING_DUMPVERBOSE = DEBUG_FLAG(148, "totaltearingdumpV", false,
  Gettext.gettext("Dumps verbose total tearing information."));
constant DebugFlag PARALLEL_CODEGEN = DEBUG_FLAG(149, "parallelCodegen", true,
  Gettext.gettext("Enables code generation in parallel (disable this if compiling a model causes you to run out of RAM)."));
constant DebugFlag SERIALIZED_SIZE = DEBUG_FLAG(150, "reportSerializedSize", false,
  Gettext.gettext("Reports serialized sizes of various data structures used in the compiler."));
constant DebugFlag BACKEND_KEEP_ENV_GRAPH = DEBUG_FLAG(151, "backendKeepEnv", true,
  Gettext.gettext("When enabled, the environment is kept when entering the backend, which enables CevalFunction (function interpretation) to work. This module not essential for the backend to function in most cases, but can improve simulation performance by evaluating functions. The drawback to keeping the environment graph in memory is that it is huge (~80% of the total memory in use when returning the frontend DAE)."));
constant DebugFlag DUMPBACKENDINLINE = DEBUG_FLAG(152, "dumpBackendInline", false,
  Gettext.gettext("Dumps debug output while inline function."));
constant DebugFlag DUMPBACKENDINLINE_VERBOSE = DEBUG_FLAG(153, "dumpBackendInlineVerbose", false,
  Gettext.gettext("Dumps debug output while inline function."));
constant DebugFlag BLT_MATRIX_DUMP = DEBUG_FLAG(154, "bltmatrixdump", false,
  Gettext.gettext("Dumps the blt matrix in html file. IE seems to be very good in displaying large matrices."));
constant DebugFlag LIST_REVERSE_WRONG_ORDER = DEBUG_FLAG(155, "listAppendWrongOrder", true,
  Gettext.gettext("Print notifications about bad usage of listAppend."));
constant DebugFlag PARTITION_INITIALIZATION = DEBUG_FLAG(156, "partitionInitialization", true,
  Gettext.gettext("This flag controls if partitioning is applied to the initialization system."));
constant DebugFlag EVAL_PARAM_DUMP = DEBUG_FLAG(157, "evalParameterDump", false,
  Gettext.gettext("Dumps information for evaluating parameters."));
constant DebugFlag NF_UNITCHECK = DEBUG_FLAG(158, "frontEndUnitCheck", false,
  Gettext.gettext("Checks the consistency of units in equation."));
constant DebugFlag DISABLE_COLORING = DEBUG_FLAG(159, "disableColoring", false,
  Gettext.gettext("Disables coloring algorithm while spasity detection."));
constant DebugFlag MERGE_ALGORITHM_SECTIONS = DEBUG_FLAG(160, "mergeAlgSections", false,
  Gettext.gettext("Disables coloring algorithm while sparsity detection."));
constant DebugFlag WARN_NO_NOMINAL = DEBUG_FLAG(161, "warnNoNominal", false,
  Gettext.gettext("Prints the iteration variables in the initialization and simulation DAE, which do not have a nominal value."));
constant DebugFlag REDUCE_DAE = DEBUG_FLAG(162, "backendReduceDAE", false,
  Gettext.gettext("Prints all Reduce DAE debug information."));
constant DebugFlag IGNORE_CYCLES = DEBUG_FLAG(163, "ignoreCycles", false,
  Gettext.gettext("Ignores cycles between constant/parameter components."));
constant DebugFlag ALIAS_CONFLICTS = DEBUG_FLAG(164, "aliasConflicts", false,
  Gettext.gettext("Dumps alias sets with different start or nominal values."));
constant DebugFlag SUSAN_MATCHCONTINUE_DEBUG = DEBUG_FLAG(165, "susanDebug", false,
  Gettext.gettext("Makes Susan generate code using try/else to better debug which function broke the expected match semantics."));
constant DebugFlag OLD_FE_UNITCHECK = DEBUG_FLAG(166, "oldFrontEndUnitCheck", false,
  Gettext.gettext("Checks the consistency of units in equation (for the old front-end)."));
constant DebugFlag EXEC_STAT_EXTRA_GC = DEBUG_FLAG(167, "execstatGCcollect", false,
  Gettext.gettext("When running execstat, also perform an extra full garbage collection."));
constant DebugFlag DEBUG_DAEMODE = DEBUG_FLAG(168, "debugDAEmode", false,
  Gettext.gettext("Dump debug output for the DAEmode."));
constant DebugFlag NF_SCALARIZE = DEBUG_FLAG(169, "nfScalarize", true,
  Gettext.gettext("Run scalarization in NF, default true."));
constant DebugFlag NF_EVAL_CONST_ARG_FUNCS = DEBUG_FLAG(170, "nfEvalConstArgFuncs", true,
  Gettext.gettext("Evaluate all functions with constant arguments in the new frontend."));
constant DebugFlag NF_EXPAND_OPERATIONS = DEBUG_FLAG(171, "nfExpandOperations", true,
  Gettext.gettext("Expand all unary/binary operations to scalar expressions in the new frontend."));
constant DebugFlag NF_API = DEBUG_FLAG(172, "nfAPI", false,
  Gettext.gettext("Enables experimental new instantiation use in the OMC API."));
constant DebugFlag NF_API_DYNAMIC_SELECT = DEBUG_FLAG(173, "nfAPIDynamicSelect", false,
  Gettext.gettext("Show DynamicSelect(static, dynamic) in annotations. Default to false and will select the first (static) expression"));
constant DebugFlag NF_API_NOISE = DEBUG_FLAG(174, "nfAPINoise", false,
  Gettext.gettext("Enables error display for the experimental new instantiation use in the OMC API."));
constant DebugFlag FMI20_DEPENDENCIES = DEBUG_FLAG(175, "disableFMIDependency", false,
  Gettext.gettext("Disables the dependency analysis and generation for FMI 2.0."));
constant DebugFlag WARNING_MINMAX_ATTRIBUTES = DEBUG_FLAG(176, "warnMinMax", true,
  Gettext.gettext("Makes a warning assert from min/max variable attributes instead of error."));
constant DebugFlag NF_EXPAND_FUNC_ARGS = DEBUG_FLAG(177, "nfExpandFuncArgs", false,
  Gettext.gettext("Expand all function arguments in the new frontend."));
constant DebugFlag DUMP_JL = DEBUG_FLAG(178, "dumpJL", false,
  Gettext.gettext("Dumps the absyn representation of a program as a Julia representation"));
constant DebugFlag DUMP_ASSC = DEBUG_FLAG(179, "dumpASSC", false,
  Gettext.gettext("Dumps the conversion process of analytical to structural singularities."));
constant DebugFlag SPLIT_CONSTANT_PARTS_SYMJAC = DEBUG_FLAG(180, "symJacConstantSplit", false,
  Gettext.gettext("Generates all symbolic Jacobians with splitted constant parts."));
constant DebugFlag DUMP_FORCE_FMI_ATTRIBUTES = DEBUG_FLAG(181, "force-fmi-attributes", false,
  Gettext.gettext("Force to export all fmi attributes to the modelDescription.xml, including those which have default values"));
constant DebugFlag DUMP_DATARECONCILIATION = DEBUG_FLAG(182, "dataReconciliation", false,
  Gettext.gettext("Dumps all the dataReconciliation extraction algorithm procedure"));
constant DebugFlag ARRAY_CONNECT = DEBUG_FLAG(183, "arrayConnect", false,
  Gettext.gettext("Use experimental array connection handler."));
constant DebugFlag COMBINE_SUBSCRIPTS = DEBUG_FLAG(184, "combineSubscripts", false,
  Gettext.gettext("Move all subscripts to the end of component references."));
constant DebugFlag ZMQ_LISTEN_TO_ALL = DEBUG_FLAG(185, "zmqDangerousAcceptConnectionsFromAnywhere", false,
  Gettext.gettext("When opening a zmq connection, listen on all interfaces instead of only connections from 127.0.0.1."));
constant DebugFlag DUMP_CONVERSION_RULES = DEBUG_FLAG(186, "dumpConversionRules", false,
  Gettext.gettext("Dumps the rules when converting a package using a conversion script."));
constant DebugFlag PRINT_RECORD_TYPES = DEBUG_FLAG(187, "printRecordTypes", false,
  Gettext.gettext("Prints out record types as part of the flat code."));

public
// CONFIGURATION FLAGS
constant ConfigFlag DEBUG = CONFIG_FLAG(1, "debug",
  SOME("d"), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Gettext.gettext("Sets debug flags. Use --help=debug to see available flags."));

constant ConfigFlag HELP = CONFIG_FLAG(2, "help",
  SOME("h"), EXTERNAL(), STRING_FLAG(""), NONE(),
  Gettext.gettext("Displays the help text. Use --help=topics for more information."));

constant ConfigFlag RUNNING_TESTSUITE = CONFIG_FLAG(3, "running-testsuite",
  NONE(), INTERNAL(), STRING_FLAG(""), NONE(),
  Gettext.gettext("Used when running the testsuite."));

constant ConfigFlag SHOW_VERSION = CONFIG_FLAG(4, "version",
  SOME("-v"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Print the version and exit."));

constant ConfigFlag TARGET = CONFIG_FLAG(5, "target", NONE(), EXTERNAL(),
  STRING_FLAG("gcc"), SOME(STRING_OPTION({"gcc", "msvc","msvc10","msvc12","msvc13","msvc15","msvc19", "vxworks69", "debugrt"})),
  Gettext.gettext("Sets the target compiler to use."));

constant ConfigFlag GRAMMAR = CONFIG_FLAG(6, "grammar", SOME("g"), EXTERNAL(),
  ENUM_FLAG(MODELICA, {("Modelica", MODELICA), ("MetaModelica", METAMODELICA), ("ParModelica", PARMODELICA), ("Optimica", OPTIMICA), ("PDEModelica", PDEMODELICA)}),
  SOME(STRING_OPTION({"Modelica", "MetaModelica", "ParModelica", "Optimica", "PDEModelica"})),
  Gettext.gettext("Sets the grammar and semantics to accept."));

constant ConfigFlag ANNOTATION_VERSION = CONFIG_FLAG(7, "annotationVersion",
  NONE(), EXTERNAL(), STRING_FLAG("3.x"), SOME(STRING_OPTION({"1.x", "2.x", "3.x"})),
  Gettext.gettext("Sets the annotation version that should be used."));

constant ConfigFlag LANGUAGE_STANDARD = CONFIG_FLAG(8, "std", NONE(), EXTERNAL(),
  ENUM_FLAG(1000,
    {("1.x", 10), ("2.x", 20), ("3.0", 30), ("3.1", 31), ("3.2", 32), ("3.3", 33),
     ("3.4", 34), ("3.5", 35), ("latest",1000), ("experimental", 9999)}),
  SOME(STRING_OPTION({"1.x", "2.x", "3.1", "3.2", "3.3", "3.4", "3.5", "latest", "experimental"})),
  Gettext.gettext("Sets the language standard that should be used."));

constant ConfigFlag SHOW_ERROR_MESSAGES = CONFIG_FLAG(9, "showErrorMessages",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Show error messages immediately when they happen."));

constant ConfigFlag SHOW_ANNOTATIONS = CONFIG_FLAG(10, "showAnnotations",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Show annotations in the flattened code."));

constant ConfigFlag NO_SIMPLIFY = CONFIG_FLAG(11, "noSimplify",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Do not simplify expressions if set."));
constant Gettext.TranslatableContent removeSimpleEquationDesc = Gettext.gettext("Performs alias elimination and removes constant variables from the DAE, replacing all occurrences of the old variable reference with the new value (constants) or variable reference (alias elimination).");

public
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
    ("introduceOutputAliases", Gettext.gettext("Introduces aliases for top-level outputs.")),
    ("clockPartitioning", Gettext.gettext("Does the clock partitioning.")),
    ("collapseArrayExpressions", collapseArrayExpressionsText),
    ("comSubExp", Gettext.gettext("Introduces alias assignments for variables which are assigned to simple terms i.e. a = b/c; d = b/c; --> a=d")),
    ("dumpDAE", Gettext.gettext("dumps the DAE representation of the current transformation state")),
    ("dumpDAEXML", Gettext.gettext("dumps the DAE as xml representation of the current transformation state")),
    ("encapsulateWhenConditions", Gettext.gettext("This module replaces each when condition with a boolean variable.")),
    ("evalFunc", Gettext.gettext("evaluates functions partially")),
    ("evaluateParameters", Gettext.gettext("Evaluates parameters with annotation(Evaluate=true). Use '--evaluateFinalParameters=true' or '--evaluateProtectedParameters=true' to specify additional parameters to be evaluated. Use '--replaceEvaluatedParameters=true' if the evaluated parameters should be replaced in the DAE. To evaluate all parameters in the Frontend use -d=evaluateAllParameters.")),
    ("expandDerOperator", Gettext.notrans("Expands der(expr) using Derive.differentiteExpTime.")),
    ("findStateOrder", Gettext.notrans("Sets derivative information to states.")),
    ("inlineArrayEqn", Gettext.gettext("This module expands all array equations to scalar equations.")),
    ("normalInlineFunction", Gettext.gettext("Perform function inlining for function with annotation Inline=true.")),
    ("inputDerivativesForDynOpt", Gettext.gettext("Allowed derivatives of inputs in dyn. optimization.")),
    ("introduceDerAlias", Gettext.notrans("Adds for every der-call an alias equation e.g. dx = der(x).")),
    ("removeEqualRHS", Gettext.notrans("Detects equal expressions of the form a=<exp> and b=<exp> and substitutes them to get speed up.")),
    ("removeProtectedParameters", Gettext.gettext("Replace all parameters with protected=true in the system.")),
    ("removeSimpleEquations", removeSimpleEquationDesc),
    ("removeUnusedParameter", Gettext.gettext("Strips all parameter not present in the equations from the system.")),
    ("removeUnusedVariables", Gettext.gettext("Strips all variables not present in the equations from the system.")),
    ("removeVerySimpleEquations", Gettext.gettext("[Experimental] Like removeSimpleEquations, but less thorough. Note that this always uses the experimental new alias elimination, --removeSimpleEquations=new, which makes it unstable. In particular, MultiBody systems fail to translate correctly. It can be used for simple (but large) systems of equations.")),
    ("replaceEdgeChange", Gettext.gettext("Replace edge(b) = b and not pre(b) and change(b) = v <> pre(v).")),
    ("residualForm", Gettext.gettext("Transforms simple equations x=y to zero-sum equations 0=y-x.")),
    ("resolveLoops", Gettext.gettext("resolves linear equations in loops")),
    ("simplifyAllExpressions", Gettext.notrans("Does simplifications on all expressions.")),
    ("simplifyIfEquations", Gettext.gettext("Tries to simplify if equations by use of information from evaluated parameters.")),
    ("sortEqnsVars", Gettext.notrans("Heuristic sorting for equations and variables.")),
    ("unitChecking", Gettext.gettext("This module is no longer available and its use is deprecated. Use --unitChecking instead.")),
    ("wrapFunctionCalls", Gettext.gettext("This module introduces variables for each function call and substitutes all these calls with the newly introduced variables."))
    })),
  Gettext.gettext("Sets the pre optimization modules to use in the back end. See --help=optmodules for more info."));

constant ConfigFlag CHEAPMATCHING_ALGORITHM = CONFIG_FLAG(13, "cheapmatchingAlgorithm",
  NONE(), EXTERNAL(), INT_FLAG(3),
  SOME(STRING_DESC_OPTION({
    ("0", Gettext.gettext("No cheap matching.")),
    ("1", Gettext.gettext("Cheap matching, traverses all equations and match the first free variable.")),
    ("3", Gettext.gettext("Random Karp-Sipser: R. M. Karp and M. Sipser. Maximum matching in sparse random graphs."))})),
    Gettext.gettext("Sets the cheap matching algorithm to use. A cheap matching algorithm gives a jump start matching by heuristics."));

constant ConfigFlag MATCHING_ALGORITHM = CONFIG_FLAG(14, "matchingAlgorithm",
  NONE(), EXTERNAL(), STRING_FLAG("PFPlusExt"),
  SOME(STRING_DESC_OPTION({
    ("BFSB", Gettext.gettext("Breadth First Search based algorithm.")),
    ("DFSB", Gettext.gettext("Depth First Search based algorithm.")),
    ("MC21A", Gettext.gettext("Depth First Search based algorithm with look ahead feature.")),
    ("PF", Gettext.gettext("Depth First Search based algorithm with look ahead feature.")),
    ("PFPlus", Gettext.gettext("Depth First Search based algorithm with look ahead feature and fair row traversal.")),
    ("HK", Gettext.gettext("Combined BFS and DFS algorithm.")),
    ("HKDW", Gettext.gettext("Combined BFS and DFS algorithm.")),
    ("ABMP", Gettext.gettext("Combined BFS and DFS algorithm.")),
    ("PR", Gettext.gettext("Matching algorithm using push relabel mechanism.")),
    ("DFSBExt", Gettext.gettext("Depth First Search based Algorithm external c implementation.")),
    ("BFSBExt", Gettext.gettext("Breadth First Search based Algorithm external c implementation.")),
    ("MC21AExt", Gettext.gettext("Depth First Search based Algorithm with look ahead feature external c implementation.")),
    ("PFExt", Gettext.gettext("Depth First Search based Algorithm with look ahead feature external c implementation.")),
    ("PFPlusExt", Gettext.gettext("Depth First Search based Algorithm with look ahead feature and fair row traversal external c implementation.")),
    ("HKExt", Gettext.gettext("Combined BFS and DFS algorithm external c implementation.")),
    ("HKDWExt", Gettext.gettext("Combined BFS and DFS algorithm external c implementation.")),
    ("ABMPExt", Gettext.gettext("Combined BFS and DFS algorithm external c implementation.")),
    ("PRExt", Gettext.gettext("Matching algorithm using push relabel mechanism external c implementation.")),
    ("BB", Gettext.gettext("BBs try."))})),
    Gettext.gettext("Sets the matching algorithm to use. See --help=optmodules for more info."));

constant ConfigFlag INDEX_REDUCTION_METHOD = CONFIG_FLAG(15, "indexReductionMethod",
  NONE(), EXTERNAL(), STRING_FLAG("dynamicStateSelection"),
  SOME(STRING_DESC_OPTION({
    ("none", Gettext.gettext("Skip index reduction")),
    ("uode", Gettext.gettext("Use the underlying ODE without the constraints.")),
    ("dynamicStateSelection", Gettext.gettext("Simple index reduction method, select (dynamic) dummy states based on analysis of the system.")),
    ("dummyDerivatives", Gettext.gettext("Simple index reduction method, select (static) dummy states based on heuristic."))
    })),
    Gettext.gettext("Sets the index reduction method to use. See --help=optmodules for more info."));

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
    ("addScaledVars_states", Gettext.notrans("added var_norm = var/nominal, where var is state")),
    ("addScaledVars_inputs", Gettext.notrans("added var_norm = var/nominal, where var is input")),
    ("addTimeAsState", Gettext.gettext("Experimental feature: this replaces each occurrence of variable time with a new introduced state $time with equation der($time) = 1.0")),
    ("calculateStateSetsJacobians", Gettext.gettext("Generates analytical jacobian for dynamic state selection sets.")),
    ("calculateStrongComponentJacobians", Gettext.gettext("Generates analytical jacobian for torn linear and non-linear strong components. By default linear components and non-linear components with user-defined function calls are skipped. See also debug flags: LSanalyticJacobian, NLSanalyticJacobian and forceNLSanalyticJacobian")),
    ("collapseArrayExpressions", collapseArrayExpressionsText),
    ("constantLinearSystem", Gettext.gettext("Evaluates constant linear systems (a*x+b*y=c; d*x+e*y=f; a,b,c,d,e,f are constants) at compile-time.")),
    ("countOperations", Gettext.gettext("Count the mathematical operations of the system.")),
    ("cseBinary", Gettext.gettext("Common Sub-expression Elimination")),
    ("dumpComponentsGraphStr", Gettext.notrans("Dumps the assignment graph used to determine strong components to format suitable for Mathematica")),
    ("dumpDAE", Gettext.gettext("dumps the DAE representation of the current transformation state")),
    ("dumpDAEXML", Gettext.gettext("dumps the DAE as xml representation of the current transformation state")),
    ("evaluateParameters", Gettext.gettext("Evaluates parameters with annotation(Evaluate=true). Use '--evaluateFinalParameters=true' or '--evaluateProtectedParameters=true' to specify additional parameters to be evaluated. Use '--replaceEvaluatedParameters=true' if the evaluated parameters should be replaced in the DAE. To evaluate all parameters in the Frontend use -d=evaluateAllParameters.")),
    ("extendDynamicOptimization", Gettext.gettext("Move loops to constraints.")),
    ("generateSymbolicLinearization", Gettext.gettext("Generates symbolic linearization matrices A,B,C,D for linear model:\n\t:math:`\\dot{x} = Ax + Bu `\n\t:math:`y = Cx +Du`")),
    ("generateSymbolicSensitivities", Gettext.gettext("Generates symbolic Sensivities matrix, where der(x) is differentiated w.r.t. param.")),
    ("inlineArrayEqn", Gettext.gettext("This module expands all array equations to scalar equations.")),
    ("inputDerivativesUsed", Gettext.gettext("Checks if derivatives of inputs are need to calculate the model.")),
    ("lateInlineFunction", Gettext.gettext("Perform function inlining for function with annotation LateInline=true.")),
    ("partlintornsystem",Gettext.notrans("partitions linear torn systems.")),
    ("recursiveTearing", Gettext.notrans("inline and repeat tearing")),
    ("reduceDynamicOptimization", Gettext.notrans("Removes equations which are not needed for the calculations of cost and constraints. This module requires --postOptModules+=reduceDynamicOptimization.")),
    ("relaxSystem", Gettext.notrans("relaxation from gausian elemination")),
    ("removeConstants", Gettext.gettext("Remove all constants in the system.")),
    ("removeEqualRHS", Gettext.notrans("Detects equal function calls of the form a=f(b) and c=f(b) and substitutes them to get speed up.")),
    ("removeSimpleEquations", removeSimpleEquationDesc),
    ("removeUnusedParameter", Gettext.gettext("Strips all parameter not present in the equations from the system to get speed up for compilation of target code.")),
    ("removeUnusedVariables", Gettext.notrans("Strips all variables not present in the equations from the system to get speed up for compilation of target code.")),
    ("reshufflePost", Gettext.gettext("Reshuffles algebraic loops.")),
    ("simplifyAllExpressions", Gettext.notrans("Does simplifications on all expressions.")),
    ("simplifyComplexFunction", Gettext.notrans("Some simplifications on complex functions (complex refers to the internal data structure)")),
    ("simplifyConstraints", Gettext.notrans("Rewrites nonlinear constraints into box constraints if possible. This module requires +gDynOpt.")),
    ("simplifyLoops", Gettext.notrans("Simplifies algebraic loops. This modules requires +simplifyLoops.")),
    ("simplifyTimeIndepFuncCalls", Gettext.gettext("Simplifies time independent built in function calls like pre(param) -> param, der(param) -> 0.0, change(param) -> false, edge(param) -> false.")),
    ("simplifysemiLinear", Gettext.gettext("Simplifies calls to semiLinear.")),
    ("solveLinearSystem", Gettext.notrans("solve linear system with newton step")),
    ("solveSimpleEquations", Gettext.notrans("Solves simple equations")),
    ("symSolver", Gettext.notrans("Rewrites the ode system for implicit Euler method. This module requires +symSolver.")),
    ("symbolicJacobian", Gettext.notrans("Detects the sparse pattern of the ODE system and calculates also the symbolic Jacobian if flag '--generateSymbolicJacobian' is enabled.")),
    ("tearingSystem", Gettext.notrans("For method selection use flag tearingMethod.")),
    ("wrapFunctionCalls", Gettext.gettext("This module introduces variables for each function call and substitutes all these calls with the newly introduced variables."))
    })),
  Gettext.gettext("Sets the post optimization modules to use in the back end. See --help=optmodules for more info."));

constant ConfigFlag SIMCODE_TARGET = CONFIG_FLAG(17, "simCodeTarget",
  NONE(), EXTERNAL(), STRING_FLAG("C"),
  SOME(STRING_OPTION({"None", "C", "Cpp","omsicpp", "ExperimentalEmbeddedC", "JavaScript", "omsic", "XML", "MidC"})),
  Gettext.gettext("Sets the target language for the code generation."));


constant ConfigFlag ORDER_CONNECTIONS = CONFIG_FLAG(18, "orderConnections",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  Gettext.gettext("Orders connect equations alphabetically if set."));

constant ConfigFlag TYPE_INFO = CONFIG_FLAG(19, "typeinfo",
  SOME("t"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Prints out extra type information if set."));

constant ConfigFlag KEEP_ARRAYS = CONFIG_FLAG(20, "keepArrays",
  SOME("a"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Sets whether to split arrays or not."));

constant ConfigFlag MODELICA_OUTPUT = CONFIG_FLAG(21, "modelicaOutput",
  SOME("m"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Enables valid modelica output for flat modelica."));

constant ConfigFlag SILENT = CONFIG_FLAG(22, "silent",
  SOME("q"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Turns on silent mode."));

constant ConfigFlag CORBA_SESSION = CONFIG_FLAG(23, "corbaSessionName",
  SOME("c"), EXTERNAL(), STRING_FLAG(""), NONE(),
  Gettext.gettext("Sets the name of the corba session if -d=interactiveCorba or --interactive=corba is used."));

constant ConfigFlag NUM_PROC = CONFIG_FLAG(24, "numProcs",
  SOME("n"), EXTERNAL(), INT_FLAG(0), NONE(),
  Gettext.gettext("Sets the number of processors to use (0=default=auto)."));

constant ConfigFlag LATENCY = CONFIG_FLAG(25, "latency",
  SOME("l"), EXTERNAL(), INT_FLAG(0), NONE(),
  Gettext.gettext("Sets the latency for parallel execution."));

constant ConfigFlag BANDWIDTH = CONFIG_FLAG(26, "bandwidth",
  SOME("b"), EXTERNAL(), INT_FLAG(0), NONE(),
  Gettext.gettext("Sets the bandwidth for parallel execution."));

constant ConfigFlag INST_CLASS = CONFIG_FLAG(27, "instClass",
  SOME("i"), EXTERNAL(), STRING_FLAG(""), NONE(),
  Gettext.gettext("Instantiate the class given by the fully qualified path."));

constant ConfigFlag VECTORIZATION_LIMIT = CONFIG_FLAG(28, "vectorizationLimit",
  SOME("v"), EXTERNAL(), INT_FLAG(0), NONE(),
  Gettext.gettext("Sets the vectorization limit, arrays and matrices larger than this will not be vectorized."));

constant ConfigFlag SIMULATION_CG = CONFIG_FLAG(29, "simulationCg",
  SOME("s"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Turns on simulation code generation."));

constant ConfigFlag EVAL_PARAMS_IN_ANNOTATIONS = CONFIG_FLAG(30,
  "evalAnnotationParams", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Sets whether to evaluate parameters in annotations or not."));

constant ConfigFlag CHECK_MODEL = CONFIG_FLAG(31,
  "checkModel", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Set when checkModel is used to turn on specific features for checking."));

constant ConfigFlag CEVAL_EQUATION = CONFIG_FLAG(32,
  "cevalEquation", NONE(), INTERNAL(), BOOL_FLAG(true), NONE(),
  Gettext.notrans(""));

constant ConfigFlag UNIT_CHECKING = CONFIG_FLAG(33,
  "unitChecking", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.notrans(""));

constant ConfigFlag TRANSLATE_DAE_STRING = CONFIG_FLAG(34,
  "translateDAEString", NONE(), INTERNAL(), BOOL_FLAG(true), NONE(),
  Gettext.notrans(""));

constant ConfigFlag GENERATE_LABELED_SIMCODE = CONFIG_FLAG(35,
  "generateLabeledSimCode", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Turns on labeled SimCode generation for reduction algorithms."));

constant ConfigFlag REDUCE_TERMS = CONFIG_FLAG(36,
  "reduceTerms", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Turns on reducing terms for reduction algorithms."));

constant ConfigFlag REDUCTION_METHOD = CONFIG_FLAG(37, "reductionMethod",
  NONE(), EXTERNAL(), STRING_FLAG("deletion"),
  SOME(STRING_OPTION({"deletion","substitution","linearization"})),
    Gettext.gettext("Sets the reduction method to be used."));

constant ConfigFlag DEMO_MODE = CONFIG_FLAG(38, "demoMode",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Disable Warning/Error Massages."));

constant ConfigFlag LOCALE_FLAG = CONFIG_FLAG(39, "locale",
  NONE(), EXTERNAL(), STRING_FLAG(""), NONE(),
  Gettext.gettext("Override the locale from the environment."));

constant ConfigFlag DEFAULT_OPENCL_DEVICE = CONFIG_FLAG(40, "defaultOCLDevice",
  SOME("o"), EXTERNAL(), INT_FLAG(0), NONE(),
  Gettext.gettext("Sets the default OpenCL device to be used for parallel execution."));

constant ConfigFlag MAXTRAVERSALS = CONFIG_FLAG(41, "maxTraversals",
  NONE(), EXTERNAL(), INT_FLAG(2),NONE(),
  Gettext.gettext("Maximal traversals to find simple equations in the acausal system."));

constant ConfigFlag DUMP_TARGET = CONFIG_FLAG(42, "dumpTarget",
  NONE(), EXTERNAL(), STRING_FLAG(""), NONE(),
  Gettext.gettext("Redirect the dump to file. If the file ends with .html HTML code is generated."));

constant ConfigFlag DELAY_BREAK_LOOP = CONFIG_FLAG(43, "delayBreakLoop",
  NONE(), EXTERNAL(), BOOL_FLAG(true),NONE(),
  Gettext.gettext("Enables (very) experimental code to break algebraic loops using the delay() operator. Probably messes with initialization."));

constant ConfigFlag TEARING_METHOD = CONFIG_FLAG(44, "tearingMethod",
  NONE(), EXTERNAL(), STRING_FLAG("cellier"),
  SOME(STRING_DESC_OPTION({
    ("noTearing", Gettext.gettext("Skip tearing. This breaks models with mixed continuous-integer/boolean unknowns")),
    ("minimalTearing", Gettext.gettext("Minimal tearing method to only tear discrete variables.")),
    ("omcTearing", Gettext.gettext("Tearing method developed by TU Dresden: Frenkel, Schubert.")),
    ("cellier", Gettext.gettext("Tearing based on Celliers method, revised by FH Bielefeld: Täuber, Patrick"))})),

    Gettext.gettext("Sets the tearing method to use. Select no tearing or choose tearing method."));

constant ConfigFlag TEARING_HEURISTIC = CONFIG_FLAG(45, "tearingHeuristic",
  NONE(), EXTERNAL(), STRING_FLAG("MC3"),
  SOME(STRING_DESC_OPTION({
    ("MC1", Gettext.gettext("Original cellier with consideration of impossible assignments and discrete Vars.")),
    ("MC2", Gettext.gettext("Modified cellier, drop first step.")),
    ("MC11", Gettext.gettext("Modified MC1, new last step 'count impossible assignments'.")),
    ("MC21", Gettext.gettext("Modified MC2, new last step 'count impossible assignments'.")),
    ("MC12", Gettext.gettext("Modified MC1, step 'count impossible assignments' before last step.")),
    ("MC22", Gettext.gettext("Modified MC2, step 'count impossible assignments' before last step.")),
    ("MC13", Gettext.gettext("Modified MC1, build sum of impossible assignment and causalizable equations, choose var with biggest sum.")),
    ("MC23", Gettext.gettext("Modified MC2, build sum of impossible assignment and causalizable equations, choose var with biggest sum.")),
    ("MC231", Gettext.gettext("Modified MC23, Two rounds, choose better potentials-set.")),
    ("MC3", Gettext.gettext("Modified cellier, build sum of impossible assignment and causalizable equations for all vars, choose var with biggest sum.")),
    ("MC4", Gettext.gettext("Modified cellier, use all heuristics, choose var that occurs most in potential sets"))})),
    Gettext.gettext("Sets the tearing heuristic to use for Cellier-tearing."));

constant ConfigFlag SCALARIZE_MINMAX = CONFIG_FLAG(46, "scalarizeMinMax",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Scalarizes the builtin min/max reduction operators if true."));

constant ConfigFlag STRICT = CONFIG_FLAG(47, "strict",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Enables stricter enforcement of Modelica language rules."));

constant ConfigFlag SCALARIZE_BINDINGS = CONFIG_FLAG(48, "scalarizeBindings",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Always scalarizes bindings if set."));

constant ConfigFlag CORBA_OBJECT_REFERENCE_FILE_PATH = CONFIG_FLAG(49, "corbaObjectReferenceFilePath",
  NONE(), EXTERNAL(), STRING_FLAG(""), NONE(),
  Gettext.gettext("Sets the path for corba object reference file if -d=interactiveCorba is used."));

constant ConfigFlag HPCOM_SCHEDULER = CONFIG_FLAG(50, "hpcomScheduler",
  NONE(), EXTERNAL(), STRING_FLAG("level"), NONE(),
  Gettext.gettext("Sets the scheduler for task graph scheduling (list | listr | level | levelfix | ext | metis | mcp | taskdep | tds | bls | rand | none). Default: level."));

constant ConfigFlag HPCOM_CODE = CONFIG_FLAG(51, "hpcomCode",
  NONE(), EXTERNAL(), STRING_FLAG("openmp"), NONE(),
  Gettext.gettext("Sets the code-type produced by hpcom (openmp | pthreads | pthreads_spin | tbb | mpi). Default: openmp."));


constant ConfigFlag REWRITE_RULES_FILE = CONFIG_FLAG(52, "rewriteRulesFile", NONE(), EXTERNAL(),
  STRING_FLAG(""), NONE(),
  Gettext.gettext("Activates user given rewrite rules for Absyn expressions. The rules are read from the given file and are of the form rewrite(fromExp, toExp);"));

constant ConfigFlag REPLACE_HOMOTOPY = CONFIG_FLAG(53, "replaceHomotopy",
  NONE(), EXTERNAL(), STRING_FLAG("none"),
  SOME(STRING_DESC_OPTION({
    ("none", Gettext.gettext("Default, do not replace homotopy.")),
    ("actual", Gettext.gettext("Replace homotopy(actual, simplified) with actual.")),
    ("simplified", Gettext.gettext("Replace homotopy(actual, simplified) with simplified."))
    })),
    Gettext.gettext("Replaces homotopy(actual, simplified) with the actual expression or the simplified expression. Good for debugging models which use homotopy. The default is to not replace homotopy."));

constant ConfigFlag GENERATE_SYMBOLIC_JACOBIAN = CONFIG_FLAG(54, "generateSymbolicJacobian",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Generates symbolic Jacobian matrix, where der(x) is differentiated w.r.t. x. This matrix can be used by dassl or ida solver with simulation flag '-jacobian'."));

constant ConfigFlag GENERATE_SYMBOLIC_LINEARIZATION = CONFIG_FLAG(55, "generateSymbolicLinearization",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Generates symbolic linearization matrices A,B,C,D for linear model:\n\t\t:math:`\\dot x = Ax + Bu`\n\t\t:math:`y = Cx +Du`"));

constant ConfigFlag INT_ENUM_CONVERSION = CONFIG_FLAG(56, "intEnumConversion",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Allow Integer to enumeration conversion."));

constant ConfigFlag PROFILING_LEVEL = CONFIG_FLAG(57, "profiling",
  NONE(), EXTERNAL(), STRING_FLAG("none"), SOME(STRING_DESC_OPTION({
    ("none",Gettext.gettext("Generate code without profiling")),
    ("blocks",Gettext.gettext("Generate code for profiling function calls as well as linear and non-linear systems of equations")),
    ("blocks+html",Gettext.gettext("Like blocks, but also run xsltproc and gnuplot to generate an html report")),
    ("all",Gettext.gettext("Generate code for profiling of all functions and equations")),
    ("all_perf",Gettext.gettext("Generate code for profiling of all functions and equations with additional performance data using the papi-interface (cpp-runtime)")),
    ("all_stat",Gettext.gettext("Generate code for profiling of all functions and equations with additional statistics (cpp-runtime)"))
    })),
  Gettext.gettext("Sets the profiling level to use. Profiled equations and functions record execution time and count for each time step taken by the integrator."));

constant ConfigFlag RESHUFFLE = CONFIG_FLAG(58, "reshuffle",
  NONE(), EXTERNAL(), INT_FLAG(1), NONE(),
  Gettext.gettext("sets tolerance of reshuffling algorithm: 1: conservative, 2: more tolerant, 3 resolve all"));

constant ConfigFlag GENERATE_DYN_OPTIMIZATION_PROBLEM = CONFIG_FLAG(59, "gDynOpt",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Generate dynamic optimization problem based on annotation approach."));

constant ConfigFlag MAX_SIZE_FOR_SOLVE_LINIEAR_SYSTEM = CONFIG_FLAG(60, "maxSizeSolveLinearSystem",
  NONE(), EXTERNAL(), INT_FLAG(0), NONE(),
  Gettext.gettext("Max size for solveLinearSystem."));

constant ConfigFlag CPP_FLAGS = CONFIG_FLAG(61, "cppFlags",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({""}), NONE(),
  Gettext.gettext("Sets extra flags for compilation with the C++ compiler (e.g. +cppFlags=-O3,-Wall)"));

constant ConfigFlag REMOVE_SIMPLE_EQUATIONS = CONFIG_FLAG(62, "removeSimpleEquations",
  NONE(), EXTERNAL(), STRING_FLAG("default"),
  SOME(STRING_DESC_OPTION({
    ("none", Gettext.gettext("Disables module")),
    ("default", Gettext.gettext("Performs alias elimination and removes constant variables. Default case uses in preOpt phase the fastAcausal and in postOpt phase the causal implementation.")),
    ("causal", Gettext.gettext("Performs alias elimination and removes constant variables. Causal implementation.")),
    ("fastAcausal", Gettext.gettext("Performs alias elimination and removes constant variables. fastImplementation fastAcausal.")),
    ("allAcausal", Gettext.gettext("Performs alias elimination and removes constant variables. Implementation allAcausal.")),
    ("new", Gettext.gettext("New implementation (experimental)"))
    })),
    Gettext.gettext("Specifies method that removes simple equations."));

constant ConfigFlag DYNAMIC_TEARING = CONFIG_FLAG(63, "dynamicTearing",
  NONE(), EXTERNAL(), STRING_FLAG("false"),
  SOME(STRING_DESC_OPTION({
    ("false", Gettext.gettext("No dynamic tearing.")),
    ("true", Gettext.gettext("Dynamic tearing for linear and nonlinear systems.")),
    ("linear", Gettext.gettext("Dynamic tearing only for linear systems.")),
    ("nonlinear", Gettext.gettext("Dynamic tearing only for nonlinear systems."))
  })),
  Gettext.gettext("Activates dynamic tearing (TearingSet can be changed automatically during runtime, strict set vs. casual set.)"));

constant ConfigFlag SYM_SOLVER = CONFIG_FLAG(64, "symSolver",
  NONE(), EXTERNAL(), ENUM_FLAG(0, {("none",0), ("impEuler", 1), ("expEuler",2)}), SOME(STRING_OPTION({"none", "impEuler", "expEuler"})),
  Gettext.gettext("Activates symbolic implicit solver (original system is not changed)."));

constant ConfigFlag LOOP2CON = CONFIG_FLAG(65, "loop2con",
  NONE(), EXTERNAL(), STRING_FLAG("none"),
  SOME(STRING_DESC_OPTION({
    ("none", Gettext.gettext("Disables module")),
    ("lin", Gettext.gettext("linear loops --> constraints")),
    ("noLin", Gettext.gettext("no linear loops --> constraints")),
    ("all", Gettext.gettext("loops --> constraints"))})),
    Gettext.gettext("Specifies method that transform loops in constraints. hint: using initial guess from file!"));

constant ConfigFlag FORCE_TEARING = CONFIG_FLAG(66, "forceTearing",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Use tearing set even if it is not smaller than the original component."));

constant ConfigFlag SIMPLIFY_LOOPS = CONFIG_FLAG(67, "simplifyLoops",
  NONE(), EXTERNAL(), INT_FLAG(0),
  SOME(STRING_DESC_OPTION({
    ("0", Gettext.gettext("do nothing")),
    ("1", Gettext.gettext("special modification of residual expressions")),
    ("2", Gettext.gettext("special modification of residual expressions with helper variables"))
    })),
    Gettext.gettext("Simplify algebraic loops."));

constant ConfigFlag RTEARING = CONFIG_FLAG(68, "recursiveTearing",
  NONE(), EXTERNAL(), INT_FLAG(0),
  SOME(STRING_DESC_OPTION({
    ("0", Gettext.gettext("do nothing")),
    ("1", Gettext.gettext("linear tearing set of size 1")),
    ("2", Gettext.gettext("linear tearing"))
    })),
    Gettext.gettext("Inline and repeat tearing."));

constant ConfigFlag FLOW_THRESHOLD = CONFIG_FLAG(69, "flowThreshold",
  NONE(), EXTERNAL(), REAL_FLAG(1e-7), NONE(),
  Gettext.gettext("Sets the minium threshold for stream flow rates"));

constant ConfigFlag MATRIX_FORMAT = CONFIG_FLAG(70, "matrixFormat",
  NONE(), EXTERNAL(), STRING_FLAG("dense"), NONE(),
  Gettext.gettext("Sets the matrix format type in cpp runtime which should be used (dense | sparse ). Default: dense."));

constant ConfigFlag PARTLINTORN = CONFIG_FLAG(71, "partlintorn",
  NONE(), EXTERNAL(), INT_FLAG(0), NONE(),
  Gettext.gettext("Sets the limit for partitionin of linear torn systems."));

constant ConfigFlag INIT_OPT_MODULES = CONFIG_FLAG(72, "initOptModules",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({
    "simplifyComplexFunction",
    "tearingSystem",
    "solveSimpleEquations",
    "calculateStrongComponentJacobians",
    "simplifyAllExpressions",
    "collapseArrayExpressions"
    }),
  SOME(STRING_DESC_OPTION({
    ("calculateStrongComponentJacobians", Gettext.gettext("Generates analytical jacobian for torn linear and non-linear strong components. By default linear components and non-linear components with user-defined function calls are skipped. See also debug flags: LSanalyticJacobian, NLSanalyticJacobian and forceNLSanalyticJacobian")),
    ("collapseArrayExpressions", collapseArrayExpressionsText),
    ("constantLinearSystem", Gettext.gettext("Evaluates constant linear systems (a*x+b*y=c; d*x+e*y=f; a,b,c,d,e,f are constants) at compile-time.")),
    ("extendDynamicOptimization", Gettext.gettext("Move loops to constraints.")),
    ("generateHomotopyComponents", Gettext.gettext("Finds the parts of the DAE that have to be handled by the homotopy solver and creates a strong component out of it.")),
    ("inlineHomotopy", Gettext.gettext("Experimental: Inlines the homotopy expression to allow symbolic simplifications.")),
    ("inputDerivativesUsed", Gettext.gettext("Checks if derivatives of inputs are need to calculate the model.")),
    ("recursiveTearing", Gettext.notrans("inline and repeat tearing")),
    ("reduceDynamicOptimization", Gettext.notrans("Removes equations which are not needed for the calculations of cost and constraints. This module requires --postOptModules+=reduceDynamicOptimization.")),
    ("replaceHomotopyWithSimplified", Gettext.notrans("Replaces the homotopy expression homotopy(actual, simplified) with the simplified part.")),
    ("simplifyAllExpressions", Gettext.notrans("Does simplifications on all expressions.")),
    ("simplifyComplexFunction", Gettext.notrans("Some simplifications on complex functions (complex refers to the internal data structure)")),
    ("simplifyConstraints", Gettext.notrans("Rewrites nonlinear constraints into box constraints if possible. This module requires +gDynOpt.")),
    ("simplifyLoops", Gettext.notrans("Simplifies algebraic loops. This modules requires +simplifyLoops.")),
    ("solveSimpleEquations", Gettext.notrans("Solves simple equations")),
    ("tearingSystem", Gettext.notrans("For method selection use flag tearingMethod.")),
    ("wrapFunctionCalls", Gettext.gettext("This module introduces variables for each function call and substitutes all these calls with the newly introduced variables."))
    })),
  Gettext.gettext("Sets the initialization optimization modules to use in the back end. See --help=optmodules for more info."));

constant ConfigFlag MAX_MIXED_DETERMINED_INDEX = CONFIG_FLAG(73, "maxMixedDeterminedIndex",
  NONE(), EXTERNAL(), INT_FLAG(10), NONE(),
  Gettext.gettext("Sets the maximum mixed-determined index that is handled by the initialization."));
constant ConfigFlag USE_LOCAL_DIRECTION = CONFIG_FLAG(74, "useLocalDirection",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Keeps the input/output prefix for all variables in the flat model, not only top-level ones."));
constant ConfigFlag DEFAULT_OPT_MODULES_ORDERING = CONFIG_FLAG(75, "defaultOptModulesOrdering",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  Gettext.gettext("If this is activated, then the specified pre-/post-/init-optimization modules will be rearranged to the recommended ordering."));
constant ConfigFlag PRE_OPT_MODULES_ADD = CONFIG_FLAG(76, "preOptModules+",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Gettext.gettext("Enables additional pre-optimization modules, e.g. --preOptModules+=module1,module2 would additionally enable module1 and module2. See --help=optmodules for more info."));
constant ConfigFlag PRE_OPT_MODULES_SUB = CONFIG_FLAG(77, "preOptModules-",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Gettext.gettext("Disables a list of pre-optimization modules, e.g. --preOptModules-=module1,module2 would disable module1 and module2. See --help=optmodules for more info."));
constant ConfigFlag POST_OPT_MODULES_ADD = CONFIG_FLAG(78, "postOptModules+",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Gettext.gettext("Enables additional post-optimization modules, e.g. --postOptModules+=module1,module2 would additionally enable module1 and module2. See --help=optmodules for more info."));
constant ConfigFlag POST_OPT_MODULES_SUB = CONFIG_FLAG(79, "postOptModules-",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Gettext.gettext("Disables a list of post-optimization modules, e.g. --postOptModules-=module1,module2 would disable module1 and module2. See --help=optmodules for more info."));
constant ConfigFlag INIT_OPT_MODULES_ADD = CONFIG_FLAG(80, "initOptModules+",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Gettext.gettext("Enables additional init-optimization modules, e.g. --initOptModules+=module1,module2 would additionally enable module1 and module2. See --help=optmodules for more info."));
constant ConfigFlag INIT_OPT_MODULES_SUB = CONFIG_FLAG(81, "initOptModules-",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Gettext.gettext("Disables a list of init-optimization modules, e.g. --initOptModules-=module1,module2 would disable module1 and module2. See --help=optmodules for more info."));
constant ConfigFlag PERMISSIVE = CONFIG_FLAG(82, "permissive",
  NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Disables some error checks to allow erroneous models to compile."));
constant ConfigFlag HETS = CONFIG_FLAG(83, "hets",
  NONE(), INTERNAL(), STRING_FLAG("none"),SOME(
    STRING_DESC_OPTION({
    ("none", Gettext.gettext("do nothing")),
    ("derCalls", Gettext.gettext("sort terms based on der-calls"))
    })),
  Gettext.gettext("Heuristic equation terms sort"));
constant ConfigFlag DEFAULT_CLOCK_PERIOD = CONFIG_FLAG(84, "defaultClockPeriod",
  NONE(), INTERNAL(), REAL_FLAG(1.0), NONE(),
  Gettext.gettext("Sets the default clock period (in seconds) for state machines (default: 1.0)."));
constant ConfigFlag INST_CACHE_SIZE = CONFIG_FLAG(85, "instCacheSize",
  NONE(), EXTERNAL(), INT_FLAG(25343), NONE(),
  Gettext.gettext("Sets the size of the internal hash table used for instantiation caching."));
constant ConfigFlag MAX_SIZE_LINEAR_TEARING = CONFIG_FLAG(86, "maxSizeLinearTearing",
  NONE(), EXTERNAL(), INT_FLAG(200), NONE(),
  Gettext.gettext("Sets the maximum system size for tearing of linear systems (default 200)."));
constant ConfigFlag MAX_SIZE_NONLINEAR_TEARING = CONFIG_FLAG(87, "maxSizeNonlinearTearing",
  NONE(), EXTERNAL(), INT_FLAG(10000), NONE(),
  Gettext.gettext("Sets the maximum system size for tearing of nonlinear systems (default 10000)."));
constant ConfigFlag NO_TEARING_FOR_COMPONENT = CONFIG_FLAG(88, "noTearingForComponent",
  NONE(), EXTERNAL(), INT_LIST_FLAG({}), NONE(),
  Gettext.gettext("Deactivates tearing for the specified components.\nUse '-d=tearingdump' to find out the relevant indexes."));
constant ConfigFlag CT_STATE_MACHINES = CONFIG_FLAG(89, "ctStateMachines",
  NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Experimental: Enable continuous-time state machine prototype"));
constant ConfigFlag DAE_MODE = CONFIG_FLAG(90, "daeMode",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Generates code to simulate models in DAE mode. The whole system is passed directly to the DAE solver SUNDIALS/IDA and no algebraic solver is involved in the simulation process."));
constant ConfigFlag INLINE_METHOD = CONFIG_FLAG(91, "inlineMethod",
  NONE(), EXTERNAL(), ENUM_FLAG(1, {("replace",1), ("append",2)}),
  SOME(STRING_OPTION({"replace", "append"})),
  Gettext.gettext("Sets the inline method to use.\n"+
               "replace : This method inlines by replacing in place all expressions. Might lead to very long expression.\n"+
               "append  : This method inlines by adding additional variables to the whole system. Might lead to much bigger system."));
constant ConfigFlag SET_TEARING_VARS = CONFIG_FLAG(92, "setTearingVars",
  NONE(), EXTERNAL(), INT_LIST_FLAG({}), NONE(),
  Gettext.gettext("Sets the tearing variables by its strong component indexes. Use '-d=tearingdump' to find out the relevant indexes.\nUse following format: '--setTearingVars=(sci,n,t1,...,tn)*', with sci = strong component index, n = number of tearing variables, t1,...tn = tearing variables.\nE.g.: '--setTearingVars=4,2,3,5' would select variables 3 and 5 in strong component 4."));
constant ConfigFlag SET_RESIDUAL_EQNS = CONFIG_FLAG(93, "setResidualEqns",
  NONE(), EXTERNAL(), INT_LIST_FLAG({}), NONE(),
  Gettext.gettext("Sets the residual equations by its strong component indexes. Use '-d=tearingdump' to find out the relevant indexes for the collective equations.\nUse following format: '--setResidualEqns=(sci,n,r1,...,rn)*', with sci = strong component index, n = number of residual equations, r1,...rn = residual equations.\nE.g.: '--setResidualEqns=4,2,3,5' would select equations 3 and 5 in strong component 4.\nOnly works in combination with 'setTearingVars'."));
constant ConfigFlag IGNORE_COMMAND_LINE_OPTIONS_ANNOTATION = CONFIG_FLAG(94, "ignoreCommandLineOptionsAnnotation",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Ignores the command line options specified as annotation in the class."));
constant ConfigFlag CALCULATE_SENSITIVITIES = CONFIG_FLAG(95, "calculateSensitivities",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Generates sensitivities variables and matrixes."));
constant ConfigFlag ALARM = CONFIG_FLAG(96, "alarm",
  SOME("r"), EXTERNAL(), INT_FLAG(0), NONE(),
  Gettext.gettext("Sets the number seconds until omc timeouts and exits. Used by the testing framework to terminate infinite running processes."));
constant ConfigFlag TOTAL_TEARING = CONFIG_FLAG(97, "totalTearing",
  NONE(), EXTERNAL(), INT_LIST_FLAG({}), NONE(),
  Gettext.gettext("Activates total tearing (determination of all possible tearing sets) for the specified components.\nUse '-d=tearingdump' to find out the relevant indexes."));
constant ConfigFlag IGNORE_SIMULATION_FLAGS_ANNOTATION = CONFIG_FLAG(98, "ignoreSimulationFlagsAnnotation",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Ignores the simulation flags specified as annotation in the class."));
constant ConfigFlag DYNAMIC_TEARING_FOR_INITIALIZATION = CONFIG_FLAG(99, "dynamicTearingForInitialization",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Enable Dynamic Tearing also for the initialization system."));
constant ConfigFlag PREFER_TVARS_WITH_START_VALUE = CONFIG_FLAG(100, "preferTVarsWithStartValue",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  Gettext.gettext("Prefer tearing variables with start value for initialization."));
constant ConfigFlag EQUATIONS_PER_FILE = CONFIG_FLAG(101, "equationsPerFile",
  NONE(), EXTERNAL(), INT_FLAG(2000), NONE(),
  Gettext.gettext("Generate code for at most this many equations per C-file (partially implemented in the compiler)."));
constant ConfigFlag EVALUATE_FINAL_PARAMS = CONFIG_FLAG(102, "evaluateFinalParameters",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Evaluates all the final parameters in addition to parameters with annotation(Evaluate=true)."));
constant ConfigFlag EVALUATE_PROTECTED_PARAMS = CONFIG_FLAG(103, "evaluateProtectedParameters",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Evaluates all the protected parameters in addition to parameters with annotation(Evaluate=true)."));
constant ConfigFlag REPLACE_EVALUATED_PARAMS = CONFIG_FLAG(104, "replaceEvaluatedParameters",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  Gettext.gettext("Replaces all the evaluated parameters in the DAE."));
constant ConfigFlag CONDENSE_ARRAYS = CONFIG_FLAG(105, "condenseArrays",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  Gettext.gettext("Sets whether array expressions containing function calls are condensed or not."));
constant ConfigFlag WFC_ADVANCED = CONFIG_FLAG(106, "wfcAdvanced",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("wrapFunctionCalls ignores more then default cases, e.g. exp, sin, cos, log, (experimental flag)"));
constant ConfigFlag GRAPHICS_EXP_MODE = CONFIG_FLAG(107,
  "graphicsExpMode", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Sets whether we are in graphics exp mode (evaluating icons)."));
constant ConfigFlag TEARING_STRICTNESS = CONFIG_FLAG(108, "tearingStrictness",
  NONE(), EXTERNAL(), STRING_FLAG("strict"),SOME(
    STRING_DESC_OPTION({
    ("casual", Gettext.gettext("Loose tearing rules using ExpressionSolve to determine the solvability instead of considering the partial derivative. Allows to solve for everything that is analytically possible. This could lead to singularities during simulation.")),
    ("strict", Gettext.gettext("Robust tearing rules by consideration of the partial derivative. Allows to divide by parameters that are not equal to or close to zero.")),
    ("veryStrict", Gettext.gettext("Very strict tearing rules that do not allow to divide by any parameter. Use this if you aim at overriding parameters after compilation with values equal to or close to zero."))
    })),
  Gettext.gettext("Sets the strictness of the tearing method regarding the solvability restrictions."));
constant ConfigFlag INTERACTIVE = CONFIG_FLAG(109, "interactive",
  NONE(), EXTERNAL(), STRING_FLAG("none"),SOME(
    STRING_DESC_OPTION({
    ("none", Gettext.gettext("do nothing")),
    ("corba", Gettext.gettext("Starts omc as a server listening on the Corba interface.")),
    ("tcp", Gettext.gettext("Starts omc as a server listening on the socket interface.")),
    ("zmq", Gettext.gettext("Starts omc as a ZeroMQ server listening on the socket interface."))
    })),
  Gettext.gettext("Sets the interactive mode for omc."));
constant ConfigFlag ZEROMQ_FILE_SUFFIX = CONFIG_FLAG(110, "zeroMQFileSuffix",
  SOME("z"), EXTERNAL(), STRING_FLAG(""), NONE(),
  Gettext.gettext("Sets the file suffix for zeroMQ port file if --interactive=zmq is used."));
constant ConfigFlag HOMOTOPY_APPROACH = CONFIG_FLAG(111, "homotopyApproach",
  NONE(), EXTERNAL(), STRING_FLAG("equidistantGlobal"),
  SOME(STRING_DESC_OPTION({
    ("equidistantLocal", Gettext.gettext("Local homotopy approach with equidistant lambda steps. The homotopy parameter only effects the local strongly connected component.")),
    ("adaptiveLocal", Gettext.gettext("Local homotopy approach with adaptive lambda steps. The homotopy parameter only effects the local strongly connected component.")),
    ("equidistantGlobal", Gettext.gettext("Default, global homotopy approach with equidistant lambda steps. The homotopy parameter effects the entire initialization system.")),
    ("adaptiveGlobal", Gettext.gettext("Global homotopy approach with adaptive lambda steps. The homotopy parameter effects the entire initialization system."))
    })),
    Gettext.gettext("Sets the homotopy approach."));
constant ConfigFlag IGNORE_REPLACEABLE = CONFIG_FLAG(112, "ignoreReplaceable",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Sets whether to ignore replaceability or not when redeclaring."));

constant ConfigFlag LABELED_REDUCTION = CONFIG_FLAG(113,
  "labeledReduction", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Turns on labeling and reduce terms to do whole process of reduction."));

constant ConfigFlag DISABLE_EXTRA_LABELING = CONFIG_FLAG(114,
  "disableExtraLabeling", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Disable adding extra label into the whole experssion with more than one term and +,- operations."));

constant ConfigFlag LOAD_MSL_MODEL = CONFIG_FLAG(115,
  "loadMSLModel", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Used to know loadFile doesn't need to be called in cpp-runtime (for labeled model reduction)."));

constant ConfigFlag Load_PACKAGE_FILE = CONFIG_FLAG(116,
  "loadPackageFile", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("used when the outside name is different with the inside name of the packge, in cpp-runtime (for labeled model reduction)."));

constant ConfigFlag BUILDING_FMU = CONFIG_FLAG(117,
  "", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Is true when building an FMU (so the compiler can look for URIs to package as FMI resources)."));

constant ConfigFlag BUILDING_MODEL = CONFIG_FLAG(118,
  "", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Is true when building a model (as opposed to running a Modelica script)."));

constant ConfigFlag POST_OPT_MODULES_DAE = CONFIG_FLAG(119, "postOptModulesDAE",
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
    "detectDAEmodeSparsePattern",
    "setEvaluationStage"
    }),NONE(),
    Gettext.gettext("Sets the optimization modules for the DAEmode in the back end. See --help=optmodules for more info."));

constant ConfigFlag EVAL_LOOP_LIMIT = CONFIG_FLAG(120,
  "evalLoopLimit", NONE(), EXTERNAL(), INT_FLAG(100000), NONE(),
  Gettext.gettext("The loop iteration limit used when evaluating constant function calls."));

constant ConfigFlag EVAL_RECURSION_LIMIT = CONFIG_FLAG(121,
  "evalRecursionLimit", NONE(), EXTERNAL(), INT_FLAG(256), NONE(),
  Gettext.gettext("The recursion limit used when evaluating constant function calls."));

constant ConfigFlag SINGLE_INSTANCE_AGLSOLVER = CONFIG_FLAG(122, "singleInstanceAglSolver",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Sets to instantiate only  one algebraic loop solver all algebraic loops"));

constant ConfigFlag SHOW_STRUCTURAL_ANNOTATIONS = CONFIG_FLAG(123, "showStructuralAnnotations",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Show annotations affecting the solution process in the flattened code."));

constant ConfigFlag INITIAL_STATE_SELECTION = CONFIG_FLAG(124, "initialStateSelection",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Activates the state selection inside initialization to avoid singularities."));

constant ConfigFlag LINEARIZATION_DUMP_LANGUAGE = CONFIG_FLAG(125, "linearizationDumpLanguage",
  NONE(), EXTERNAL(), STRING_FLAG("modelica"),
  SOME(STRING_OPTION({"modelica","matlab","julia","python"})),
    Gettext.gettext("Sets the target language for the produced code of linearization. Only works with '--generateSymbolicLinearization' and 'linearize(modelName)'."));

constant ConfigFlag NO_ASSC = CONFIG_FLAG(126, "noASSC",
  NONE(), EXTERNAL(),  BOOL_FLAG(false), NONE(),
  Gettext.gettext("Disables analytical to structural singularity conversion."));

constant ConfigFlag FULL_ASSC = CONFIG_FLAG(127, "fullASSC",
  NONE(), EXTERNAL(),  BOOL_FLAG(false), NONE(),
  Gettext.gettext("Enables full equation replacement for BLT transformation from the ASSC algorithm."));

constant ConfigFlag REAL_ASSC = CONFIG_FLAG(128, "realASSC",
  NONE(), EXTERNAL(),  BOOL_FLAG(false), NONE(),
  Gettext.gettext("Enables the ASSC algorithm to evaluate real valued coefficients (usually only integers)."));

constant ConfigFlag INIT_ASSC = CONFIG_FLAG(129, "initASSC",
  NONE(), EXTERNAL(),  BOOL_FLAG(false), NONE(),
  Gettext.gettext("Enables the ASSC algorithm for initialization."));

constant ConfigFlag MAX_SIZE_ASSC = CONFIG_FLAG(130, "maxSizeASSC",
  NONE(), EXTERNAL(), INT_FLAG(200), NONE(),
  Gettext.gettext("Sets the maximum system size for the analytical to structural conversion algorithm (default 200)."));

constant ConfigFlag USE_ZEROMQ_IN_SIM = CONFIG_FLAG(131, "useZeroMQInSim",
  NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Configures to use zeroMQ in simulation runtime to exchange information via ZeroMQ with other applications"));

constant ConfigFlag ZEROMQ_PUB_PORT = CONFIG_FLAG(132, "zeroMQPubPort",
  NONE(), INTERNAL(), INT_FLAG(3203), NONE(),
  Gettext.gettext("Configures port number for simulation runtime to send information via ZeroMQ"));

constant ConfigFlag ZEROMQ_SUB_PORT = CONFIG_FLAG(133, "zeroMQSubPort",
  NONE(), INTERNAL(), INT_FLAG(3204), NONE(),
  Gettext.gettext("Configures port number for simulation runtime to receive information via ZeroMQ"));

constant ConfigFlag ZEROMQ_JOB_ID = CONFIG_FLAG(134, "zeroMQJOBID",
  NONE(), INTERNAL(), STRING_FLAG("empty"), NONE(),
  Gettext.gettext("Configures the ID with which the omc api call is labelled for zeroMQ communication."));
constant ConfigFlag ZEROMQ_SERVER_ID = CONFIG_FLAG(135, "zeroMQServerID",
  NONE(), INTERNAL(), STRING_FLAG("empty"), NONE(),
  Gettext.gettext("Configures the ID with which server application is labelled for zeroMQ communication."));
constant ConfigFlag ZEROMQ_CLIENT_ID = CONFIG_FLAG(136, "zeroMQClientID",
  NONE(), INTERNAL(), STRING_FLAG("empty"), NONE(),
  Gettext.gettext("Configures the ID with which the client application is labelled for zeroMQ communication."));

constant ConfigFlag FMI_VERSION = CONFIG_FLAG(137,
  "", NONE(), INTERNAL(), STRING_FLAG(""), NONE(),
  Gettext.gettext("returns the FMI Version either 1.0 or 2.0."));

constant ConfigFlag FLAT_MODELICA = CONFIG_FLAG(138, "flatModelica",
  SOME("f"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Outputs experimental flat Modelica."));

constant ConfigFlag FMI_FILTER = CONFIG_FLAG(139, "fmiFilter", NONE(), EXTERNAL(),
  ENUM_FLAG(FMI_INTERNAL, {("none", FMI_NONE), ("internal", FMI_INTERNAL), ("protected", FMI_PROTECTED), ("blackBox", FMI_BLACKBOX)}),
  SOME(STRING_DESC_OPTION({
    ("none", Gettext.gettext("All variables will be exposed, even variables that are introduced by the symbolic transformations. Hence, this is intended to be used for debugging.")),
    ("internal", Gettext.gettext("All internal variables introduced by the symbolic transformations are filtered out. Only the variables from the actual Modelica model are exposed (with minor exceptions, e.g. for state sets).")),
    ("protected", Gettext.gettext("All protected model variables will be filtered out in addition to --fmiFilter=internal.")),
    ("blackBox", Gettext.gettext("This option is used to hide everything except for inputs and outputs. Additional variables that need to be present in the modelDescription file for structrial reasons will have concealed names."))
    })),
  Gettext.gettext("Specifies which model variables get exposed by the modelDescription.xml"));

constant ConfigFlag FMI_SOURCES = CONFIG_FLAG(140, "fmiSources", NONE(), EXTERNAL(),
  BOOL_FLAG(true), NONE(),
  Gettext.gettext("Defines if FMUs will be exported with sources or not. --fmiFilter=blackBox might override this, because black box FMUs do never contain their source code."));

constant ConfigFlag FMI_FLAGS = CONFIG_FLAG(141, "fmiFlags", NONE(), EXTERNAL(),
  STRING_LIST_FLAG({}), NONE(),
  Gettext.gettext("Add simulation flags to FMU. Will create <fmiPrefix>_flags.json in resources folder with given flags. Use --fmiFlags or --fmiFlags=none to disable [default]. Use --fmiFlags=default for the default simulation flags. To pass flags use e.g. --fmiFlags=s:cvode,nls:homotopy or --fmiFlags=path/to/yourFlags.json."));

constant ConfigFlag NEW_BACKEND = CONFIG_FLAG(142, "newBackend",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Activates experimental new backend for better array handling. This also activates the new frontend. [WIP]"));

constant ConfigFlag PARMODAUTO = CONFIG_FLAG(143, "parmodauto",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Experimental: Enable parallelization of independent systems of equations in the translated model."));

constant ConfigFlag INTERACTIVE_PORT = CONFIG_FLAG(144, "interactivePort",
  NONE(), EXTERNAL(), INT_FLAG(0), NONE(),
  Gettext.gettext("Sets the port used by the interactive server."));

constant ConfigFlag ALLOW_NON_STANDARD_MODELICA = CONFIG_FLAG(145, "allowNonStandardModelica",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({
    }),
  SOME(STRING_DESC_OPTION({
    ("nonStdMultipleExternalDeclarations", Gettext.gettext("Allow several external declarations in functions.\nSee: https://specification.modelica.org/maint/3.5/functions.html#function-as-a-specialized-class")),
    ("nonStdEnumerationAsIntegers", Gettext.gettext("Allow enumeration as integer without casting via Integer(Enum).\nSee: https://specification.modelica.org/maint/3.5/class-predefined-types-and-declarations.html#type-conversion-of-enumeration-values-to-string-or-integer")),
    ("nonStdIntegersAsEnumeration", Gettext.gettext("Allow integer as enumeration without casting via Enum(Integer).\nSee: https://specification.modelica.org/maint/3.5/class-predefined-types-and-declarations.html#type-conversion-of-integer-to-enumeration-values")),
    ("nonStdDifferentCaseFileVsClassName", Gettext.gettext("Allow directory or file with different case in the name than the contained class name.\nSee: https://specification.modelica.org/maint/3.5/packages.html#mapping-package-class-structures-to-a-hierarchical-file-system"))
    })),
  Gettext.gettext("Flags to allow non-standard Modelica."));

constant ConfigFlag EXPORT_CLOCKS_IN_MODELDESCRIPTION = CONFIG_FLAG(146, "exportClocksInModelDescription",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("exports clocks in modeldescription.xml for fmus, The default is false."));

constant ConfigFlag LINK_TYPE = CONFIG_FLAG(147, "linkType",
  NONE(), EXTERNAL(), ENUM_FLAG(1, {("dynamic",1), ("static",2)}),
  SOME(STRING_OPTION({"dynamic", "static"})),
  Gettext.gettext("Sets the link type for the simulation executable.\n"+
               "dynamic: libraries are dynamically linked; the executable is built very fast but is not portable because of DLL dependencies.\n"+
               "static: libraries are statically linked; the executable is built more slowly but it is portable and dependency-free.\n"));

constant ConfigFlag TEARING_ALWAYS_DERIVATIVES = CONFIG_FLAG(148, "tearingAlwaysDer",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Gettext.gettext("Always choose state derivatives as iteration variables in strong components."));

constant ConfigFlag DUMP_FLAT_MODEL = CONFIG_FLAG(149, "dumpFlatModel",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({"all"}),
  SOME(STRING_DESC_OPTION({
    ("flatten", Gettext.gettext("After flattening but before connection handling.")),
    ("connections", Gettext.gettext("After connection handling.")),
    ("eval", Gettext.gettext("After evaluating constants.")),
    ("simplify", Gettext.gettext("After model simplification.")),
    ("scalarize", Gettext.gettext("After scalarizing arrays."))
  })),
  Gettext.gettext("Dumps the flat model at the given stages of the frontend."));

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
