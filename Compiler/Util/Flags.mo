/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package Flags
" file:        Flags.mo
  package:     Flags
  description: Tools for using compiler flags.

  RCS: $Id$

  This package contains function for using compiler flags. There are two types
  of flags, debug flag and configuration flags. The flags are stored and
  retrieved with set/getGlobalRoot so that they can be accessed everywhere in
  the compiler.

  Configuration flags are flags such as +std which affects the behaviour of the
  compiler. These flags can have different types, see the FlagData uniontype
  below, and they also have a default value. There is also another package,
  Config, which acts as a wrapper for many of these flags.

  Debug flags are boolean flags specified with +d, which can be used together
  with the Debug package. They are typically used to enable printing of extra
  information that helps debugging, such as the failtrace flag. Unlike
  configuration flags they are only on or off, i.e. true or false.

  To add a new flag, simply add a new constant of either DebugFlag or ConfigFlag
  type below, and then add it to either the allDebugFlags or allConfigFlags list
  depending on which type it is.
  "

protected import Corba;
protected import Debug;
protected import Error;
protected import ErrorExt;
protected import Global;
protected import List;
protected import Print;
protected import Settings;
protected import System;
public import Absyn;
public import Util;

public uniontype DebugFlag
  record DEBUG_FLAG
    Integer index "Unique index.";
    String name "The name of the flag used by +d";
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

// DEBUG FLAGS
public
constant DebugFlag FAILTRACE = DEBUG_FLAG(1, "failtrace", false,
  Util.gettext("Sets whether to print a failtrace or not."));
constant DebugFlag CEVAL = DEBUG_FLAG(2, "ceval", false,
  Util.gettext("Prints extra information from Ceval."));
constant DebugFlag CHECK_BACKEND_DAE = DEBUG_FLAG(3, "checkBackendDae", false,
  Util.gettext("Do some simple analyses on the datastructure from the frontend to check if it is consistent."));
