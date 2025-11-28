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

encapsulated package FlagsUtil
" file:        FlagsUtil.mo
  package:     FlagsUtil
  description: Tools for using compiler flags.

  This package contains function for using the compiler flags in Flags.mo."

import Flags;

protected

import Corba;
import Error;
import ErrorExt;
import Global;
import List;
import Print;
import Settings;
import StringUtil;
import System;
import Util;

// This is a list of all debug flags, to keep track of which flags are used. A
// flag can not be used unless it's in this list, and the list is checked at
// initialization so that all flags are sorted by index (and thus have unique
// indices).
protected
constant list<Flags.DebugFlag> allDebugFlags = {
  Flags.FAILTRACE,
  Flags.CEVAL,
  Flags.CHECK_BACKEND_DAE,
  Flags.PTHREADS,
  Flags.EVENTS,
  Flags.DUMP_INLINE_SOLVER,
  Flags.EVAL_FUNC,
  Flags.GEN,
  Flags.DYN_LOAD,
  Flags.GENERATE_CODE_CHEAT,
  Flags.CGRAPH_GRAPHVIZ_FILE,
  Flags.CGRAPH_GRAPHVIZ_SHOW,
  Flags.GC_PROF,
  Flags.CHECK_DAE_CREF_TYPE,
  Flags.CHECK_ASUB,
  Flags.INSTANCE,
  Flags.CACHE,
  Flags.RML,
  Flags.TAIL,
  Flags.LOOKUP,
  Flags.PATTERNM_SKIP_FILTER_UNUSED_AS_BINDINGS,
  Flags.PATTERNM_ALL_INFO,
  Flags.PATTERNM_DCE,
  Flags.PATTERNM_MOVE_LAST_EXP,
  Flags.EXPERIMENTAL_REDUCTIONS,
  Flags.EVAL_PARAM,
  Flags.TYPES,
  Flags.SHOW_STATEMENT,
  Flags.DUMP,
  Flags.DUMP_GRAPHVIZ,
  Flags.EXEC_STAT,
  Flags.TRANSFORMS_BEFORE_DUMP,
  Flags.DAE_DUMP_GRAPHV,
  Flags.INTERACTIVE_TCP,
  Flags.INTERACTIVE_CORBA,
  Flags.INTERACTIVE_DUMP,
  Flags.RELIDX,
  Flags.DUMP_REPL,
  Flags.DUMP_FP_REPL,
  Flags.DUMP_PARAM_REPL,
  Flags.DUMP_PP_REPL,
  Flags.DUMP_EA_REPL,
  Flags.DEBUG_ALIAS,
  Flags.TEARING_DUMP,
  Flags.JAC_DUMP,
  Flags.JAC_DUMP2,
  Flags.DUMP_BINDINGS,
  Flags.DUMP_SORTING,
  Flags.DUMP_SPARSE,
  Flags.DUMP_SPARSE_VERBOSE,
  Flags.BLT_DUMP,
  Flags.DUMMY_SELECT,
  Flags.DUMP_DAE_LOW,
  Flags.DUMP_INDX_DAE,
  Flags.OPT_DAE_DUMP,
  Flags.EXEC_HASH,
  Flags.PARAM_DLOW_DUMP,
  Flags.DUMP_ENCAPSULATECONDITIONS,
  Flags.SHORT_OUTPUT,
  Flags.COUNT_OPERATIONS,
  Flags.CGRAPH,
  Flags.UPDMOD,
  Flags.STATIC,
  Flags.TPL_PERF_TIMES,
  Flags.CHECK_SIMPLIFY,
  Flags.SCODE_INST,
  Flags.WRITE_TO_BUFFER,
  Flags.DUMP_BACKENDDAE_INFO,
  Flags.GEN_DEBUG_SYMBOLS,
  Flags.DUMP_STATESELECTION_INFO,
  Flags.DUMP_EQNINORDER,
  Flags.SEMILINEAR,
  Flags.UNCERTAINTIES,
  Flags.SHOW_START_ORIGIN,
  Flags.DUMP_SIMCODE,
  Flags.DUMP_INITIAL_SYSTEM,
  Flags.GRAPH_INST,
  Flags.GRAPH_INST_RUN_DEP,
  Flags.GRAPH_INST_GEN_GRAPH,
  Flags.DUMP_CONST_REPL,
  Flags.SHOW_EQUATION_SOURCE,
  Flags.LS_ANALYTIC_JACOBIAN,
  Flags.NLS_ANALYTIC_JACOBIAN,
  Flags.INLINE_SOLVER,
  Flags.HPCOM,
  Flags.INITIALIZATION,
  Flags.INLINE_FUNCTIONS,
  Flags.DUMP_SCC_GRAPHML,
  Flags.TEARING_DUMPVERBOSE,
  Flags.DISABLE_SINGLE_FLOW_EQ,
  Flags.DUMP_DISCRETEVARS_INFO,
  Flags.ADDITIONAL_GRAPHVIZ_DUMP,
  Flags.INFO_XML_OPERATIONS,
  Flags.HPCOM_DUMP,
  Flags.RESOLVE_LOOPS_DUMP,
  Flags.DISABLE_WINDOWS_PATH_CHECK_WARNING,
  Flags.DISABLE_RECORD_CONSTRUCTOR_OUTPUT,
  Flags.IMPL_ODE,
  Flags.EVAL_FUNC_DUMP,
  Flags.PRINT_STRUCTURAL,
  Flags.ITERATION_VARS,
  Flags.ALLOW_RECORD_TOO_MANY_FIELDS,
  Flags.HPCOM_MEMORY_OPT,
  Flags.DUMP_SYNCHRONOUS,
  Flags.STRIP_PREFIX,
  Flags.DO_SCODE_DEP,
  Flags.SHOW_INST_CACHE_INFO,
  Flags.DUMP_UNIT,
  Flags.DUMP_EQ_UNIT,
  Flags.DUMP_EQ_UNIT_STRUCT,
  Flags.SHOW_DAE_GENERATION,
  Flags.RESHUFFLE_POST,
  Flags.SHOW_EXPANDABLE_INFO,
  Flags.DUMP_HOMOTOPY,
  Flags.OMC_RELOCATABLE_FUNCTIONS,
  Flags.GRAPHML,
  Flags.USEMPI,
  Flags.DUMP_CSE,
  Flags.DUMP_CSE_VERBOSE,
  Flags.NO_START_CALC,
  Flags.CONSTJAC,
  Flags.VISUAL_XML,
  Flags.VECTORIZE,
  Flags.CHECK_EXT_LIBS,
  Flags.RUNTIME_STATIC_LINKING,
  Flags.SORT_EQNS_AND_VARS,
  Flags.DUMP_SIMPLIFY_LOOPS,
  Flags.DUMP_RTEARING,
  Flags.DIS_SYMJAC_FMI20,
  Flags.EVAL_OUTPUT_ONLY,
  Flags.HARDCODED_START_VALUES,
  Flags.DUMP_FUNCTIONS,
  Flags.DEBUG_DIFFERENTIATION,
  Flags.DEBUG_DIFFERENTIATION_VERBOSE,
  Flags.FMU_EXPERIMENTAL,
  Flags.DUMP_DGESV,
  Flags.MULTIRATE_PARTITION,
  Flags.DUMP_EXCLUDED_EXP,
  Flags.DEBUG_ALGLOOP_JACOBIAN,
  Flags.DISABLE_JACSCC,
  Flags.FORCE_NLS_ANALYTIC_JACOBIAN,
  Flags.DUMP_LOOPS,
  Flags.DUMP_LOOPS_VERBOSE,
  Flags.SKIP_INPUT_OUTPUT_SYNTACTIC_SUGAR,
  Flags.OMC_RECORD_ALLOC_WORDS,
  Flags.TOTAL_TEARING_DUMP,
  Flags.TOTAL_TEARING_DUMPVERBOSE,
  Flags.PARALLEL_CODEGEN,
  Flags.SERIALIZED_SIZE,
  Flags.BACKEND_KEEP_ENV_GRAPH,
  Flags.DUMPBACKENDINLINE,
  Flags.DUMPBACKENDINLINE_VERBOSE,
  Flags.BLT_MATRIX_DUMP,
  Flags.LIST_REVERSE_WRONG_ORDER,
  Flags.PARTITION_INITIALIZATION,
  Flags.EVAL_PARAM_DUMP,
  Flags.NF_UNITCHECK,
  Flags.DISABLE_COLORING,
  Flags.MERGE_ALGORITHM_SECTIONS,
  Flags.WARN_NO_NOMINAL,
  Flags.REDUCE_DAE,
  Flags.IGNORE_CYCLES,
  Flags.ALIAS_CONFLICTS,
  Flags.SUSAN_MATCHCONTINUE_DEBUG,
  Flags.OLD_FE_UNITCHECK,
  Flags.EXEC_STAT_EXTRA_GC,
  Flags.DEBUG_DAEMODE,
  Flags.NF_SCALARIZE,
  Flags.NF_EVAL_CONST_ARG_FUNCS,
  Flags.NF_EXPAND_OPERATIONS,
  Flags.NF_API,
  Flags.NF_API_DYNAMIC_SELECT,
  Flags.NF_API_NOISE,
  Flags.FMI20_DEPENDENCIES,
  Flags.WARNING_MINMAX_ATTRIBUTES,
  Flags.NF_EXPAND_FUNC_ARGS,
  Flags.DUMP_JL,
  Flags.DUMP_ASSC,
  Flags.SPLIT_CONSTANT_PARTS_SYMJAC,
  Flags.DUMP_FORCE_FMI_ATTRIBUTES,
  Flags.DUMP_DATARECONCILIATION,
  Flags.ARRAY_CONNECT,
  Flags.COMBINE_SUBSCRIPTS,
  Flags.ZMQ_LISTEN_TO_ALL,
  Flags.DUMP_CONVERSION_RULES,
  Flags.PRINT_RECORD_TYPES,
  Flags.DUMP_SIMPLIFY,
  Flags.DUMP_BACKEND_CLOCKS,
  Flags.DUMP_SET_BASED_GRAPHS,
  Flags.MERGE_COMPONENTS,
  Flags.DUMP_SLICE,
  Flags.VECTORIZE_BINDINGS,
  Flags.DUMP_EVENTS,
  Flags.DUMP_RESIZABLE,
  Flags.DUMP_SOLVE,
  Flags.FORCE_SCALARIZE
};

