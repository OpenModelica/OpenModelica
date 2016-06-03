/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2015, Open Source Modelica Consortium (OSMC),
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

public import Util;

protected import Corba;
protected import Error;
protected import ErrorExt;
protected import Global;
protected import List;
protected import Print;
protected import Settings;
protected import StringUtil;
protected import System;

public uniontype DebugFlag
  record DEBUG_FLAG
    Integer index "Unique index.";
    String name "The name of the flag used by -d";
    Boolean default "Default enabled or not";
    Util.TranslatableContent description "A description of the flag.";
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
    Util.TranslatableContent description "A description of the flag.";
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

public uniontype Flags
  "The structure which stores the flags."
  record FLAGS
    array<Boolean> debugFlags;
    array<FlagData> configFlags;
  end FLAGS;

  record NO_FLAGS end NO_FLAGS;
end Flags;

public uniontype ValidOptions
  "Specifies valid options for a flag."

  record STRING_OPTION
    "Options for a string flag."
    list<String> options;
  end STRING_OPTION;

  record STRING_DESC_OPTION
    "Options for a string flag, with a description for each option."
    list<tuple<String, Util.TranslatableContent>> options;
  end STRING_DESC_OPTION;
end ValidOptions;

// Change this to a proper enum when we have support for them.
public constant Integer MODELICA = 1;
public constant Integer METAMODELICA = 2;
public constant Integer PARMODELICA = 3;
public constant Integer OPTIMICA = 4;
public constant Integer PDEMODELICA = 5;

// DEBUG FLAGS
public
constant DebugFlag FAILTRACE = DEBUG_FLAG(1, "failtrace", false,
  Util.gettext("Sets whether to print a failtrace or not."));
constant DebugFlag CEVAL = DEBUG_FLAG(2, "ceval", false,
  Util.gettext("Prints extra information from Ceval."));
constant DebugFlag CHECK_BACKEND_DAE = DEBUG_FLAG(3, "checkBackendDae", false,
  Util.gettext("Do some simple analyses on the datastructure from the frontend to check if it is consistent."));
constant DebugFlag PARMODAUTO = DEBUG_FLAG(4, "parmodauto", false,
  Util.gettext("Experimental: Enable parallelization of independent systems of equations in the translated model."));
constant DebugFlag PTHREADS = DEBUG_FLAG(5, "pthreads", false,
  Util.gettext("Experimental: Unused parallelization."));
constant DebugFlag EVENTS = DEBUG_FLAG(6, "events", true,
  Util.gettext("Turns on/off events handling."));
constant DebugFlag DUMP_INLINE_SOLVER = DEBUG_FLAG(7, "dumpInlineSolver", false,
  Util.gettext("Dumps the inline solver equation system."));
constant DebugFlag EVAL_FUNC = DEBUG_FLAG(8, "evalfunc", true,
  Util.gettext("Turns on/off symbolic function evaluation."));
constant DebugFlag GEN = DEBUG_FLAG(9, "gen", true,
  Util.gettext("Turns on/off dynamic loading of functions that are compiled during translation. Only enable this if external functions are needed to calculate structural parameters or constants."));
constant DebugFlag DYN_LOAD = DEBUG_FLAG(10, "dynload", false,
  Util.gettext("Display debug information about dynamic loading of compiled functions."));
constant DebugFlag GENERATE_CODE_CHEAT = DEBUG_FLAG(11, "generateCodeCheat", false,
  Util.gettext("Used to generate code for the bootstrapped compiler."));
constant DebugFlag CGRAPH_GRAPHVIZ_FILE = DEBUG_FLAG(12, "cgraphGraphVizFile", false,
  Util.gettext("Generates a graphviz file of the connection graph."));
constant DebugFlag CGRAPH_GRAPHVIZ_SHOW = DEBUG_FLAG(13, "cgraphGraphVizShow", false,
  Util.gettext("Displays the connection graph with the GraphViz lefty tool."));
constant DebugFlag GC_PROF = DEBUG_FLAG(14, "gcProfiling", false,
  Util.gettext("Prints garbage collection stats to standard output."));
constant DebugFlag CHECK_DAE_CREF_TYPE = DEBUG_FLAG(15, "checkDAECrefType", false,
  Util.gettext("Enables extra type checking for cref expressions."));
constant DebugFlag CHECK_ASUB = DEBUG_FLAG(16, "checkASUB", false,
  Util.gettext("Prints out a warning if an ASUB is created from a CREF expression."));
constant DebugFlag INSTANCE = DEBUG_FLAG(17, "instance", false,
  Util.gettext("Prints extra failtrace from InstanceHierarchy."));
constant DebugFlag CACHE = DEBUG_FLAG(18, "Cache", true,
  Util.gettext("Turns off the instantiation cache."));
constant DebugFlag RML = DEBUG_FLAG(19, "rml", false,
  Util.gettext("Converts Modelica-style arrays to lists."));
constant DebugFlag TAIL = DEBUG_FLAG(20, "tail", false,
  Util.gettext("Prints out a notification if tail recursion optimization has been applied."));
constant DebugFlag LOOKUP = DEBUG_FLAG(21, "lookup", false,
  Util.gettext("Print extra failtrace from lookup."));
constant DebugFlag PATTERNM_SKIP_FILTER_UNUSED_AS_BINDINGS = DEBUG_FLAG(22, "patternmSkipFilterUnusedBindings", false,
  Util.notrans(""));
constant DebugFlag PATTERNM_ALL_INFO = DEBUG_FLAG(23, "patternmAllInfo", false,
  Util.gettext("Adds notifications of all pattern-matching optimizations that are performed."));
constant DebugFlag PATTERNM_DCE = DEBUG_FLAG(24, "patternmDeadCodeElimination", true,
  Util.gettext("Performs dead code elimination in match-expressions."));
constant DebugFlag PATTERNM_MOVE_LAST_EXP = DEBUG_FLAG(25, "patternmMoveLastExp", true,
  Util.gettext("Optimization that moves the last assignment(s) into the result of a match-expression. For example: equation c = fn(b); then c; => then fn(b);"));
constant DebugFlag EXPERIMENTAL_REDUCTIONS = DEBUG_FLAG(26, "experimentalReductions", false,
  Util.gettext("Turns on custom reduction functions (OpenModelica extension)."));
constant DebugFlag EVAL_PARAM = DEBUG_FLAG(27, "evalparam", false,
  Util.gettext("Constant evaluates parameters if set."));
constant DebugFlag TYPES = DEBUG_FLAG(28, "types", false,
  Util.gettext("Prints extra failtrace from Types."));
constant DebugFlag SHOW_STATEMENT = DEBUG_FLAG(29, "showStatement", false,
  Util.gettext("Shows the statement that is currently being evaluated when evaluating a script."));
constant DebugFlag DUMP = DEBUG_FLAG(30, "dump", false,
  Util.gettext("Dumps the absyn representation of a program."));
constant DebugFlag DUMP_GRAPHVIZ = DEBUG_FLAG(31, "graphviz", false,
  Util.gettext("Dumps the absyn representation of a program in graphviz format."));
constant DebugFlag EXEC_STAT = DEBUG_FLAG(32, "execstat", false,
  Util.gettext("Prints out execution statistics for the compiler."));
constant DebugFlag TRANSFORMS_BEFORE_DUMP = DEBUG_FLAG(33, "transformsbeforedump", false,
  Util.gettext("Applies transformations required for code generation before dumping flat code."));
constant DebugFlag DAE_DUMP_GRAPHV = DEBUG_FLAG(34, "daedumpgraphv", false,
  Util.gettext("Dumps the DAE in graphviz format."));
constant DebugFlag INTERACTIVE = DEBUG_FLAG(35, "interactive", false,
  Util.gettext("Starts omc as a server listening on the socket interface."));
constant DebugFlag INTERACTIVE_CORBA = DEBUG_FLAG(36, "interactiveCorba", false,
  Util.gettext("Starts omc as a server listening on the Corba interface."));
constant DebugFlag INTERACTIVE_DUMP = DEBUG_FLAG(37, "interactivedump", false,
  Util.gettext("Prints out debug information for the interactive server."));
constant DebugFlag RELIDX = DEBUG_FLAG(38, "relidx", false,
  Util.notrans("Prints out debug information about relations, that are used as zero crossings."));
constant DebugFlag DUMP_REPL = DEBUG_FLAG(39, "dumprepl", false,
  Util.gettext("Dump the found replacements for simple equation removal."));
constant DebugFlag DUMP_FP_REPL = DEBUG_FLAG(40, "dumpFPrepl", false,
  Util.gettext("Dump the found replacements for final parameters."));
constant DebugFlag DUMP_PARAM_REPL = DEBUG_FLAG(41, "dumpParamrepl", false,
  Util.gettext("Dump the found replacements for remove parameters."));
constant DebugFlag DUMP_PP_REPL = DEBUG_FLAG(42, "dumpPPrepl", false,
  Util.gettext("Dump the found replacements for protected parameters."));
constant DebugFlag DUMP_EA_REPL = DEBUG_FLAG(43, "dumpEArepl", false,
  Util.gettext("Dump the found replacements for evaluate annotations (evaluate=true) parameters."));
constant DebugFlag DEBUG_ALIAS = DEBUG_FLAG(44, "debugAlias", false,
  Util.gettext("Dump the found alias variables."));
constant DebugFlag TEARING_DUMP = DEBUG_FLAG(45, "tearingdump", false,
  Util.gettext("Dumps tearing information."));
constant DebugFlag JAC_DUMP = DEBUG_FLAG(46, "symjacdump", false,
  Util.gettext("Dumps information about symbolic Jacobians. Can be used only with postOptModules: generateSymbolicJacobian, generateSymbolicLinearization."));
constant DebugFlag JAC_DUMP2 = DEBUG_FLAG(47, "symjacdumpverbose", false,
  Util.gettext("Dumps information in verbose mode about symbolic Jacobians. Can be used only with postOptModules: generateSymbolicJacobian, generateSymbolicLinearization."));
constant DebugFlag JAC_DUMP_EQN = DEBUG_FLAG(48, "symjacdumpeqn", false,
  Util.gettext("Dump for debug purpose of symbolic Jacobians. (deactivated now)."));
constant DebugFlag JAC_WARNINGS = DEBUG_FLAG(49, "symjacwarnings", false,
  Util.gettext("Prints warnings regarding symoblic jacbians."));
constant DebugFlag DUMP_SPARSE = DEBUG_FLAG(50, "dumpSparsePattern", false,
  Util.gettext("Dumps sparse pattern with coloring used for simulation."));
constant DebugFlag DUMP_SPARSE_VERBOSE = DEBUG_FLAG(51, "dumpSparsePatternVerbose", false,
  Util.gettext("Dumps in verbose mode sparse pattern with coloring used for simulation."));
constant DebugFlag BLT_DUMP = DEBUG_FLAG(52, "bltdump", false,
  Util.gettext("Dumps information from index reduction."));
constant DebugFlag DUMMY_SELECT = DEBUG_FLAG(53, "dummyselect", false,
  Util.gettext("Dumps information from dummy state selection heuristic."));
constant DebugFlag DUMP_DAE_LOW = DEBUG_FLAG(54, "dumpdaelow", false,
  Util.gettext("Dumps the equation system at the beginning of the back end."));
constant DebugFlag DUMP_INDX_DAE = DEBUG_FLAG(55, "dumpindxdae", false,
  Util.gettext("Dumps the equation system after index reduction and optimization."));
constant DebugFlag OPT_DAE_DUMP = DEBUG_FLAG(56, "optdaedump", false,
  Util.gettext("Dumps information from the optimization modules."));
constant DebugFlag EXEC_HASH = DEBUG_FLAG(57, "execHash", false,
  Util.gettext("Measures the time it takes to hash all simcode variables before code generation."));
constant DebugFlag PARAM_DLOW_DUMP = DEBUG_FLAG(58, "paramdlowdump", false,
  Util.gettext("Enables dumping of the parameters in the order they are calculated."));
constant DebugFlag DUMP_ENCAPSULATECONDITIONS = DEBUG_FLAG(59, "dumpEncapsulateConditions", false,
  Util.gettext("Dumps the results of the preOptModule encapsulateWhenConditions."));
constant DebugFlag ON_RELAXATION = DEBUG_FLAG(60, "onRelaxation", false,
  Util.gettext("Perform O(n) relaxation.\nDeprecated flag: Use --postOptModules+=relaxSystem instead."));
constant DebugFlag SHORT_OUTPUT = DEBUG_FLAG(61, "shortOutput", false,
  Util.gettext("Enables short output of the simulate() command. Useful for tools like OMNotebook."));
constant DebugFlag COUNT_OPERATIONS = DEBUG_FLAG(62, "countOperations", false,
  Util.gettext("Count operations."));
constant DebugFlag CGRAPH = DEBUG_FLAG(63, "cgraph", false,
  Util.gettext("Prints out connection graph information."));
constant DebugFlag UPDMOD = DEBUG_FLAG(64, "updmod", false,
  Util.gettext("Prints information about modification updates."));
constant DebugFlag STATIC = DEBUG_FLAG(65, "static", false,
  Util.gettext("Enables extra debug output from the static elaboration."));
constant DebugFlag TPL_PERF_TIMES = DEBUG_FLAG(66, "tplPerfTimes", false,
  Util.gettext("Enables output of template performance data for rendering text to file."));
constant DebugFlag CHECK_SIMPLIFY = DEBUG_FLAG(67, "checkSimplify", false,
  Util.gettext("Enables checks for expression simplification and prints a notification whenever an undesirable transformation has been performed."));
constant DebugFlag SCODE_INST = DEBUG_FLAG(68, "newInst", false,
  Util.gettext("Enables experimental new instantiation phase."));
constant DebugFlag WRITE_TO_BUFFER = DEBUG_FLAG(69, "writeToBuffer", false,
  Util.gettext("Enables writing simulation results to buffer."));
constant DebugFlag DUMP_BACKENDDAE_INFO = DEBUG_FLAG(70, "backenddaeinfo", false,
  Util.gettext("Enables dumping of back-end information about system (Number of equations before back-end,...)."));
constant DebugFlag GEN_DEBUG_SYMBOLS = DEBUG_FLAG(71, "gendebugsymbols", false,
  Util.gettext("Generate code with debugging symbols."));
constant DebugFlag DUMP_STATESELECTION_INFO = DEBUG_FLAG(72, "stateselection", false,
  Util.gettext("Enables dumping of selected states. Extends -d=backenddaeinfo."));
constant DebugFlag DUMP_EQNINORDER = DEBUG_FLAG(73, "dumpeqninorder", false,
  Util.gettext("Enables dumping of the equations in the order they are calculated."));
constant DebugFlag SEMILINEAR = DEBUG_FLAG(74, "semiLinear", false,
  Util.gettext("Enables dumping of the optimization information when optimizing calls to semiLinear."));
constant DebugFlag UNCERTAINTIES = DEBUG_FLAG(75, "uncertainties", false,
  Util.gettext("Enables dumping of status when calling modelEquationsUC."));
constant DebugFlag SHOW_START_ORIGIN = DEBUG_FLAG(76, "showStartOrigin", false,
  Util.gettext("Enables dumping of the DAE startOrigin attribute of the variables."));
constant DebugFlag DUMP_SIMCODE = DEBUG_FLAG(77, "dumpSimCode", false,
  Util.gettext("Dumps the simCode model used for code generation."));
constant DebugFlag DUMP_INITIAL_SYSTEM = DEBUG_FLAG(78, "dumpinitialsystem", false,
  Util.gettext("Dumps the initial equation system."));
constant DebugFlag GRAPH_INST = DEBUG_FLAG(79, "graphInst", false,
  Util.gettext("Do graph based instantiation."));
constant DebugFlag GRAPH_INST_RUN_DEP = DEBUG_FLAG(80, "graphInstRunDep", false,
  Util.gettext("Run scode dependency analysis. Use with -d=graphInst"));
constant DebugFlag GRAPH_INST_GEN_GRAPH = DEBUG_FLAG(81, "graphInstGenGraph", false,
  Util.gettext("Dumps a graph of the program. Use with -d=graphInst"));
constant DebugFlag GRAPH_INST_SHOW_GRAPH = DEBUG_FLAG(82, "graphInstShowGraph", false,
  Util.gettext("Display a graph of the program interactively. Use with -d=graphInst"));
constant DebugFlag DUMP_CONST_REPL = DEBUG_FLAG(83, "dumpConstrepl", false,
  Util.gettext("Dump the found replacements for constants."));
constant DebugFlag PEDANTIC = DEBUG_FLAG(84, "pedantic", false,
  Util.gettext("Switch into pedantic debug-mode, to get much more feedback."));
constant DebugFlag SHOW_EQUATION_SOURCE = DEBUG_FLAG(85, "showEquationSource", false,
  Util.gettext("Display the element source information in the dumped DAE for easier debugging."));
constant DebugFlag NLS_ANALYTIC_JACOBIAN = DEBUG_FLAG(86, "NLSanalyticJacobian", true,
  Util.gettext("Enables analytical jacobian for non-linear strong components without user-defined function calls, for that see forceNLSanalyticJacobian"));
constant DebugFlag INLINE_SOLVER = DEBUG_FLAG(87, "inlineSolver", false,
  Util.gettext("Generates code for inline solver."));
constant DebugFlag HPCOM = DEBUG_FLAG(88, "hpcom", false,
  Util.gettext("Enables parallel calculation based on task-graphs."));
constant DebugFlag INITIALIZATION = DEBUG_FLAG(89, "initialization", false,
  Util.gettext("Shows additional information from the initialization process."));
constant DebugFlag INLINE_FUNCTIONS = DEBUG_FLAG(90, "inlineFunctions", true,
  Util.gettext("Controls if function inlining should be performed."));
constant DebugFlag DUMP_SCC_GRAPHML = DEBUG_FLAG(91, "dumpSCCGraphML", false,
  Util.gettext("Dumps graphml files with the strongly connected components."));
constant DebugFlag TEARING_DUMPVERBOSE = DEBUG_FLAG(92, "tearingdumpV", false,
  Util.gettext("Dumps verbose tearing information."));