constant DebugFlag OPENMP = DEBUG_FLAG(4, "openmp", false,
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
constant DebugFlag USEDEP = DEBUG_FLAG(14, "usedep", false,
  Util.gettext("Turns on/off dependency analysis for getTotalProgram."));
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
constant DebugFlag PATTERNM_DCE = DEBUG_FLAG(24, "patternmDeadCodeEliminiation", true,
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
constant DebugFlag DUMP_ENCAPSULATEWHENCONDITIONS = DEBUG_FLAG(59, "dumpEncapsulateWhenConditions", false,
  Util.gettext("Dumps the results of the preOptModule encapsulateWhenConditions."));
constant DebugFlag ON_RELAXATION = DEBUG_FLAG(60, "onRelaxation", false,
  Util.gettext("Perform O(n) relaxation."));
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
constant DebugFlag SCODE_INST = DEBUG_FLAG(68, "scodeInst", false,
  Util.gettext("Enables experimental SCode instantiation phase."));
constant DebugFlag WRITE_TO_BUFFER = DEBUG_FLAG(69, "writeToBuffer", false,
  Util.gettext("Enables writing simulation results to buffer."));
constant DebugFlag DUMP_BACKENDDAE_INFO = DEBUG_FLAG(70, "backenddaeinfo", false,
  Util.gettext("Enables dumping of back-end information about system (Number of equations before back-end,...)."));
constant DebugFlag GEN_DEBUG_SYMBOLS = DEBUG_FLAG(71, "gendebugsymbols", false,
  Util.gettext("Generate code with debugging symbols."));
constant DebugFlag DUMP_STATESELECTION_INFO = DEBUG_FLAG(72, "stateselection", false,
  Util.gettext("Enables dumping of selected states. Extends +d=backenddaeinfo."));
constant DebugFlag DUMP_EQNINORDER = DEBUG_FLAG(73, "dumpeqninorder", false,
  Util.gettext("Enables dumping of the equations in the order they are calculated."));
constant DebugFlag SYMBOLIC_INITIALIZATION = DEBUG_FLAG(74, "symbolicInitialization", false,
  Util.gettext("Enables using of symbolic matrices for initialization (ipopt only)."));
constant DebugFlag DUMPOPTINIT = DEBUG_FLAG(75, "dumpoptinit", false,
  Util.gettext("Enables dumping of the optimization information when optimizing the initial system."));
constant DebugFlag SEMILINEAR = DEBUG_FLAG(76, "semiLinear", false,
  Util.gettext("Enables dumping of the optimization information when optimizing calls to semiLinear."));
constant DebugFlag UNCERTAINTIES = DEBUG_FLAG(77, "uncertainties", false,
  Util.gettext("Enables dumping of status when calling modelEquationsUC."));
constant DebugFlag DUMP_DAE= DEBUG_FLAG(78, "daeunparser", false,
  Util.gettext("Enables dumping of the DAE."));
constant DebugFlag SHOW_START_ORIGIN = DEBUG_FLAG(79, "showStartOrigin", false,
  Util.gettext("Enables dumping of the DAE startOrigin attribute of the variables."));
// The flags mixedTearing are only needed as long tearing of mixed system in not default.
constant DebugFlag MIXED_TEARING = DEBUG_FLAG(80, "MixedTearing", true,
  Util.gettext("Disables tearing of mixed system."));
constant DebugFlag LINEAR_TEARING = DEBUG_FLAG(81, "doLinearTearing", false,
  Util.gettext("Enables tearing of linear systems, but for now they aren't handled efficent in the runtime."));
constant DebugFlag DUMP_INITIAL_SYSTEM = DEBUG_FLAG(82, "dumpinitialsystem", false,
  Util.gettext("Dumps the initial equation system."));
constant DebugFlag GRAPH_INST = DEBUG_FLAG(83, "graphInst", false,
  Util.gettext("Do graph based instantation."));
constant DebugFlag GRAPH_INST_RUN_DEP = DEBUG_FLAG(84, "graphInstRunDep", false,
  Util.gettext("Run scode dependency analysis. Use with +d=graphInst"));
constant DebugFlag GRAPH_INST_GEN_GRAPH = DEBUG_FLAG(85, "graphInstGenGraph", false,
  Util.gettext("Dumps a graph of the program. Use with +d=graphInst"));
constant DebugFlag DUMP_CONST_REPL = DEBUG_FLAG(86, "dumpConstrepl", false,
  Util.gettext("Dump the found replacements for constants."));
constant DebugFlag PEDANTIC = DEBUG_FLAG(87, "pedantic", false,
  Util.gettext("Switch into pedantic debug-mode, to get much more feedback."));
constant DebugFlag SHOW_EQUATION_SOURCE = DEBUG_FLAG(88, "showEquationSource", false,
  Util.gettext("Display the element source information in the dumped DAE for easier debugging."));
constant DebugFlag NLS_ANALYTIC_JACOBIAN = DEBUG_FLAG(89, "NLSanalyticJacobian", false,
  Util.gettext("Generates analytical Jacobian for non-linear algebraic loops."));
constant DebugFlag INLINE_SOLVER = DEBUG_FLAG(90, "inlineSolver", false,
  Util.gettext("Generates code for inline solver."));
constant DebugFlag HPCOM = DEBUG_FLAG(91, "hpcom", false,
  Util.gettext("Enables parallel calculation based on task-graphs."));
constant DebugFlag INITIALIZATION = DEBUG_FLAG(92, "initialization", false,
  Util.gettext("Shows additional information from the initialization process."));
constant DebugFlag INLINE_FUNCTIONS = DEBUG_FLAG(93, "inlineFunctions", true,
  Util.gettext("Controls if function inlining should be performed."));
constant DebugFlag DUMP_SCC_GRAPHML = DEBUG_FLAG(94, "dumpSCCGraphML", false,
  Util.gettext("Dumps graphml files with the strongly connected components."));
constant DebugFlag TEARING_DUMPVERBOSE = DEBUG_FLAG(95, "tearingdumpV", false,
  Util.gettext("Dumps verbose tearing information."));
constant DebugFlag DISABLE_SINGLE_FLOW_EQ = DEBUG_FLAG(96, "disableSingleFlowEq", false,
  Util.gettext("Disables the generation of single flow equations."));
constant DebugFlag PARTLINTORNSYSTEM = DEBUG_FLAG(97, "partlintornsystem", false,
  Util.gettext("Disassembles linear torn systems to various singleEquations and a reduced tornSystem."));
constant DebugFlag DUMP_DISCRETEVARS_INFO = DEBUG_FLAG(98, "discreteinfo", false,
  Util.gettext("Enables dumping of discrete variables. Extends +d=backenddaeinfo."));
constant DebugFlag ADDITIONAL_GRAPHVIZ_DUMP = DEBUG_FLAG(99, "graphvizDump", false,
  Util.gettext("Activates additional graphviz dumps (as *.dot files). It can be used in addition to one of the following flags: {dumpdaelow|dumpinitialsystems|dumpindxdae}."));
constant DebugFlag INFO_XML_OPERATIONS = DEBUG_FLAG(100, "infoXmlOperations", false,
  Util.gettext("Enables output of the operations in the _info.xml file when translating models."));
constant DebugFlag HPCOM_DUMP = DEBUG_FLAG(101, "hpcomDump", false,
  Util.gettext("Dumps additional information on the parallel execution with hpcom."));
constant DebugFlag RESOLVE_LOOPS = DEBUG_FLAG(102, "resolveLoops", false,
  Util.gettext("Activates the resolveLoops module."));
constant DebugFlag DISABLE_WINDOWS_PATH_CHECK_WARNING = DEBUG_FLAG(103, "disableWindowsPathCheckWarning", false,
  Util.gettext("Disables warnings on Windows if OPENMODELICAHOME/MinGW is missing."));
constant DebugFlag DISABLE_RECORD_CONSTRUCTOR_OUTPUT = DEBUG_FLAG(104, "disableRecordConstructorOutput", false, 
  Util.gettext("Disables output of record constructors in the flat code."));
constant DebugFlag DUMP_TRANSFORMED_MODELICA_MODEL = DEBUG_FLAG(105, "dumpTransformedModelica", false,
  Util.gettext("Dumps the back-end DAE to a Modelica-like model after all symbolic transformations are applied."));
constant DebugFlag EVALUATE_CONST_FUNCTIONS = DEBUG_FLAG(106, "evalConstFuncs", false,
  Util.gettext("Evaluates functions complete and partially and checks for constant output."));
constant DebugFlag HPCOM_ANALYZATION_MODE = DEBUG_FLAG(107, "hpcomAnalyzationMode", false,
  Util.gettext("Creates statically linked c++ - code for analyzation (requires statically build cpp-runtime)"));
constant DebugFlag STRICT_RML = DEBUG_FLAG(108, "strictRml", false,
  Util.gettext("Turns on extra RML checks."));
// This is a list of all debug flags, to keep track of which flags are used. A
// flag can not be used unless it's in this list, and the list is checked at
// initialization so that all flags are sorted by index (and thus have unique
// indices).
constant list<DebugFlag> allDebugFlags = {
  FAILTRACE,
  CEVAL,
  CHECK_BACKEND_DAE,
  OPENMP,
  PTHREADS,
  EVENTS,
  DUMP_INLINE_SOLVER,
  EVAL_FUNC,
  GEN,
  DYN_LOAD,
  GENERATE_CODE_CHEAT,
  CGRAPH_GRAPHVIZ_FILE,
  CGRAPH_GRAPHVIZ_SHOW,
  USEDEP,
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
  DUMP_ENCAPSULATEWHENCONDITIONS,
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
  SYMBOLIC_INITIALIZATION,
  DUMPOPTINIT,
  SEMILINEAR,
  UNCERTAINTIES,
  DUMP_DAE,
  SHOW_START_ORIGIN,
  MIXED_TEARING,
  LINEAR_TEARING,
  DUMP_INITIAL_SYSTEM,
  GRAPH_INST,
  GRAPH_INST_RUN_DEP,
  GRAPH_INST_GEN_GRAPH,
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
  PARTLINTORNSYSTEM,
  DUMP_DISCRETEVARS_INFO,
  ADDITIONAL_GRAPHVIZ_DUMP,
  INFO_XML_OPERATIONS,
  HPCOM_DUMP,
  RESOLVE_LOOPS,
  DISABLE_WINDOWS_PATH_CHECK_WARNING,
  DISABLE_RECORD_CONSTRUCTOR_OUTPUT,
  DUMP_TRANSFORMED_MODELICA_MODEL,
  EVALUATE_CONST_FUNCTIONS,
  HPCOM_ANALYZATION_MODE,
  STRICT_RML
};

// CONFIGURATION FLAGS
constant ConfigFlag DEBUG = CONFIG_FLAG(1, "debug",
  SOME("d"), EXTERNAL(), STRING_LIST_FLAG({}), NONE(),
  Util.gettext("Sets debug flags. Use +help=debug to see available flags."));

constant ConfigFlag HELP = CONFIG_FLAG(2, "help",
  SOME("h"), EXTERNAL(), STRING_FLAG(""), NONE(),
  Util.gettext("Displays the help text. Use +help=topics for more information."));

constant ConfigFlag RUNNING_TESTSUITE = CONFIG_FLAG(3, "running-testsuite",
  NONE(), INTERNAL(), STRING_FLAG(""), NONE(),
  Util.gettext("Used when running the testsuite."));

constant ConfigFlag SHOW_VERSION = CONFIG_FLAG(4, "version",
  SOME("+v"), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Print the version and exit."));

constant ConfigFlag TARGET = CONFIG_FLAG(5, "target", NONE(), EXTERNAL(),
  STRING_FLAG("gcc"), SOME(STRING_OPTION({"gcc", "msvc"})),
  Util.gettext("Sets the target compiler to use."));

constant ConfigFlag GRAMMAR = CONFIG_FLAG(6, "grammar", SOME("g"), EXTERNAL(),
  ENUM_FLAG(MODELICA, {("Modelica", MODELICA), ("MetaModelica", METAMODELICA), ("ParModelica", PARMODELICA), ("Optimica", OPTIMICA)}),
  SOME(STRING_OPTION({"Modelica", "MetaModelica", "ParModelica", "Optimica"})),
  Util.gettext("Sets the grammar and semantics to accept."));

constant ConfigFlag ANNOTATION_VERSION = CONFIG_FLAG(7, "annotationVersion",
  NONE(), EXTERNAL(), STRING_FLAG("3.x"), SOME(STRING_OPTION({"1.x", "2.x", "3.x"})),
  Util.gettext("Sets the annotation version that should be used."));

constant ConfigFlag LANGUAGE_STANDARD = CONFIG_FLAG(8, "std", NONE(), EXTERNAL(),
  ENUM_FLAG(1000,
    {("1.x", 10), ("2.x", 20), ("3.0", 30), ("3.1", 31), ("3.2", 32), ("3.3", 33)}),
  SOME(STRING_OPTION({"1.x", "2.x", "3.1", "3.2", "3.3"})),
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
    "evaluateReplaceFinalEvaluateParameters",
    "simplifyIfEquations",
    "removeEqualFunctionCalls",
    "partitionIndependentBlocks",
    "expandDerOperator",
    "findStateOrder",
    "replaceEdgeChange",
    "inlineArrayEqn",
    "removeSimpleEquations",
    // "addInitialStmtsToAlgorithms",
    "resolveLoops",
    "evalFunc"
    }),
  SOME(STRING_DESC_OPTION({
    ("removeSimpleEquations", removeSimpleEquationDesc),
    ("removeAllSimpleEquations", removeSimpleEquationDesc),
    ("inlineArrayEqn", Util.gettext("This module expands all array equations to scalar equations.")),
    ("evaluateFinalParameters", Util.gettext("Structural parameters and parameters declared as final are evalutated and replaced with their value in other vars. They may no longer be changed in the init file.")),
    ("evaluateEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateFinalEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateReplaceFinalParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateReplaceEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateReplaceFinalEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("removeEqualFunctionCalls", Util.notrans("DESCRIBE ME")),
    ("removeProtectedParameters", Util.gettext("Replace all parameters with protected=true in the system.")),
    ("removeUnusedParameter", Util.gettext("Strips all parameter not present in the equations from the system.")),
    ("removeUnusedVariables", Util.gettext("Strips all variables not present in the equations from the system.")),
    ("partitionIndependentBlocks", Util.gettext("Partitions the equation system into independent equation systems (which can then be simulated in parallel or used to speed up subsequent optimizations).")),
    ("collapseIndependentBlocks", Util.gettext("Collapses all equation systems back into one big system again (undo partitionIndependentBlocks).")),
    ("expandDerOperator", Util.notrans("DESCRIBE ME")),
    ("simplifyIfEquations", Util.gettext("Tries to simplify if equations by use of information from evaluated parameters.")),
    ("replaceEdgeChange", Util.gettext("Replace edge(b) = b and not pre(b) and change(b) = v <> pre(v).")),
    ("residualForm", Util.gettext("Transforms simple equations x=y to zero-sum equations 0=y-x.")),
    ("addInitialStmtsToAlgorithms", Util.gettext("Expands all algorithms with initial statements for outputs.")),
    ("resolveLoops", Util.gettext("resolves linear equations in loops")),
    ("evalFunc", Util.gettext("evaluates functions partially"))
    })),
  Util.gettext("Sets the pre optimization modules to use in the back end. See +help=optmodules for more info."));

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
    ("PRExt", Util.gettext("Matching algorithm using push relabel mechanism external c implementation."))})),
    Util.gettext("Sets the matching algorithm to use. See +help=optmodules for more info."));