protected
// This is a list of all configuration flags. A flag can not be used unless it's
// in this list, and the list is checked at initialization so that all flags are
// sorted by index (and thus have unique indices).
constant list<Flags.ConfigFlag> allConfigFlags = {
  Flags.DEBUG,
  Flags.HELP,
  Flags.RUNNING_TESTSUITE,
  Flags.SHOW_VERSION,
  Flags.TARGET,
  Flags.GRAMMAR,
  Flags.ANNOTATION_VERSION,
  Flags.LANGUAGE_STANDARD,
  Flags.SHOW_ERROR_MESSAGES,
  Flags.SHOW_ANNOTATIONS,
  Flags.NO_SIMPLIFY,
  Flags.PRE_OPT_MODULES,
  Flags.CHEAPMATCHING_ALGORITHM,
  Flags.MATCHING_ALGORITHM,
  Flags.INDEX_REDUCTION_METHOD,
  Flags.POST_OPT_MODULES,
  Flags.SIMCODE_TARGET,
  Flags.ORDER_CONNECTIONS,
  Flags.TYPE_INFO,
  Flags.KEEP_ARRAYS,
  Flags.MODELICA_OUTPUT,
  Flags.SILENT,
  Flags.CORBA_SESSION,
  Flags.NUM_PROC,
  Flags.INST_CLASS,
  Flags.VECTORIZATION_LIMIT,
  Flags.SIMULATION_CG,
  Flags.EVAL_PARAMS_IN_ANNOTATIONS,
  Flags.CHECK_MODEL,
  Flags.CEVAL_EQUATION,
  Flags.UNIT_CHECKING,
  Flags.GENERATE_LABELED_SIMCODE,
  Flags.REDUCE_TERMS,
  Flags.REDUCTION_METHOD,
  Flags.DEMO_MODE,
  Flags.LOCALE_FLAG,
  Flags.DEFAULT_OPENCL_DEVICE,
  Flags.MAXTRAVERSALS,
  Flags.DUMP_TARGET,
  Flags.DELAY_BREAK_LOOP,
  Flags.TEARING_METHOD,
  Flags.TEARING_HEURISTIC,
  Flags.SCALARIZE_MINMAX,
  Flags.STRICT,
  Flags.SCALARIZE_BINDINGS,
  Flags.CORBA_OBJECT_REFERENCE_FILE_PATH,
  Flags.HPCOM_SCHEDULER,
  Flags.HPCOM_CODE,
  Flags.REWRITE_RULES_FILE,
  Flags.REPLACE_HOMOTOPY,
  Flags.GENERATE_DYNAMIC_JACOBIAN,
  Flags.GENERATE_SYMBOLIC_LINEARIZATION,
  Flags.INT_ENUM_CONVERSION,
  Flags.PROFILING_LEVEL,
  Flags.RESHUFFLE,
  Flags.GENERATE_DYN_OPTIMIZATION_PROBLEM,
  Flags.MAX_SIZE_FOR_SOLVE_LINIEAR_SYSTEM,
  Flags.CPP_FLAGS,
  Flags.REMOVE_SIMPLE_EQUATIONS,
  Flags.DYNAMIC_TEARING,
  Flags.SYM_SOLVER,
  Flags.LOOP2CON,
  Flags.FORCE_TEARING,
  Flags.SIMPLIFY_LOOPS,
  Flags.RTEARING,
  Flags.FLOW_THRESHOLD,
  Flags.MATRIX_FORMAT,
  Flags.PARTLINTORN,
  Flags.INIT_OPT_MODULES,
  Flags.MAX_MIXED_DETERMINED_INDEX,
  Flags.USE_LOCAL_DIRECTION,
  Flags.DEFAULT_OPT_MODULES_ORDERING,
  Flags.PRE_OPT_MODULES_ADD,
  Flags.PRE_OPT_MODULES_SUB,
  Flags.POST_OPT_MODULES_ADD,
  Flags.POST_OPT_MODULES_SUB,
  Flags.INIT_OPT_MODULES_ADD,
  Flags.INIT_OPT_MODULES_SUB,
  Flags.PERMISSIVE,
  Flags.HETS,
  Flags.DEFAULT_CLOCK_PERIOD,
  Flags.INST_CACHE_SIZE,
  Flags.MAX_SIZE_LINEAR_TEARING,
  Flags.MAX_SIZE_NONLINEAR_TEARING,
  Flags.NO_TEARING_FOR_COMPONENT,
  Flags.CT_STATE_MACHINES,
  Flags.DAE_MODE,
  Flags.INLINE_METHOD,
  Flags.SET_TEARING_VARS,
  Flags.SET_RESIDUAL_EQNS,
  Flags.IGNORE_COMMAND_LINE_OPTIONS_ANNOTATION,
  Flags.CALCULATE_SENSITIVITIES,
  Flags.ALARM,
  Flags.TOTAL_TEARING,
  Flags.IGNORE_SIMULATION_FLAGS_ANNOTATION,
  Flags.DYNAMIC_TEARING_FOR_INITIALIZATION,
  Flags.PREFER_TVARS_WITH_START_VALUE,
  Flags.EQUATIONS_PER_FILE,
  Flags.EVALUATE_FINAL_PARAMS,
  Flags.EVALUATE_PROTECTED_PARAMS,
  Flags.REPLACE_EVALUATED_PARAMS,
  Flags.CONDENSE_ARRAYS,
  Flags.WFC_ADVANCED,
  Flags.GRAPHICS_EXP_MODE,
  Flags.TEARING_STRICTNESS,
  Flags.INTERACTIVE,
  Flags.ZEROMQ_FILE_SUFFIX,
  Flags.HOMOTOPY_APPROACH,
  Flags.IGNORE_REPLACEABLE,
  Flags.LABELED_REDUCTION,
  Flags.DISABLE_EXTRA_LABELING,
  Flags.LOAD_MSL_MODEL,
  Flags.LOAD_PACKAGE_FILE,
  Flags.BUILDING_FMU,
  Flags.BUILDING_MODEL,
  Flags.POST_OPT_MODULES_DAE,
  Flags.EVAL_LOOP_LIMIT,
  Flags.EVAL_RECURSION_LIMIT,
  Flags.SINGLE_INSTANCE_AGLSOLVER,
  Flags.SHOW_STRUCTURAL_ANNOTATIONS,
  Flags.INITIAL_STATE_SELECTION,
  Flags.LINEARIZATION_DUMP_LANGUAGE,
  Flags.NO_ASSC,
  Flags.FULL_ASSC,
  Flags.REAL_ASSC,
  Flags.INIT_ASSC,
  Flags.MAX_SIZE_ASSC,
  Flags.USE_ZEROMQ_IN_SIM,
  Flags.ZEROMQ_PUB_PORT,
  Flags.ZEROMQ_SUB_PORT,
  Flags.ZEROMQ_JOB_ID,
  Flags.ZEROMQ_SERVER_ID,
  Flags.ZEROMQ_CLIENT_ID,
  Flags.FMI_VERSION,
  Flags.BASE_MODELICA,
  Flags.FMI_FILTER,
  Flags.FMI_SOURCES,
  Flags.FMI_FLAGS,
  Flags.FMU_CMAKE_BUILD,
  Flags.NEW_BACKEND,
  Flags.PARMODAUTO,
  Flags.INTERACTIVE_PORT,
  Flags.ALLOW_NON_STANDARD_MODELICA,
  Flags.EXPORT_CLOCKS_IN_MODELDESCRIPTION,
  Flags.LINK_TYPE,
  Flags.TEARING_ALWAYS_DERIVATIVES,
  Flags.DUMP_FLAT_MODEL,
  Flags.SIMULATION,
  Flags.OBFUSCATE,
  Flags.FMU_RUNTIME_DEPENDS,
  Flags.FRONTEND_INLINE,
  Flags.EXPOSE_LOCAL_IOS,
  Flags.BASE_MODELICA_FORMAT,
  Flags.BASE_MODELICA_OPTIONS,
  Flags.DEBUG_FOLLOW_EQUATIONS,
  Flags.MAX_SIZE_LINEARIZATION,
  Flags.RESIZABLE_ARRAYS,
  Flags.EVALUATE_STRUCTURAL_PARAMETERS,
  Flags.LOAD_MISSING_LIBRARIES,
  Flags.CAUSALIZE_DAE_MODE,
  Flags.SIM_CODE_SCALARIZE
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
  input Flags.Flag inFlags;
algorithm
  setGlobalRoot(Global.flagsIndex, inFlags);
end saveFlags;

protected function createConfigFlags
  output array<Flags.FlagData> configFlags;
algorithm
  configFlags := listArray(list(flag.defaultValue for flag in allConfigFlags));
end createConfigFlags;

protected function createDebugFlags
  output array<Boolean> debugFlags;
algorithm
  debugFlags := listArray(list(flag.default for flag in allDebugFlags));
end createDebugFlags;

public function loadFlags
  "Loads the flags with getGlobalRoot. Creates a new flags structure if it
   hasn't been created yet."
  input Boolean initialize = true;
  output Flags.Flag flags;
algorithm
  try
    flags := Flags.getFlags();
  else
    if initialize then
      checkDebugFlags();
      checkConfigFlags();
      flags := Flags.FLAGS(createDebugFlags(), createConfigFlags());
      saveFlags(flags);
    else
      print("Flag loading failed!\n");
      flags := Flags.NO_FLAGS();
    end if;
  end try;
end loadFlags;

public function backupFlags
  "Creates a copy of the existing flags."
  output Flags.Flag outFlags;
protected
  array<Boolean> debug_flags;
  array<Flags.FlagData> config_flags;
algorithm
  Flags.FLAGS(debug_flags, config_flags) := loadFlags();
  outFlags := Flags.FLAGS(arrayCopy(debug_flags), arrayCopy(config_flags));
end backupFlags;

public function resetDebugFlags
  "Resets all debug flags to their default values."
protected
  array<Boolean> debug_flags;
  array<Flags.FlagData> config_flags;
algorithm
  Flags.FLAGS(_, config_flags) := loadFlags();
  debug_flags := createDebugFlags();
  saveFlags(Flags.FLAGS(debug_flags, config_flags));
end resetDebugFlags;

public function resetConfigFlags
  "Resets all configuration flags to their default values."
protected
  array<Boolean> debug_flags;
  array<Flags.FlagData> config_flags;
algorithm
  Flags.FLAGS(debug_flags, _) := loadFlags();
  config_flags := createConfigFlags();
  saveFlags(Flags.FLAGS(debug_flags, config_flags));
end resetConfigFlags;

protected function checkDebugFlags
  "Checks that the flags listed in allDebugFlags have sequential and unique indices."
protected
  Integer index = 0;
  String err_str;
algorithm
  for flag in allDebugFlags loop
    index := index + 1;

    // If the flag indices are borked, print an error and terminate the compiler.
    // Only failing here could cause an infinite loop of trying to load the flags.
    if flag.index <> index then
      err_str := "Invalid flag '" + flag.name + "' with index " + String(flag.index) + " (expected " + String(index) +
        ") in Flags.allDebugFlags. Make sure that all flags are present and ordered correctly!";
      Error.terminateError(err_str, sourceInfo());
    end if;
  end for;
end checkDebugFlags;

protected function checkConfigFlags
  "Checks that the flags listed in allConfigFlags have sequential and unique indices."
protected
  Integer index = 0;
  String err_str;
algorithm
  for flag in allConfigFlags loop
    index := index + 1;

    // If the flag indices are borked, print an error and terminate the compiler.
    // Only failing here could cause an infinite loop of trying to load the flags.
    if flag.index <> index then
      err_str := "Invalid flag '" + flag.name + "' with index " + String(flag.index) + " (expected " + String(index) +
        ") in Flags.allConfigFlags. Make sure that all flags are present and ordered correctly!";
      Error.terminateError(err_str, sourceInfo());
    end if;
  end for;
end checkConfigFlags;

public function set
  "Sets the value of a debug flag, and returns the old value."
  input Flags.DebugFlag inFlag;
  input Boolean inValue;
  output Boolean outOldValue;
protected
  array<Boolean> debug_flags;
  array<Flags.FlagData> config_flags;
algorithm
  Flags.FLAGS(debug_flags, config_flags) := loadFlags();
  (debug_flags, outOldValue) := updateDebugFlagArray(debug_flags, inValue, inFlag);
  saveFlags(Flags.FLAGS(debug_flags, config_flags));
end set;

public function enableDebug
  "Enables a debug flag."
  input Flags.DebugFlag inFlag;
  output Boolean outOldValue;
algorithm
  outOldValue := set(inFlag, true);
end enableDebug;

public function disableDebug
  "Disables a debug flag."
  input Flags.DebugFlag inFlag;
  output Boolean outOldValue;
algorithm
  outOldValue := set(inFlag, false);
end disableDebug;


function getConfigOptionsStringList
  "Returns the valid options of a single-string configuration flag."
  input Flags.ConfigFlag inFlag;
  output list<String> outOptions;
  output list<String> outComments;
algorithm
  (outOptions,outComments) := match inFlag
    local
      list<tuple<String, Gettext.TranslatableContent>> options;
      list<String> flags;
    case Flags.CONFIG_FLAG(validOptions=SOME(Flags.STRING_DESC_OPTION(options)))
      then (List.map(options,Util.tuple21),List.mapMap(options, Util.tuple22, Gettext.translateContent));
    case Flags.CONFIG_FLAG(validOptions=SOME(Flags.STRING_OPTION(flags)))
      then (flags,List.fill("",listLength(flags)));
  end match;
end getConfigOptionsStringList;

protected function updateDebugFlagArray
  "Updates the value of a debug flag in the debug flag array."
  input array<Boolean> inFlags;
  input Boolean inValue;
  input Flags.DebugFlag inFlag;
  output array<Boolean> outFlags;
  output Boolean outOldValue;
protected
  Integer index;
algorithm
  Flags.DEBUG_FLAG(index = index) := inFlag;
  outOldValue := arrayGet(inFlags, index);
  outFlags := arrayUpdate(inFlags, index, inValue);
end updateDebugFlagArray;

protected function updateConfigFlagArray
  "Updates the value of a configuration flag in the configuration flag array."
  input array<Flags.FlagData> inFlags;
  input Flags.FlagData inValue;
  input Flags.ConfigFlag inFlag;
  output array<Flags.FlagData> outFlags;
protected
  Integer index;
algorithm
  Flags.CONFIG_FLAG(index = index) := inFlag;
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
  Flags.Flag flags;
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
  _ := List.map2(outArgs, System.iconv, "UTF-8", "UTF-8");
  Error.assertionOrAddSourceMessage(numError == Error.getNumErrorMessages(), Error.UTF8_COMMAND_LINE_ARGS, {}, Util.dummyInfo);
  saveFlags(flags);

  // after reading all flags, handle the deprecated ones
  handleDeprecatedFlags();
end readArgs;

protected function readArg
  "Reads a single command line argument. Returns true if the argument was
  consumed, otherwise false."
  input String inArg;
  input Flags.Flag inFlags;
  output Boolean outConsumed;
protected
  String flagtype;
  Integer len;
algorithm
  flagtype := stringGetStringChar(inArg, 1);
  len := stringLength(inArg);

  // Flags beginning with + can be both short and long, i.e. +h or +help.
  if flagtype == "+" then
    if len == 1 then
      // + alone is not a valid flag.
      parseFlag(inArg, Flags.NO_FLAGS());
    else
      parseFlag(System.substring(inArg, 2, len), inFlags, flagtype);
    end if;
    outConsumed := true;
  // Flags beginning with - must have another - for long flags, i.e. -h or --help.
  elseif flagtype == "-" then
    if len == 1 then
      // - alone is not a valid flag.
      parseFlag(inArg, Flags.NO_FLAGS());
    elseif len == 2 then
      // Short flag without argument, i.e. -h.
      parseFlag(System.substring(inArg, 2, 2), inFlags, flagtype);
    elseif stringGetStringChar(inArg, 2) == "-" then
      if len < 4 or stringGetStringChar(inArg, 4) == "=" then
        // Short flags may not be used with --, i.e. --h or --h=debug.
        parseFlag(inArg, Flags.NO_FLAGS());
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
        parseFlag(inArg, Flags.NO_FLAGS());
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
  input Flags.Flag inFlags;
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
  input Flags.Flag inFlags;
  input String inFlagPrefix;
protected
  Flags.ConfigFlag config_flag;
algorithm
  config_flag := lookupConfigFlag(inFlag, inFlagPrefix);
  evaluateConfigFlag(config_flag, inValues, inFlags);
end parseConfigFlag;

protected function lookupConfigFlag
  "Lookup up the flag with the given name in the list of configuration flags."
  input String inFlag;
  input String inFlagPrefix;
  output Flags.ConfigFlag outFlag;
algorithm
  try
    outFlag := List.getMemberOnTrue(inFlag, allConfigFlags, matchConfigFlag);
  else
    Error.addMessage(Error.UNKNOWN_OPTION, {inFlagPrefix + inFlag});
    fail();
  end try;
end lookupConfigFlag;

protected function configFlagEq
  input Flags.ConfigFlag inFlag1;
  input Flags.ConfigFlag inFlag2;
  output Boolean eq;
algorithm
  eq := match(inFlag1, inFlag2)
    local
      Integer index1, index2;
    case(Flags.CONFIG_FLAG(index=index1), Flags.CONFIG_FLAG(index=index2))
    then index1 == index2;
  end match;
end configFlagEq;

protected function setAdditionalOptModules
  input Flags.ConfigFlag inFlag;
  input Flags.ConfigFlag inOppositeFlag;
  input list<String> inValues;
protected
  list<String> values;
algorithm
  for value in inValues loop
    // remove value from inOppositeFlag
    values := Flags.getConfigStringList(inOppositeFlag);
    values := List.removeOnTrue(value, stringEq, values);
    setConfigStringList(inOppositeFlag, values);

    // add value to inFlag
    values := Flags.getConfigStringList(inFlag);
    values := List.removeOnTrue(value, stringEq, values);
    setConfigStringList(inFlag, value::values);
  end for;
end setAdditionalOptModules;

protected function evaluateConfigFlag
  "Evaluates a given flag and it's arguments."
  input Flags.ConfigFlag inFlag;
  input list<String> inValues;
  input Flags.Flag inFlags;
algorithm
  _ := match(inFlag, inFlags)
    local
      array<Boolean> debug_flags;
      array<Flags.FlagData> config_flags;
      list<String> values;

    // Special case for +d, +debug, set the given debug flags.
    case (Flags.CONFIG_FLAG(index = 1), Flags.FLAGS(debugFlags = debug_flags))
      equation
        List.map1_0(inValues, setDebugFlag, debug_flags);
      then
        ();

    // Special case for +h, +help, show help text.
    case (Flags.CONFIG_FLAG(index = 2), _)
      equation
        values = List.map(inValues, System.tolower);
        System.gettextInit(if Flags.getConfigString(Flags.RUNNING_TESTSUITE) == "" then Flags.getConfigString(Flags.LOCALE_FLAG) else "C");
        print(printHelp(values));
        setConfigString(Flags.HELP, "omc");
      then
        ();

    // Special case for --preOptModules+=<value>
    case (_, _) guard(configFlagEq(inFlag, Flags.PRE_OPT_MODULES_ADD))
      equation
        setAdditionalOptModules(Flags.PRE_OPT_MODULES_ADD, Flags.PRE_OPT_MODULES_SUB, inValues);
      then
        ();

    // Special case for --preOptModules-=<value>
    case (_, _) guard(configFlagEq(inFlag, Flags.PRE_OPT_MODULES_SUB))
      equation
        setAdditionalOptModules(Flags.PRE_OPT_MODULES_SUB, Flags.PRE_OPT_MODULES_ADD, inValues);
      then
        ();

    // Special case for --postOptModules+=<value>
    case (_, _) guard(configFlagEq(inFlag, Flags.POST_OPT_MODULES_ADD))
      equation
        setAdditionalOptModules(Flags.POST_OPT_MODULES_ADD, Flags.POST_OPT_MODULES_SUB, inValues);
      then
        ();

    // Special case for --postOptModules-=<value>
    case (_, _) guard(configFlagEq(inFlag, Flags.POST_OPT_MODULES_SUB))
      equation
        setAdditionalOptModules(Flags.POST_OPT_MODULES_SUB, Flags.POST_OPT_MODULES_ADD, inValues);
      then
        ();

    // Special case for --initOptModules+=<value>
    case (_, _) guard(configFlagEq(inFlag, Flags.INIT_OPT_MODULES_ADD))
      equation
        setAdditionalOptModules(Flags.INIT_OPT_MODULES_ADD, Flags.INIT_OPT_MODULES_SUB, inValues);
      then
        ();

    // Special case for --initOptModules-=<value>
    case (_, _) guard(configFlagEq(inFlag, Flags.INIT_OPT_MODULES_SUB))
      equation
        setAdditionalOptModules(Flags.INIT_OPT_MODULES_SUB, Flags.INIT_OPT_MODULES_ADD, inValues);
      then
        ();

    // All other configuration flags, set the flag to the given values.
    case (_, Flags.FLAGS(configFlags = config_flags))
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
  flag_str := if negated then StringUtil.rest(inFlag) else inFlag;
  flag_str := if neg2 then StringUtil.rest(flag_str) else flag_str;
  setDebugFlag2(flag_str, not negated, inFlags);
end setDebugFlag;

protected function setDebugFlag2
  input String inFlag;
  input Boolean inValue;
  input array<Boolean> inFlags;
algorithm
  _ := matchcontinue(inFlag, inValue, inFlags)
    local
      Flags.DebugFlag flag;

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
  input Flags.DebugFlag inFlag;
  output Boolean outMatches;
protected
  String name;
algorithm
  Flags.DEBUG_FLAG(name = name) := inFlag;
  outMatches := stringEq(inFlagName, name);
end matchDebugFlag;

protected function matchConfigFlag
  "Returns true if the given flag has the given name, otherwise false."
  input String inFlagName;
  input Flags.ConfigFlag inFlag;
  output Boolean outMatches;
protected
  Option<String> opt_shortname;
  String name, shortname;
algorithm
  // A configuration flag may have two names, one long and one short.
  Flags.CONFIG_FLAG(name = name, shortname = opt_shortname) := inFlag;
  shortname := Util.getOptionOrDefault(opt_shortname, "");
  outMatches := stringEq(inFlagName, shortname) or
                stringEq(System.tolower(inFlagName), System.tolower(name));
end matchConfigFlag;

protected function setConfigFlag
  "Sets the value of a configuration flag, where the value is given as a list of
  strings."
  input Flags.ConfigFlag inFlag;
  input array<Flags.FlagData> inConfigData;
  input list<String> inValues;
protected
  Flags.FlagData data, default_value;
  String name;
  Option<Flags.ValidOptions> validOptions;
algorithm
  Flags.CONFIG_FLAG(name = name, defaultValue = default_value, validOptions = validOptions) := inFlag;
  data := stringFlagData(inValues, default_value, validOptions, name);
  _ := updateConfigFlagArray(inConfigData, data, inFlag);
end setConfigFlag;

protected function stringFlagData
  "Converts a list of strings into a FlagData value. The expected type is also
   given so that the value can be typechecked."
  input list<String> inValues;
  input Flags.FlagData inExpectedType;
  input Option<Flags.ValidOptions> validOptions;
  input String inName;
  output Flags.FlagData outValue;
algorithm
  outValue := matchcontinue(inValues, inExpectedType, validOptions, inName)
    local
      Boolean b;
      Integer i;
      list<Integer> ilst;
      String s, et, at;
      list<tuple<String, Integer>> enums;
      list<String> flags, slst;
      Flags.ValidOptions options;

    // A boolean value.
    case ({s}, Flags.BOOL_FLAG(), _, _)
      equation
        b = Util.stringBool(s);
      then
        Flags.BOOL_FLAG(b);

    // No value, but a boolean flag => enable the flag.
    case ({}, Flags.BOOL_FLAG(), _, _) then Flags.BOOL_FLAG(true);

    // An integer value.
    case ({s}, Flags.INT_FLAG(), _, _)
      equation
        i = stringInt(s);
        true = stringEq(intString(i), s);
      then
        Flags.INT_FLAG(i);

    // integer list.
    case (slst, Flags.INT_LIST_FLAG(), _, _)
      equation
        ilst = List.map(slst,stringInt);
      then
        Flags.INT_LIST_FLAG(ilst);

    // A real value.
    case ({s}, Flags.REAL_FLAG(), _, _)
      then Flags.REAL_FLAG(System.stringReal(s));

    // A string value.
    case ({s}, Flags.STRING_FLAG(), SOME(options), _)
      equation
        flags = getValidStringOptions(options);
        true = listMember(s,flags);
      then Flags.STRING_FLAG(s);
    case ({s}, Flags.STRING_FLAG(), NONE(), _) then Flags.STRING_FLAG(s);

    // A multiple-string value.
    case (_, Flags.STRING_LIST_FLAG(), _, _) then Flags.STRING_LIST_FLAG(inValues);

    // An enumeration value.
    case ({s}, Flags.ENUM_FLAG(validValues = enums), _, _)
      equation
        i = Util.assoc(s, enums);
      then
        Flags.ENUM_FLAG(i, enums);

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
  input Flags.FlagData inType;
  output String outTypeStr;
algorithm
  outTypeStr := match(inType)
    local
      list<tuple<String, Integer>> enums;
      list<String> enum_strs;

    case Flags.BOOL_FLAG() then "a boolean value";
    case Flags.INT_FLAG() then "an integer value";
    case Flags.REAL_FLAG() then "a floating-point value";
    case Flags.STRING_FLAG() then "a string";
    case Flags.STRING_LIST_FLAG() then "a comma-separated list of strings";
    case Flags.ENUM_FLAG(validValues = enums)
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
  input Flags.ConfigFlag inFlag1;
  input Flags.ConfigFlag inFlag2;
  output Boolean outEqualIndex;
protected
  Integer index1, index2;
algorithm
  Flags.CONFIG_FLAG(index = index1) := inFlag1;
  Flags.CONFIG_FLAG(index = index2) := inFlag2;
  outEqualIndex := intEq(index1, index2);
end configFlagsIsEqualIndex;

protected function handleDeprecatedFlags
  "Gives warnings when deprecated flags are used. Sets newer flags if
   appropriate."
protected
  list<String> remaining_flags;
algorithm
  // At some point in the future remove all these flags and do the checks in
  // parseConfigFlag or something like that...

  // DEBUG FLAGS
  if Flags.isSet(Flags.NF_UNITCHECK) then
    disableDebug(Flags.NF_UNITCHECK);
    setConfigBool(Flags.UNIT_CHECKING, true);
    Error.addMessage(Error.DEPRECATED_FLAG, {"-d=frontEndUnitCheck", "--unitChecking"});
  end if;
  if Flags.isSet(Flags.OLD_FE_UNITCHECK) then
    disableDebug(Flags.OLD_FE_UNITCHECK);
    setConfigBool(Flags.UNIT_CHECKING, true);
    Error.addMessage(Error.DEPRECATED_FLAG, {"-d=oldFrontEndUnitCheck", "--unitChecking"});
  end if;
  if Flags.isSet(Flags.INTERACTIVE_TCP) then
    disableDebug(Flags.INTERACTIVE_TCP);
    setConfigString(Flags.INTERACTIVE, "tcp");
    Error.addMessage(Error.DEPRECATED_FLAG, {"-d=interactive", "--interactive=tcp"});
    // The error message might get lost, so also print it directly here.
    print("The flag -d=interactive is depreciated. Please use --interactive=tcp instead.\n");
  end if;
  if Flags.isSet(Flags.INTERACTIVE_CORBA) then
    disableDebug(Flags.INTERACTIVE_CORBA);
    setConfigString(Flags.INTERACTIVE, "corba");
    Error.addMessage(Error.DEPRECATED_FLAG, {"-d=interactiveCorba", "--interactive=corba"});
    // The error message might get lost, so also print it directly here.
    print("The flag -d=interactiveCorba is depreciated. Please use --interactive=corba instead.\n");
  end if;
  // add other deprecated flags here...

  // CONFIG_FLAGS
  if Flags.getConfigString(Flags.TEARING_METHOD) == "noTearing" then
    setConfigString(Flags.TEARING_METHOD, "minimalTearing");
    Error.addMessage(Error.DEPRECATED_FLAG, {"--tearingMethod=noTearing", "--tearingMethod=minimalTearing"});
  end if;
  remaining_flags := {};
  for flag in Flags.getConfigStringList(Flags.PRE_OPT_MODULES) loop
    if flag == "unitChecking" then
      setConfigBool(Flags.UNIT_CHECKING, true);
      Error.addMessage(Error.DEPRECATED_FLAG, {"--preOptModules=unitChecking", "--unitChecking"});
    //elseif flag ==
    // add other deprecated flags here...
    else
      remaining_flags := flag :: remaining_flags;
    end if;
  end for;
  setConfigStringList(Flags.PRE_OPT_MODULES, listReverse(remaining_flags));
  remaining_flags := {};
  for flag in Flags.getConfigStringList(Flags.PRE_OPT_MODULES_ADD) loop
    if flag == "unitChecking" then
      setConfigBool(Flags.UNIT_CHECKING, true);
      Error.addMessage(Error.DEPRECATED_FLAG, {"--preOptModules+=unitChecking", "--unitChecking"});
    //elseif flag ==
    // add other deprecated flags here...
    else
      remaining_flags := flag :: remaining_flags;
    end if;
  end for;
  setConfigStringList(Flags.PRE_OPT_MODULES_ADD, listReverse(remaining_flags));
  // add other deprecated flags here...
end handleDeprecatedFlags;

protected function applySideEffects
  "Some flags have side effects, which are handled by this function."
  input Flags.ConfigFlag inFlag;
  input Flags.FlagData inValue;
algorithm
  _ := matchcontinue(inFlag, inValue)
    local
      Boolean value;
      String corba_name, corba_objid_path, zeroMQFileSuffix;

    // +showErrorMessages needs to be sent to the C runtime.
    case (_, _)
      equation
        true = configFlagsIsEqualIndex(inFlag, Flags.SHOW_ERROR_MESSAGES);
        Flags.BOOL_FLAG(data = value) = inValue;
        ErrorExt.setShowErrorMessages(value);
      then
        ();

    // The corba object reference file path needs to be sent to the C runtime.
    case (_, _)
      equation
        true = configFlagsIsEqualIndex(inFlag, Flags.CORBA_OBJECT_REFERENCE_FILE_PATH);
        Flags.STRING_FLAG(data = corba_objid_path) = inValue;
        Corba.setObjectReferenceFilePath(corba_objid_path);
      then
        ();

    // The corba session name needs to be sent to the C runtime.
    case (_, _)
      equation
        true = configFlagsIsEqualIndex(inFlag, Flags.CORBA_SESSION);
        Flags.STRING_FLAG(data = corba_name) = inValue;
        Corba.setSessionName(corba_name);
      then
        ();

    else ();
  end matchcontinue;
end applySideEffects;

public function setConfigValue
  "Sets the value of a configuration flag."
  input Flags.ConfigFlag inFlag;
  input Flags.FlagData inValue;
protected
  array<Boolean> debug_flags;
  array<Flags.FlagData> config_flags;
  Flags.Flag flags;
algorithm
  flags := loadFlags();
  Flags.FLAGS(debug_flags, config_flags) := flags;
  config_flags := updateConfigFlagArray(config_flags, inValue, inFlag);
  saveFlags(Flags.FLAGS(debug_flags, config_flags));
end setConfigValue;

public function setConfigBool
  "Sets the value of a boolean configuration flag."
  input Flags.ConfigFlag inFlag;
  input Boolean inValue;
algorithm
  setConfigValue(inFlag, Flags.BOOL_FLAG(inValue));
end setConfigBool;

public function setConfigInt
  "Sets the value of an integer configuration flag."
  input Flags.ConfigFlag inFlag;
  input Integer inValue;
algorithm
  setConfigValue(inFlag, Flags.INT_FLAG(inValue));
end setConfigInt;

public function setConfigReal
  "Sets the value of a real configuration flag."
  input Flags.ConfigFlag inFlag;
  input Real inValue;
algorithm
  setConfigValue(inFlag, Flags.REAL_FLAG(inValue));
end setConfigReal;

public function setConfigString
  "Sets the value of a string configuration flag."
  input Flags.ConfigFlag inFlag;
  input String inValue;
algorithm
  setConfigValue(inFlag, Flags.STRING_FLAG(inValue));
end setConfigString;

public function setConfigStringList
  "Sets the value of a multiple-string configuration flag."
  input Flags.ConfigFlag inFlag;
  input list<String> inValue;
algorithm
  setConfigValue(inFlag, Flags.STRING_LIST_FLAG(inValue));
end setConfigStringList;

public function setConfigEnum
  "Sets the value of an enumeration configuration flag."
  input Flags.ConfigFlag inFlag;
  input Integer inValue;
protected
  list<tuple<String, Integer>> valid_values;
algorithm
  Flags.CONFIG_FLAG(defaultValue = Flags.ENUM_FLAG(validValues = valid_values)) := inFlag;
  setConfigValue(inFlag, Flags.ENUM_FLAG(inValue, valid_values));
end setConfigEnum;

// Used by the print functions below to indent descriptions.
protected constant String descriptionIndent = "                            ";

public function printHelp
  "Prints out help for the given list of topics."
  input list<String> inTopics;
  output String help;
algorithm
  help := matchcontinue (inTopics)
    local
      Gettext.TranslatableContent desc;
      list<String> rest_topics, strs, data;
      String str,name,str1,str1a,str1b,str2,str3,str3a,str3b,str4,str5,str5a,str5b,str6,str7,str7a,str7b,str8,str9,str9a,str9b,str10;
      Flags.ConfigFlag config_flag;
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
        Flags.CONFIG_FLAG(defaultValue=Flags.STRING_LIST_FLAG(data=data)) = Flags.PRE_OPT_MODULES;
        str1a = System.gettext("The modules used by default are:") + "\n--preOptModules=" + stringDelimitList(data, ",");
        str1b = System.gettext("The valid modules are:");
        str2 = printFlagValidOptionsDesc(Flags.PRE_OPT_MODULES);

        // matching
        str3 = System.gettext("The --matchingAlgorithm sets the method that is used for the matching algorithm, after the pre optimization modules.");
        str3 = stringAppendList(StringUtil.wordWrap(str3,System.getTerminalWidth(),"\n"));
        Flags.CONFIG_FLAG(defaultValue=Flags.STRING_FLAG(data=str3a)) = Flags.MATCHING_ALGORITHM;
        str3a = System.gettext("The method used by default is:") + "\n--matchingAlgorithm=" + str3a;
        str3b = System.gettext("The valid methods are:");
        str4 = printFlagValidOptionsDesc(Flags.MATCHING_ALGORITHM);

        // index reduction
        str5 = System.gettext("The --indexReductionMethod sets the method that is used for the index reduction, after the pre optimization modules.");
        str5 = stringAppendList(StringUtil.wordWrap(str5,System.getTerminalWidth(),"\n"));
        Flags.CONFIG_FLAG(defaultValue=Flags.STRING_FLAG(data=str5a)) = Flags.INDEX_REDUCTION_METHOD;
        str5a = System.gettext("The method used by default is:") + "\n--indexReductionMethod=" + str5a;
        str5b = System.gettext("The valid methods are:");
        str6 = printFlagValidOptionsDesc(Flags.INDEX_REDUCTION_METHOD);

        // post-optimization (initialization)
        str7 = System.gettext("The --initOptModules then sets the optimization modules which are used after the index reduction to optimize the system for initialization, specified as a comma-separated list.");
        str7 = stringAppendList(StringUtil.wordWrap(str7,System.getTerminalWidth(),"\n"));
        Flags.CONFIG_FLAG(defaultValue=Flags.STRING_LIST_FLAG(data=data)) = Flags.INIT_OPT_MODULES;
        str7a = System.gettext("The modules used by default are:") + "\n--initOptModules=" + stringDelimitList(data, ",");
        str7b = System.gettext("The valid modules are:");
        str8 = printFlagValidOptionsDesc(Flags.INIT_OPT_MODULES);

        // post-optimization (simulation)
        str9 = System.gettext("The --postOptModules then sets the optimization modules which are used after the index reduction to optimize the system for simulation, specified as a comma-separated list.");
        str9 = stringAppendList(StringUtil.wordWrap(str9,System.getTerminalWidth(),"\n"));
        Flags.CONFIG_FLAG(defaultValue=Flags.STRING_LIST_FLAG(data=data)) = Flags.POST_OPT_MODULES;
        str9a = System.gettext("The modules used by default are:") + "\n--postOptModules=" + stringDelimitList(data, ",");
        str9b = System.gettext("The valid modules are:");
        str10 = printFlagValidOptionsDesc(Flags.POST_OPT_MODULES);

        help = stringAppendList({str1,"\n\n",str1a,"\n\n",str1b,"\n",str2,"\n",str3,"\n\n",str3a,"\n\n",str3b,"\n",str4,"\n",str5,"\n\n",str5a,"\n\n",str5b,"\n",str6,"\n",str7,"\n\n",str7a,"\n\n",str7b,"\n",str8,"\n",str9,"\n\n",str9a,"\n\n",str9b,"\n",str10,"\n"});
      then help;

    case {str}
      equation
        (config_flag as Flags.CONFIG_FLAG(name=name,description=desc)) = List.getMemberOnTrue(str, allConfigFlags, matchConfigFlag);
        str1 = "-" + name;
        str2 = stringAppendList(StringUtil.wordWrap(Gettext.translateContent(desc), System.getTerminalWidth(), "\n"));
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
  Flags.ValidOptions validOptions;
  Gettext.TranslatableContent mainDescription;
algorithm
  Flags.CONFIG_FLAG(description=mainDescription,validOptions=SOME(validOptions)) := List.getMemberOnTrue(flagName, allConfigFlags, matchConfigFlag);
  mainDescriptionStr := Gettext.translateContent(mainDescription);
  (validStrings,descriptions) := getValidOptionsAndDescription2(validOptions);
end getValidOptionsAndDescription;

protected function getValidOptionsAndDescription2
  input Flags.ValidOptions validOptions;
  output list<String> validStrings;
  output list<String> descriptions;
algorithm
  (validStrings,descriptions) := match validOptions
    local
      list<tuple<String,Gettext.TranslatableContent>> options;
    case Flags.STRING_OPTION(validStrings) then (validStrings,{});
    case Flags.STRING_DESC_OPTION(options)
      equation
        validStrings = List.map(options,Util.tuple21);
        descriptions = List.mapMap(options,Util.tuple22,Gettext.translateContent);
      then (validStrings,descriptions);
  end match;
end getValidOptionsAndDescription2;

protected function compareDebugFlags
  input Flags.DebugFlag flag1;
  input Flags.DebugFlag flag2;
  output Boolean b;
protected
  String name1,name2;
algorithm
  Flags.DEBUG_FLAG(name=name1) := flag1;
  Flags.DEBUG_FLAG(name=name2) := flag2;
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
  Print.printBuf(System.gettext("Copyright © 2019 Open Source Modelica Consortium (OSMC)\n"));
  Print.printBuf(System.gettext("Distributed under OMSC-PL and GPL, see www.openmodelica.org\n\n"));
  //Print.printBuf("Please check the System Guide for full information about flags.\n");
  Print.printBuf(System.gettext("Usage: omc [Options] (Model.mo | Script.mos) [Libraries | .mo-files]\n* Libraries: Fully qualified names of libraries to load before processing Model or Script.\n             The libraries should be separated by spaces: Lib1 Lib2 ... LibN.\n"));
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
  Print.printBuf(System.gettext("  omc Model.mo Modelica    will first load the Modelica library and then produce\n                            flattened Model on standard output.\n"));
  Print.printBuf(System.gettext("  omc Model1.mo Model2.mo  will load both Model1.mo and Model2.mo, and produce\n                            flattened Model1 on standard output.\n"));
  Print.printBuf(System.gettext("  *.mo (Modelica files)\n"));
  //Print.printBuf("\t*.mof (Flat Modelica files)\n");
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
  Print.printBuf("\n.. _openmodelica-compiler-flags :\n\n");
  Print.printBuf(s);
  Print.printBuf("\n");
  Print.printBuf(sum("=" for e in 1:stringLength(s)));
  Print.printBuf("\n");
  Print.printBuf(System.gettext("Usage: omc [Options] (Model.mo | Script.mos) [Libraries | .mo-files]\n\n* Libraries: Fully qualified names of libraries to load before processing Model or Script.\n  The libraries should be separated by spaces: Lib1 Lib2 ... LibN.\n\n"));
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
  input Flags.ConfigFlag inFlag;
  output String outString;
algorithm
  outString := match(inFlag)
    local
      Gettext.TranslatableContent desc;
      String name, desc_str, flag_str, delim_str, opt_str;
      list<String> wrapped_str;

    case Flags.CONFIG_FLAG(visibility = Flags.INTERNAL()) then "";

    case Flags.CONFIG_FLAG(description = desc)
      equation
        desc_str = Gettext.translateContent(desc);
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
  input Flags.ConfigFlag inFlag;
  output String outString;
algorithm
  outString := match(inFlag)
    local
      Gettext.TranslatableContent desc;
      String name, longName, desc_str, flag_str, delim_str, opt_str;
      list<String> wrapped_str;

    case Flags.CONFIG_FLAG(visibility = Flags.INTERNAL()) then "";

    case Flags.CONFIG_FLAG(description = desc)
      equation
        desc_str = Gettext.translateContent(desc);
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
  input Flags.ConfigFlag inFlag;
  input Boolean sphinx=false;
  output String outString;
  output String longName;
algorithm
  (outString,longName) := match(inFlag)
    local
      String name, shortname;

    case Flags.CONFIG_FLAG(name = name, shortname = SOME(shortname))
      equation
        shortname = if sphinx then "-" + shortname else Util.stringPadLeft("-" + shortname, 4, " ");
      then (stringAppendList({shortname, ", --", name}), name);

    case Flags.CONFIG_FLAG(name = name, shortname = NONE())
      then ((if sphinx then "--" else "      --") + name, name);

  end match;
end printConfigFlagName;

protected function printValidOptions
  "Prints out the valid options of a configuration flag to a string."
  input Flags.ConfigFlag inFlag;
  output String outString;
algorithm
  outString := match(inFlag)
    local
      list<String> strl;
      String opt_str;
      list<tuple<String, Gettext.TranslatableContent>> descl;

    case Flags.CONFIG_FLAG(validOptions = NONE()) then "";
    case Flags.CONFIG_FLAG(validOptions = SOME(Flags.STRING_OPTION(options = strl)))
      equation
        opt_str = descriptionIndent + "   " + System.gettext("Valid options:") + " " +
          stringDelimitList(strl, ", ");
        strl = StringUtil.wordWrap(opt_str, System.getTerminalWidth(), descriptionIndent + "     ");
        opt_str = stringDelimitList(strl, "\n");
        opt_str = "\n" + opt_str;
      then
        opt_str;
    case Flags.CONFIG_FLAG(validOptions = SOME(Flags.STRING_DESC_OPTION(options = descl)))
      equation
        opt_str = "\n" + descriptionIndent + "   " + System.gettext("Valid options:") + "\n" +
          stringAppendList(list(printFlagOptionDescShort(d) for d in descl));
      then
        opt_str;
  end match;
end printValidOptions;

protected function printValidOptionsSphinx
  "Prints out the valid options of a configuration flag to a string."
  input Flags.ConfigFlag inFlag;
  output String outString;
algorithm
  outString := match(inFlag)
    local
      list<String> strl;
      String opt_str;
      list<tuple<String, Gettext.TranslatableContent>> descl;

    case Flags.CONFIG_FLAG(validOptions = NONE()) then "\n" + defaultFlagSphinx(inFlag.defaultValue) + "\n";
    case Flags.CONFIG_FLAG(validOptions = SOME(Flags.STRING_OPTION(options = strl)))
      equation
        opt_str = "\n" + defaultFlagSphinx(inFlag.defaultValue) + " " + System.gettext("Valid options") + ":\n\n" +
          sum("* " + s + "\n" for s in strl);
      then opt_str;
    case Flags.CONFIG_FLAG(validOptions = SOME(Flags.STRING_DESC_OPTION(options = descl)))
      equation
        opt_str = "\n" + defaultFlagSphinx(inFlag.defaultValue) + " " + System.gettext("Valid options") + ":\n\n" +
          sum(printFlagOptionDesc(s, sphinx=true) for s in descl);
      then
        opt_str;
  end match;
end printValidOptionsSphinx;

protected function defaultFlagSphinx
  input Flags.FlagData flag;
  output String str;
algorithm
  str := match flag
    local
      Integer i;
    case Flags.BOOL_FLAG() then System.gettext("Boolean (default")+" ``" + boolString(flag.data) + "``).";
    case Flags.INT_FLAG() then System.gettext("Integer (default")+" ``" + intString(flag.data) + "``).";
    case Flags.REAL_FLAG() then System.gettext("Real (default")+" ``" + realString(flag.data) + "``).";
    case Flags.STRING_FLAG("") then System.gettext("String (default *empty*).");
    case Flags.STRING_FLAG() then System.gettext("String (default")+" " + flag.data + ").";
    case Flags.STRING_LIST_FLAG(data={}) then System.gettext("String list (default *empty*).");
    case Flags.STRING_LIST_FLAG() then System.gettext("String list (default")+" " + stringDelimitList(flag.data, ",") + ").";
    case Flags.ENUM_FLAG()
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
  input tuple<String, Gettext.TranslatableContent> inOption;
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
  input Flags.ConfigFlag inFlag;
  output String outString;
protected
  list<tuple<String, Gettext.TranslatableContent>> options;
algorithm
  Flags.CONFIG_FLAG(validOptions = SOME(Flags.STRING_DESC_OPTION(options = options))) := inFlag;
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
  input tuple<String, Gettext.TranslatableContent> inOption;
  input Boolean sphinx=false;
  output String outString;
protected
  Gettext.TranslatableContent desc;
  String name, desc_str, str;
algorithm
  (name, desc) := inOption;
  desc_str := Gettext.translateContent(desc);
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
  input Flags.DebugFlag inFlag;
  input Boolean sphinx=false;
  output String outString;
protected
  Gettext.TranslatableContent desc;
  String name, desc_str;
  Boolean default;
algorithm
  Flags.DEBUG_FLAG(default = default, name = name, description = desc) := inFlag;
  desc_str := Gettext.translateContent(desc);
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
  input Flags.DebugFlag inFlag;
  output String name;
algorithm
  Flags.DEBUG_FLAG(name = name) := inFlag;
end debugFlagName;

public function configFlagName
  "Prints out name of a debug flag."
  input Flags.ConfigFlag inFlag;
  output String name;
algorithm
  Flags.CONFIG_FLAG(name = name) := inFlag;
end configFlagName;

protected function getValidStringOptions
  input Flags.ValidOptions inOptions;
  output list<String> validOptions;
algorithm
  validOptions := match inOptions
    local
      list<tuple<String, Gettext.TranslatableContent>> options;
    case Flags.STRING_OPTION(validOptions) then validOptions;
    case Flags.STRING_DESC_OPTION(options) then List.map(options,Util.tuple21);
  end match;
end getValidStringOptions;

public
function flagDataEq
  input Flags.FlagData data1;
  input Flags.FlagData data2;
  output Boolean eq;
algorithm
  eq := match (data1, data2)
    case (Flags.EMPTY_FLAG(), Flags.EMPTY_FLAG()) then true;
    case (Flags.BOOL_FLAG(), Flags.BOOL_FLAG()) then data1.data == data2.data;
    case (Flags.INT_FLAG(), Flags.INT_FLAG()) then data1.data == data2.data;
    case (Flags.INT_LIST_FLAG(), Flags.INT_LIST_FLAG())
      then List.isEqualOnTrue(data1.data, data2.data, intEq);
    case (Flags.REAL_FLAG(), Flags.REAL_FLAG()) then data1.data == data2.data;
    case (Flags.STRING_FLAG(), Flags.STRING_FLAG()) then data1.data == data2.data;
    case (Flags.STRING_LIST_FLAG(), Flags.STRING_LIST_FLAG())
      then List.isEqualOnTrue(data1.data, data2.data, stringEq);
    case (Flags.ENUM_FLAG(), Flags.ENUM_FLAG())
      then referenceEq(data1.validValues, data2.validValues) and
           data1.data == data2.data;
    else false;
  end match;
end flagDataEq;

function flagDataString
  input Flags.FlagData flagData;
  output String str;
algorithm
  str := match flagData
    local
      Integer v;

    case Flags.BOOL_FLAG() then boolString(flagData.data);
    case Flags.INT_FLAG() then intString(flagData.data);
    case Flags.INT_LIST_FLAG()
      then List.toString(flagData.data, intString, "", "", ",", "", false);

    case Flags.REAL_FLAG() then realString(flagData.data);
    case Flags.STRING_FLAG() then flagData.data;
    case Flags.STRING_LIST_FLAG() then stringDelimitList(flagData.data, ",");
    case Flags.ENUM_FLAG()
      algorithm
        for vt in flagData.validValues loop
          (str, v) := vt;
          if v == flagData.data then
            return;
          end if;
        end for;
      then
        "";

    else "";
  end match;
end flagDataString;

function unparseFlags
  "Goes through all the existing flags, and returns a list of all flags with
   values that differ from the default. The format of each string is flag=value."
  output list<String> flagStrings = {};
protected
  Flags.Flag flags;
  array<Boolean> debug_flags;
  array<Flags.FlagData> config_flags;
  String name;
  list<String> strl = {};
  Boolean fvalue;
algorithm
  try
    Flags.FLAGS(debugFlags = debug_flags, configFlags = config_flags) := loadFlags(false);
  else
    return;
  end try;

  for f in allConfigFlags loop
    if not flagDataEq(f.defaultValue, config_flags[f.index]) then
      name := match f.shortname
        case SOME(name) then "-" + name;
        else "--" + f.name;
      end match;

      flagStrings := (name + "=" + flagDataString(config_flags[f.index])) :: flagStrings;
    end if;
  end for;

  for f in allDebugFlags loop
    fvalue := debug_flags[f.index];
    if f.default <> fvalue then
      name := if fvalue then f.name else "no" + f.name;
      strl := name :: strl;
    end if;
  end for;

  if not listEmpty(strl) then
    flagStrings := "-d=" + stringDelimitList(strl, ",") :: flagStrings;
  end if;
end unparseFlags;

annotation(__OpenModelica_Interface="util");
end FlagsUtil;