constant DebugFlag DISABLE_SINGLE_FLOW_EQ = DEBUG_FLAG(93, "disableSingleFlowEq", false,
  Util.gettext("Disables the generation of single flow equations."));
constant DebugFlag DUMP_DISCRETEVARS_INFO = DEBUG_FLAG(94, "discreteinfo", false,
  Util.gettext("Enables dumping of discrete variables. Extends -d=backenddaeinfo."));
constant DebugFlag ADDITIONAL_GRAPHVIZ_DUMP = DEBUG_FLAG(95, "graphvizDump", false,
  Util.gettext("Activates additional graphviz dumps (as .dot files). It can be used in addition to one of the following flags: {dumpdaelow|dumpinitialsystems|dumpindxdae}."));
constant DebugFlag INFO_XML_OPERATIONS = DEBUG_FLAG(96, "infoXmlOperations", false,
  Util.gettext("Enables output of the operations in the _info.xml file when translating models."));
constant DebugFlag HPCOM_DUMP = DEBUG_FLAG(97, "hpcomDump", false,
  Util.gettext("Dumps additional information on the parallel execution with hpcom."));
constant DebugFlag RESOLVE_LOOPS = DEBUG_FLAG(98, "resolveLoops", false,
  Util.gettext("Activates the resolveLoops module.\nDeprecated flag: Use --preOptModules+=resolveLoops instead."));
constant DebugFlag DISABLE_WINDOWS_PATH_CHECK_WARNING = DEBUG_FLAG(99, "disableWindowsPathCheckWarning", false,
  Util.gettext("Disables warnings on Windows if OPENMODELICAHOME/MinGW is missing."));
constant DebugFlag DISABLE_RECORD_CONSTRUCTOR_OUTPUT = DEBUG_FLAG(100, "disableRecordConstructorOutput", false,
  Util.gettext("Disables output of record constructors in the flat code."));
constant DebugFlag DUMP_TRANSFORMED_MODELICA_MODEL = DEBUG_FLAG(101, "dumpTransformedModelica", false,
  Util.gettext("Dumps the back-end DAE to a Modelica-like model after all symbolic transformations are applied."));
constant DebugFlag EVALUATE_CONST_FUNCTIONS = DEBUG_FLAG(102, "evalConstFuncs", true,
  Util.gettext("Evaluates functions complete and partially and checks for constant output.\nDeprecated flag: Use --preOptModules+=evalFunc instead."));
constant DebugFlag IMPL_ODE = DEBUG_FLAG(103, "implOde", false,
  Util.gettext("activates implicit codegen"));
constant DebugFlag EVAL_FUNC_DUMP = DEBUG_FLAG(104, "evalFuncDump", false,
  Util.gettext("dumps debug information about the function evaluation"));
constant DebugFlag PRINT_STRUCTURAL = DEBUG_FLAG(105, "printStructuralParameters", false,
  Util.gettext("Prints the structural parameters identified by the front-end"));
constant DebugFlag ITERATION_VARS = DEBUG_FLAG(106, "iterationVars", false,
  Util.gettext("Shows a list of all iteration variables."));
constant DebugFlag ALLOW_RECORD_TOO_MANY_FIELDS = DEBUG_FLAG(107, "acceptTooManyFields", false,
  Util.gettext("Accepts passing records with more fields than expected to a function. This is not allowed, but is used in Fluid.Dissipation. See https://trac.modelica.org/Modelica/ticket/1245 for details."));
constant DebugFlag HPCOM_MEMORY_OPT = DEBUG_FLAG(108, "hpcomMemoryOpt", false,
  Util.gettext("Optimize the memory structure regarding the selected scheduler"));
constant DebugFlag DUMP_SYNCHRONOUS = DEBUG_FLAG(109, "dumpSynchronous", false,
  Util.gettext("Dumps information of the clock partitioning."));
constant DebugFlag STRIP_PREFIX = DEBUG_FLAG(110, "stripPrefix", true,
  Util.gettext("Strips the environment prefix from path/crefs. Defaults to true."));
constant DebugFlag DO_SCODE_DEP = DEBUG_FLAG(111, "scodeDep", true,
  Util.gettext("Does scode dependency analysis prior to instantiation. Defaults to true."));
constant DebugFlag SHOW_INST_CACHE_INFO = DEBUG_FLAG(112, "showInstCacheInfo", false,
  Util.gettext("Prints information about instantiation cache hits and additions. Defaults to false."));
constant DebugFlag DUMP_UNIT = DEBUG_FLAG(113, "dumpUnits", false,
  Util.gettext("Dumps all the calculated units."));
constant DebugFlag DUMP_EQ_UNIT = DEBUG_FLAG(114, "dumpEqInUC", false,
  Util.gettext("Dumps all equations handled by the unit checker."));
constant DebugFlag DUMP_EQ_UNIT_STRUCT = DEBUG_FLAG(115, "dumpEqUCStruct", false,
  Util.gettext("Dumps all the equations handled by the unit checker as tree-structure."));
constant DebugFlag SHOW_DAE_GENERATION = DEBUG_FLAG(116, "showDaeGeneration", false,
  Util.gettext("Show the dae variable declarations as they happen."));
constant DebugFlag RESHUFFLE_POST = DEBUG_FLAG(117, "reshufflePost", false,
  Util.gettext("Reshuffles the systems of equations."));
constant DebugFlag SHOW_EXPANDABLE_INFO = DEBUG_FLAG(118, "showExpandableInfo", false,
  Util.gettext("Show information about expandable connector handling."));
constant DebugFlag DUMP_HOMOTOPY = DEBUG_FLAG(119, "dumpHomotopy", false,
  Util.gettext("Dumps the results of the postOptModule optimizeHomotopyCalls."));
constant DebugFlag OMC_RELOCATABLE_FUNCTIONS = DEBUG_FLAG(120, "relocatableFunctions", false,
  Util.gettext("Generates relocatable code: all functions become function pointers and can be replaced at run-time."));
constant DebugFlag GRAPHML = DEBUG_FLAG(121, "graphml", false,
  Util.gettext("Dumps .graphml files for the bipartite graph after Index Reduction and a task graph for the SCCs. Can be displayed with yEd. "));
constant DebugFlag USEMPI = DEBUG_FLAG(122, "useMPI", false,
  Util.gettext("Add MPI init and finalize to main method (CPPruntime). "));
constant DebugFlag DUMP_CSE = DEBUG_FLAG(123, "dumpCSE", false,
  Util.gettext("Additional output for CSE module."));
constant DebugFlag DUMP_CSE_VERBOSE = DEBUG_FLAG(124, "dumpCSE_verbose", false,
  Util.gettext("Additional output for CSE module."));