constant ConfigFlag INDEX_REDUCTION_METHOD = CONFIG_FLAG(15, "indexReductionMethod",
  NONE(), EXTERNAL(), STRING_FLAG("dynamicStateSelection"),
  SOME(STRING_DESC_OPTION({
    ("uode", Util.gettext("Use the underlying ODE without the constraints.")),
    ("dynamicStateSelection", Util.gettext("Simple index reduction method, select (dynamic) dummy states based on analysis of the system."))})),
    Util.gettext("Sets the index reduction method to use. See +help=optmodules for more info."));

constant ConfigFlag POST_OPT_MODULES = CONFIG_FLAG(16, "postOptModules",
  NONE(), EXTERNAL(), STRING_LIST_FLAG({
    "relaxSystem",
    "inlineArrayEqn",
    "constantLinearSystem",
    "simplifysemiLinear",
    "removeSimpleEquations",
    "encapsulateWhenConditions",  // must called after remove simple equations
    "tearingSystem", // must be the last one, otherwise the torn systems are lost when throw away the matching information
    "countOperations",
    "inputDerivativesUsed",
    "calculateStrongComponentJacobians",
    "calculateStateSetsJacobians",
    "detectJacobianSparsePattern",
    "generateSymbolicJacobian",
    "generateSymbolicLinearization",
    "removeUnusedFunctions",
    "removeConstants"
    // "partitionIndependentBlocks",
    // "addInitialStmtsToAlgorithms"
    //"resolveLoops"
    }),
  SOME(STRING_DESC_OPTION({
    ("encapsulateWhenConditions", Util.gettext("Replace each when-condition with an discrete variable.")),
    ("lateInlineFunction", Util.gettext("Perform function inlining for function with annotation LateInline=true.")),
    ("removeSimpleEquationsFast", removeSimpleEquationDesc),
    ("removeSimpleEquations", removeSimpleEquationDesc),
    ("evaluateFinalParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateFinalEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateReplaceFinalParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateReplaceEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("evaluateReplaceFinalEvaluateParameters", Util.gettext("Structural parameters and parameters declared as final are removed and replaced with their value. They may no longer be changed in the init file.")),
    ("removeEqualFunctionCalls", Util.notrans("DESCRIBE ME")),
    ("inlineArrayEqn", Util.gettext("This module expands all array equations to scalar equations.")),
    ("removeUnusedParameter", Util.gettext("Strips all parameter not present in the equations from the system.")),
    ("constantLinearSystem", Util.gettext("Evaluates constant linear systems (a*x+b*y=c; d*x+e*y=f; a,b,c,d,e,f are constants) at compile-time.")),
    ("tearingSystem",Util.notrans("For method selection use flag tearingMethod.")),
    ("relaxSystem",Util.notrans("DESCRIBE ME")),
    ("countOperations", Util.gettext("Count the mathematic operations of the system.")),
    ("dumpComponentsGraphStr", Util.notrans("DESCRIBE ME")),
    ("generateSymbolicJacobian", Util.gettext("Generates symbolic jacobian matrix, where der(x) is differentiated w.r.t. x. This matrix can be used to simulate with dasslColorSymJac.")),
    ("generateSymbolicLinearization", Util.gettext("Generates symbolic linearization matrixes A,B,C,D for linear model:\n\t\t\\dot x = Ax + Bu\n\t\ty = Cx +Du")),
    ("collapseIndependentBlocks", Util.gettext("Collapses all equation systems back into one big system again (undo partitionIndependentBlocks).")),
    ("removeUnusedFunctions", Util.gettext("Removed all unused functions from functionTree.")),
    ("simplifyTimeIndepFuncCalls", Util.gettext("Simplifies time independent built in function calls like pre(param) -> param, der(param) -> 0.0, change(param) -> false, edge(param) -> false.")),
    ("inputDerivativesUsed", Util.gettext("Checks if derivatives of inputs are need to calculate the model.")),
    ("simplifysemiLinear", Util.gettext("Simplifies calls to semiLinear.")),
    ("removeConstants", Util.gettext("Remove all constants in the system.")),
    ("optimizeInitialSystem", Util.gettext("Simplifies time initial system.")),
    ("detectJacobianSparsePattern", Util.gettext("Detects the sparse pattern for Jacobian A.")),
    ("calculateStrongComponentJacobians", Util.gettext("Generates analytical jacobian for non-linear strong components.")),
    ("calculateStateSetsJacobians", Util.gettext("Generates analytical jacobian for dynamic state selection sets.")),
    ("partitionIndependentBlocks", Util.gettext("Partitions the equation system into independent equation systems (which can then be simulated in parallel or used to speed up subsequent optimizations).")),
    ("addInitialStmtsToAlgorithms", Util.gettext("Expands all algorithms with initial statements for outputs."))
    })),
  Util.gettext("Sets the post optimization modules to use in the back end. See +help=optmodules for more info."));

constant ConfigFlag SIMCODE_TARGET = CONFIG_FLAG(17, "simCodeTarget",
  NONE(), EXTERNAL(), STRING_FLAG("C"),
  SOME(STRING_OPTION({"C", "CSharp", "Cpp", "Adevs", "QSS", "Dump", "XML", "Java", "JavaScript", "None"})),
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
  Util.gettext("Sets the name of the corba session if +d=interactiveCorba is used."));

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

constant ConfigFlag PLOT_SILENT = CONFIG_FLAG(38, "plotSilent",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Defines whether plot commands should open OMPlot or show the list of arguments that would have been sent to OMPlot."));

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
  NONE(), EXTERNAL(), STRING_FLAG("omcTearing"),
  SOME(STRING_DESC_OPTION({
    ("noTearing", Util.gettext("Skip tearing.")),
    ("omcTearing", Util.gettext("Tearing method developed by TU Dresden: Frenkel, Schubert.")),
    ("cellier", Util.gettext("Cellier tearing.")),
    ("carpanzano2", Util.gettext("Carpanzano2 tearing.")),
    ("olleroAmselem", Util.gettext("Ollero-Amselem tearing.")),
    ("steward", Util.gettext("Steward tearing."))})),
    Util.gettext("Sets the tearing method to use. Select no tearing or choose tearing method."));

constant ConfigFlag SCALARIZE_MINMAX = CONFIG_FLAG(45, "scalarizeMinMax",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Scalarizes the builtin min/max reduction operators if true."));

constant ConfigFlag RUNNING_WSM_TESTSUITE = CONFIG_FLAG(46, "wsm-testsuite",
  NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Used when running the WSM testsuite."));

constant ConfigFlag CORRECT_CREF_TYPES = CONFIG_FLAG(47, "correctCrefTypes",
  NONE(), INTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Set to true to set correct types in component references. Doesn't work for OpenModelica back-end."));

constant ConfigFlag SCALARIZE_BINDINGS = CONFIG_FLAG(48, "scalarizeBindings",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Always scalarizes bindings if set."));

constant ConfigFlag CORBA_OBJECT_REFERENCE_FILE_PATH = CONFIG_FLAG(49, "corbaObjectReferenceFilePath",
  NONE(), EXTERNAL(), STRING_FLAG(""), NONE(),
  Util.gettext("Sets the path for corba object reference file if +d=interactiveCorba is used."));

constant ConfigFlag HPCOM_SCHEDULER = CONFIG_FLAG(50, "hpcomScheduler",
  NONE(), EXTERNAL(), STRING_FLAG(""), NONE(),
  Util.gettext("Sets the scheduler for task graph scheduling (list | level | levelr | ext | mcp | taskdep). Default: list."));
  
constant ConfigFlag TEARING_HEURISTIC = CONFIG_FLAG(51, "tearingHeuristic",
  NONE(), EXTERNAL(), STRING_FLAG("MC1"),
  SOME(STRING_DESC_OPTION({
    ("MC1", Util.gettext("Original cellier with consideration of impossible assignments and discrete Vars.")),
  ("MC2", Util.gettext("Modified cellier, drop first step.")),
    ("MC11", Util.gettext("Modified MC1, new last step 'count impossible assignments'.")),
    ("MC21", Util.gettext("Modified MC2, , new last step 'count impossible assignments'.")),
    ("MC12", Util.gettext("Modified MC1, step 'count impossible assignments' before last step.")),
    ("MC22", Util.gettext("Modified MC2, step 'count impossible assignments' before last step.")),
  ("MC13", Util.gettext("Modified MC1, build sum of impossible assignment and causalizable equations, choose var with biggest sum.")),
  ("MC23", Util.gettext("Modified MC2, build sum of impossible assignment and causalizable equations, choose var with biggest sum.")),
    ("MC231", Util.gettext("Modified MC23, Two rounds, choose better potentials-set.")),
  ("MC3", Util.gettext("Modified cellier, build sum of impossible assignment and causalizable equations for all vars, choose var with biggest sum.")),
  ("MC4", Util.gettext("Modified cellier, use all heuristics, choose var that occurs most in potential sets"))})),
    Util.gettext("Sets the tearing heuristic to use for Cellier-tearing."));

constant ConfigFlag HPCOM_CODE = CONFIG_FLAG(52, "hpcomCode",
  NONE(), EXTERNAL(), STRING_FLAG("openmp"), NONE(),
  Util.gettext("Sets the code-type produced by hpcom (openmp | pthreads | pthreads_spin). Default: openmp."));

constant ConfigFlag REWRITE_RULES_FILE = CONFIG_FLAG(53, "rewriteRulesFile", NONE(), EXTERNAL(),
  STRING_FLAG(""), NONE(),
  Util.gettext("Activates user given rewrite rules for Absyn expressions. The rules are read from the given file and are of the form rewrite(fromExp, toExp);"));

constant ConfigFlag REPLACE_HOMOTOPY = CONFIG_FLAG(54, "replaceHomotopy",
  NONE(), EXTERNAL(), STRING_FLAG("none"),
  SOME(STRING_DESC_OPTION({
    ("none", Util.gettext("Default, do not replace homotopy.")),
    ("actual", Util.gettext("Replace homotopy(actual, simplified) with actual.")),
    ("simplified", Util.gettext("Replace homotopy(actual, simplified with simplified."))
    })),
    Util.gettext("Replaces homotopy(actual, simplified) with the actual expression or the simplified expression. Good for debugging models which use homotopy. The default is to not replace homotopy."));
  
constant ConfigFlag GENERATE_SYMBOLIC_JACOBIAN = CONFIG_FLAG(55, "generateSymbolicJacobian",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Generates symbolic jacobian matrix, where der(x) is differentiated w.r.t. x. This matrix can be used to simulate with dasslColorSymJac."));

constant ConfigFlag GENERATE_SYMBOLIC_LINEARIZATION = CONFIG_FLAG(56, "generateSymbolicLinearization",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Generates symbolic linearization matrixes A,B,C,D for linear model:\n\t\t\\dot x = Ax + Bu\n\t\ty = Cx +Du"));

constant ConfigFlag INT_ENUM_CONVERSION = CONFIG_FLAG(57, "intEnumConversion",
  NONE(), EXTERNAL(), BOOL_FLAG(false), NONE(),
  Util.gettext("Allow Integer to enumeration conversion."));


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
  PLOT_SILENT,
  LOCALE_FLAG,
  DEFAULT_OPENCL_DEVICE,
  MAXTRAVERSALS,
  DUMP_TARGET,
  DELAY_BREAK_LOOP,
  TEARING_METHOD,
  SCALARIZE_MINMAX,
  RUNNING_WSM_TESTSUITE,
  CORRECT_CREF_TYPES,
  SCALARIZE_BINDINGS,
  CORBA_OBJECT_REFERENCE_FILE_PATH,
  HPCOM_SCHEDULER,
  TEARING_HEURISTIC,
  HPCOM_CODE,
  REWRITE_RULES_FILE,
  REPLACE_HOMOTOPY,
  GENERATE_SYMBOLIC_JACOBIAN,
  GENERATE_SYMBOLIC_LINEARIZATION,
  INT_ENUM_CONVERSION
};

public function new
  "Create a new flags structure and read the given arguments."
  input list<String> inArgs;
  output list<String> outArgs;
algorithm
  _ := loadFlags();
  outArgs := readArgs(inArgs);
end new;

protected function saveFlags
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

protected function loadFlags
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
        _ = List.fold(allDebugFlags, checkDebugFlag, 1);
        debug_flags = createDebugFlags();
        config_flags = createConfigFlags();
        flags = FLAGS(debug_flags, config_flags);
        saveFlags(flags);
      then
        flags;

  end matchcontinue;
end loadFlags;

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
  outNextFlagIndex := matchcontinue(inDebugFlag, inFlagIndex)
    local
      Integer index;
      String name, index_str, err_str;

    case (DEBUG_FLAG(index = index), _)
      equation
        true = intEq(index, inFlagIndex);
      then inFlagIndex + 1;

    case (DEBUG_FLAG(index = index, name = name), _)
      equation
        index_str = intString(index);
        err_str = "Invalid flag " +& name +& " with index " +& index_str +&
          " in Flags.allDebugFlags. Make sure that all flags are present and ordered correctly.";
        Error.addMessage(Error.INTERNAL_ERROR, {err_str});
      then fail();
  end matchcontinue;
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
        _ = arrayUpdate(inConfigData, index, default_value);
      then
        inFlagIndex + 1;

    case (CONFIG_FLAG(index = index, name = name), _, _)
      equation
        index_str = intString(index);
        err_str = "Invalid flag " +& name +& " with index " +& index_str +&
          " in Flags.allConfigFlags. Make sure that all flags are present and ordered correctly.";
        Error.addMessage(Error.INTERNAL_ERROR, {err_str});
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
  output list<String> outArgs;
protected
  Flags flags;
  Integer numError;
algorithm
  numError := Error.getNumErrorMessages();
  flags := loadFlags();
  outArgs := List.filter1OnTrue(inArgs, readArg, flags);
  _ := List.map2(outArgs,System.iconv,"UTF-8","UTF-8");
  Error.assertionOrAddSourceMessage(numError == Error.getNumErrorMessages(), Error.UTF8_COMMAND_LINE_ARGS, {}, Absyn.dummyInfo);
  saveFlags(flags);
end readArgs;

protected function readArg
  "Reads a single command line argument. Returns true if the argument was not
  consumed, otherwise false."
  input String inArg;
  input Flags inFlags;
  output Boolean outNotConsumed;
algorithm
  outNotConsumed := matchcontinue(inArg, inFlags)
    local
      Integer len, pos;
      String flag;

    // Ignore flags that don't start with + or -.
    case (_, _)
      equation
        flag = stringGetStringChar(inArg, 1);
        false = stringEq(flag, "+") or stringEq(flag, "-");
      then
        true;

    // Flags that start with --.
    case (_, _)
      equation
        true = stringEq(System.substring(inArg, 1, 2), "--");
        len = stringLength(inArg);
        // Don't allow short names with --, like --a.
        true = len > 3;
        flag = System.substring(inArg, 3, len);
        parseFlag(flag, inFlags);
      then
        false;

    // Flags beginning with - are consumed by the RML runtime, until -- is
    // encountered. The bootstrapped compiler gets all flags though, so this
    // case is to make sure that -- is consumed and not treated as a flag.
    case ("--", _) then false;

    // Flags that start with +.
    else
      equation
        true = stringEq(stringGetStringChar(inArg, 1), "+");
        len = stringLength(inArg);
        pos = Util.if_(len == 1, 1, 2); // Handle + without anything else.
        flag = System.substring(inArg, pos, len);
        parseFlag(flag, inFlags);
      then
        false;
  end matchcontinue;
end readArg;

protected function parseFlag
  "Parses a single flag."
  input String inFlag;
  input Flags inFlags;
protected
  String flag;
  list<String> values;
algorithm
  flag :: values := System.strtok(inFlag, "=");
  values := List.flatten(List.map1(values, System.strtok, ","));
  parseConfigFlag(flag, values, inFlags);
end parseFlag;

protected function parseConfigFlag
  "Tries to look up the flag with the given name, and set it to the given value."
  input String inFlag;
  input list<String> inValues;
  input Flags inFlags;
protected
  ConfigFlag config_flag;
algorithm
  config_flag := lookupConfigFlag(inFlag);
  evaluateConfigFlag(config_flag, inValues, inFlags);
end parseConfigFlag;

protected function lookupConfigFlag
  "Lookup up the flag with the given name in the list of configuration flags."
  input String inFlag;
  output ConfigFlag outFlag;
algorithm
  outFlag := matchcontinue(inFlag)
    case (_)
      then List.getMemberOnTrue(inFlag, allConfigFlags, matchConfigFlag);

    else
      equation
        Error.addMessage(Error.UNKNOWN_OPTION, {inFlag});
      then
        fail();

  end matchcontinue;
end lookupConfigFlag;

protected function evaluateConfigFlag
  "Evaluates a given flag and it's arguments."
  input ConfigFlag inFlag;
  input list<String> inValues;
  input Flags inFlags;
algorithm
  _ := match(inFlag, inValues, inFlags)
    local
      array<Boolean> debug_flags;
      array<FlagData> config_flags;
      list<String> values;

    // Special case for +d, +debug, set the given debug flags.
    case (CONFIG_FLAG(index = 1), _, FLAGS(debugFlags = debug_flags))
      equation
        List.map1_0(inValues, setDebugFlag, debug_flags);
      then
        ();

    // Special case for +h, +help, show help text.
    case (CONFIG_FLAG(index = 2), _, _)
      equation
        values = List.map(inValues, System.tolower);
        System.gettextInit(Util.if_(getConfigString(RUNNING_TESTSUITE) ==& "",
          getConfigString(LOCALE_FLAG), "C"));
        print(printHelp(values));
        setConfigString(HELP, "omc");
      then
        ();

    // All other configuration flags, set the flag to the given values.
    case (_, _, FLAGS(configFlags = config_flags))
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
  flag_str := Debug.bcallret1(negated, Util.stringRest, inFlag, inFlag);
  flag_str := Debug.bcallret1(neg2, Util.stringRest, flag_str, flag_str);
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
algorithm
  CONFIG_FLAG(name = name, defaultValue = default_value) := inFlag;
  data := stringFlagData(inValues, default_value, name);
  _ := updateConfigFlagArray(inConfigData, data, inFlag);
end setConfigFlag;

protected function stringFlagData
  "Converts a list of strings into a FlagData value. The expected type is also
   given so that the value can be typechecked."
  input list<String> inValues;
  input FlagData inExpectedType;
  input String inName;
  output FlagData outValue;
algorithm
  outValue := matchcontinue(inValues, inExpectedType, inName)
    local
      Boolean b;
      Integer i;
      String s, et, at;
      list<tuple<String, Integer>> enums;

    // A boolean value.
    case ({s}, BOOL_FLAG(data = _), _)
      equation
        b = Util.stringBool(s);
      then
        BOOL_FLAG(b);

    // No value, but a boolean flag => enable the flag.
    case ({}, BOOL_FLAG(data = _), _) then BOOL_FLAG(true);

    // An integer value.
    case ({s}, INT_FLAG(data = _), _)
      equation
        i = stringInt(s);
        true = stringEq(intString(i), s);
      then
        INT_FLAG(i);

    // A real value.
    case ({s}, REAL_FLAG(data = _), _)
      equation
        //r = stringReal(s);
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Flags.stringFlagData: RML doesn't have stringReal, enable this for the bootstrapped compiler"});
      then
        fail();
        //REAL_FLAG(r);

    // A string value.
    case ({s}, STRING_FLAG(data = _), _) then STRING_FLAG(s);

    // A multiple-string value.
    case (_, STRING_LIST_FLAG(data = _), _) then STRING_LIST_FLAG(inValues);

    // An enumeration value.
    case ({s}, ENUM_FLAG(validValues = enums), _)
      equation
        i = Util.assoc(s, enums);
      then
        ENUM_FLAG(i, enums);

    // Type mismatch, print error.
    else
      equation
        et = printExpectedTypeStr(inExpectedType);
        at = printActualTypeStr(inValues);
        Error.addMessage(Error.INVALID_FLAG_TYPE, {inName, et, at});
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

    case BOOL_FLAG(data = _) then "a boolean value";
    case INT_FLAG(data = _) then "an integer value";
    case REAL_FLAG(data = _) then "a floating-point value";
    case STRING_FLAG(data = _) then "a string";
    case STRING_LIST_FLAG(data = _) then "a comma-separated list of strings";
    case ENUM_FLAG(validValues = enums)
      equation
        enum_strs = List.map(enums, Util.tuple21);
      then
        "one of the values {" +& stringDelimitList(enum_strs, ", ") +& "}";
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
    case {s} equation _ = Util.stringBool(s); then "the boolean value " +& s;
    case {s}
      equation
        i = stringInt(s);
        // intString returns 0 on failure, so this is to make sure that it
        // actually succeeded.
        true = stringEq(intString(i), s);
      then
        "the number " +& intString(i);
    //case {s}
    //  equation
    //    _ = stringReal(s);
    //  then
    //    "the number " +& intString(i);
    case {s} then "the string \"" +& s +& "\"";
    case _ then "a list of values.";
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
      list<String>  rest_topics, strs;
      String str,name,str1,str2,str3,str4,str5,str6,str7,str8;
      ConfigFlag config_flag;
      list<tuple<String,String>> topics;

    case {} then printUsage();

    case {"omc"} then printUsage();

    //case {"mos"} then System.gettext("TODO: Write help-text");

    case {"topics"}
      equation
        /* TODO: RML won't let us compile with the text inside the list directly... */
        str1 = System.gettext("Help on the command-line and scripting environments, including OMShell and OMNotebook.");
        str2 = System.gettext("The command-line options available for omc.");
        str3 = System.gettext("Flags that enable debugging, diagnostics, and research prototypes.");
        str4 = System.gettext("Flags that determine which symbolic methods are used to produce the causalized equation system.");
        str5 = System.gettext("The command-line options available for simulation executables generated by OpenModelica.");
        str6 = System.gettext("Displays option descriptions for multi-option flag <flagname>.");
        str7 = System.gettext("This help-text.");
        topics = {
          //("mos",str1),
          ("omc",str2),
          ("debug",str3),
          ("optmodules",str4),
          ("simulation",str5),
          ("<flagname>",str6),
          ("topics",str7)
        };
        str = System.gettext("The available topics (help(\"topics\")) are as follows:\n");
        strs = List.map(topics,makeTopicString);
        help = str +& stringDelimitList(strs,"\n") +& "\n";
      then help;

    case {"simulation"}
      equation
        help = System.gettext("The simulation executable takes the following flags:\n") +& System.getSimulationHelpText(true);
      then help;

    case {"debug"}
      equation
        str1 = System.gettext("The debug flag takes a comma-separated list of flags which are used by the\ncompiler for debugging or experimental purposes.\nFlags prefixed with \"-\" or \"no\" will be disabled.\n");
        str2 = System.gettext("The available flags are (+ are enabled by default, - are disabled):\n\n");
        strs = List.map(List.sort(allDebugFlags,compareDebugFlags), printDebugFlag);
        help = stringAppendList(str1 :: str2 :: strs);
      then help;

    case {"optmodules"}
      equation
        str1 = System.gettext("The +preOptModules flag sets the optimization modules which are used before the\nmatching and index reduction in the back end. These modules are specified as a comma-separated list, where the valid modules are:");
        str1 = stringAppendList(Util.stringWrap(str1,System.getTerminalWidth(),"\n"));
        str2 = printFlagValidOptionsDesc(PRE_OPT_MODULES);
        str3 = System.gettext("The +matchingAlgorithm sets the method that is used for the matching algorithm, after the pre optimization modules. Valid options are:");
        str3 = stringAppendList(Util.stringWrap(str3,System.getTerminalWidth(),"\n"));
        str4 = printFlagValidOptionsDesc(MATCHING_ALGORITHM);
        str5 = System.gettext("The +indexReductionMethod sets the method that is used for the index reduction, after the pre optimization modules. Valid options are:");
        str5 = stringAppendList(Util.stringWrap(str5,System.getTerminalWidth(),"\n"));
        str6 = printFlagValidOptionsDesc(INDEX_REDUCTION_METHOD);
        str7 = System.gettext("The +postOptModules then sets the optimization modules which are used after the index reduction, specified as a comma-separated list. The valid modules are:");
        str7 = stringAppendList(Util.stringWrap(str7,System.getTerminalWidth(),"\n"));
        str8 = printFlagValidOptionsDesc(POST_OPT_MODULES);
        help = stringAppendList({str1,"\n\n",str2,"\n",str3,"\n\n",str4,"\n",str5,"\n\n",str6,"\n",str7,"\n\n",str8,"\n"});
      then help;

    case {str}
      equation
        (config_flag as CONFIG_FLAG(name=name,description=desc)) = List.getMemberOnTrue(str, allConfigFlags, matchConfigFlag);
        str = Util.translateContent(desc);
        str = "    +" +& name +& " " +& str +& "\n";
        str = stringAppendList(Util.stringWrap(str, System.getTerminalWidth(), descriptionIndent));
        str2 = printFlagValidOptionsDesc(config_flag);
        help = stringAppendList({str,"\n",str2});
      then help;

    case {str}
      then "I'm sorry, I don't know what " +& str +& " is.\n";

    case (str :: (rest_topics as _::_))
      equation
        str = printHelp({str}) +& "\n";
        help = printHelp(rest_topics);
      then str +& help;

  end matchcontinue;
end printHelp;

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
  str := stringAppendList(Util.stringWrap(str1 +& str2, System.getTerminalWidth(), "\n               "));
end makeTopicString;

public function printUsage
  "Prints out the usage text for the compiler."
  output String usage;
algorithm
  Print.clearBuf();
  Print.printBuf("OpenModelica Compiler "); Print.printBuf(Settings.getVersionNr()); Print.printBuf("\n");
  Print.printBuf(System.gettext("Copyright © 2013 Open Source Modelica Consortium (OSMC)\n"));
  Print.printBuf(System.gettext("Distributed under OMSC-PL and GPL, see www.openmodelica.org\n\n"));
  //Print.printBuf("Please check the System Guide for full information about flags.\n");
  Print.printBuf(System.gettext("Usage: omc [-runtimeOptions +omcOptions] (Model.mo | Script.mos) [Libraries | .mo-files] \n* Libraries: Fully qualified names of libraries to load before processing Model or Script.\n             The libraries should be separated by spaces: Lib1 Lib2 ... LibN.\n* runtimeOptions: call omc -help to see runtime options\n"));
  Print.printBuf(System.gettext("\n* +omcOptions:\n"));
  Print.printBuf(printAllConfigFlags());
  Print.printBuf(System.gettext("\nFor more details on a specific topic, use +help=topics or help(\"topics\")\n\n"));
  Print.printBuf(System.gettext("* Examples:\n"));
  Print.printBuf(System.gettext("  omc Model.mo             will produce flattened Model on standard output.\n"));
  Print.printBuf(System.gettext("  omc +s Model.mo          will produce simulation code for the model:\n"));
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
  Print.printBuf(System.gettext("For available simulation flags, use +help=simulation.\n\n"));
  Print.printBuf(System.gettext("Documentation is available in the built-in package OpenModelica.Scripting or\nonline <https://build.openmodelica.org/Documentation/OpenModelica.Scripting.html>.\n"));
  usage := Print.getString();
  Print.clearBuf();
end printUsage;

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
        delim_str = descriptionIndent +& "  ";
        wrapped_str = Util.stringWrap(flag_str, System.getTerminalWidth(), delim_str);
        opt_str = printValidOptions(inFlag);
        flag_str = stringDelimitList(wrapped_str, "\n") +& opt_str +& "\n";
      then
        flag_str;

  end match;
end printConfigFlag;

protected function printConfigFlagName
  "Prints out the name of a configuration flag, formatted for use by
   printConfigFlag."
  input ConfigFlag inFlag;
  output String outString;
algorithm
  outString := match(inFlag)
    local
      String name, shortname;

    case CONFIG_FLAG(name = name, shortname = SOME(shortname))
      equation
        shortname = Util.stringPadLeft("+" +& shortname, 4, " ");
      then stringAppendList({shortname, ", +", name});

    case CONFIG_FLAG(name = name, shortname = NONE())
      then "      +" +& name;

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
        opt_str = "\n" +& descriptionIndent +& "   " +& System.gettext("Valid options:") +& " " +&
          stringDelimitList(strl, ", ");
      then
        opt_str;
    case CONFIG_FLAG(validOptions = SOME(STRING_DESC_OPTION(options = descl)))
      equation
        opt_str = "\n" +& descriptionIndent +& "   " +& System.gettext("Valid options:") +& "\n" +&
          stringAppendList(List.map(descl, printFlagOptionDescShort));
      then
        opt_str;
  end match;
end printValidOptions;

protected function printFlagOptionDescShort
  "Prints out the name of a flag option."
  input tuple<String, Util.TranslatableContent> inOption;
  output String outString;
protected
  String name;
algorithm
  (name, _) := inOption;
  outString := descriptionIndent +& "    * " +& name +& "\n";
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
  outString := stringAppendList(List.map(options, printFlagOptionDesc));
end printFlagValidOptionsDesc;

protected function printFlagOptionDesc
  "Helper function to printFlagValidOptionsDesc."
  input tuple<String, Util.TranslatableContent> inOption;
  output String outString;
protected
  Util.TranslatableContent desc;
  String name, desc_str, str;
algorithm
  (name, desc) := inOption;
  desc_str := Util.translateContent(desc);
  str := Util.stringPadRight(" * " +& name +& " ", 30, " ") +& desc_str;
  outString := stringDelimitList(
    Util.stringWrap(str, System.getTerminalWidth(), descriptionIndent +& "    "), "\n") +& "\n";
end printFlagOptionDesc;

protected function printDebugFlag
  "Prints out name and description of a debug flag."
  input DebugFlag inFlag;
  output String outString;
protected
  Util.TranslatableContent desc;
  String name, desc_str;
  Boolean default;
algorithm
  DEBUG_FLAG(default = default, name = name, description = desc) := inFlag;
  desc_str := Util.translateContent(desc);
  outString := Util.stringPadRight(Util.if_(default," + "," - ") +& name +& " ", 26, " ") +& desc_str;
  outString := stringDelimitList(Util.stringWrap(outString, System.getTerminalWidth(),
    descriptionIndent), "\n") +& "\n";
end printDebugFlag;

public function debugFlagName
  "Prints out name of a debug flag."
  input DebugFlag inFlag;
  output String name;
algorithm
  DEBUG_FLAG(name = name) := inFlag;
end debugFlagName;

end Flags;