constant DebugFlag ADD_DER_ALIASES = DEBUG_FLAG(125, "addDerAliases", false,
  Util.gettext("Adds for every der-call an alias equation e.g. dx = der(x). It's a work-a-round flag,
                which helps in some cases to simulate the models e.g.
                Modelica.Fluid.Examples.HeatExchanger.HeatExchangerSimulation.
                Deprecated flag: Use --preOptModules+=introduceDerAlias instead."));
constant DebugFlag DISABLE_COMSUBEXP = DEBUG_FLAG(126, "disableComSubExp", false,
  Util.gettext("Deactivates module 'comSubExp'\nDeprecated flag: Use --preOptModules-=comSubExp instead."));
constant DebugFlag NO_START_CALC = DEBUG_FLAG(127, "disableStartCalc", false,
  Util.gettext("Deactivates the pre-calculation of start values during compile-time."));
constant DebugFlag NO_PARTITIONING = DEBUG_FLAG(128, "disablePartitioning", false,
  Util.gettext("Deactivates partitioning of entire equation system.\nDeprecated flag: Use --preOptModules-=clockPartitioning instead."));
constant DebugFlag ALLOW_IMPOSSIBLE_ASSIGNMENTS = DEBUG_FLAG(129, "allowImpossibleAssignments", false,
  Util.gettext("Using ExpressionSolve in adjacencyRowEnhanced instead of considering the partial derivative. This could lead to singularities during simulation."));
constant DebugFlag CONSTJAC = DEBUG_FLAG(130, "constjac", false,
  Util.gettext("solves linear systems with constant Jacobian and variable b-Vector symbolically"));
constant DebugFlag REDUCE_DYN_OPT = DEBUG_FLAG(131, "reduceDynOpt", false,
  Util.gettext("remove eqs which not need for the calculations of cost and constraints\nDeprecated flag: Use --postOptModules+=reduceDynamicOptimization instead."));
constant DebugFlag VISUAL_XML = DEBUG_FLAG(132, "visxml", false,
  Util.gettext("Outputs a xml-file that contains information for visualization."));
constant DebugFlag ADD_SCALED_VARS = DEBUG_FLAG(133, "addScaledVars", false,
  Util.gettext("Adds an alias equation var_nrom = var/nominal where var is state\nDeprecated flag: Use --postOptModules+=addScaledVars_states instead."));
constant DebugFlag ADD_SCALED_VARS_INPUT = DEBUG_FLAG(134, "addScaledVarsInput", false,
  Util.gettext("Adds an alias equation var_nrom = var/nominal where var is input\nDeprecated flag: Use --postOptModules+=addScaledVars_inputs instead."));
constant DebugFlag VECTORIZE = DEBUG_FLAG(135, "vectorize", false,
  Util.gettext("Activates vectorization in the backend."));
constant DebugFlag CHECK_EXT_LIBS = DEBUG_FLAG(136, "buildExternalLibs", true,
  Util.gettext("Use the autotools project in the Resources folder of the library to build missing external libraries."));
constant DebugFlag RUNTIME_STATIC_LINKING = DEBUG_FLAG(137, "runtimeStaticLinking", false,
  Util.gettext("Use the static simulation runtime libraries (C++ simulation runtime)."));
constant DebugFlag SORT_EQNS_AND_VARS = DEBUG_FLAG(138, "sortEqnsAndVars", false,
  Util.gettext("Heuristic sorting for equations and variables. Influenced: removeSimpleEquations and tearing.\nDeprecated flag: Use --preOptModules+=sortEqnsVars instead."));
constant DebugFlag DUMP_SIMPLIFY_LOOPS = DEBUG_FLAG(139, "dumpSimplifyLoops", false,
  Util.gettext("Dump between steps of simplifyLoops"));
constant DebugFlag DUMP_RTEARING = DEBUG_FLAG(140, "dumpRecursiveTearing", false,
  Util.gettext("Dump between steps of recursiveTearing"));
constant DebugFlag DIS_SIMP_FUN = DEBUG_FLAG(141, "disableSimplifyComplexFunction", false,
  Util.gettext("disable simplifyComplexFunction\nDeprecated flag: Use --postOptModules-=simplifyComplexFunction/--initOptModules-=simplifyComplexFunction instead."));
constant DebugFlag DIS_SYMJAC_FMI20 = DEBUG_FLAG(142, "disableSymbolicLinearization", false,
  Util.gettext("For FMI 2.0 only dependecy analysis will be perform."));
constant DebugFlag EVAL_ALL_PARAMS = DEBUG_FLAG(143, "evalAllParams", false,
  Util.gettext("Evaluates all parameters in order to increase simulation speed.\nDeprecated flag: Use --preOptModules+=evaluateAllParameters instead."));
constant DebugFlag EVAL_OUTPUT_ONLY = DEBUG_FLAG(144, "evalOutputOnly", false,
  Util.gettext("Generates equations to calculate outputs only."));
constant DebugFlag HARDCODED_START_VALUES = DEBUG_FLAG(145, "hardcodedStartValues", false,
  Util.gettext("Embed the start values of variables and parameters into the c++ code and do not read it from xml file."));
constant DebugFlag DUMP_FUNCTIONS = DEBUG_FLAG(146, "dumpFunctions", false,
  Util.gettext("Add functions to backend dumps."));
constant DebugFlag DEBUG_DIFFERENTIATION = DEBUG_FLAG(147, "debugDifferentiation", false,
  Util.gettext("Dumps debug output for the differentiation process."));
constant DebugFlag DEBUG_DIFFERENTIATION_VERBOSE = DEBUG_FLAG(148, "debugDifferentiationVerbose", false,
  Util.gettext("Dumps verbose debug output for the differentiation process."));
constant DebugFlag FMU_EXPERIMENTAL = DEBUG_FLAG(149, "fmuExperimental", false,
  Util.gettext("Include an extra function in the FMU fmi2GetSpecificDerivatives."));
constant DebugFlag DUMP_DGESV = DEBUG_FLAG(150, "dumpdgesv", false,
  Util.gettext("Enables dumping of the information whether DGESV is used to solve linear systems."));
constant DebugFlag MULTIRATE_PARTITION = DEBUG_FLAG(151, "multirate", false,
  Util.gettext("The solver can switch partitions in the system."));
constant DebugFlag DUMP_EXCLUDED_EXP = DEBUG_FLAG(152, "dumpExcludedSymJacExps", false,
  Util.gettext("This flags dumps all expression that are excluded from differentiation of a symbolic Jacobian."));
constant DebugFlag DEBUG_ALGLOOP_JACOBIAN = DEBUG_FLAG(153, "debugAlgebraicLoopsJacobian", false,
  Util.gettext("Dumps debug output while creating symbolic jacobians for non-linear systems."));
constant DebugFlag DISABLE_JACSCC = DEBUG_FLAG(154, "disableJacsforSCC", false,
  Util.gettext("Disables calculation of jacobians to detect if a SCC is linear or non-linear. By disabling all SCC will handled like non-linear."));
constant DebugFlag FORCE_NLS_ANALYTIC_JACOBIAN = DEBUG_FLAG(155, "forceNLSanalyticJacobian", false,
  Util.gettext("Forces calculation analytical jacobian also for non-linear strong components with user-defined functions."));
constant DebugFlag DUMP_LOOPS = DEBUG_FLAG(156, "dumpLoops", false,
  Util.gettext("Dumps loop equation."));
constant DebugFlag SKIP_INPUT_OUTPUT_SYNTACTIC_SUGAR = DEBUG_FLAG(157, "skipInputOutputSyntacticSugar", false,
  Util.gettext("Used when bootstrapping to preserve the input output parsing of the code output by the list command."));
constant DebugFlag OMC_RECORD_ALLOC_WORDS = DEBUG_FLAG(158, "metaModelicaRecordAllocWords", false,
  Util.gettext("Instrument the source code to record memory allocations (requires run-time and generated files compiled with -DOMC_RECORD_ALLOC_WORDS)."));
constant DebugFlag TOTAL_TEARING_DUMP = DEBUG_FLAG(159, "totaltearingdump", false,
  Util.gettext("Dumps total tearing information."));
constant DebugFlag TOTAL_TEARING_DUMPVERBOSE = DEBUG_FLAG(160, "totaltearingdumpV", false,
  Util.gettext("Dumps verbose total tearing information."));
constant DebugFlag PARALLEL_CODEGEN = DEBUG_FLAG(161, "parallelCodegen", true,
  Util.gettext("Enables code generation in parallel (disable this if compiling a model causes you to run out of RAM)."));
constant DebugFlag SERIALIZED_SIZE = DEBUG_FLAG(162, "reportSerializedSize", false,
  Util.gettext("Reports serialized sizes of various data structures used in the compiler."));
constant DebugFlag BACKEND_KEEP_ENV_GRAPH = DEBUG_FLAG(163, "backendKeepEnv", true,
  Util.gettext("When enabled, the environment is kept when entering the backend, which enables CevalFunction (function interpretation) to work. This module not essential for the backend to function in most cases, but can improve simulation performance by evaluating functions. The drawback to keeping the environment graph in memory is that it is huge (~80% of the total memory in use when returning the frontend DAE)."));
constant DebugFlag DUMPBACKENDINLINE = DEBUG_FLAG(164, "dumpBackendInline", false,
  Util.gettext("Dumps debug output while inline function."));
constant DebugFlag DUMPBACKENDINLINE_VERBOSE = DEBUG_FLAG(165, "dumpBackendInlineVerbose", false,
  Util.gettext("Dumps debug output while inline function."));
constant DebugFlag BLT_MATRIX_DUMP = DEBUG_FLAG(166, "bltmatrixdump", false,
  Util.gettext("Dumps the blt matrix in html file. IE seems to be very good in displaying large matrices."));

// This is a list of all debug flags, to keep track of which flags are used. A
// flag can not be used unless it's in this list, and the list is checked at
// initialization so that all flags are sorted by index (and thus have unique
// indices).
protected
constant list<DebugFlag> allDebugFlags = {
  FAILTRACE,
  CEVAL,
  CHECK_BACKEND_DAE,
  PARMODAUTO,
  PTHREADS,
  EVENTS,
  DUMP_INLINE_SOLVER,
  EVAL_FUNC,
  GEN,
  DYN_LOAD,
  GENERATE_CODE_CHEAT,
  CGRAPH_GRAPHVIZ_FILE,
  CGRAPH_GRAPHVIZ_SHOW,
  GC_PROF,
  CHECK_DAE_CREF_TYPE,
  CHECK_ASUB,
  INSTANCE,
  CACHE,
  RML,
  TAIL,
  LOOKUP,
  PATTERNM_SKIP_FILTER_UNUSED_AS_BINDINGS,
  PATTERNM_ALL_INFO,
  PATTERNM_DCE,
  PATTERNM_MOVE_LAST_EXP,
  EXPERIMENTAL_REDUCTIONS,
  EVAL_PARAM,
  TYPES,
  SHOW_STATEMENT,
  DUMP,
  DUMP_GRAPHVIZ,
  EXEC_STAT,
  TRANSFORMS_BEFORE_DUMP,
  DAE_DUMP_GRAPHV,
  INTERACTIVE,
  INTERACTIVE_CORBA,
  INTERACTIVE_DUMP,
  RELIDX,
  DUMP_REPL,
  DUMP_FP_REPL,
  DUMP_PARAM_REPL,
  DUMP_PP_REPL,
  DUMP_EA_REPL,
  DEBUG_ALIAS,
  TEARING_DUMP,
  JAC_DUMP,
  JAC_DUMP2,
  JAC_DUMP_EQN,
  JAC_WARNINGS,
  DUMP_SPARSE,
  DUMP_SPARSE_VERBOSE,
  BLT_DUMP,
  DUMMY_SELECT,
  DUMP_DAE_LOW,
  DUMP_INDX_DAE,
  OPT_DAE_DUMP,
  EXEC_HASH,
  PARAM_DLOW_DUMP,
  DUMP_ENCAPSULATECONDITIONS,
  ON_RELAXATION,
  SHORT_OUTPUT,
  COUNT_OPERATIONS,
  CGRAPH,
  UPDMOD,
  STATIC,
  TPL_PERF_TIMES,
  CHECK_SIMPLIFY,
  SCODE_INST,
  WRITE_TO_BUFFER,
  DUMP_BACKENDDAE_INFO,
  GEN_DEBUG_SYMBOLS,
  DUMP_STATESELECTION_INFO,
  DUMP_EQNINORDER,
  SEMILINEAR,
  UNCERTAINTIES,
  SHOW_START_ORIGIN,
  DUMP_SIMCODE,
  DUMP_INITIAL_SYSTEM,
  GRAPH_INST,
  GRAPH_INST_RUN_DEP,
  GRAPH_INST_GEN_GRAPH,
  GRAPH_INST_SHOW_GRAPH,
  DUMP_CONST_REPL,
  PEDANTIC,
  SHOW_EQUATION_SOURCE,
  NLS_ANALYTIC_JACOBIAN,
  INLINE_SOLVER,
  HPCOM,
  INITIALIZATION,
  INLINE_FUNCTIONS,
  DUMP_SCC_GRAPHML,
  TEARING_DUMPVERBOSE,
  DISABLE_SINGLE_FLOW_EQ,
  DUMP_DISCRETEVARS_INFO,
  ADDITIONAL_GRAPHVIZ_DUMP,
  INFO_XML_OPERATIONS,
  HPCOM_DUMP,
  RESOLVE_LOOPS,
  DISABLE_WINDOWS_PATH_CHECK_WARNING,
  DISABLE_RECORD_CONSTRUCTOR_OUTPUT,
  DUMP_TRANSFORMED_MODELICA_MODEL,
  EVALUATE_CONST_FUNCTIONS,
  IMPL_ODE,
  EVAL_FUNC_DUMP,
  PRINT_STRUCTURAL,
  ITERATION_VARS,
  ALLOW_RECORD_TOO_MANY_FIELDS,
  HPCOM_MEMORY_OPT,
  DUMP_SYNCHRONOUS,
  STRIP_PREFIX,
  DO_SCODE_DEP,
  SHOW_INST_CACHE_INFO,
  DUMP_UNIT,
  DUMP_EQ_UNIT,
  DUMP_EQ_UNIT_STRUCT,
  SHOW_DAE_GENERATION,
  RESHUFFLE_POST,
  SHOW_EXPANDABLE_INFO,
  DUMP_HOMOTOPY,
  OMC_RELOCATABLE_FUNCTIONS,
  GRAPHML,
  USEMPI,
  DUMP_CSE,
  DUMP_CSE_VERBOSE,
  ADD_DER_ALIASES,
  DISABLE_COMSUBEXP,
  NO_START_CALC,
  NO_PARTITIONING,
  ALLOW_IMPOSSIBLE_ASSIGNMENTS,
  CONSTJAC,
  REDUCE_DYN_OPT,
  VISUAL_XML,
  ADD_SCALED_VARS,
  ADD_SCALED_VARS_INPUT,
  VECTORIZE,
  CHECK_EXT_LIBS,
  RUNTIME_STATIC_LINKING,
  SORT_EQNS_AND_VARS,
  DUMP_SIMPLIFY_LOOPS,
  DUMP_RTEARING,
  DIS_SIMP_FUN,
  DIS_SYMJAC_FMI20,
  EVAL_ALL_PARAMS,
  EVAL_OUTPUT_ONLY,
  HARDCODED_START_VALUES,
  DUMP_FUNCTIONS,
  DEBUG_DIFFERENTIATION,
  DEBUG_DIFFERENTIATION_VERBOSE,
  FMU_EXPERIMENTAL,
  DUMP_DGESV,
  MULTIRATE_PARTITION,
  DUMP_EXCLUDED_EXP,
  DEBUG_ALGLOOP_JACOBIAN,
  DISABLE_JACSCC,
  FORCE_NLS_ANALYTIC_JACOBIAN,
  DUMP_LOOPS,
  SKIP_INPUT_OUTPUT_SYNTACTIC_SUGAR,
  OMC_RECORD_ALLOC_WORDS,
  TOTAL_TEARING_DUMP,
  TOTAL_TEARING_DUMPVERBOSE,
  PARALLEL_CODEGEN,
  SERIALIZED_SIZE,
  BACKEND_KEEP_ENV_GRAPH,
  DUMPBACKENDINLINE,
  DUMPBACKENDINLINE_VERBOSE,
  BLT_MATRIX_DUMP
};

public
// CONFIGURATION FLAGS
constant ConfigFlag DEBUG = CONFIG_FLAG(1, "debug",
  SOME("d"), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Util.gettext("Sets debug flags. Use --help=debug to see available flags."));

constant ConfigFlag HELP = CONFIG_FLAG(2, "help",
  SOME("h"), EXTERNAL(), STRING_FLAG(""), NONE(),
  Util.gettext("Displays the help text. Use --help=topics for more information."));

constant ConfigFlag RUNNING_TESTSUITE = CONFIG_FLAG(3, "running-testsuite",
  NONE(), INTERNAL(), STRING_FLAG(""), NONE(),
  Util.gettext("Used when running the testsuite."));

constant ConfigFlag SHOW_VERSION = CONFIG_FLAG(4, "version",
  SOME("-v"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Print the version and exit."));

constant ConfigFlag TARGET = CONFIG_FLAG(5, "target", NONE(), EXTERNAL(),
  STRING_FLAG("gcc"), SOME(STRING_OPTION({"gcc", "msvc","msvc10","msvc12","msvc13","msvc15", "vxworks69", "debugrt"})),
  Util.gettext("Sets the target compiler to use."));

constant ConfigFlag GRAMMAR = CONFIG_FLAG(6, "grammar", SOME("g"), EXTERNAL(),
  ENUM_FLAG(MODELICA, {("Modelica", MODELICA), ("MetaModelica", METAMODELICA), ("ParModelica", PARMODELICA), ("Optimica", OPTIMICA), ("PDEModelica", PDEMODELICA)}),
  SOME(STRING_OPTION({"Modelica", "MetaModelica", "ParModelica", "Optimica", "PDEModelica"})),
  Util.gettext("Sets the grammar and semantics to accept."));

constant ConfigFlag ANNOTATION_VERSION = CONFIG_FLAG(7, "annotationVersion",
  NONE(), EXTERNAL(), STRING_FLAG("3.x"), SOME(STRING_OPTION({"1.x", "2.x", "3.x"})),
  Util.gettext("Sets the annotation version that should be used."));

constant ConfigFlag LANGUAGE_STANDARD = CONFIG_FLAG(8, "std", NONE(), EXTERNAL(),
  ENUM_FLAG(1000,
    {("1.x", 10), ("2.x", 20), ("3.0", 30), ("3.1", 31), ("3.2", 32), ("3.3", 33), ("latest",1000)}),
  SOME(STRING_OPTION({"1.x", "2.x", "3.1", "3.2", "3.3", "latest"})),
  Util.gettext("Sets the language standard that should be used."));

constant ConfigFlag SHOW_ERROR_MESSAGES = CONFIG_FLAG(9, "showErrorMessages",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Show error messages immediately when they happen."));

constant ConfigFlag SHOW_ANNOTATIONS = CONFIG_FLAG(10, "showAnnotations",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Show annotations in the flattened code."));

constant ConfigFlag NO_SIMPLIFY = CONFIG_FLAG(11, "noSimplify",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Do not simplify expressions if set."));
constant Util.TranslatableContent removeSimpleEquationDesc = Util.gettext("Performs alias elimination and removes constant variables from the DAE, replacing all occurrences of the old variable reference with the new value (constants) or variable reference (alias elimination).");

public
constant ConfigFlag PRE_OPT_MODULES = CONFIG_FLAG(12, "preOptModules",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({
    "normalInlineFunction",
    "evaluateReplaceProtectedFinalEvaluateParameters",
    "simplifyIfEquations",
    "expandDerOperator",
    "removeEqualFunctionCalls",
    "clockPartitioning",
    "findStateOrder",
    "replaceEdgeChange",
    "inlineArrayEqn",
    "removeSimpleEquations",
    "comSubExp",
    "evalFunc",
    "encapsulateWhenConditions"
    }),
  SOME(STRING_DESC_OPTION({
    ("clockPartitioning", Util.gettext("Does the clock partitioning.")),
    ("comSubExp", Util.gettext("replaces common sub expressions")),
    ("dumpDAE", Util.gettext("dumps the DAE representation of the current transformation state")),
    ("dumpDAEXML", Util.gettext("dumps the DAE as xml representation of the current transformation state")),
    ("encapsulateWhenConditions", Util.gettext("This module replaces each when condition with a boolean variable.")),
    ("evalFunc", Util.gettext("evaluates functions partially")),
    ("evaluateAllParameters", Util.gettext("Evaluates all parameters to increase simulation speed.")),
    ("evaluateEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateFinalEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateFinalParameters", Util.gettext("Structural parameters and parameters declared as final are evaluated and replaced with their value in other vars. They may no longer be changed in the init file.")),
    ("evaluateReplaceEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateReplaceFinalEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateReplaceFinalParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateReplaceProtectedFinalEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final or protected are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("expandDerOperator", Util.notrans("Expands der(expr) using Derive.differentiteExpTime.")),
    ("findStateOrder", Util.notrans("Sets derivative information to states.")),
    ("inlineArrayEqn", Util.gettext("This module expands all array equations to scalar equations.")),
    ("normalInlineFunction", Util.gettext("Perform function inlining for function with annotation Inline=true.")),
    ("inputDerivativesForDynOpt", Util.gettext("Allowed derivatives of inputs in dyn. optimization.")),
    ("introduceDerAlias", Util.notrans("Adds for every der-call an alias equation e.g. dx = der(x).")),
    ("removeEqualFunctionCalls", Util.notrans("Detects equal function calls of the form a=f(b) and c=f(b) and substitutes them to get speed up.")),
    ("removeProtectedParameters", Util.gettext("Replace all parameters with protected=true in the system.")),
    ("removeSimpleEquations", removeSimpleEquationDesc),
    ("removeUnusedParameter", Util.gettext("Strips all parameter not present in the equations from the system.")),
    ("removeUnusedVariables", Util.gettext("Strips all variables not present in the equations from the system.")),
    ("removeVerySimpleEquations", Util.gettext("[Experimental] Like removeSimpleEquations, but less thorough. Note that this always uses the experimental new alias elimination, --removeSimpleEquations=new, which makes it unstable. In particular, MultiBody systems fail to translate correctly. It can be used for simple (but large) systems of equations.")),
    ("replaceEdgeChange", Util.gettext("Replace edge(b) = b and not pre(b) and change(b) = v <> pre(v).")),
    ("residualForm", Util.gettext("Transforms simple equations x=y to zero-sum equations 0=y-x.")),
    ("resolveLoops", Util.gettext("resolves linear equations in loops")),
    ("simplifyAllExpressions", Util.notrans("Does simplifications on all expressions.")),
    ("simplifyIfEquations", Util.gettext("Tries to simplify if equations by use of information from evaluated parameters.")),
    ("sortEqnsVars", Util.notrans("Heuristic sorting for equations and variables. This module requires +d=sortEqnsAndVars.")),
    ("stateMachineElab", Util.gettext("Does the elaboration of state machines.")),
    ("unitChecking", Util.gettext("advanced unit checking: 1. calculation of unspecified unit information for variables; 2. unit consistency check for equations")),
    ("wrapFunctionCalls", Util.gettext("This module introduces variables for each function call and substitutes all these calls with the newly introduced variables."))
    })),
  Util.gettext("Sets the pre optimization modules to use in the back end. See --help=optmodules for more info."));

constant ConfigFlag CHEAPMATCHING_ALGORITHM = CONFIG_FLAG(13, "cheapmatchingAlgorithm",
  NONE(), EXTERNAL(), INT_FLAG(3),
  SOME(STRING_DESC_OPTION({
    ("0", Util.gettext("No cheap matching.")),
    ("1", Util.gettext("Cheap matching, traverses all equations and match the first free variable.")),
    ("3", Util.gettext("Random Karp-Sipser: R. M. Karp and M. Sipser. Maximum matching in sparse random graphs."))})),
    Util.gettext("Sets the cheap matching algorithm to use. A cheap matching algorithm gives a jump start matching by heuristics."));

constant ConfigFlag MATCHING_ALGORITHM = CONFIG_FLAG(14, "matchingAlgorithm",
  NONE(), EXTERNAL(), STRING_FLAG("PFPlusExt"),
  SOME(STRING_DESC_OPTION({
    ("BFSB", Util.gettext("Breadth First Search based algorithm.")),
    ("DFSB", Util.gettext("Depth First Search based algorithm.")),
    ("MC21A", Util.gettext("Depth First Search based algorithm with look ahead feature.")),
    ("PF", Util.gettext("Depth First Search based algorithm with look ahead feature.")),
    ("PFPlus", Util.gettext("Depth First Search based algorithm with look ahead feature and fair row traversal.")),
    ("HK", Util.gettext("Combined BFS and DFS algorithm.")),
    ("HKDW", Util.gettext("Combined BFS and DFS algorithm.")),
    ("ABMP", Util.gettext("Combined BFS and DFS algorithm.")),
    ("PR", Util.gettext("Matching algorithm using push relabel mechanism.")),
    ("DFSBExt", Util.gettext("Depth First Search based Algorithm external c implementation.")),
    ("BFSBExt", Util.gettext("Breadth First Search based Algorithm external c implementation.")),
    ("MC21AExt", Util.gettext("Depth First Search based Algorithm with look ahead feature external c implementation.")),
    ("PFExt", Util.gettext("Depth First Search based Algorithm with look ahead feature external c implementation.")),
    ("PFPlusExt", Util.gettext("Depth First Search based Algorithm with look ahead feature and fair row traversal external c implementation.")),
    ("HKExt", Util.gettext("Combined BFS and DFS algorithm external c implementation.")),
    ("HKDWExt", Util.gettext("Combined BFS and DFS algorithm external c implementation.")),
    ("ABMPExt", Util.gettext("Combined BFS and DFS algorithm external c implementation.")),
    ("PRExt", Util.gettext("Matching algorithm using push relabel mechanism external c implementation.")),
    ("BB", Util.gettext("BBs try."))})),
    Util.gettext("Sets the matching algorithm to use. See --help=optmodules for more info."));

constant ConfigFlag INDEX_REDUCTION_METHOD = CONFIG_FLAG(15, "indexReductionMethod",
  NONE(), EXTERNAL(), STRING_FLAG("dynamicStateSelection"),
  SOME(STRING_DESC_OPTION({
    ("uode", Util.gettext("Use the underlying ODE without the constraints.")),
    ("dynamicStateSelection", Util.gettext("Simple index reduction method, select (dynamic) dummy states based on analysis of the system.")),
    ("dummyDerivatives", Util.gettext("Simple index reduction method, select (static) dummy states based on heuristic."))
    })),
    Util.gettext("Sets the index reduction method to use. See --help=optmodules for more info."));

constant ConfigFlag POST_OPT_MODULES = CONFIG_FLAG(16, "postOptModules",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({
    "lateInlineFunction",
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
    "detectJacobianSparsePattern",
    "removeConstants",
    "simplifyTimeIndepFuncCalls",
    "simplifyAllExpressions"
    }),
  SOME(STRING_DESC_OPTION({
    ("addScaledVars_states", Util.notrans("added var_norm = var/nominal, where var is state")),
    ("addScaledVars_inputs", Util.notrans("added var_norm = var/nominal, where var is input")),
    ("addTimeAsState", Util.gettext("Experimental feature: this replaces each occurrence of variable time with a new introduced state $time with equation der($time) = 1.0")),
    ("calculateStateSetsJacobians", Util.gettext("Generates analytical jacobian for dynamic state selection sets.")),
    ("calculateStrongComponentJacobians", Util.gettext("Generates analytical jacobian for torn linear and non-linear strong components. By default non-linear components with user-defined function calls are skipped. See also debug flags: NLSanalyticJacobian and forceNLSanalyticJacobian")),
    ("constantLinearSystem", Util.gettext("Evaluates constant linear systems (a*x+b*y=c; d*x+e*y=f; a,b,c,d,e,f are constants) at compile-time.")),
    ("countOperations", Util.gettext("Count the mathematical operations of the system.")),
    ("cseBinary", Util.gettext("Common Sub-expression Elimination")),
    ("detectJacobianSparsePattern", Util.gettext("Detects the sparse pattern for Jacobian A.")),
    ("dumpComponentsGraphStr", Util.notrans("Dumps the assignment graph used to determine strong components to format suitable for Mathematica")),
    ("dumpDAE", Util.gettext("dumps the DAE representation of the current transformation state")),
    ("dumpDAEXML", Util.gettext("dumps the DAE as xml representation of the current transformation state")),
    ("evaluateEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateFinalEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateFinalParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateReplaceEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateReplaceFinalEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateReplaceFinalParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateReplaceProtectedFinalEvaluateParameters", Util.notrans("Structural parameters and parameters declared as final and protected parameters are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("extendDynamicOptimization", Util.gettext("Move loops to constraints.")),
    ("generateSymbolicJacobian", Util.gettext("Generates symbolic Jacobian matrix, where der(x) is differentiated w.r.t. x. This matrix can be used to simulate with dasslColorSymJac.")),
    ("generateSymbolicLinearization", Util.gettext("Generates symbolic linearization matrices A,B,C,D for linear model:\n\t\t:math:`\\dot{x} = Ax + Bu`\n\t:math:`ty = Cx +Du`")),
    ("generateSymbolicSensitivities", Util.gettext("Generates symbolic Sensivities matrix, where der(x) is differentiated w.r.t. param.")),
    ("inlineArrayEqn", Util.gettext("This module expands all array equations to scalar equations.")),
    ("inputDerivativesUsed", Util.gettext("Checks if derivatives of inputs are need to calculate the model.")),
    ("lateInlineFunction", Util.gettext("Perform function inlining for function with annotation LateInline=true.")),
    ("partlintornsystem",Util.notrans("partitions linear torn systems.")),
    ("recursiveTearing", Util.notrans("inline and repeat tearing")),
    ("reduceDynamicOptimization", Util.notrans("Removes equations which are not needed for the calculations of cost and constraints. This module requires +d=reduceDynOpt.")),
    ("relaxSystem", Util.notrans("relaxation from gausian elemination")),
    ("removeConstants", Util.gettext("Remove all constants in the system.")),
    ("removeEqualFunctionCalls", Util.notrans("Detects equal function calls of the form a=f(b) and c=f(b) and substitutes them to get speed up.")),
    ("removeSimpleEquations", removeSimpleEquationDesc),
    ("removeUnusedParameter", Util.gettext("Strips all parameter not present in the equations from the system to get speed up for compilation of target code.")),
    ("removeUnusedVariables", Util.notrans("Strips all variables not present in the equations from the system to get speed up for compilation of target code.")),
    ("reshufflePost", Util.gettext("Reshuffles algebraic loops.")),
    ("simplifyAllExpressions", Util.notrans("Does simplifications on all expressions.")),
    ("simplifyComplexFunction", Util.notrans("Some simplifications on complex functions (complex refers to the internal data structure)")),
    ("simplifyConstraints", Util.notrans("Rewrites nonlinear constraints into box constraints if possible. This module requires +gDynOpt.")),
    ("simplifyLoops", Util.notrans("Simplifies algebraic loops. This modules requires +simplifyLoops.")),
    ("simplifyTimeIndepFuncCalls", Util.gettext("Simplifies time independent built in function calls like pre(param) -> param, der(param) -> 0.0, change(param) -> false, edge(param) -> false.")),
    ("simplifysemiLinear", Util.gettext("Simplifies calls to semiLinear.")),
    ("solveLinearSystem", Util.notrans("solve linear system with newton step")),
    ("solveSimpleEquations", Util.notrans("Solves simple equations")),
    ("symEuler", Util.notrans("Rewrites the ode system for implicit Euler method. This module requires +symEuler.")),
    ("tearingSystem", Util.notrans("For method selection use flag tearingMethod.")),
    ("wrapFunctionCalls", Util.gettext("This module introduces variables for each function call and substitutes all these calls with the newly introduced variables."))
    })),
  Util.gettext("Sets the post optimization modules to use in the back end. See --help=optmodules for more info."));

constant ConfigFlag SIMCODE_TARGET = CONFIG_FLAG(17, "simCodeTarget",
  NONE(), EXTERNAL(), STRING_FLAG("C"),
  SOME(STRING_OPTION({"None", "Adevs", "C", "Cpp", "CSharp", "Java", "JavaScript", "sfmi", "XML"})),
  Util.gettext("Sets the target language for the code generation."));

constant ConfigFlag ORDER_CONNECTIONS = CONFIG_FLAG(18, "orderConnections",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  Util.gettext("Orders connect equations alphabetically if set."));

constant ConfigFlag TYPE_INFO = CONFIG_FLAG(19, "typeinfo",
  SOME("t"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Prints out extra type information if set."));

constant ConfigFlag KEEP_ARRAYS = CONFIG_FLAG(20, "keepArrays",
  SOME("a"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Sets whether to split arrays or not."));

constant ConfigFlag MODELICA_OUTPUT = CONFIG_FLAG(21, "modelicaOutput",
  SOME("m"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Enables valid modelica output for flat modelica."));

constant ConfigFlag SILENT = CONFIG_FLAG(22, "silent",
  SOME("q"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Turns on silent mode."));

constant ConfigFlag CORBA_SESSION = CONFIG_FLAG(23, "corbaSessionName",
  SOME("c"), EXTERNAL(), STRING_FLAG(""), NONE(),
  Util.gettext("Sets the name of the corba session if -d=interactiveCorba is used."));

constant ConfigFlag NUM_PROC = CONFIG_FLAG(24, "numProcs",
  SOME("n"), EXTERNAL(), INT_FLAG(0), NONE(),
  Util.gettext("Sets the number of processors to use (0=default=auto)."));

constant ConfigFlag LATENCY = CONFIG_FLAG(25, "latency",
  SOME("l"), EXTERNAL(), INT_FLAG(0), NONE(),
  Util.gettext("Sets the latency for parallel execution."));

constant ConfigFlag BANDWIDTH = CONFIG_FLAG(26, "bandwidth",
  SOME("b"), EXTERNAL(), INT_FLAG(0), NONE(),
  Util.gettext("Sets the bandwidth for parallel execution."));

constant ConfigFlag INST_CLASS = CONFIG_FLAG(27, "instClass",
  SOME("i"), EXTERNAL(), STRING_FLAG(""), NONE(),
  Util.gettext("Instantiate the class given by the fully qualified path."));

constant ConfigFlag VECTORIZATION_LIMIT = CONFIG_FLAG(28, "vectorizationLimit",
  SOME("v"), EXTERNAL(), INT_FLAG(0), NONE(),
  Util.gettext("Sets the vectorization limit, arrays and matrices larger than this will not be vectorized."));

constant ConfigFlag SIMULATION_CG = CONFIG_FLAG(29, "simulationCg",
  SOME("s"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Turns on simulation code generation."));

constant ConfigFlag EVAL_PARAMS_IN_ANNOTATIONS = CONFIG_FLAG(30,
  "evalAnnotationParams", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Sets whether to evaluate parameters in annotations or not."));

constant ConfigFlag CHECK_MODEL = CONFIG_FLAG(31,
  "checkModel", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Set when checkModel is used to turn on specific features for checking."));

constant ConfigFlag CEVAL_EQUATION = CONFIG_FLAG(32,
  "cevalEquation", NONE(), INTERNAL(), BOOL_FLAG(true), NONE(),
  Util.notrans(""));

constant ConfigFlag UNIT_CHECKING = CONFIG_FLAG(33,
  "unitChecking", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Util.notrans(""));

constant ConfigFlag TRANSLATE_DAE_STRING = CONFIG_FLAG(34,
  "translateDAEString", NONE(), INTERNAL(), BOOL_FLAG(true), NONE(),
  Util.notrans(""));

constant ConfigFlag GENERATE_LABELED_SIMCODE = CONFIG_FLAG(35,
  "generateLabeledSimCode", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Turns on labeled SimCode generation for reduction algorithms."));

constant ConfigFlag REDUCE_TERMS = CONFIG_FLAG(36,
  "reduceTerms", NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Turns on reducing terms for reduction algorithms."));

constant ConfigFlag REDUCTION_METHOD = CONFIG_FLAG(37, "reductionMethod",
  NONE(), EXTERNAL(), STRING_FLAG("deletion"),
  SOME(STRING_OPTION({"deletion","substitution","linearization"})),
    Util.gettext("Sets the reduction method to be used."));

constant ConfigFlag DEMO_MODE = CONFIG_FLAG(38, "demoMode",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Disable Warning/Error Massages."));

constant ConfigFlag LOCALE_FLAG = CONFIG_FLAG(39, "locale",
  NONE(), EXTERNAL(), STRING_FLAG(""), NONE(),
  Util.gettext("Override the locale from the environment."));

constant ConfigFlag DEFAULT_OPENCL_DEVICE = CONFIG_FLAG(40, "defaultOCLDevice",
  SOME("o"), EXTERNAL(), INT_FLAG(0), NONE(),
  Util.gettext("Sets the default OpenCL device to be used for parallel execution."));

constant ConfigFlag MAXTRAVERSALS = CONFIG_FLAG(41, "maxTraversals",
  NONE(), EXTERNAL(), INT_FLAG(2),NONE(),
  Util.gettext("Maximal traversals to find simple equations in the acausal system."));

constant ConfigFlag DUMP_TARGET = CONFIG_FLAG(42, "dumpTarget",
  NONE(), EXTERNAL(), STRING_FLAG(""), NONE(),
  Util.gettext("Redirect the dump to file. If the file ends with .html HTML code is generated."));

constant ConfigFlag DELAY_BREAK_LOOP = CONFIG_FLAG(43, "delayBreakLoop",
  NONE(), EXTERNAL(), BOOL_FLAG(true),NONE(),
  Util.gettext("Enables (very) experimental code to break algebraic loops using the delay() operator. Probably messes with initialization."));

constant ConfigFlag TEARING_METHOD = CONFIG_FLAG(44, "tearingMethod",
  NONE(), EXTERNAL(), STRING_FLAG("cellier"),
  SOME(STRING_DESC_OPTION({
    ("noTearing", Util.gettext("Skip tearing.")),
    ("omcTearing", Util.gettext("Tearing method developed by TU Dresden: Frenkel, Schubert.")),
    ("cellier", Util.gettext("Tearing based on Celliers method, revised by FH Bielefeld: Täuber, Patrick"))})),
    Util.gettext("Sets the tearing method to use. Select no tearing or choose tearing method."));

constant ConfigFlag TEARING_HEURISTIC = CONFIG_FLAG(45, "tearingHeuristic",
  NONE(), EXTERNAL(), STRING_FLAG("MC3"),
  SOME(STRING_DESC_OPTION({
    ("MC1", Util.gettext("Original cellier with consideration of impossible assignments and discrete Vars.")),
    ("MC2", Util.gettext("Modified cellier, drop first step.")),
    ("MC11", Util.gettext("Modified MC1, new last step 'count impossible assignments'.")),
    ("MC21", Util.gettext("Modified MC2, new last step 'count impossible assignments'.")),
    ("MC12", Util.gettext("Modified MC1, step 'count impossible assignments' before last step.")),
    ("MC22", Util.gettext("Modified MC2, step 'count impossible assignments' before last step.")),
    ("MC13", Util.gettext("Modified MC1, build sum of impossible assignment and causalizable equations, choose var with biggest sum.")),
    ("MC23", Util.gettext("Modified MC2, build sum of impossible assignment and causalizable equations, choose var with biggest sum.")),
    ("MC231", Util.gettext("Modified MC23, Two rounds, choose better potentials-set.")),
    ("MC3", Util.gettext("Modified cellier, build sum of impossible assignment and causalizable equations for all vars, choose var with biggest sum.")),
    ("MC4", Util.gettext("Modified cellier, use all heuristics, choose var that occurs most in potential sets"))})),
    Util.gettext("Sets the tearing heuristic to use for Cellier-tearing."));

constant ConfigFlag DISABLE_LINEAR_TEARING = CONFIG_FLAG(46, "disableLinearTearing",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Disables the tearing of linear systems. That might improve the performance of large linear systems(N>1000) in combination with a sparse solver (e.g. umfpack) at runtime (usage with: -ls umfpack).\nDeprecated flag: Use --maxSizeLinearTearing=0 instead."));

constant ConfigFlag SCALARIZE_MINMAX = CONFIG_FLAG(47, "scalarizeMinMax",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Scalarizes the builtin min/max reduction operators if true."));

constant ConfigFlag RUNNING_WSM_TESTSUITE = CONFIG_FLAG(48, "wsm-testsuite",
  NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Used when running the WSM testsuite."));

constant ConfigFlag SCALARIZE_BINDINGS = CONFIG_FLAG(49, "scalarizeBindings",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Always scalarizes bindings if set."));

constant ConfigFlag CORBA_OBJECT_REFERENCE_FILE_PATH = CONFIG_FLAG(50, "corbaObjectReferenceFilePath",
  NONE(), EXTERNAL(), STRING_FLAG(""), NONE(),
  Util.gettext("Sets the path for corba object reference file if -d=interactiveCorba is used."));

constant ConfigFlag HPCOM_SCHEDULER = CONFIG_FLAG(51, "hpcomScheduler",
  NONE(), EXTERNAL(), STRING_FLAG("level"), NONE(),
  Util.gettext("Sets the scheduler for task graph scheduling (list | listr | level | levelfix | ext | metis | mcp | taskdep | tds | bls | rand | none). Default: level."));

constant ConfigFlag HPCOM_CODE = CONFIG_FLAG(52, "hpcomCode",
  NONE(), EXTERNAL(), STRING_FLAG("openmp"), NONE(),
  Util.gettext("Sets the code-type produced by hpcom (openmp | pthreads | pthreads_spin | tbb | mpi). Default: openmp."));


constant ConfigFlag REWRITE_RULES_FILE = CONFIG_FLAG(53, "rewriteRulesFile", NONE(), EXTERNAL(),
  STRING_FLAG(""), NONE(),
  Util.gettext("Activates user given rewrite rules for Absyn expressions. The rules are read from the given file and are of the form rewrite(fromExp, toExp);"));

constant ConfigFlag REPLACE_HOMOTOPY = CONFIG_FLAG(54, "replaceHomotopy",
  NONE(), EXTERNAL(), STRING_FLAG("none"),
  SOME(STRING_DESC_OPTION({
    ("none", Util.gettext("Default, do not replace homotopy.")),
    ("actual", Util.gettext("Replace homotopy(actual, simplified) with actual.")),
    ("simplified", Util.gettext("Replace homotopy(actual, simplified) with simplified."))
    })),
    Util.gettext("Replaces homotopy(actual, simplified) with the actual expression or the simplified expression. Good for debugging models which use homotopy. The default is to not replace homotopy."));

constant ConfigFlag GENERATE_SYMBOLIC_JACOBIAN = CONFIG_FLAG(55, "generateSymbolicJacobian",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Generates symbolic Jacobian matrix, where der(x) is differentiated w.r.t. x. This matrix can be utilise by dassl with the runtime option: -dasslJacobian=coloredSymbolical|symbolical.\nDeprecated flag: Use --postOptModules+=generateSymbolicJacobian instead."));

constant ConfigFlag GENERATE_SYMBOLIC_LINEARIZATION = CONFIG_FLAG(56, "generateSymbolicLinearization",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Generates symbolic linearization matrices A,B,C,D for linear model:\n\t\t:math:`\\dot x = Ax + Bu`\n\t\t:math:`y = Cx +Du`"));

constant ConfigFlag INT_ENUM_CONVERSION = CONFIG_FLAG(57, "intEnumConversion",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Allow Integer to enumeration conversion."));

constant ConfigFlag PROFILING_LEVEL = CONFIG_FLAG(58, "profiling",
  NONE(), EXTERNAL(), STRING_FLAG("none"), SOME(STRING_DESC_OPTION({
    ("none",Util.gettext("Generate code without profiling")),
    ("blocks",Util.gettext("Generate code for profiling function calls as well as linear and non-linear systems of equations")),
    ("blocks+html",Util.gettext("Like blocks, but also run xsltproc and gnuplot to generate an html report")),
    ("all",Util.gettext("Generate code for profiling of all functions and equations")),
    ("all_perf",Util.gettext("Generate code for profiling of all functions and equations with additional performance data using the papi-interface (cpp-runtime)")),
    ("all_stat",Util.gettext("Generate code for profiling of all functions and equations with additional statistics (cpp-runtime)"))
    })),
  Util.gettext("Sets the profiling level to use. Profiled equations and functions record execution time and count for each time step taken by the integrator."));

constant ConfigFlag RESHUFFLE = CONFIG_FLAG(59, "reshuffle",
  NONE(), EXTERNAL(), INT_FLAG(1), NONE(),
  Util.gettext("sets tolerance of reshuffling algorithm: 1: conservative, 2: more tolerant, 3 resolve all"));

constant ConfigFlag GENERATE_DYN_OPTIMIZATION_PROBLEM = CONFIG_FLAG(60, "gDynOpt",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Generate dynamic optimization problem based on annotation approach."));

constant ConfigFlag CSE_CALL = CONFIG_FLAG(61,
  "cseCall", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Deprecated flag: Use --postOptModules+=wrapFunctionCalls instead."));

constant ConfigFlag CSE_BINARY = CONFIG_FLAG(62,
  "cseBinary", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Deprecated flag: Use --postOptModules+=cseBinary instead."));

constant ConfigFlag CSE_EACHCALL = CONFIG_FLAG(63,
  "cseEachCall", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Deprecated flag: Use --postOptModules+=wrapFunctionCalls instead."));

constant ConfigFlag MAX_SIZE_FOR_SOLVE_LINIEAR_SYSTEM = CONFIG_FLAG(64, "maxSizeSolveLinearSystem",
  NONE(), EXTERNAL(), INT_FLAG(0), NONE(),
  Util.gettext("Max size for solveLinearSystem."));

constant ConfigFlag CPP_FLAGS = CONFIG_FLAG(65, "cppFlags",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({""}), NONE(),
  Util.gettext("Sets extra flags for compilation with the C++ compiler (e.g. +cppFlags=-O3,-Wall)"));

constant ConfigFlag REMOVE_SIMPLE_EQUATIONS = CONFIG_FLAG(66, "removeSimpleEquations",
  NONE(), EXTERNAL(), STRING_FLAG("default"),
  SOME(STRING_DESC_OPTION({
    ("none", Util.gettext("Disables module")),
    ("default", Util.gettext("Performs alias elimination and removes constant variables. Default case uses in preOpt phase the fastAcausal and in postOpt phase the causal implementation.")),
    ("causal", Util.gettext("Performs alias elimination and removes constant variables. Causal implementation.")),
    ("fastAcausal", Util.gettext("Performs alias elimination and removes constant variables. fastImplementation fastAcausal.")),
    ("allAcausal", Util.gettext("Performs alias elimination and removes constant variables. Implementation allAcausal.")),
    ("new", Util.gettext("New implementation (experimental)"))
    })),
    Util.gettext("Specifies method that removes simple equations."));

constant ConfigFlag DYNAMIC_TEARING = CONFIG_FLAG(67, "dynamicTearing",
  NONE(), EXTERNAL(), STRING_FLAG("false"),
  SOME(STRING_DESC_OPTION({
    ("false", Util.gettext("No dynamic tearing.")),
    ("true", Util.gettext("Dynamic tearing for linear and nonlinear systems.")),
    ("linear", Util.gettext("Dynamic tearing only for linear systems.")),
    ("nonlinear", Util.gettext("Dynamic tearing only for nonlinear systems."))
  })),
  Util.gettext("Activates dynamic tearing (TearingSet can be changed automatically during runtime, strict set vs. casual set.)"));

constant ConfigFlag SYM_EULER = CONFIG_FLAG(68, "symEuler",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Rewrite the ode system for implicit euler."));

constant ConfigFlag ADD_TIME_AS_STATE = CONFIG_FLAG(69,
  "addTimeAsState", NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Experimental feature: this replaces each occurrence of variable time with a new introduced state $time with equation der($time) = 1.0\nDeprecated flag: Use --postOptModules+=addTimeAsState instead."));

constant ConfigFlag LOOP2CON = CONFIG_FLAG(70, "loop2con",
  NONE(), EXTERNAL(), STRING_FLAG("none"),
  SOME(STRING_DESC_OPTION({
    ("none", Util.gettext("Disables module")),
    ("lin", Util.gettext("linear loops --> constraints")),
    ("noLin", Util.gettext("no linear loops --> constraints")),
    ("all", Util.gettext("loops --> constraints"))})),
    Util.gettext("Specifies method that transform loops in constraints. hint: using initial guess from file!"));

constant ConfigFlag FORCE_TEARING = CONFIG_FLAG(71, "forceTearing",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Use tearing set even if it is not smaller than the original component."));

constant ConfigFlag SIMPLIFY_LOOPS = CONFIG_FLAG(72, "simplifyLoops",
  NONE(), EXTERNAL(), INT_FLAG(0),
  SOME(STRING_DESC_OPTION({
    ("0", Util.gettext("do nothing")),
    ("1", Util.gettext("special modification of residual expressions")),
    ("2", Util.gettext("special modification of residual expressions with helper variables"))
    })),
    Util.gettext("Simplify algebraic loops."));

constant ConfigFlag RTEARING = CONFIG_FLAG(73, "recursiveTearing",
  NONE(), EXTERNAL(), INT_FLAG(0),
  SOME(STRING_DESC_OPTION({
    ("0", Util.gettext("do nothing")),
    ("1", Util.gettext("linear tearing set of size 1")),
    ("2", Util.gettext("linear tearing"))
    })),
    Util.gettext("Inline and repeat tearing."));

constant ConfigFlag FLOW_THRESHOLD = CONFIG_FLAG(74, "flowThreshold",
  NONE(), EXTERNAL(), REAL_FLAG(1e-7), NONE(),
  Util.gettext("Sets the minium threshold for stream flow rates"));

constant ConfigFlag MATRIX_FORMAT = CONFIG_FLAG(75, "matrixFormat",
  NONE(), EXTERNAL(), STRING_FLAG("dense"), NONE(),
  Util.gettext("Sets the matrix format type in cpp runtime which should be used (dense | sparse ). Default: dense."));

constant ConfigFlag PARTLINTORN = CONFIG_FLAG(76, "partlintorn",
  NONE(), EXTERNAL(), INT_FLAG(0), NONE(),
  Util.gettext("Sets the limit for partitionin of linear torn systems."));

constant ConfigFlag INIT_OPT_MODULES = CONFIG_FLAG(77, "initOptModules",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({
    "simplifyComplexFunction",
    "tearingSystem",
    "calculateStrongComponentJacobians",
    "solveSimpleEquations",
    "simplifyAllExpressions"
    }),
  SOME(STRING_DESC_OPTION({
    ("calculateStrongComponentJacobians", Util.gettext("Generates analytical jacobian for torn linear and non-linear strong components. By default non-linear components with user-defined function calls are skipped. See also debug flags: NLSanalyticJacobian and NLSanalyticJacobianDisable")),
    ("constantLinearSystem", Util.gettext("Evaluates constant linear systems (a*x+b*y=c; d*x+e*y=f; a,b,c,d,e,f are constants) at compile-time.")),
    ("extendDynamicOptimization", Util.gettext("Move loops to constraints.")),
    ("inputDerivativesUsed", Util.gettext("Checks if derivatives of inputs are need to calculate the model.")),
    ("recursiveTearing", Util.notrans("inline and repeat tearing")),
    ("reduceDynamicOptimization", Util.notrans("Removes equations which are not needed for the calculations of cost and constraints. This module requires +d=reduceDynOpt.")),
    ("simplifyAllExpressions", Util.notrans("Does simplifications on all expressions.")),
    ("simplifyComplexFunction", Util.notrans("Some simplifications on complex functions (complex refers to the internal data structure)")),
    ("simplifyConstraints", Util.notrans("Rewrites nonlinear constraints into box constraints if possible. This module requires +gDynOpt.")),
    ("simplifyLoops", Util.notrans("Simplifies algebraic loops. This modules requires +simplifyLoops.")),
    ("solveSimpleEquations", Util.notrans("Solves simple equations")),
    ("tearingSystem", Util.notrans("For method selection use flag tearingMethod."))
    })),
  Util.gettext("Sets the initialization optimization modules to use in the back end. See --help=optmodules for more info."));

constant ConfigFlag MAX_MIXED_DETERMINED_INDEX = CONFIG_FLAG(78, "maxMixedDeterminedIndex",
  NONE(), EXTERNAL(), INT_FLAG(3), NONE(),
  Util.gettext("Sets the maximum mixed-determined index that is handled by the initialization."));
constant ConfigFlag USE_LOCAL_DIRECTION = CONFIG_FLAG(79, "useLocalDirection",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Keeps the input/output prefix for all variables in the flat model, not only top-level ones."));
constant ConfigFlag DEFAULT_OPT_MODULES_ORDERING = CONFIG_FLAG(80, "defaultOptModulesOrdering",
  NONE(), EXTERNAL(), BOOL_FLAG(true), NONE(),
  Util.gettext("If this is activated, then the specified pre-/post-/init-optimization modules will be rearranged to the recommended ordering."));
constant ConfigFlag PRE_OPT_MODULES_ADD = CONFIG_FLAG(81, "preOptModules+",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Util.gettext("Enables additional pre-optimization modules, e.g. --preOptModules+=module1,module2 would additionally enable module1 and module2. See --help=optmodules for more info."));
constant ConfigFlag PRE_OPT_MODULES_SUB = CONFIG_FLAG(82, "preOptModules-",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Util.gettext("Disables a list of pre-optimization modules, e.g. --preOptModules-=module1,module2 would disable module1 and module2. See --help=optmodules for more info."));
constant ConfigFlag POST_OPT_MODULES_ADD = CONFIG_FLAG(83, "postOptModules+",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Util.gettext("Enables additional post-optimization modules, e.g. --postOptModules+=module1,module2 would additionally enable module1 and module2. See --help=optmodules for more info."));
constant ConfigFlag POST_OPT_MODULES_SUB = CONFIG_FLAG(84, "postOptModules-",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Util.gettext("Disables a list of post-optimization modules, e.g. --postOptModules-=module1,module2 would disable module1 and module2. See --help=optmodules for more info."));
constant ConfigFlag INIT_OPT_MODULES_ADD = CONFIG_FLAG(85, "initOptModules+",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Util.gettext("Enables additional init-optimization modules, e.g. --initOptModules+=module1,module2 would additionally enable module1 and module2. See --help=optmodules for more info."));
constant ConfigFlag INIT_OPT_MODULES_SUB = CONFIG_FLAG(86, "initOptModules-",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Util.gettext("Disables a list of init-optimization modules, e.g. --initOptModules-=module1,module2 would disable module1 and module2. See --help=optmodules for more info."));
constant ConfigFlag PERMISSIVE = CONFIG_FLAG(87, "permissive",
  NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Disables some error checks to allow erroneous models to compile."));
constant ConfigFlag HETS = CONFIG_FLAG(88, "hets",
  NONE(), INTERNAL(), STRING_FLAG("none"),SOME(
    STRING_DESC_OPTION({
    ("none", Util.gettext("do nothing")),
    ("derCalls", Util.gettext("sort terms based on der-calls"))
    })),
  Util.gettext("Heuristic equation terms sort"));
constant ConfigFlag DEFAULT_CLOCK_PERIOD = CONFIG_FLAG(89, "defaultClockPeriod",
  NONE(), INTERNAL(), REAL_FLAG(1.0), NONE(),
  Util.gettext("Sets the default clock period (in seconds) for state machines (default: 1.0)."));
constant ConfigFlag INST_CACHE_SIZE = CONFIG_FLAG(90, "instCacheSize",
  NONE(), EXTERNAL(), INT_FLAG(25343), NONE(),
  Util.gettext("Sets the size of the internal hash table used for instantiation caching."));
constant ConfigFlag MAX_SIZE_LINEAR_TEARING = CONFIG_FLAG(91, "maxSizeLinearTearing",
  NONE(), EXTERNAL(), INT_FLAG(4000), NONE(),
  Util.gettext("Sets the maximum system size for tearing of linear systems (default 4000)."));
constant ConfigFlag MAX_SIZE_NONLINEAR_TEARING = CONFIG_FLAG(92, "maxSizeNonlinearTearing",
  NONE(), EXTERNAL(), INT_FLAG(10000), NONE(),
  Util.gettext("Sets the maximum system size for tearing of nonlinear systems (default 10000)."));
constant ConfigFlag NO_TEARING_FOR_COMPONENT = CONFIG_FLAG(93, "noTearingForComponent",
  NONE(), EXTERNAL(), INT_LIST_FLAG({}), NONE(),
  Util.gettext("Deactivates tearing for the specified components.\nUse '+d=tearingdump' to find out the relevant indexes."));
constant ConfigFlag CT_STATE_MACHINES = CONFIG_FLAG(94, "ctStateMachines",
  NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Experimental: Enable continuous-time state machine prototype"));
constant ConfigFlag DAE_MODE = CONFIG_FLAG(95, "daeMode",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Generates additional code for DAE mode, where dynamic equations are not causelized."));
constant ConfigFlag INLINE_METHOD = CONFIG_FLAG(96, "inlineMethod",
  NONE(), EXTERNAL(), ENUM_FLAG(1, {("replace",1), ("append",2)}),
  SOME(STRING_OPTION({"replace", "append"})),
  Util.gettext("Sets the inline method to use.\n"+
               "replace : This method inlines by replacing in place all expressions. Might lead to very long expression.\n"+
               "append  : This method inlines by adding additional variables to the whole system. Might lead to much bigger system."));
constant ConfigFlag SET_TEARING_VARS = CONFIG_FLAG(97, "setTearingVars",
  NONE(), EXTERNAL(), INT_LIST_FLAG({}), NONE(),
  Util.gettext("Sets the tearing variables by its strong component indexes. Use '+d=tearingdump' to find out the relevant indexes.\nUse following format: '--setTearingVars=(sci,n,t1,...,tn)*', with sci = strong component index, n = number of tearing variables, t1,...tn = tearing variables.\nE.g.: '--setTearingVars=4,2,3,5' would select variables 3 and 5 in strong component 4.\nOnly works in combination with 'setResidualEqns'."));
constant ConfigFlag SET_RESIDUAL_EQNS = CONFIG_FLAG(98, "setResidualEqns",
  NONE(), EXTERNAL(), INT_LIST_FLAG({}), NONE(),
  Util.gettext("Sets the residual equations by its strong component indexes. Use '+d=tearingdump' to find out the relevant indexes for the collective equations.\nUse following format: '--setResidualEqns=(sci,n,r1,...,rn)*', with sci = strong component index, n = number of residual equations, r1,...rn = residual equations.\nE.g.: '--setResidualEqns=4,2,3,5' would select equations 3 and 5 in strong component 4.\nOnly works in combination with 'setTearingVars'."));
constant ConfigFlag IGNORE_COMMAND_LINE_OPTIONS_ANNOTATION = CONFIG_FLAG(99, "ignoreCommandLineOptionsAnnotation",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Ignores the command line options specified as annotation in the class."));
constant ConfigFlag CALCULATE_SENSITIVITIES = CONFIG_FLAG(100, "calculateSensitivities",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Generates sensitivities variables and matrixes."));
constant ConfigFlag ALARM = CONFIG_FLAG(101, "alarm",
  SOME("r"), EXTERNAL(), INT_FLAG(0), NONE(),
  Util.gettext("Sets the number seconds until omc timeouts and exits. Used by the testing framework to terminate infinite running processes."));
constant ConfigFlag TOTAL_TEARING = CONFIG_FLAG(102, "totalTearing",
  NONE(), EXTERNAL(), INT_LIST_FLAG({}), NONE(),
  Util.gettext("Activates total tearing (determination of all possible tearing sets) for the specified components.\nUse '+d=tearingdump' to find out the relevant indexes."));
constant ConfigFlag IGNORE_SIMULATION_FLAGS_ANNOTATION = CONFIG_FLAG(103, "ignoreSimulationFlagsAnnotation",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Ignores the simulation flags specified as annotation in the class."));

protected
// This is a list of all configuration flags. A flag can not be used unless it's
// in this list, and the list is checked at initialization so that all flags are
// sorted by index (and thus have unique indices).
constant list<ConfigFlag> allConfigFlags = {
  DEBUG,
  HELP,
  RUNNING_TESTSUITE,
  SHOW_VERSION,
  TARGET,
  GRAMMAR,
  ANNOTATION_VERSION,
  LANGUAGE_STANDARD,
  SHOW_ERROR_MESSAGES,
  SHOW_ANNOTATIONS,
  NO_SIMPLIFY,
  PRE_OPT_MODULES,
  CHEAPMATCHING_ALGORITHM,
  MATCHING_ALGORITHM,
  INDEX_REDUCTION_METHOD,
  POST_OPT_MODULES,
  SIMCODE_TARGET,
  ORDER_CONNECTIONS,
  TYPE_INFO,
  KEEP_ARRAYS,
  MODELICA_OUTPUT,
  SILENT,
  CORBA_SESSION,
  NUM_PROC,
  LATENCY,
  BANDWIDTH,
  INST_CLASS,
  VECTORIZATION_LIMIT,
  SIMULATION_CG,
  EVAL_PARAMS_IN_ANNOTATIONS,
  CHECK_MODEL,
  CEVAL_EQUATION,
  UNIT_CHECKING,
  TRANSLATE_DAE_STRING,
  GENERATE_LABELED_SIMCODE,
  REDUCE_TERMS,
  REDUCTION_METHOD,
  DEMO_MODE,
  LOCALE_FLAG,
  DEFAULT_OPENCL_DEVICE,
  MAXTRAVERSALS,
  DUMP_TARGET,
  DELAY_BREAK_LOOP,
  TEARING_METHOD,
  TEARING_HEURISTIC,
  DISABLE_LINEAR_TEARING,
  SCALARIZE_MINMAX,
  RUNNING_WSM_TESTSUITE,
  SCALARIZE_BINDINGS,
  CORBA_OBJECT_REFERENCE_FILE_PATH,
  HPCOM_SCHEDULER,
  HPCOM_CODE,
  REWRITE_RULES_FILE,
  REPLACE_HOMOTOPY,
  GENERATE_SYMBOLIC_JACOBIAN,
  GENERATE_SYMBOLIC_LINEARIZATION,
  INT_ENUM_CONVERSION,
  PROFILING_LEVEL,
  RESHUFFLE,
  GENERATE_DYN_OPTIMIZATION_PROBLEM,
  CSE_CALL,
  CSE_BINARY,
  CSE_EACHCALL,
  MAX_SIZE_FOR_SOLVE_LINIEAR_SYSTEM,
  CPP_FLAGS,
  REMOVE_SIMPLE_EQUATIONS,
  DYNAMIC_TEARING,
  SYM_EULER,
  ADD_TIME_AS_STATE,
  LOOP2CON,
  FORCE_TEARING,
  SIMPLIFY_LOOPS,
  RTEARING,
  FLOW_THRESHOLD,
  MATRIX_FORMAT,
  PARTLINTORN,
  INIT_OPT_MODULES,
  MAX_MIXED_DETERMINED_INDEX,
  USE_LOCAL_DIRECTION,
  DEFAULT_OPT_MODULES_ORDERING,
  PRE_OPT_MODULES_ADD,
  PRE_OPT_MODULES_SUB,
  POST_OPT_MODULES_ADD,
  POST_OPT_MODULES_SUB,
  INIT_OPT_MODULES_ADD,
  INIT_OPT_MODULES_SUB,
  PERMISSIVE,
  HETS,
  DEFAULT_CLOCK_PERIOD,
  INST_CACHE_SIZE,
  MAX_SIZE_LINEAR_TEARING,
  MAX_SIZE_NONLINEAR_TEARING,
  NO_TEARING_FOR_COMPONENT,
  CT_STATE_MACHINES,
  DAE_MODE,
  INLINE_METHOD,
  SET_TEARING_VARS,
  SET_RESIDUAL_EQNS,
  IGNORE_COMMAND_LINE_OPTIONS_ANNOTATION,
  CALCULATE_SENSITIVITIES,
  ALARM,
  TOTAL_TEARING,
  IGNORE_SIMULATION_FLAGS_ANNOTATION
};

public function new
  "Create a new flags structure and read the given arguments."
  input list<String> inArgs;
  output list<String> outArgs;
algorithm
  _ := loadFlags();
  outArgs := readArgs(inArgs);
end new;

public function saveFlags
  "Saves the flags with setGlobalRoot."
  input Flags inFlags;
algorithm
  setGlobalRoot(Global.flagsIndex, inFlags);
end saveFlags;

protected function createConfigFlags
  output array<FlagData> outConfigFlags;
protected
  Integer count;
algorithm
  count := listLength(allConfigFlags);
  outConfigFlags := arrayCreate(count, EMPTY_FLAG());
  _ := List.fold1(allConfigFlags, setDefaultConfig, outConfigFlags, 1);
end createConfigFlags;

protected function createDebugFlags
  output array<Boolean> outDebugFlags;
algorithm
  outDebugFlags := listArray(List.map(allDebugFlags, defaultDebugFlag));
end createDebugFlags;

public function loadFlags
  "Loads the flags with getGlobalRoot. Creates a new flags structure if it
   hasn't been created yet."
  output Flags outFlags;
algorithm
  outFlags := matchcontinue()
    local
      array<Boolean> debug_flags;
      array<FlagData> config_flags;
      Flags flags;
      Integer debug_count, config_count;

    case ()
      equation
        outFlags = getGlobalRoot(Global.flagsIndex);
      then
        outFlags;

    else
      equation
        List.fold(allDebugFlags, checkDebugFlag, 1);
        debug_flags = createDebugFlags();
        config_flags = createConfigFlags();
        flags = FLAGS(debug_flags, config_flags);
        saveFlags(flags);
      then
        flags;

  end matchcontinue;
end loadFlags;

public function backupFlags
  "Creates a copy of the existing flags."
  output Flags outFlags;
protected
  array<Boolean> debug_flags;
  array<FlagData> config_flags;
algorithm
  FLAGS(debug_flags, config_flags) := loadFlags();
  outFlags := FLAGS(arrayCopy(debug_flags), arrayCopy(config_flags));
end backupFlags;

public function resetDebugFlags
  "Resets all debug flags to their default values."
protected
  array<Boolean> debug_flags;
  array<FlagData> config_flags;
algorithm
  FLAGS(_, config_flags) := loadFlags();
  debug_flags := createDebugFlags();
  saveFlags(FLAGS(debug_flags, config_flags));
end resetDebugFlags;

public function resetConfigFlags
  "Resets all configuration flags to their default values."
protected
  array<Boolean> debug_flags;
  array<FlagData> config_flags;
algorithm
  FLAGS(debug_flags, _) := loadFlags();
  config_flags := createConfigFlags();
  saveFlags(FLAGS(debug_flags, config_flags));
end resetConfigFlags;

protected function checkDebugFlag
  "Used when creating a new flags structure (in loadFlags) to check that a debug
   flag has a valid index."
  input DebugFlag inDebugFlag;
  input Integer inFlagIndex;
  output Integer outNextFlagIndex;
algorithm
  outNextFlagIndex := match(inDebugFlag, inFlagIndex)
    local
      Integer index;
      String name, index_str, err_str;

    case (DEBUG_FLAG(index = index), _) guard intEq(index, inFlagIndex)
      then inFlagIndex + 1;

    case (DEBUG_FLAG(index = index, name = name), _)
      equation
        index_str = intString(index);
        err_str = "Invalid flag " + name + " with index " + index_str +
          " in Flags.allDebugFlags. Make sure that all flags are present and ordered correctly.";
        Error.addSourceMessage(Error.INTERNAL_ERROR, {err_str}, sourceInfo());
      then fail();
  end match;
end checkDebugFlag;

protected function defaultDebugFlag
  "Used when creating a new flags structure (in loadFlags) to get the default values of debug flags"
  input DebugFlag inDebugFlag;
  output Boolean default;
algorithm
  DEBUG_FLAG(default = default) := inDebugFlag;
end defaultDebugFlag;

protected function setDefaultConfig
  "Used when creating a new flags structure (in loadFlags) to set the default
   value of a configuration flag, and also to check that it has a valid index."
  input ConfigFlag inConfigFlag;
  input array<FlagData> inConfigData;
  input Integer inFlagIndex;
  output Integer outFlagIndex;
algorithm
  outFlagIndex := matchcontinue(inConfigFlag, inConfigData, inFlagIndex)
    local
      Integer index;
      FlagData default_value;
      String name, index_str, err_str;

    case (CONFIG_FLAG(index = index, defaultValue = default_value), _, _)
      equation
        true = intEq(index, inFlagIndex);
        arrayUpdate(inConfigData, index, default_value);
      then
        inFlagIndex + 1;

    case (CONFIG_FLAG(index = index, name = name), _, _)
      equation
        index_str = intString(index);
        err_str = "Invalid flag " + name + " with index " + index_str +
          " in Flags.allConfigFlags. Make sure that all flags are present and ordered correctly.";
        Error.addSourceMessage(Error.INTERNAL_ERROR, {err_str}, sourceInfo());
      then
        fail();
  end matchcontinue;
end setDefaultConfig;

public function set
  "Sets the value of a debug flag, and returns the old value."
  input DebugFlag inFlag;
  input Boolean inValue;
  output Boolean outOldValue;
protected
  array<Boolean> debug_flags;
  array<FlagData> config_flags;
  Flags flags;
algorithm
  FLAGS(debug_flags, config_flags) := loadFlags();
  (debug_flags, outOldValue) := updateDebugFlagArray(debug_flags, inValue, inFlag);
  saveFlags(FLAGS(debug_flags, config_flags));
end set;

public function isSet
  "Checks if a debug flag is set."
  input DebugFlag inFlag;
  output Boolean outValue;
protected
  array<Boolean> debug_flags;
  Flags flags;
  Integer index;
algorithm
  DEBUG_FLAG(index = index) := inFlag;
  flags := loadFlags();
  FLAGS(debugFlags = debug_flags) := flags;
  outValue := arrayGet(debug_flags, index);
end isSet;

public function enableDebug
  "Enables a debug flag."
  input DebugFlag inFlag;
  output Boolean outOldValue;
algorithm
  outOldValue := set(inFlag, true);
end enableDebug;

public function disableDebug
  "Disables a debug flag."
  input DebugFlag inFlag;
  output Boolean outOldValue;
algorithm
  outOldValue := set(inFlag, false);
end disableDebug;

protected function updateDebugFlagArray
  "Updates the value of a debug flag in the debug flag array."
  input array<Boolean> inFlags;
  input Boolean inValue;
  input DebugFlag inFlag;
  output array<Boolean> outFlags;
  output Boolean outOldValue;
protected
  Integer index;
algorithm
  DEBUG_FLAG(index = index) := inFlag;
  outOldValue := arrayGet(inFlags, index);
  outFlags := arrayUpdate(inFlags, index, inValue);
end updateDebugFlagArray;

protected function updateConfigFlagArray
  "Updates the value of a configuration flag in the configuration flag array."
  input array<FlagData> inFlags;
  input FlagData inValue;
  input ConfigFlag inFlag;
  output array<FlagData> outFlags;
protected
  Integer index;
algorithm
  CONFIG_FLAG(index = index) := inFlag;
  outFlags := arrayUpdate(inFlags, index, inValue);
  applySideEffects(inFlag, inValue);
end updateConfigFlagArray;

public function readArgs
  "Reads the command line arguments to the compiler and sets the flags
  accordingly. Returns a list of arguments that were not consumed, such as the
  model filename."
  input list<String> inArgs;
  output list<String> outArgs = {};
protected
  Flags flags;
  Integer numError;
  String arg;
  list<String> rest_args = inArgs;
algorithm
  numError := Error.getNumErrorMessages();
  flags := loadFlags();

  while not listEmpty(rest_args) loop
    arg :: rest_args := rest_args;

    if arg == "--" then
      // Stop parsing arguments if -- is encountered.
      break;
    else
      if not readArg(arg, flags) then
        outArgs := arg :: outArgs;
      end if;
    end if;
  end while;

  outArgs := List.append_reverse(outArgs, rest_args);
  _ := List.map2(outArgs,System.iconv,"UTF-8","UTF-8");
  Error.assertionOrAddSourceMessage(numError == Error.getNumErrorMessages(), Error.UTF8_COMMAND_LINE_ARGS, {}, Util.dummyInfo);
  saveFlags(flags);
end readArgs;

protected function readArg
  "Reads a single command line argument. Returns true if the argument was not
  consumed, otherwise false."
  input String inArg;
  input Flags inFlags;
  output Boolean outConsumed;
protected
  String flagtype;
  Integer len, pos;
algorithm
  flagtype := stringGetStringChar(inArg, 1);
  len := stringLength(inArg);

  // Flags beginning with + can be both short and long, i.e. +h or +help.
  if flagtype == "+" then
    if len == 1 then
      // + alone is not a valid flag.
      parseFlag(inArg, NO_FLAGS());
    else
      parseFlag(System.substring(inArg, 2, len), inFlags, flagtype);
    end if;
    outConsumed := true;
  // Flags beginning with - must have another - for long flags, i.e. -h or --help.
  elseif flagtype == "-" then
    if len == 1 then
      // - alone is not a valid flag.
      parseFlag(inArg, NO_FLAGS());
    elseif len == 2 then
      // Short flag without argument, i.e. -h.
      parseFlag(System.substring(inArg, 2, 2), inFlags, flagtype);
    elseif stringGetStringChar(inArg, 2) == "-" then
      if len < 4 or stringGetStringChar(inArg, 4) == "=" then
        // Short flags may not be used with --, i.e. --h or --h=debug.
        parseFlag(inArg, NO_FLAGS());
      else
        // Long flag, i.e. --help or --help=debug.
        parseFlag(System.substring(inArg, 3, len), inFlags, "--");
      end if;
    else
      if stringGetStringChar(inArg, 3) == "=" then
        // Short flag with argument, i.e. -h=debug.
        parseFlag(System.substring(inArg, 2, len), inFlags, flagtype);
      else
        // Long flag used with -, i.e. -help, which is not allowed.
        parseFlag(inArg, NO_FLAGS());
      end if;
    end if;
    outConsumed := true;
  else
    // Arguments that don't begin with + or - are not flags, ignore them.
    outConsumed := false;
  end if;
end readArg;

protected function parseFlag
  "Parses a single flag."
  input String inFlag;
  input Flags inFlags;
  input String inFlagPrefix = "";
protected
  String flag;
  list<String> values;
algorithm
  flag :: values := System.strtok(inFlag, "=");
  values := List.flatten(List.map1(values, System.strtok, ","));
  parseConfigFlag(flag, values, inFlags, inFlagPrefix);
end parseFlag;

protected function parseConfigFlag
  "Tries to look up the flag with the given name, and set it to the given value."
  input String inFlag;
  input list<String> inValues;
  input Flags inFlags;
  input String inFlagPrefix;
protected
  ConfigFlag config_flag;
algorithm
  config_flag := lookupConfigFlag(inFlag, inFlagPrefix);
  evaluateConfigFlag(config_flag, inValues, inFlags);
end parseConfigFlag;

protected function lookupConfigFlag
  "Lookup up the flag with the given name in the list of configuration flags."
  input String inFlag;
  input String inFlagPrefix;
  output ConfigFlag outFlag;
algorithm
  try
    outFlag := List.getMemberOnTrue(inFlag, allConfigFlags, matchConfigFlag);
  else
    Error.addMessage(Error.UNKNOWN_OPTION, {inFlagPrefix + inFlag});
    fail();
  end try;
end lookupConfigFlag;

protected function configFlagEq
  input ConfigFlag inFlag1;
  input ConfigFlag inFlag2;
  output Boolean eq;
algorithm
  eq := match(inFlag1, inFlag2)
    local
      Integer index1, index2;
    case(CONFIG_FLAG(index=index1), CONFIG_FLAG(index=index2))
    then index1 == index2;
  end match;
end configFlagEq;

protected function setAdditionalOptModules
  input ConfigFlag inFlag;
  input ConfigFlag inOppositeFlag;
  input list<String> inValues;
protected
  list<String> values;
algorithm
  for value in inValues loop
    // remove value from inOppositeFlag
    values := getConfigStringList(inOppositeFlag);
    values := List.removeOnTrue(value, stringEq, values);
    setConfigStringList(inOppositeFlag, values);

    // add value to inFlag
    values := getConfigStringList(inFlag);
    values := List.removeOnTrue(value, stringEq, values);
    setConfigStringList(inFlag, value::values);
  end for;
end setAdditionalOptModules;

protected function evaluateConfigFlag
  "Evaluates a given flag and it's arguments."
  input ConfigFlag inFlag;
  input list<String> inValues;
  input Flags inFlags;
algorithm
  _ := match(inFlag, inFlags)
    local
      array<Boolean> debug_flags;
      array<FlagData> config_flags;
      list<String> values;

    // Special case for +d, +debug, set the given debug flags.
    case (CONFIG_FLAG(index = 1), FLAGS(debugFlags = debug_flags))
      equation
        List.map1_0(inValues, setDebugFlag, debug_flags);
      then
        ();

    // Special case for +h, +help, show help text.
    case (CONFIG_FLAG(index = 2), _)
      equation
        values = List.map(inValues, System.tolower);
        System.gettextInit(if getConfigString(RUNNING_TESTSUITE) == "" then getConfigString(LOCALE_FLAG) else "C");
        print(printHelp(values));
        setConfigString(HELP, "omc");
      then
        ();

    // Special case for --preOptModules+=<value>
    case (_, FLAGS(configFlags = config_flags)) guard(configFlagEq(inFlag, PRE_OPT_MODULES_ADD))
      equation
        setAdditionalOptModules(PRE_OPT_MODULES_ADD, PRE_OPT_MODULES_SUB, inValues);
      then
        ();

    // Special case for --preOptModules-=<value>
    case (_, FLAGS(configFlags = config_flags)) guard(configFlagEq(inFlag, PRE_OPT_MODULES_SUB))
      equation
        setAdditionalOptModules(PRE_OPT_MODULES_SUB, PRE_OPT_MODULES_ADD, inValues);
      then
        ();

    // Special case for --postOptModules+=<value>
    case (_, FLAGS(configFlags = config_flags)) guard(configFlagEq(inFlag, POST_OPT_MODULES_ADD))
      equation
        setAdditionalOptModules(POST_OPT_MODULES_ADD, POST_OPT_MODULES_SUB, inValues);
      then
        ();

    // Special case for --postOptModules-=<value>
    case (_, FLAGS(configFlags = config_flags)) guard(configFlagEq(inFlag, POST_OPT_MODULES_SUB))
      equation
        setAdditionalOptModules(POST_OPT_MODULES_SUB, POST_OPT_MODULES_ADD, inValues);
      then
        ();

    // Special case for --initOptModules+=<value>
    case (_, FLAGS(configFlags = config_flags)) guard(configFlagEq(inFlag, INIT_OPT_MODULES_ADD))
      equation
        setAdditionalOptModules(INIT_OPT_MODULES_ADD, INIT_OPT_MODULES_SUB, inValues);
      then
        ();

    // Special case for --initOptModules-=<value>
    case (_, FLAGS(configFlags = config_flags)) guard(configFlagEq(inFlag, INIT_OPT_MODULES_SUB))
      equation
        setAdditionalOptModules(INIT_OPT_MODULES_SUB, INIT_OPT_MODULES_ADD, inValues);
      then
        ();

    // All other configuration flags, set the flag to the given values.
    case (_, FLAGS(configFlags = config_flags))
      equation
        setConfigFlag(inFlag, config_flags, inValues);
      then
        ();

  end match;
end evaluateConfigFlag;

protected function setDebugFlag
  "Enables a debug flag given as a string, or disables it if it's prefixed with -."
  input String inFlag;
  input array<Boolean> inFlags;
protected
  Boolean negated,neg1,neg2;
  String flag_str;
algorithm
  neg1 := stringEq(stringGetStringChar(inFlag, 1), "-");
  neg2 := System.strncmp("no",inFlag,2) == 0;
  negated :=  neg1 or neg2;
  flag_str := if negated then Util.stringRest(inFlag) else inFlag;
  flag_str := if neg2 then Util.stringRest(flag_str) else flag_str;
  setDebugFlag2(flag_str, not negated, inFlags);
end setDebugFlag;

protected function setDebugFlag2
  input String inFlag;
  input Boolean inValue;
  input array<Boolean> inFlags;
algorithm
  _ := matchcontinue(inFlag, inValue, inFlags)
    local
      DebugFlag flag;

    case (_, _, _)
      equation
        flag = List.getMemberOnTrue(inFlag, allDebugFlags, matchDebugFlag);
        (_, _) = updateDebugFlagArray(inFlags, inValue, flag);
      then
        ();

    else
      equation
        Error.addMessage(Error.UNKNOWN_DEBUG_FLAG, {inFlag});
      then
        fail();

  end matchcontinue;
end setDebugFlag2;

protected function matchDebugFlag
  "Returns true if the given flag has the given name, otherwise false."
  input String inFlagName;
  input DebugFlag inFlag;
  output Boolean outMatches;
protected
  String name;
algorithm
  DEBUG_FLAG(name = name) := inFlag;
  outMatches := stringEq(inFlagName, name);
end matchDebugFlag;

protected function matchConfigFlag
  "Returns true if the given flag has the given name, otherwise false."
  input String inFlagName;
  input ConfigFlag inFlag;
  output Boolean outMatches;
protected
  Option<String> opt_shortname;
  String name, shortname;
algorithm
  // A configuration flag may have two names, one long and one short.
  CONFIG_FLAG(name = name, shortname = opt_shortname) := inFlag;
  shortname := Util.getOptionOrDefault(opt_shortname, "");
  outMatches := stringEq(inFlagName, shortname) or
                stringEq(System.tolower(inFlagName), System.tolower(name));
end matchConfigFlag;

protected function setConfigFlag
  "Sets the value of a configuration flag, where the value is given as a list of
  strings."
  input ConfigFlag inFlag;
  input array<FlagData> inConfigData;
  input list<String> inValues;
protected
  FlagData data, default_value;
  String name;
  Option<ValidOptions> validOptions;
algorithm
  CONFIG_FLAG(name = name, defaultValue = default_value, validOptions = validOptions) := inFlag;
  data := stringFlagData(inValues, default_value, validOptions, name);
  _ := updateConfigFlagArray(inConfigData, data, inFlag);
end setConfigFlag;

protected function stringFlagData
  "Converts a list of strings into a FlagData value. The expected type is also
   given so that the value can be typechecked."
  input list<String> inValues;
  input FlagData inExpectedType;
  input Option<ValidOptions> validOptions;
  input String inName;
  output FlagData outValue;
algorithm
  outValue := matchcontinue(inValues, inExpectedType, validOptions, inName)
    local
      Boolean b;
      Integer i;
      list<Integer> ilst;
      String s, et, at;
      list<tuple<String, Integer>> enums;
      list<String> flags, slst;
      ValidOptions options;

    // A boolean value.
    case ({s}, BOOL_FLAG(), _, _)
      equation
        b = Util.stringBool(s);
      then
        BOOL_FLAG(b);

    // No value, but a boolean flag => enable the flag.
    case ({}, BOOL_FLAG(), _, _) then BOOL_FLAG(true);

    // An integer value.
    case ({s}, INT_FLAG(), _, _)
      equation
        i = stringInt(s);
        true = stringEq(intString(i), s);
      then
        INT_FLAG(i);

    // integer list.
    case (slst, INT_LIST_FLAG(), _, _)
      equation
        ilst = List.map(slst,stringInt);
      then
        INT_LIST_FLAG(ilst);

    // A real value.
    case ({s}, REAL_FLAG(), _, _)
      then REAL_FLAG(System.stringReal(s));

    // A string value.
    case ({s}, STRING_FLAG(), SOME(options), _)
      equation
        flags = getValidStringOptions(options);
        true = listMember(s,flags);
      then STRING_FLAG(s);
    case ({s}, STRING_FLAG(), NONE(), _) then STRING_FLAG(s);

    // A multiple-string value.
    case (_, STRING_LIST_FLAG(), _, _) then STRING_LIST_FLAG(inValues);

    // An enumeration value.
    case ({s}, ENUM_FLAG(validValues = enums), _, _)
      equation
        i = Util.assoc(s, enums);
      then
        ENUM_FLAG(i, enums);

    // Type mismatch, print error.
    case (_, _, NONE(), _)
      equation
        et = printExpectedTypeStr(inExpectedType);
        at = printActualTypeStr(inValues);
        Error.addMessage(Error.INVALID_FLAG_TYPE, {inName, et, at});
      then
        fail();

    case (_, _, SOME(options), _)
      equation
        flags = getValidStringOptions(options);
        et = stringDelimitList(flags, ", ");
        at = printActualTypeStr(inValues);
        Error.addMessage(Error.INVALID_FLAG_TYPE_STRINGS, {inName, et, at});
      then
        fail();

  end matchcontinue;
end stringFlagData;

protected function printExpectedTypeStr
  "Prints the expected type as a string."
  input FlagData inType;
  output String outTypeStr;
algorithm
  outTypeStr := match(inType)
    local
      list<tuple<String, Integer>> enums;
      list<String> enum_strs;

    case BOOL_FLAG() then "a boolean value";
    case INT_FLAG() then "an integer value";
    case REAL_FLAG() then "a floating-point value";
    case STRING_FLAG() then "a string";
    case STRING_LIST_FLAG() then "a comma-separated list of strings";
    case ENUM_FLAG(validValues = enums)
      equation
        enum_strs = List.map(enums, Util.tuple21);
      then
        "one of the values {" + stringDelimitList(enum_strs, ", ") + "}";
  end match;
end printExpectedTypeStr;

protected function printActualTypeStr
  "Prints the actual type as a string."
  input list<String> inType;
  output String outTypeStr;
algorithm
  outTypeStr := matchcontinue(inType)
    local
      String s;
      Integer i;

    case {} then "nothing";
    case {s} equation Util.stringBool(s); then "the boolean value " + s;
    case {s}
      equation
        i = stringInt(s);
        // intString returns 0 on failure, so this is to make sure that it
        // actually succeeded.
        true = stringEq(intString(i), s);
      then
        "the number " + intString(i);
    //case {s}
    //  equation
    //    System.stringReal(s);
    //  then
    //    "the number " + intString(i);
    case {s} then "the string \"" + s + "\"";
    else "a list of values.";
  end matchcontinue;
end printActualTypeStr;

protected function configFlagsIsEqualIndex
  "Checks if two config flags have the same index."
  input ConfigFlag inFlag1;
  input ConfigFlag inFlag2;
  output Boolean outEqualIndex;
protected
  Integer index1, index2;
algorithm
  CONFIG_FLAG(index = index1) := inFlag1;
  CONFIG_FLAG(index = index2) := inFlag2;
  outEqualIndex := intEq(index1, index2);
end configFlagsIsEqualIndex;

protected function applySideEffects
  "Some flags have side effects, which are handled by this function."
  input ConfigFlag inFlag;
  input FlagData inValue;
algorithm
  _ := matchcontinue(inFlag, inValue)
    local
      Boolean value;
      String corba_name, corba_objid_path;

    // +showErrorMessages needs to be sent to the C runtime.
    case (_, _)
      equation
        true = configFlagsIsEqualIndex(inFlag, SHOW_ERROR_MESSAGES);
        BOOL_FLAG(data = value) = inValue;
        ErrorExt.setShowErrorMessages(value);
      then
        ();

    // The corba object reference file path needs to be sent to the C runtime.
    case (_, _)
      equation
        true = configFlagsIsEqualIndex(inFlag, CORBA_OBJECT_REFERENCE_FILE_PATH);
        STRING_FLAG(data = corba_objid_path) = inValue;
        Corba.setObjectReferenceFilePath(corba_objid_path);
      then
        ();

    // The corba session name needs to be sent to the C runtime.
    case (_, _)
      equation
        true = configFlagsIsEqualIndex(inFlag, CORBA_SESSION);
        STRING_FLAG(data = corba_name) = inValue;
        Corba.setSessionName(corba_name);
      then
        ();

    else ();
  end matchcontinue;
end applySideEffects;

public function setConfigValue
  "Sets the value of a configuration flag."
  input ConfigFlag inFlag;
  input FlagData inValue;
protected
  array<Boolean> debug_flags;
  array<FlagData> config_flags;
  Flags flags;
algorithm
  flags := loadFlags();
  FLAGS(debug_flags, config_flags) := flags;
  config_flags := updateConfigFlagArray(config_flags, inValue, inFlag);
  saveFlags(FLAGS(debug_flags, config_flags));
end setConfigValue;

public function setConfigBool
  "Sets the value of a boolean configuration flag."
  input ConfigFlag inFlag;
  input Boolean inValue;
algorithm
  setConfigValue(inFlag, BOOL_FLAG(inValue));
end setConfigBool;

public function setConfigInt
  "Sets the value of an integer configuration flag."
  input ConfigFlag inFlag;
  input Integer inValue;
algorithm
  setConfigValue(inFlag, INT_FLAG(inValue));
end setConfigInt;

public function setConfigReal
  "Sets the value of a real configuration flag."
  input ConfigFlag inFlag;
  input Real inValue;
algorithm
  setConfigValue(inFlag, REAL_FLAG(inValue));
end setConfigReal;

public function setConfigString
  "Sets the value of a string configuration flag."
  input ConfigFlag inFlag;
  input String inValue;
algorithm
  setConfigValue(inFlag, STRING_FLAG(inValue));
end setConfigString;

public function setConfigStringList
  "Sets the value of a multiple-string configuration flag."
  input ConfigFlag inFlag;
  input list<String> inValue;
algorithm
  setConfigValue(inFlag, STRING_LIST_FLAG(inValue));
end setConfigStringList;

public function setConfigEnum
  "Sets the value of an enumeration configuration flag."
  input ConfigFlag inFlag;
  input Integer inValue;
protected
  list<tuple<String, Integer>> valid_values;
algorithm
  CONFIG_FLAG(defaultValue = ENUM_FLAG(validValues = valid_values)) := inFlag;
  setConfigValue(inFlag, ENUM_FLAG(inValue, valid_values));
end setConfigEnum;

public function getConfigValue
  "Returns the value of a configuration flag."
  input ConfigFlag inFlag;
  output FlagData outValue;
protected
  array<FlagData> config_flags;
  Integer index;
  Flags flags;
  String name;
algorithm
  CONFIG_FLAG(name = name, index = index) := inFlag;
  flags := loadFlags();
  FLAGS(configFlags = config_flags) := flags;
  outValue := arrayGet(config_flags, index);
end getConfigValue;

public function getConfigBool
  "Returns the value of a boolean configuration flag."
  input ConfigFlag inFlag;
  output Boolean outValue;
algorithm
  BOOL_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigBool;

public function getConfigInt
  "Returns the value of an integer configuration flag."
  input ConfigFlag inFlag;
  output Integer outValue;
algorithm
  INT_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigInt;

public function getConfigIntList
  "Returns the value of an integer configuration flag."
  input ConfigFlag inFlag;
  output list<Integer> outValue;
algorithm
  INT_LIST_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigIntList;

public function getConfigReal
  "Returns the value of a real configuration flag."
  input ConfigFlag inFlag;
  output Real outValue;
algorithm
  REAL_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigReal;

public function getConfigString
  "Returns the value of a string configuration flag."
  input ConfigFlag inFlag;
  output String outValue;
algorithm
  STRING_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigString;

public function getConfigStringList
  "Returns the value of a multiple-string configuration flag."
  input ConfigFlag inFlag;
  output list<String> outValue;
algorithm
  STRING_LIST_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigStringList;

public function getConfigOptionsStringList
  "Returns the valid options of a single-string configuration flag."
  input ConfigFlag inFlag;
  output list<String> outOptions;
  output list<String> outComments;
algorithm
  (outOptions,outComments) := match inFlag
    local
      list<tuple<String, Util.TranslatableContent>> options;
      list<String> flags;
    case CONFIG_FLAG(validOptions=SOME(STRING_DESC_OPTION(options)))
      then (List.map(options,Util.tuple21),List.mapMap(options, Util.tuple22, Util.translateContent));
    case CONFIG_FLAG(validOptions=SOME(STRING_OPTION(flags)))
      then (flags,List.fill("",listLength(flags)));
  end match;
end getConfigOptionsStringList;

public function getConfigEnum
  "Returns the value of an enumeration configuration flag."
  input ConfigFlag inFlag;
  output Integer outValue;
algorithm
  ENUM_FLAG(data = outValue) := getConfigValue(inFlag);
end getConfigEnum;

// Used by the print functions below to indent descriptions.
protected constant String descriptionIndent = "                            ";

public function printHelp
  "Prints out help for the given list of topics."
  input list<String> inTopics;
  output String help;
algorithm
  help := matchcontinue (inTopics)
    local
      Util.TranslatableContent desc;
      list<String> rest_topics, strs, data;
      String str,name,str1,str1a,str1b,str2,str3,str3a,str3b,str4,str5,str5a,str5b,str6,str7,str7a,str7b,str8,str9,str9a,str9b,str10;
      ConfigFlag config_flag;
      list<tuple<String,String>> topics;

    case {} then printUsage();

    case {"omc"} then printUsage();

    case {"omcall-sphinxoutput"} then printUsageSphinxAll();

    //case {"mos"} then System.gettext("TODO: Write help-text");

    case {"topics"}
      equation
        topics = {
          //("mos",System.gettext("Help on the command-line and scripting environments, including OMShell and OMNotebook.")),
          ("omc",System.gettext("The command-line options available for omc.")),
          ("debug",System.gettext("Flags that enable debugging, diagnostics, and research prototypes.")),
          ("optmodules",System.gettext("Flags that determine which symbolic methods are used to produce the causalized equation system.")),
          ("simulation",System.gettext("The command-line options available for simulation executables generated by OpenModelica.")),
          ("<flagname>",System.gettext("Displays option descriptions for multi-option flag <flagname>.")),
          ("topics",System.gettext("This help-text."))
        };
        str = System.gettext("The available topics (help(\"topics\")) are as follows:\n");
        strs = List.map(topics,makeTopicString);
        help = str + stringDelimitList(strs,"\n") + "\n";
      then help;

    case {"simulation"}
      equation
        help = System.gettext("The simulation executable takes the following flags:\n\n") + System.getSimulationHelpText(true);
      then help;

    case {"simulation-sphinxoutput"}
      equation
        help = System.gettext("The simulation executable takes the following flags:\n\n") + System.getSimulationHelpText(true,sphinx=true);
      then help;

    case {"debug"}
      equation
        str1 = System.gettext("The debug flag takes a comma-separated list of flags which are used by the\ncompiler for debugging or experimental purposes.\nFlags prefixed with \"-\" or \"no\" will be disabled.\n");
        str2 = System.gettext("The available flags are (+ are enabled by default, - are disabled):\n\n");
        strs = list(printDebugFlag(flag) for flag in List.sort(allDebugFlags,compareDebugFlags));
        help = stringAppendList(str1 :: str2 :: strs);
      then help;

    case {"optmodules"}
      equation
        // pre-optimization
        str1 = System.gettext("The --preOptModules flag sets the optimization modules which are used before the\nmatching and index reduction in the back end. These modules are specified as a comma-separated list.");
        str1 = stringAppendList(StringUtil.wordWrap(str1,System.getTerminalWidth(),"\n"));
        CONFIG_FLAG(defaultValue=STRING_LIST_FLAG(data=data)) = PRE_OPT_MODULES;
        str1a = System.gettext("The modules used by default are:") + "\n--preOptModules=" + stringDelimitList(data, ",");
        str1b = System.gettext("The valid modules are:");
        str2 = printFlagValidOptionsDesc(PRE_OPT_MODULES);

        // matching
        str3 = System.gettext("The --matchingAlgorithm sets the method that is used for the matching algorithm, after the pre optimization modules.");
        str3 = stringAppendList(StringUtil.wordWrap(str3,System.getTerminalWidth(),"\n"));
        CONFIG_FLAG(defaultValue=STRING_FLAG(data=str3a)) = MATCHING_ALGORITHM;
        str3a = System.gettext("The method used by default is:") + "\n--matchingAlgorithm=" + str3a;
        str3b = System.gettext("The valid methods are:");
        str4 = printFlagValidOptionsDesc(MATCHING_ALGORITHM);

        // index reduction
        str5 = System.gettext("The --indexReductionMethod sets the method that is used for the index reduction, after the pre optimization modules.");
        str5 = stringAppendList(StringUtil.wordWrap(str5,System.getTerminalWidth(),"\n"));
        CONFIG_FLAG(defaultValue=STRING_FLAG(data=str5a)) = INDEX_REDUCTION_METHOD;
        str5a = System.gettext("The method used by default is:") + "\n--indexReductionMethod=" + str5a;
        str5b = System.gettext("The valid methods are:");
        str6 = printFlagValidOptionsDesc(INDEX_REDUCTION_METHOD);

        // post-optimization (initialization)
        str7 = System.gettext("The --initOptModules then sets the optimization modules which are used after the index reduction to optimize the system for initialization, specified as a comma-separated list.");
        str7 = stringAppendList(StringUtil.wordWrap(str7,System.getTerminalWidth(),"\n"));
        CONFIG_FLAG(defaultValue=STRING_LIST_FLAG(data=data)) = INIT_OPT_MODULES;
        str7a = System.gettext("The modules used by default are:") + "\n--initOptModules=" + stringDelimitList(data, ",");
        str7b = System.gettext("The valid modules are:");
        str8 = printFlagValidOptionsDesc(INIT_OPT_MODULES);

        // post-optimization (simulation)
        str9 = System.gettext("The --postOptModules then sets the optimization modules which are used after the index reduction to optimize the system for simulation, specified as a comma-separated list.");
        str9 = stringAppendList(StringUtil.wordWrap(str9,System.getTerminalWidth(),"\n"));
        CONFIG_FLAG(defaultValue=STRING_LIST_FLAG(data=data)) = POST_OPT_MODULES;
        str9a = System.gettext("The modules used by default are:") + "\n--postOptModules=" + stringDelimitList(data, ",");
        str9b = System.gettext("The valid modules are:");
        str10 = printFlagValidOptionsDesc(POST_OPT_MODULES);

        help = stringAppendList({str1,"\n\n",str1a,"\n\n",str1b,"\n",str2,"\n",str3,"\n\n",str3a,"\n\n",str3b,"\n",str4,"\n",str5,"\n\n",str5a,"\n\n",str5b,"\n",str6,"\n",str7,"\n\n",str7a,"\n\n",str7b,"\n",str8,"\n",str9,"\n\n",str9a,"\n\n",str9b,"\n",str10,"\n"});
      then help;

    case {str}
      equation
        (config_flag as CONFIG_FLAG(name=name,description=desc)) = List.getMemberOnTrue(str, allConfigFlags, matchConfigFlag);
        str1 = "-" + name;
        str2 = stringAppendList(StringUtil.wordWrap(Util.translateContent(desc), System.getTerminalWidth(), "\n"));
        str = printFlagValidOptionsDesc(config_flag);
        help = stringAppendList({str1,"\n",str2,"\n",str});
      then help;

    case {str}
      then "I'm sorry, I don't know what " + str + " is.\n";

    case (str :: (rest_topics as _::_))
      equation
        str = printHelp({str}) + "\n";
        help = printHelp(rest_topics);
      then str + help;

  end matchcontinue;
end printHelp;

public function getValidOptionsAndDescription
  input String flagName;
  output list<String> validStrings;
  output String mainDescriptionStr;
  output list<String> descriptions;
protected
  ValidOptions validOptions;
  Util.TranslatableContent mainDescription;
algorithm
  CONFIG_FLAG(description=mainDescription,validOptions=SOME(validOptions)) := List.getMemberOnTrue(flagName, allConfigFlags, matchConfigFlag);
  mainDescriptionStr := Util.translateContent(mainDescription);
  (validStrings,descriptions) := getValidOptionsAndDescription2(validOptions);
end getValidOptionsAndDescription;

protected function getValidOptionsAndDescription2
  input ValidOptions validOptions;
  output list<String> validStrings;
  output list<String> descriptions;
algorithm
  (validStrings,descriptions) := match validOptions
    local
      list<tuple<String,Util.TranslatableContent>> options;
    case STRING_OPTION(validStrings) then (validStrings,{});
    case STRING_DESC_OPTION(options)
      equation
        validStrings = List.map(options,Util.tuple21);
        descriptions = List.mapMap(options,Util.tuple22,Util.translateContent);
      then (validStrings,descriptions);
  end match;
end getValidOptionsAndDescription2;

protected function compareDebugFlags
  input DebugFlag flag1;
  input DebugFlag flag2;
  output Boolean b;
protected
  String name1,name2;
algorithm
  DEBUG_FLAG(name=name1) := flag1;
  DEBUG_FLAG(name=name2) := flag2;
  b := stringCompare(name1,name2) > 0;
end compareDebugFlags;

protected function makeTopicString
  input tuple<String,String> topic;
  output String str;
protected
  String str1,str2;
algorithm
  (str1,str2) := topic;
  str1 := Util.stringPadRight(str1,13," ");
  str := stringAppendList(StringUtil.wordWrap(str1 + str2, System.getTerminalWidth(), "\n               "));
end makeTopicString;

public function printUsage
  "Prints out the usage text for the compiler."
  output String usage;
algorithm
  Print.clearBuf();
  Print.printBuf("OpenModelica Compiler "); Print.printBuf(Settings.getVersionNr()); Print.printBuf("\n");
  Print.printBuf(System.gettext("Copyright © 2015 Open Source Modelica Consortium (OSMC)\n"));
  Print.printBuf(System.gettext("Distributed under OMSC-PL and GPL, see www.openmodelica.org\n\n"));
  //Print.printBuf("Please check the System Guide for full information about flags.\n");
  Print.printBuf(System.gettext("Usage: omc [Options] (Model.mo | Script.mos) [Libraries | .mo-files] \n* Libraries: Fully qualified names of libraries to load before processing Model or Script.\n             The libraries should be separated by spaces: Lib1 Lib2 ... LibN.\n"));
  Print.printBuf(System.gettext("\n* Options:\n"));
  Print.printBuf(printAllConfigFlags());
  Print.printBuf(System.gettext("\nFor more details on a specific topic, use --help=topics or help(\"topics\")\n\n"));
  Print.printBuf(System.gettext("* Examples:\n"));
  Print.printBuf(System.gettext("  omc Model.mo             will produce flattened Model on standard output.\n"));
  Print.printBuf(System.gettext("  omc -s Model.mo          will produce simulation code for the model:\n"));
  Print.printBuf(System.gettext("                            * Model.c           The model C code.\n"));
  Print.printBuf(System.gettext("                            * Model_functions.c The model functions C code.\n"));
  Print.printBuf(System.gettext("                            * Model.makefile    The makefile to compile the model.\n"));
  Print.printBuf(System.gettext("                            * Model_init.xml    The initial values.\n"));
  //Print.printBuf("\tomc Model.mof            will produce flattened Model on standard output\n");
  Print.printBuf(System.gettext("  omc Script.mos           will run the commands from Script.mos.\n"));
  Print.printBuf(System.gettext("  omc Model.mo Modelica    will first load the Modelica library and then produce \n                            flattened Model on standard output.\n"));
  Print.printBuf(System.gettext("  omc Model1.mo Model2.mo  will load both Model1.mo and Model2.mo, and produce \n                            flattened Model1 on standard output.\n"));
  Print.printBuf(System.gettext("  *.mo (Modelica files) \n"));
  //Print.printBuf("\t*.mof (Flat Modelica files) \n");
  Print.printBuf(System.gettext("  *.mos (Modelica Script files)\n\n"));
  Print.printBuf(System.gettext("For available simulation flags, use --help=simulation.\n\n"));
  Print.printBuf(System.gettext("Documentation is available in the built-in package OpenModelica.Scripting or\nonline <https://build.openmodelica.org/Documentation/OpenModelica.Scripting.html>.\n"));
  usage := Print.getString();
  Print.clearBuf();
end printUsage;

public function printUsageSphinxAll
  "Prints out the usage text for the compiler."
  output String usage;
protected
  String s;
algorithm
  Print.clearBuf();
  s := "OpenModelica Compiler Flags";
  Print.printBuf(s);
  Print.printBuf("\n");
  Print.printBuf(sum("=" for e in 1:stringLength(s)));
  Print.printBuf("\n");
  Print.printBuf(System.gettext("Usage: omc [Options] (Model.mo | Script.mos) [Libraries | .mo-files]\n\n* Libraries: Fully qualified names of libraries to load before processing Model or Script.\n  The libraries should be separated by spaces: Lib1 Lib2 ... LibN.\n"));
  Print.printBuf("\n.. _omcflags-options :\n\n");
  s := System.gettext("Options");
  Print.printBuf(s);
  Print.printBuf("\n");
  Print.printBuf(sum("-" for e in 1:stringLength(s)));
  Print.printBuf("\n\n");
  for flag in allConfigFlags loop
    Print.printBuf(printConfigFlagSphinx(flag));
  end for;

  Print.printBuf("\n.. _omcflag-debug-section:\n\n");
  s := System.gettext("Debug flags");
  Print.printBuf(s);
  Print.printBuf("\n");
  Print.printBuf(sum("-" for e in 1:stringLength(s)));
  Print.printBuf("\n\n");
  Print.printBuf(System.gettext("The debug flag takes a comma-separated list of flags which are used by the\ncompiler for debugging or experimental purposes.\nFlags prefixed with \"-\" or \"no\" will be disabled.\n"));
  Print.printBuf(System.gettext("The available flags are (+ are enabled by default, - are disabled):\n\n"));
  for flag in List.sort(allDebugFlags,compareDebugFlags) loop
    Print.printBuf(printDebugFlag(flag, sphinx=true));
  end for;

  Print.printBuf("\n.. _omcflag-optmodules-section:\n\n");
  s := System.gettext("Flags for Optimization Modules");
  Print.printBuf(s);
  Print.printBuf("\n");
  Print.printBuf(sum("-" for e in 1:stringLength(s)));
  Print.printBuf("\n\n");

  Print.printBuf("Flags that determine which symbolic methods are used to produce the causalized equation system.\n\n");

  Print.printBuf(System.gettext("The :ref:`--preOptModules <omcflag-preOptModules>` flag sets the optimization modules which are used before the\nmatching and index reduction in the back end. These modules are specified as a comma-separated list."));
  Print.printBuf("\n\n");
  Print.printBuf(System.gettext("The :ref:`--matchingAlgorithm <omcflag-matchingAlgorithm>` sets the method that is used for the matching algorithm, after the pre optimization modules."));
  Print.printBuf("\n\n");
  Print.printBuf(System.gettext("The :ref:`--indexReductionMethod <omcflag-indexReductionMethod>` sets the method that is used for the index reduction, after the pre optimization modules."));
  Print.printBuf("\n\n");
  Print.printBuf(System.gettext("The :ref:`--initOptModules <omcflag-initOptModules>` then sets the optimization modules which are used after the index reduction to optimize the system for initialization, specified as a comma-separated list."));
  Print.printBuf("\n\n");
  Print.printBuf(System.gettext("The :ref:`--postOptModules <omcflag-postOptModules>` then sets the optimization modules which are used after the index reduction to optimize the system for simulation, specified as a comma-separated list."));
  Print.printBuf("\n\n");

  usage := Print.getString();
  Print.clearBuf();
end printUsageSphinxAll;

public function printAllConfigFlags
  "Prints all configuration flags to a string."
  output String outString;
algorithm
  outString := stringAppendList(List.map(allConfigFlags, printConfigFlag));
end printAllConfigFlags;

protected function printConfigFlag
  "Prints a configuration flag to a string."
  input ConfigFlag inFlag;
  output String outString;
algorithm
  outString := match(inFlag)
    local
      Util.TranslatableContent desc;
      String name, desc_str, flag_str, delim_str, opt_str;
      list<String> wrapped_str;

    case CONFIG_FLAG(visibility = INTERNAL()) then "";

    case CONFIG_FLAG(description = desc)
      equation
        desc_str = Util.translateContent(desc);
        name = Util.stringPadRight(printConfigFlagName(inFlag), 28, " ");
        flag_str = stringAppendList({name, " ", desc_str});
        delim_str = descriptionIndent + "  ";
        wrapped_str = StringUtil.wordWrap(flag_str, System.getTerminalWidth(), delim_str);
        opt_str = printValidOptions(inFlag);
        flag_str = stringDelimitList(wrapped_str, "\n") + opt_str + "\n";
      then
        flag_str;

  end match;
end printConfigFlag;

protected function printConfigFlagSphinx
  "Prints a configuration flag to a restructured text string."
  input ConfigFlag inFlag;
  output String outString;
algorithm
  outString := match(inFlag)
    local
      Util.TranslatableContent desc;
      String name, longName, desc_str, flag_str, delim_str, opt_str;
      list<String> wrapped_str;

    case CONFIG_FLAG(visibility = INTERNAL()) then "";

    case CONFIG_FLAG(description = desc)
      equation
        desc_str = Util.translateContent(desc);
        desc_str = System.stringReplace(desc_str, "--help=debug", ":ref:`--help=debug <omcflag-debug-section>`");
        desc_str = System.stringReplace(desc_str, "--help=optmodules", ":ref:`--help=optmodules <omcflag-optmodules-section>`");
        (name,longName) = printConfigFlagName(inFlag,sphinx=true);
        opt_str = printValidOptionsSphinx(inFlag);
        flag_str = stringAppendList({".. _omcflag-", longName, ":\n\n:ref:`", name, "<omcflag-",longName,">`\n\n", desc_str, "\n", opt_str + "\n"});
      then flag_str;

  end match;
end printConfigFlagSphinx;

protected function printConfigFlagName
  "Prints out the name of a configuration flag, formatted for use by
   printConfigFlag."
  input ConfigFlag inFlag;
  input Boolean sphinx=false;
  output String outString;
  output String longName;
algorithm
  (outString,longName) := match(inFlag)
    local
      String name, shortname;

    case CONFIG_FLAG(name = name, shortname = SOME(shortname))
      equation
        shortname = if sphinx then "-" + shortname else Util.stringPadLeft("-" + shortname, 4, " ");
      then (stringAppendList({shortname, ", --", name}), name);

    case CONFIG_FLAG(name = name, shortname = NONE())
      then ((if sphinx then "--" else "      --") + name, name);

  end match;
end printConfigFlagName;

protected function printValidOptions
  "Prints out the valid options of a configuration flag to a string."
  input ConfigFlag inFlag;
  output String outString;
algorithm
  outString := match(inFlag)
    local
      list<String> strl;
      String opt_str;
      list<tuple<String, Util.TranslatableContent>> descl;

    case CONFIG_FLAG(validOptions = NONE()) then "";
    case CONFIG_FLAG(validOptions = SOME(STRING_OPTION(options = strl)))
      equation
        opt_str = descriptionIndent + "   " + System.gettext("Valid options:") + " " +
          stringDelimitList(strl, ", ");
        strl = StringUtil.wordWrap(opt_str, System.getTerminalWidth(), descriptionIndent + "     ");
        opt_str = stringDelimitList(strl, "\n");
        opt_str = "\n" + opt_str;
      then
        opt_str;
    case CONFIG_FLAG(validOptions = SOME(STRING_DESC_OPTION(options = descl)))
      equation
        opt_str = "\n" + descriptionIndent + "   " + System.gettext("Valid options:") + "\n" +
          stringAppendList(list(printFlagOptionDescShort(d) for d in descl));
      then
        opt_str;
  end match;
end printValidOptions;

protected function printValidOptionsSphinx
  "Prints out the valid options of a configuration flag to a string."
  input ConfigFlag inFlag;
  output String outString;
algorithm
  outString := match(inFlag)
    local
      list<String> strl;
      String opt_str;
      list<tuple<String, Util.TranslatableContent>> descl;

    case CONFIG_FLAG(validOptions = NONE()) then "\n" + defaultFlagSphinx(inFlag.defaultValue) + "\n";
    case CONFIG_FLAG(validOptions = SOME(STRING_OPTION(options = strl)))
      equation
        opt_str = "\n" + defaultFlagSphinx(inFlag.defaultValue) + " " + System.gettext("Valid options") + ":\n\n" +
          sum("* " + s + "\n" for s in strl);
      then opt_str;
    case CONFIG_FLAG(validOptions = SOME(STRING_DESC_OPTION(options = descl)))
      equation
        opt_str = "\n" + defaultFlagSphinx(inFlag.defaultValue) + " " + System.gettext("Valid options") + ":\n\n" +
          sum(printFlagOptionDesc(s, sphinx=true) for s in descl);
      then
        opt_str;
  end match;
end printValidOptionsSphinx;

protected function defaultFlagSphinx
  input FlagData flag;
  output String str;
algorithm
  str := match flag
    local
      Integer i;
    case BOOL_FLAG() then System.gettext("Boolean (default")+" ``" + boolString(flag.data) + "``).";
    case INT_FLAG() then System.gettext("Integer (default")+" ``" + intString(flag.data) + "``).";
    case REAL_FLAG() then System.gettext("Real (default")+" ``" + realString(flag.data) + "``).";
    case STRING_FLAG("") then System.gettext("String (default *empty*).");
    case STRING_FLAG() then System.gettext("String (default")+" " + flag.data + ").";
    case STRING_LIST_FLAG(data={}) then System.gettext("String list (default *empty*).");
    case STRING_LIST_FLAG() then System.gettext("String list (default")+" " + stringDelimitList(flag.data, ",") + ").";
    case ENUM_FLAG()
      algorithm
        for f in flag.validValues loop
          (str,i) := f;
          if i==flag.data then
            str := System.gettext("String (default ")+" " + str + ").";
            return;
          end if;
        end for;
      then "#ENUM_FLAG Failed#" + anyString(flag);
    else "Unknown default value" + anyString(flag);
  end match;
end defaultFlagSphinx;

protected function printFlagOptionDescShort
  "Prints out the name of a flag option."
  input tuple<String, Util.TranslatableContent> inOption;
  input Boolean sphinx=false;
  output String outString;
protected
  String name;
algorithm
  (name, _) := inOption;
  outString := (if sphinx then "* " else descriptionIndent + "    * ") + name + "\n";
end printFlagOptionDescShort;

protected function printFlagValidOptionsDesc
  "Prints out the names and descriptions of the valid options for a
   configuration flag."
  input ConfigFlag inFlag;
  output String outString;
protected
  list<tuple<String, Util.TranslatableContent>> options;
algorithm
  CONFIG_FLAG(validOptions = SOME(STRING_DESC_OPTION(options = options))) := inFlag;
  outString := sum(printFlagOptionDesc(o) for o in options);
end printFlagValidOptionsDesc;

protected function sphinxMathMode
  input String s;
  output String o = s;
protected
  Integer i;
  list<String> strs;
  String s1,s2,s3;
algorithm
  (i,strs) := System.regex(o, "^(.*)[$]([^$]*)[$](.*)$", 4, extended=true);
  if i==4 then
    _::s1::s2::s3::_ := strs;
    o := s1 + " :math:`" + s2 + "` " + s3;
  end if;
end sphinxMathMode;

protected function removeSphinxMathMode
  input String s;
  output String o = s;
protected
  Integer i;
  list<String> strs;
  String s1,s2,s3;
algorithm
  (i,strs) := System.regex(o, "^(.*):math:`([^`]*)[`](.*)$", 4, extended=true);
  if i==4 then
    o := removeSphinxMathMode(stringAppendList(listRest(strs)));
  end if;
end removeSphinxMathMode;

protected function printFlagOptionDesc
  "Helper function to printFlagValidOptionsDesc."
  input tuple<String, Util.TranslatableContent> inOption;
  input Boolean sphinx=false;
  output String outString;
protected
  Util.TranslatableContent desc;
  String name, desc_str, str;
algorithm
  (name, desc) := inOption;
  desc_str := Util.translateContent(desc);
  if sphinx then
    desc_str := sum(System.trim(s) for s in System.strtok(desc_str, "\n"));
    outString := "* " + name + " (" + desc_str + ")\n";
  else
    str := Util.stringPadRight(" * " + name + " ", 30, " ") + removeSphinxMathMode(desc_str);
    outString := stringDelimitList(
      StringUtil.wordWrap(str, System.getTerminalWidth(), descriptionIndent + "    "), "\n") + "\n";
  end if;
end printFlagOptionDesc;

protected function printDebugFlag
  "Prints out name and description of a debug flag."
  input DebugFlag inFlag;
  input Boolean sphinx=false;
  output String outString;
protected
  Util.TranslatableContent desc;
  String name, desc_str;
  Boolean default;
algorithm
  DEBUG_FLAG(default = default, name = name, description = desc) := inFlag;
  desc_str := Util.translateContent(desc);
  if sphinx then
    desc_str := stringDelimitList(list(System.trim(s) for s in System.strtok(desc_str, "\n")), "\n  ");
    outString := "\n.. _omcflag-debug-"+name+":\n\n" +
      ":ref:`" + name + " <omcflag-debug-"+name+">`" +
      " (default: "+(if default then "on" else "off")+")\n  " + desc_str + "\n";
  else
    outString := Util.stringPadRight((if default then " + " else " - ") + name + " ", 26, " ") + removeSphinxMathMode(desc_str);
    outString := stringDelimitList(StringUtil.wordWrap(outString, System.getTerminalWidth(),
      descriptionIndent), "\n") + "\n";
  end if;
end printDebugFlag;

public function debugFlagName
  "Prints out name of a debug flag."
  input DebugFlag inFlag;
  output String name;
algorithm
  DEBUG_FLAG(name = name) := inFlag;
end debugFlagName;

public function configFlagName
  "Prints out name of a debug flag."
  input ConfigFlag inFlag;
  output String name;
algorithm
  CONFIG_FLAG(name = name) := inFlag;
end configFlagName;

protected function getValidStringOptions
  input ValidOptions inOptions;
  output list<String> validOptions;
algorithm
  validOptions := match inOptions
    local
      list<tuple<String, Util.TranslatableContent>> options;
    case STRING_OPTION(validOptions) then validOptions;
    case STRING_DESC_OPTION(options) then List.map(options,Util.tuple21);
  end match;
end getValidStringOptions;

annotation(__OpenModelica_Interface="util");
end Flags;
