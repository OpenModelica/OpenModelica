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

encapsulated package SimCodeToLLVM
" file:        SimCodeToLLVM.mo
  package:     SimCodeToLLVM
  description: Lowers a SimCode.SIMCODE down to in-memory LLVM IR via
               EXT_LLVM and runs the simulation through the existing
               C-side solver+result-file plumbing -- no cc invocation,
               no .so on disk. Parallel to MidToLLVM (which handles
               MetaModelica function bodies for +d=jit_eval_func on
               function-call evaluation); this module is the
               simulate(model) entry point for the same flag.

  Phase 4.1: classify equations + map every cref to (kind, index)
             using SimCodeVar.SIMVARS.

  Initial scope:
  - explicit-ODE models with der(x) = f(x, params, time)
  - scalar Real states and algebraic vars
  - fixed Euler step
  - csv result file
  - no events, no nonlinear systems, no when-equations, no arrays.

  Runtime contract: the JIT-compiled module must plug into the
  existing OMC C runtime (SimulationRuntime/c) -- the same DATA*,
  threadData_t*, real_array, and solver-callback shapes the
  templated C code uses today. In Phase 5+ the entry point we emit
  will have the canonical signature
      int <prefix>_functionODE(DATA *data, threadData_t *threadData)
  and read/write through data->localData[0]->realVars[i] rather
  than via standalone double* buffers. The (kind, index) layout
  computed here is the bridge: kind selects which realVars slice
  to use (states are 0..nStates-1, derivatives are nStates..2*nStates-1,
  alg vars come next, etc.; see omc_init.c).

  Style: pure match throughout (no matchcontinue), no fail()-based
  control flow. Helpers return Boolean ok / Option<...>; callers
  propagate. Exhaustive cases over uniontypes; unsupported variants
  short-circuit with Boolean false.

  author: John Tinnerholm
"
public
import EXT_LLVM;
import DAEToMid;
import MidCode;
import MidToLLVM;
import SimCode;

protected
import Absyn;
import AbsynUtil;
import BackendDAE;
import ComponentReferenceBasics;
import DAE;
import DAEDump;
import ExpressionBasics;
import Error;
import Flags;
import Global;
import List;
import SimCodeVar;
import SimCodeFunction;
import System;

/* ====================================================================== *
 *  Variable layout                                                       *
 * ====================================================================== */

public uniontype VarKind
  "Where in the omc_ode(double t, double *x, double *xd, double *params)
   contract a SimVar lives. Iteration-1 scope only carries state,
   derivative, alg (treated as x for now since algs come from the
   ODE residual evaluator in trivial models), and param. Anything
   else makes a model UNSUPPORTED for SimCodeToLLVM and the legacy
   buildModel path takes over."
  record VK_STATE      end VK_STATE;
  record VK_DERIVATIVE end VK_DERIVATIVE;
  record VK_ALG        end VK_ALG;
  record VK_PARAM      end VK_PARAM;
  record VK_BOOL_PARAM end VK_BOOL_PARAM;
end VarKind;

public uniontype VarSlot
  record VAR_SLOT
    VarKind kind;
    Integer index "0-based offset within the kind's array";
    DAE.Type ty;
  end VAR_SLOT;
end VarSlot;

public uniontype VarLayout
  "Flat lookup table: ComponentRef -> VarSlot. Built once per
   genSim call from SimCodeVar.SIMVARS by enumerating each bucket."
  record VAR_LAYOUT
    list<tuple<DAE.ComponentRef, VarSlot>> entries;
    Integer nStates;
    Integer nAlgs;
    Integer nParams;
  end VAR_LAYOUT;
end VarLayout;

/* ====================================================================== *
 *  Equation classification                                               *
 * ====================================================================== */

public uniontype EqRecipe
  "How a SimEqSystem will be lowered. Phase 4.1 only produces the
   recipe; Phase 4.4 consumes it to emit IR."
  record EQ_STATE_ASSIGN
    "x[idx] := exp (initial-equation or start-value form)."
    Integer slotIndex;
    DAE.Exp rhs;
  end EQ_STATE_ASSIGN;

  record EQ_DERIVATIVE_ASSIGN
    "xd[idx] := exp (an ODE simple-assigned equation)."
    Integer slotIndex;
    DAE.Exp rhs;
  end EQ_DERIVATIVE_ASSIGN;

  record EQ_ALG_ASSIGN
    "alg[idx] := exp (a non-state algebraic var assigned)."
    Integer slotIndex;
    DAE.Exp rhs;
  end EQ_ALG_ASSIGN;

  record EQ_PARAM_ASSIGN
    "realParameter[idx] := exp (a parameter equation). Indexes into
     data->simulationInfo->realParameter[] rather than the realVars
     buffer."
    Integer slotIndex;
    DAE.Exp rhs;
  end EQ_PARAM_ASSIGN;

  record EQ_BOOL_PARAM_ASSIGN
    "booleanParameter[idx] := exp. The RHS is treated as a Real (0.0
     for false, 1.0 for true) and the bool accessor casts it back."
    Integer slotIndex;
    DAE.Exp rhs;
  end EQ_BOOL_PARAM_ASSIGN;

  record EQ_NOOP
    "Equation contributes nothing to the current emission (e.g. SES_ALIAS,
     whose body is shared with another equation already emitted in this
     or the ODE block)."
    Integer aliasOf;
  end EQ_NOOP;

  record EQ_ALG_CALL
    "Algorithm body lowered as a synthetic Modelica function. The
     statements are wrapped as SimCodeFunction.FUNCTION and routed
     through DAEToMid + MidToLLVM (the same pipeline emitUserFunctions
     uses). emitEquation emits a call to the mangled symbol name."
    String synthName "the mangled `omc_<...>` symbol";
    SimCodeFunction.Function synthFn "the synthetic function carrying the statements";
  end EQ_ALG_CALL;

  record EQ_PARAM_RANGE_ASSERT
    "Inline range-check assert on a Real parameter, as emitted by
     CodegenC for the (min=) / (max=) attribute checks. Lowered to
     a single call to omc_jit_assert_real_ge or _le with
     (DATA*, slot, bound)."
    Integer slotIndex "absolute realParameter[] slot";
    Boolean isGreaterEq "true for `>= bound`, false for `<= bound`";
    Real bound "the literal RCONST the parameter is compared against";
  end EQ_PARAM_RANGE_ASSERT;

  record EQ_UNSUPPORTED
    "Reason the equation cannot be lowered in the current scope."
    String reason;
  end EQ_UNSUPPORTED;
end EqRecipe;

/* ====================================================================== *
 *  Runtime entry-point catalog                                            *
 *                                                                         *
 *  The SimulationRuntime's CALLBACKS struct (openmodelica_func.h) holds   *
 *  ~50 function pointers populated by <Model>_setupDataStruc. Every       *
 *  symbol it points at must exist when the JIT links. The catalog below   *
 *  enumerates the subset relevant to ODE-only simulation; each entry      *
 *  declares the runtime signature plus what kind of body SCTL currently   *
 *  emits for it.                                                          *
 *                                                                         *
 *  Body sources:                                                          *
 *    STUB           - emit a trivial return-zero / return-void body.      *
 *                     Safe whenever the runtime tolerates the call being  *
 *                     a no-op for this model (most flag/log callbacks).   *
 *    NULL_PTR       - emit a body returning the null pointer. For         *
 *                     const-char* description callbacks that the runtime  *
 *                     only consults from log scopes.                      *
 *                                                                         *
 *  Future tags (not yet wired -- they exist as TODO markers):             *
 *    ODE_EQUATIONS  - lower SimCode.odeEquations through emitEquation.    *
 *                     Already produced under a different entry by         *
 *                     emitODEEntryShell (Pass 1 smoke-test).              *
 *    INITIAL_EQS    - lower SimCode.initialEquations. Needs $START.x      *
 *                     cref support and a body-validation pre-pass before  *
 *                     it can replace _06inz.c.                            *
 *    MIDCODE_FUNCS  - user-defined Modelica functions, already routed     *
 *                     through DAEToMid + MidToLLVM by emitUserFunctions.  *
 * ====================================================================== */

public uniontype EntryBody
  record EB_STUB end EB_STUB;
  record EB_NULL_PTR end EB_NULL_PTR;
  record EB_RETURN_MINUS_ONE
    "Emit a body that returns -1. Used for entries the runtime checks
     for negative-as-unavailable."
  end EB_RETURN_MINUS_ONE;
  record EB_JAC_UNAVAILABLE
    "Body for _initialAnalyticJacobian<X>(DATA*, threadData_t*, JACOBIAN*):
     calls omc_jit_jacobian_set_unavailable(jacobian) (which writes
     JACOBIAN_NOT_AVAILABLE into the struct's first field) and returns
     1. Lets DASSL distinguish 'genuinely no analytic Jacobian' from
     the default JACOBIAN_UNKNOWN that triggers an abort."
  end EB_JAC_UNAVAILABLE;
  record EB_TODO
    "Entry currently left to clang from <Model>_NN<tag>.c."
    String reason;
  end EB_TODO;
end EntryBody;

public uniontype RuntimeEntry
  record RUNTIME_ENTRY
    String nameSuffix       "appended after <prefix> -- e.g. _checkForAsserts";
    Integer retTy           "MODELICA_INTEGER / MODELICA_VOID / MODELICA_METATYPE";
    list<Integer> argTys    "ordered list of EXT_LLVM type codes";
    EntryBody body;
    String segmentFile      "name of the CodegenC .c file this entry lives in -- for the keep-in-sync invariant with compileModelToBitcode";
  end RUNTIME_ENTRY;
end RuntimeEntry;

protected function runtimeEntryCatalog
  "Single source of truth: every runtime entry point SCTL currently
   emits, in declaration order. Adding an entry here is the only
   change needed to grow SCTL's coverage of a new runtime symbol.

   Type code shorthand:
     MI = MODELICA_INTEGER   (i64)
     MV = MODELICA_VOID
     MM = MODELICA_METATYPE  (opaque ptr)"
  output list<RuntimeEntry> entries;
protected
  constant Integer MI = MODELICA_INTEGER;
  constant Integer MV = MODELICA_VOID;
  constant Integer MM = MODELICA_METATYPE;
algorithm
  entries := {
    /* -- _17inl.c -------------------------------------------------- */
    RUNTIME_ENTRY("_symbolicInlineSystem", MI, {MM, MM}, EB_STUB(), "_17inl.c"),

    /* -- _10asr.c -------------------------------------------------- */
    RUNTIME_ENTRY("_checkForAsserts", MI, {MM, MM}, EB_STUB(), "_10asr.c"),

    /* -- _07dly.c -------------------------------------------------- */
    RUNTIME_ENTRY("_function_storeDelayed", MI, {MM, MM}, EB_STUB(), "_07dly.c"),

    /* -- _18spd.c -------------------------------------------------- */
    RUNTIME_ENTRY("_function_storeSpatialDistribution", MI, {MM, MM}, EB_STUB(), "_18spd.c"),
    RUNTIME_ENTRY("_function_initSpatialDistribution",  MI, {MM, MM}, EB_STUB(), "_18spd.c"),

    /* -- _16dae.c -- runtime returns -1 ("no DAE residuals"); 0 is
                     also safe for the ODE path that DASSL drives. */
    RUNTIME_ENTRY("_initializeDAEmodeData", MI, {MM, MM}, EB_STUB(), "_16dae.c"),

    /* -- _04set.c -- (int nStateSets, STATE_SET_DATA*, DATA*) -> void.
                     int widens to i64 (no MODELICA_INT32); the unused
                     arg sits in the same register on x86-64. */
    RUNTIME_ENTRY("_initializeStateSets", MV, {MI, MM, MM}, EB_STUB(), "_04set.c"),

    /* -- _08bnd.c -- bound-parameter / bound-attribute updates. Empty
                      in CodegenC for HelloWorld but populates
                      data->simulationInfo->realParameter[] for models
                      with parameter equations (ChuaCircuit:
                      Ra/Rb/L/C1/C2). Stubbing leaves parameters at 0
                      and simulation diverges. Leaving _08bnd.c to
                      clang until real parameter-equation lowering
                      lands. */
    RUNTIME_ENTRY("_bnd_handled_by_clang", MV, {}, EB_TODO("parameter equations need real body for ChuaCircuit"), "_08bnd.c"),

    /* -- _09alg.c -- ODE-only models have no continuous-time alg.
                     CodegenC body increments a stat counter and calls
                     _function_savePreSynchronous; both safely dropped. */
    RUNTIME_ENTRY("_functionAlgebraics", MI, {MM, MM}, EB_STUB(), "_09alg.c"),

    /* -- _15syn.c -- synchronous-language support. Empty bodies for
                     non-synchronous models. */
    RUNTIME_ENTRY("_function_savePreSynchronous",  MV, {MM, MM},          EB_STUB(), "_15syn.c"),
    RUNTIME_ENTRY("_function_initSynchronous",     MV, {MM, MM},          EB_STUB(), "_15syn.c"),
    RUNTIME_ENTRY("_function_updateSynchronous",   MV, {MM, MM, MI},      EB_STUB(), "_15syn.c"),
    RUNTIME_ENTRY("_function_equationsSynchronous",MI, {MM, MM, MI, MI},  EB_STUB(), "_15syn.c"),

    /* -- _13opt.c -- optimization (Optimica) callbacks. Stubs sit in
                     the function pointer table populated by
                     setupDataStruc but never get called for ODE-only
                     simulation. */
    RUNTIME_ENTRY("_mayer",                              MI, {MM, MM, MM},                       EB_STUB(), "_13opt.c"),
    RUNTIME_ENTRY("_lagrange",                           MI, {MM, MM, MM, MM},                   EB_STUB(), "_13opt.c"),
    RUNTIME_ENTRY("_getInputVarIndicesInOptimization",   MI, {MM, MM},                           EB_STUB(), "_13opt.c"),
    RUNTIME_ENTRY("_pickUpBoundsForInputsInOptimization",MI, {MM, MM, MM, MM, MM, MM, MM, MM},   EB_STUB(), "_13opt.c"),
    RUNTIME_ENTRY("_setInputData",                       MI, {MM, MI},                           EB_STUB(), "_13opt.c"),
    RUNTIME_ENTRY("_getTimeGrid",                        MI, {MM, MM, MM},                       EB_STUB(), "_13opt.c"),

    /* -- _05evt.c -- event handling. Trivially-stub'd entries work for
                      models with no zero crossings (HelloWorld, UserFn).
                      For models with piecewise nonlinearities
                      (ChuaCircuit, hybrid systems) _function_ZeroCrossings
                      must populate the gout buffer; the stubs cause
                      DASKR's bisection logic to misfire and abort with
                      "R IS ILL-DEFINED". Leaving _05evt.c to clang until
                      the bodies are lowered. */
    RUNTIME_ENTRY("_evt_handled_by_clang", MV, {}, EB_TODO("zero-crossings need real body for hybrid models"), "_05evt.c"),

    /* -- _14lnz.c -- linearization frame strings. Returned only from
                     -d=linearization paths; null suffices for ODE. */
    RUNTIME_ENTRY("_linear_model_frame",               MM, {}, EB_NULL_PTR(), "_14lnz.c"),
    RUNTIME_ENTRY("_linear_model_datarecovery_frame", MM, {}, EB_NULL_PTR(), "_14lnz.c"),

    /* -- _06inz.c -- initial-equation block. emitInitialEquationsBlock
                      runs alongside the catalog walk and emits the three
                      entries below when SimCode.initialEquations all
                      lower cleanly. The catalog rows stay EB_TODO so
                      displacedSegmentFiles continues to leave _06inz.c
                      on clang by default; the dynamic skip wiring needs
                      one more piece before they can flip. */
    RUNTIME_ENTRY("_functionInitialEquations_0",      MV, {MM, MM}, EB_TODO("emitInitialEquationsBlock handles it"), "_06inz.c"),
    RUNTIME_ENTRY("_functionInitialEquations",        MI, {MM, MM}, EB_TODO("emitInitialEquationsBlock handles it"), "_06inz.c"),
    RUNTIME_ENTRY("_functionRemovedInitialEquations", MI, {MM, MM}, EB_TODO("emitInitialEquationsBlock handles it"), "_06inz.c"),

    /* -- _01exo.c -- external object destructors. CodegenC emits
                     `if (extObjs) { free(extObjs); extObjs = 0; }`;
                     for models with no ExternalObject declarations
                     (HelloWorld / UserFn / ChuaCircuit / ...) extObjs
                     is NULL and the call is a no-op. The stub matches
                     that behaviour. Models that use ExternalObject
                     will need an omc_jit_destroy_extobjs(DATA*)
                     accessor before this can keep its EB_STUB tag. */
    RUNTIME_ENTRY("_callExternalObjectDestructors", MV, {MM, MM}, EB_STUB(), "_01exo.c"),

    /* -- _12jac.c -- analytic Jacobian. SCTL can emit stubs that
                      mark the JACOBIAN struct as NOT_AVAILABLE so
                      HelloWorld-class non-stiff models accept the
                      numerical-differencing fallback, but stiff
                      nonlinear models (ChuaCircuit, VDP at long t)
                      need a populated sparsity pattern to converge.
                      Leaving _12jac.c on clang until real analytic
                      Jacobian lowering lands. */
    RUNTIME_ENTRY("_jacobian_handled_by_clang", MV, {}, EB_TODO("real analytic Jacobian lowering needed"), "_12jac.c")

  /* Entries still owned entirely by <Model>.c and <Model>_12jac.c are
     not in the catalog yet; they need real codegen
     (functionODE_system0, setupDataStruc, main, the eqFunction_N
     bodies, the function-pointer table, the Jacobian etc.). */
  };
end runtimeEntryCatalog;

/* ====================================================================== *
 *  Entry point                                                           *
 * ====================================================================== */

public function displacedSegmentFiles
  "Distinct list of CodegenC segment .c files SCTL fully covers.
   Combines the static set declared in runtimeEntryCatalog (entries
   whose body is not EB_TODO) with the dynamic set recorded during
   genSim via recordDisplacedSegment (e.g. _06inz.c when initial
   equations all lower cleanly for this specific model)."
  output list<String> files = {};
protected
  Boolean seen;
  list<String> dyn;
algorithm
  for e in runtimeEntryCatalog() loop
    if not isTodoBody(e.body) then
      files := uniqueAppend(files, e.segmentFile);
    end if;
  end for;
  dyn := getDynamicSkips();
  for f in dyn loop
    files := uniqueAppend(files, f);
  end for;
end displacedSegmentFiles;

protected function uniqueAppend
  "Append seg to files iff files does not already contain seg.
   Preserves order."
  input list<String> filesIn;
  input String seg;
  output list<String> filesOut = filesIn;
protected
  Boolean seen = false;
algorithm
  for f in filesIn loop
    if f == seg then
      seen := true;
    end if;
  end for;
  if not seen then
    filesOut := listAppend(filesIn, {seg});
  end if;
end uniqueAppend;

protected function getDynamicSkips
  "Current value of the per-build dynamic skip list. The slot is
   seeded by resetDynamicSkips at the start of every genSim, so by
   the time displacedSegmentFiles reads it the cell holds an
   already-initialised list<String>."
  output list<String> skips;
algorithm
  skips := getGlobalRoot(Global.simCodeToLLVMDynamicSkips);
end getDynamicSkips;

protected function resetDynamicSkips
  "Clear the per-build skip list. Called at the start of every genSim."
algorithm
  setGlobalRoot(Global.simCodeToLLVMDynamicSkips, {});
end resetDynamicSkips;

protected function recordDisplacedSegment
  "Record that <segmentFile> (e.g. \"_06inz.c\") was successfully
   emitted by SCTL for this model. compileModelToBitcode will pick
   the addition up via displacedSegmentFiles."
  input String segmentFile;
protected
  list<String> cur;
algorithm
  cur := getDynamicSkips();
  setGlobalRoot(Global.simCodeToLLVMDynamicSkips, uniqueAppend(cur, segmentFile));
end recordDisplacedSegment;

protected function isTodoBody
  input EntryBody b;
  output Boolean t;
algorithm
  t := match b
    case EB_TODO() then true;
    else false;
  end match;
end isTodoBody;

public function genSim
  "Lower a SimCode.SIMCODE to in-memory LLVM IR + run the simulation
   driver against it. Returns true on success; false on any
   unsupported construct (so the caller in SimCodeMain.generateModelCode
   falls back to the legacy template-based C path).

   Phase 4.1: build the variable layout, classify all ODE
   equations, log the result. No IR is emitted yet. Returns
   false so the legacy path stays in charge."
  input SimCode.SimCode simCode;
  output Boolean success;
protected
  Absyn.Path name;
  SimCodeVar.SimVars vars;
  list<SimCode.SimEqSystem> odeEqs;
  VarLayout layout;
  list<EqRecipe> recipes;
  Integer nSupported, nUnsupported, bcSt;
  String sctlBcPath;
algorithm
  /* Per-build state: clear the dynamic skip list before we start
   * emitting. Each successful emitInitialEquationsBlock /
   * emit<Segment> call records its segmentFile back into this list. */
  resetDynamicSkips();
  name := simCodeName(simCode);
  vars := simCodeVars(simCode);
  odeEqs := flattenOdeEquations(simCode);

  layout := buildVarLayout(vars);
  recipes := List.map1(odeEqs, classifySimEq, layout);

  nSupported   := List.fold(recipes, countSupported, 0);
  nUnsupported := List.fold(recipes, countUnsupported, 0);

  /* Phase 4.2: emit the omc_<prefix>_functionODE shell into a fresh
   * LLVM module. Body is just `return 0;` for now; per-equation IR
   * lands in Phase 4.3-4.4. The shell deliberately matches the
   * existing C runtime contract
   *   int <prefix>_functionODE(DATA *data, threadData_t *threadData)
   * so when Phase 5/6 connect a solver to the JIT module, the
   * solver_main.c call site
   *   data->callback->functionODE(data, threadData);
   * binds without any glue layer. Until then the function is
   * defined but unreferenced; dumpIR confirms its shape. */
  /* Under -d=jitSimulate emit the ODE entry-point IR in memory and
   * verify Phase 5 (LLJIT materialization) + Phase 6 (one-shot
   * functionODE invocation) succeed. -d=jit_dump_ir additionally
   * prints the IR text. The custom Euler / RK4 / implicit-Euler
   * driver loops (Phase 7-9) are no longer invoked here: simulation
   * itself stays on the legacy CodegenC + clang-via-Adrian path
   * until SimCodeToLLVM emits enough of the model to plug into the
   * existing DASSL runtime. */
  if Flags.isSet(Flags.JIT_SIMULATE) then
    /* Pass 1: in-memory functionODE for the Phase 5/6 smoke test.
     * Gated on nUnsupported == 0 because emitODEEntryShell needs to
     * lower every dynamic equation; one unsupported recipe means
     * the functionODE body cannot be emitted (the C functionODE
     * will be used instead). The Pass-2 stubs/blocks are unaffected
     * by unsupported dynamic equations and still get to run.
     * The module is consumed (moved) by jitFinalizeNoEntry into the
     * function-JIT, so it cannot be serialised after this. */
    if nUnsupported == 0 then
      EXT_LLVM.initGen(modelSymbolPrefix(name) + "_ode");
      if emitODEEntryShell(name, recipes, layout) then
        if Flags.isSet(Flags.JIT_DUMP_IR) then EXT_LLVM.dumpIR(); end if;
        finalizeAndReport(name, layout, vars);
      end if;
    end if;
    /* Pass 2: a fresh module containing only the entry points that
     * displace .c files from compileModelToBitcode. _functionODE is
     * deliberately not re-emitted here -- the C path still owns it
     * until SCTL can prove out the full ODE call site. Every stub
     * emitted here lets the matching .c file be dropped from the
     * clang loop in CevalScriptBackend.compileModelToBitcode. */
    EXT_LLVM.initGen(modelSymbolPrefix(name) + "_sctl");
    emitDisplacingStubs(name);
    /* emitUserFunctions(simCode) is intentionally not called here.
     * The DAEToMid + MidToLLVM pipeline emits wrong-signature stubs
     * for `external` Modelica functions (e.g.
     * Modelica.Blocks.Tables.Internal.getTable1DValue takes
     * (threadData, complex, integer, real) but the lowered
     * declaration was (threadData) only), and silently skips
     * functions whose types DAEToMid cannot resolve (e.g.
     * ExternalCombiTable1D_constructor). Either symptom breaks the
     * simulation. Until DAEToMid is taught to faithfully lower the
     * full SimCodeFunction signature -- arrays, complex /
     * ExternalObject types, and `external "C"` body bindings -- the
     * model's _functions.c stays on the clang path so the bodies
     * arrive correctly. */
    /* Each per-block emission runs inside try/else so a single
     * unhandled C++-side MMC_THROW (e.g. createStoreInst hitting a
     * cref whose lowered name was never alloca'd in the current
     * function) does not abort the whole genSim. A failed block
     * just does not record its segment file into the dynamic skip
     * list, leaving the corresponding _XX.c on the clang path. */
    try _ := emitInitialEquationsBlock(simCode, layout); else end try;
    try emitBoundParametersBlock(simCode, layout); else end try;
    try emitEventBlock(simCode, layout); else end try;
    try emitJacobianBlock(simCode); else end try;
    if Flags.isSet(Flags.JIT_DUMP_IR) then EXT_LLVM.dumpIR(); end if;
    /* Hand the in-memory module to omc_runModelViaJIT through a
     * process-global byte buffer (no disk hop). compileModelToBitcode
     * is still responsible for clang'ing the .c files we have not
     * yet displaced, but SCTL's own bitcode no longer touches disk. */
    bcSt := EXT_LLVM.stashCurrentModuleAsBitcode();
    if bcSt <> 0 then
      Error.addInternalError(
        "SimCodeToLLVM: stashCurrentModuleAsBitcode returned " +
        intString(bcSt) + "\n", sourceInfo());
    end if;
    /* Optional debug dump alongside, gated on jit_dump_ir. */
    if Flags.isSet(Flags.JIT_DUMP_IR) then
      sctlBcPath := modelSymbolPrefix(name) + "_sctl.bc";
      bcSt := EXT_LLVM.writeBitcodeToFile(sctlBcPath);
    end if;
  end if;

  Error.addInternalError(
    "SimCodeToLLVM: model '" + AbsynUtil.pathString(name) +
    "' layout: nStates=" + intString(layout.nStates) +
    " nAlgs=" + intString(layout.nAlgs) +
    " nParams=" + intString(layout.nParams) +
    "; eqs: supported=" + intString(nSupported) +
    " unsupported=" + intString(nUnsupported) +
    " (Phase 4.2 -- ODE entry shell can be emitted with +d=jit_dump_ir;" +
    " per-equation body and JIT execution not yet wired, falling back " +
    "to legacy buildModel)\n",
    sourceInfo());
  success := false;
end genSim;

/* ====================================================================== *
 *  IR emission                                                           *
 * ====================================================================== */

protected constant Integer MODELICA_INTEGER  = 1 "i64 in LLVM IR.";
protected constant Integer MODELICA_REAL     = 3 "double in LLVM IR.";
protected constant Integer MODELICA_METATYPE = 4 "Opaque ptr in LLVM IR (matches MidToLLVM's constant).";
protected constant Integer MODELICA_VOID     = 6 "void in LLVM IR (no return).";

protected uniontype EmitCtx
  "Carries the layout and a monotonic counter for generated temp
   names. Passed through expression lowering so each emitted
   call/op writes to a fresh alloca."
  record EMIT_CTX
    VarLayout layout;
    Integer tmpCounter;
  end EMIT_CTX;
end EmitCtx;

protected function freshTmp
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String name;
algorithm
  name := "%t_" + intString(ctx.tmpCounter);
  outCtx := EMIT_CTX(ctx.layout, ctx.tmpCounter + 1);
end freshTmp;

protected function finalizeAndReport
  "Phase 5/6: materialize the current module into LLJIT, look up
   <Model>_functionODE, and invoke it once against a fabricated
   realVars buffer as a smoke-test that the in-memory IR runs.
   Custom integrator loops (Phase 7-9: forward Euler / RK4 / implicit
   Euler) are intentionally not called from here: the model's
   numerical integration is supposed to come from the existing
   simulation runtime (DASSL et al.) once SimCodeToLLVM emits enough
   of the model to be hosted by that runtime.

   The 'vars' input is currently unused but retained so the call site
   can later thread initial values into the runtime hand-off."
  input Absyn.Path name;
  input VarLayout layout;
  input SimCodeVar.SimVars vars;
protected
  String odeSym;
  Integer st;
  list<Real> rvIn, rvOut;
algorithm
  odeSym := modelSymbolPrefix(name) + "_functionODE";
  st := EXT_LLVM.jitFinalizeNoEntry(odeSym);
  if st <> 0 then
    Error.addInternalError(
      "SimCodeToLLVM Phase 5: jitFinalizeNoEntry('" + odeSym +
      "') returned " + intString(st) + "\n", sourceInfo());
    return;
  end if;
  rvIn := List.fill(1.0, 2 * layout.nStates + layout.nAlgs + layout.nParams);
  rvOut := EXT_LLVM.jitInvokeFunctionODE(odeSym, layout.nStates, layout.nAlgs, layout.nParams, rvIn);
  Error.addInternalError(
    "SimCodeToLLVM Phase 6: jitInvokeFunctionODE('" + odeSym +
    "') with realVars=1.0 returned " + realVarsString(rvOut) + "\n",
    sourceInfo());
end finalizeAndReport;

protected function realVarsString
  input list<Real> rs;
  output String s;
algorithm
  s := "[" + stringDelimitList(List.map(rs, realString), ", ") + "]";
end realVarsString;

protected function emitODEEntryShell
  "Emit the function definition

     define i64 @<prefix>_functionODE(ptr %data, ptr %threadData) {
       <per-equation body>
       ret i64 0
     }

   into a freshly-initialised LLVM module. Returns Boolean ok -- if
   any equation's RHS contains a construct the minimal DAE.Exp
   lowering does not recognise, IR generation aborts (the partial
   module is discarded by the caller) and the legacy template path
   takes over.

   Phase 6 will narrow the i64 return type to i32 once EXT_LLVM grows
   a MODELICA_INT32 constant; the C runtime's
       int (*functionODE)(DATA *, threadData_t *)
   will then bind directly."
  input Absyn.Path modelName;
  input list<EqRecipe> recipes;
  input VarLayout layout;
  output Boolean ok;
algorithm
  ok := emitEquationFunction(odeEntryName(modelName), recipes, layout, MODELICA_INTEGER);
end emitODEEntryShell;

protected function emitEquationFunction
  "Emit one  <retTy> <fname>(DATA *, threadData_t *)  function whose body
   is the concatenation of every recipe in 'recipes'. Returns true if
   every recipe lowered cleanly. retTy = MODELICA_VOID emits 'ret void';
   any other retTy emits 'ret <zero of retTy>'.

   Used both for the runtime-contract _functionODE entry (returns int)
   and for the per-block helpers _functionInitialEquations_0 etc.
   (return void)."
  input String fname;
  input list<EqRecipe> recipes;
  input VarLayout layout;
  input Integer retTy;
  output Boolean ok;
protected
  EmitCtx ctx;
algorithm
  EXT_LLVM.startFuncGen(fname);
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "data");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "threadData");
  EXT_LLVM.genFunctionType(retTy);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);

  ctx := EMIT_CTX(layout, 0);
  ok := true;
  /* Per-recipe try/else so a deep MMC_THROW from emitEquation does
   * not skip the return / finnishGen below. The LLVM function is
   * then well-formed (has terminator) even when some recipe was
   * dropped -- the symbol is in our bitcode either way, so the
   * caller must record the segment displacement. */
  /* On throw inside emitEquation, MetaModelica's try/else does not
   * roll back partial allocas the C++ side already created in the
   * LLVM IR. The ctx (specifically tmpCounter) may also have
   * stayed at its pre-call value, so the next iteration would
   * freshTmp the SAME %t_N names and trip LLVM's per-function
   * name-uniqueness machinery (it appends suffixes silently, but
   * our symtab key then mismatches the requested name). Once any
   * recipe throws we skip the rest -- the function is still
   * well-formed because the trailing return/finnishGen runs, and
   * recordDisplacedSegment in the caller keeps clang from
   * re-emitting the symbol. */
  for r in recipes loop
    if ok then
      try
        (ctx, ok) := emitEquation(r, ctx);
      else
        if Flags.isSet(Flags.FAILTRACE) then
          print("SCTL emitEquationFunction: throw on recipe " +
                recipeKindString(r) + " rhs=" + recipeRhsStr(r) +
                ", skipping remaining recipes\n");
        end if;
        ok := false;
      end try;
    end if;
  end for;

  if retTy == MODELICA_VOID then
    EXT_LLVM.genReturnVoid();
  else
    EXT_LLVM.genReturnZero();
  end if;
  EXT_LLVM.finnishGen();
end emitEquationFunction;

/* ====================================================================== *
 *  Stub emitter                                                           *
 *                                                                         *
 *  emitStub is the single workhorse for "I want an LLVM IR function with  *
 *  signature (argTys) -> retTy whose body is 'return zero of retTy'".     *
 *  The arguments are named a0, a1, ... and never read; the body shape is  *
 *  fixed.                                                                 *
 *                                                                         *
 *  The convenience wrappers below name the two signatures that occur most *
 *  often in CodegenC's generated entry points, so emitDisplacingStubs     *
 *  reads as a flat directory of "<segment .c file>: <names it owns>"      *
 *  instead of a list of bare type tuples.                                 *
 * ====================================================================== */

protected function emitStub
  "Emit  <retTy> <fname>(<argTys...>) { return <zero of retTy>; }
   into the current in-memory module. retTy = MODELICA_VOID yields a
   plain `ret void`; any other retTy yields `ret <zero>` matching the
   declared return type."
  input String fname;
  input Integer retTy;
  input list<Integer> argTys = {};
protected
  Integer i = 0;
algorithm
  EXT_LLVM.startFuncGen(fname);
  for ty in argTys loop
    EXT_LLVM.genFunctionArg(ty, "a" + intString(i));
    i := i + 1;
  end for;
  EXT_LLVM.genFunctionType(retTy);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);
  /* Return shape must match the declared return type or LLVM
   * verifyFunction fails (and dumps the IR before downstream
   * materialization SIGSEGVs). MODELICA_VOID -> ret void;
   * MODELICA_METATYPE / *_PTR -> ret null; all real / integer /
   * boolean -> ret 0. */
  if retTy == MODELICA_VOID then
    EXT_LLVM.genReturnVoid();
  elseif retTy == MODELICA_METATYPE then
    EXT_LLVM.genReturnNullPtr();
  else
    EXT_LLVM.genReturnZero();
  end if;
  EXT_LLVM.finnishGen();
end emitStub;

protected function emitStubNullPtr
  "Emit  <retTy> <fname>(<argTys...>) { return null; }  into the
   active module. Used for the EB_NULL_PTR catalog entries -- the
   runtime checks for non-null before reading the result so a null
   sentinel is the right semantic, not the wrong-type i64 0 that
   genReturnZero would emit."
  input String fname;
  input Integer retTy;
  input list<Integer> argTys = {};
protected
  Integer i = 0;
algorithm
  EXT_LLVM.startFuncGen(fname);
  for ty in argTys loop
    EXT_LLVM.genFunctionArg(ty, "a" + intString(i));
    i := i + 1;
  end for;
  EXT_LLVM.genFunctionType(retTy);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);
  EXT_LLVM.genReturnNullPtr();
  EXT_LLVM.finnishGen();
end emitStubNullPtr;

protected function emitRuntimeIntStub
  "Convenience: (DATA *, threadData_t *) -> int { return 0; }
   The shape of most runtime callbacks the generated model exports."
  input String fname;
algorithm
  emitStub(fname, MODELICA_INTEGER, {MODELICA_METATYPE, MODELICA_METATYPE});
end emitRuntimeIntStub;

protected function emitRuntimeVoidStub
  "Convenience: (DATA *, threadData_t *) -> void."
  input String fname;
algorithm
  emitStub(fname, MODELICA_VOID, {MODELICA_METATYPE, MODELICA_METATYPE});
end emitRuntimeVoidStub;

protected function emitNamedEquationFunction
  "Emit  void <prefix>_eqFunction_<idx>(DATA *data, threadData_t *threadData)
   carrying a single recipe's body. Used so cross-file extern refs
   from still-clang'd files (_05evt.c, the driver) resolve at JIT
   link time. Returns false if the recipe failed to emit cleanly."
  input String prefix;
  input tuple<SimCode.SimEqSystem, EqRecipe> eqAndRecipe;
  input VarLayout layout;
  output Boolean ok;
protected
  SimCode.SimEqSystem eq;
  EqRecipe recipe;
  Integer eqIndex;
  String fname;
  EmitCtx ctx;
algorithm
  (eq, recipe) := eqAndRecipe;
  eqIndex := simEqIndex(eq);
  fname := prefix + "_eqFunction_" + intString(eqIndex);
  EXT_LLVM.startFuncGen(fname);
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "data");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "threadData");
  EXT_LLVM.genFunctionType(MODELICA_VOID);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);
  ctx := EMIT_CTX(layout, 0);
  try
    (_, ok) := emitEquation(recipe, ctx);
  else
    if Flags.isSet(Flags.FAILTRACE) then
      print("SCTL emitNamedEquationFunction: throw on " + fname +
            " recipe " + recipeKindString(recipe) +
            " rhs=" + recipeRhsStr(recipe) + "\n");
    end if;
    ok := false;
  end try;
  EXT_LLVM.genReturnVoid();
  EXT_LLVM.finnishGen();
end emitNamedEquationFunction;

protected function simEqIndex
  "Pull the source-level equation index off a SimEqSystem variant."
  input SimCode.SimEqSystem eq;
  output Integer index;
algorithm
  index := match eq
    case SimCode.SES_SIMPLE_ASSIGN()     then eq.index;
    case SimCode.SES_ALGORITHM()         then eq.index;
    case SimCode.SES_RESIDUAL()          then eq.index;
    case SimCode.SES_LINEAR()            then 0;
    case SimCode.SES_NONLINEAR()         then 0;
    case SimCode.SES_MIXED()             then eq.index;
    case SimCode.SES_WHEN()              then eq.index;
    case SimCode.SES_IFEQUATION()        then eq.index;
    case SimCode.SES_ARRAY_CALL_ASSIGN() then eq.index;
    case SimCode.SES_ALIAS()             then eq.index;
    else 0;
  end match;
end simEqIndex;

protected function emitInitialEquationsDispatcher
  "Emit  void <prefix>_functionInitialEquations_0(DATA *data,
                                                 threadData_t *threadData)
   that calls each <prefix>_eqFunction_<idx> in initEqs order. Skips
   SES_ALIAS entries -- their body is shared with another equation
   that already emits its own eqFunction symbol."
  input String prefix;
  input list<SimCode.SimEqSystem> initEqs;
protected
  String fname;
  Integer eqIndex;
algorithm
  fname := prefix + "_functionInitialEquations_0";
  EXT_LLVM.startFuncGen(fname);
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "data");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "threadData");
  EXT_LLVM.genFunctionType(MODELICA_VOID);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);
  for eq in initEqs loop
    () := match eq
      case SimCode.SES_ALIAS() then ();
      else algorithm
        eqIndex := simEqIndex(eq);
        EXT_LLVM.genCallArg("data");
        EXT_LLVM.genCallArg("threadData");
        EXT_LLVM.genCall(prefix + "_eqFunction_" + intString(eqIndex),
                         MODELICA_VOID, "", false);
      then ();
    end match;
  end for;
  EXT_LLVM.genReturnVoid();
  EXT_LLVM.finnishGen();
end emitInitialEquationsDispatcher;

protected function emitInitialEquationsBlock
  "Emit the three runtime entry points produced by
   <Model>_06inz.c:

     void <prefix>_functionInitialEquations_0(DATA *, threadData_t *)
     int  <prefix>_functionInitialEquations  (DATA *, threadData_t *)
     int  <prefix>_functionRemovedInitialEquations(DATA *, threadData_t *)

   The first contains the actual initial-equation bodies (same shape
   as the ODE block, lowered through emitEquation). The second is a
   thin wrapper around the first (CodegenC bookends it with
   discreteCall++/--, which is observable only by event-handling
   paths the JIT does not currently drive). The third is a no-op for
   ODE-only models like HelloWorld.

   Returns true only if every initial equation lowered cleanly. On
   false the caller leaves _06inz.c to clang -- the SCTL output
   would be unusable as a replacement."
  input SimCode.SimCode simCode;
  input VarLayout layout;
  output Boolean ok;
protected
  list<SimCode.SimEqSystem> initEqs;
  list<EqRecipe> recipes;
  String prefix;
  Absyn.Path name;
algorithm
  name := simCodeName(simCode);
  prefix := modelSymbolPrefix(name);
  initEqs := match simCode
    case SimCode.SIMCODE(initialEquations = initEqs) then initEqs;
  end match;
  recipes := List.map1(initEqs, classifySimEq, layout);
  /* Two-stage gate so we never commit a half-emitted function body
   * (which would collide with and silently win over _06inz.c's real
   * version): classify-time check, then expression-tree check. */
  ok := List.fold(recipes, countUnsupportedAsBoolean, true);
  if not ok then
    return;
  end if;
  for r in recipes loop
    if not canLowerEquation(r, layout) then
      ok := false;
      return;
    end if;
  end for;
  /* Emit each equation as its own  <Model>_eqFunction_<idx>
   * (DATA*, threadData_t*) -> void  function and a
   * <Model>_functionInitialEquations_0 dispatcher that calls them
   * in order. The per-equation symbols make cross-file extern
   * references from still-clang'd files (_05evt.c, the driver)
   * resolve at JIT link time -- the previous inline-only emission
   * left those symbols undefined and forced the modelHasNoEvents
   * gate. */
  for eqRec in List.zip(initEqs, recipes) loop
    if not emitNamedEquationFunction(prefix, eqRec, layout) then
      ok := false;
      return;
    end if;
  end for;
  emitInitialEquationsDispatcher(prefix, initEqs);
  /* Wrapper: CodegenC version calls _0 between discreteCall++/--.
   * Dropping the bookend is harmless for the ODE-only initialisation
   * path that DASSL drives. */
  emitInitialEquationsWrapper(prefix + "_functionInitialEquations",
                              prefix + "_functionInitialEquations_0");
  /* No removed initial equations for the supported models so far. */
  emitRuntimeIntStub(prefix + "_functionRemovedInitialEquations");
  /* All three _06inz.c entries are now SCTL-supplied; tell the bash
   * glue to skip clang on the matching .c file. */
  recordDisplacedSegment("_06inz.c");
end emitInitialEquationsBlock;

protected function modelHasNoEvents
  "True iff the model has no zero crossings and no relations -- the
   same condition emitEventBlock uses to displace _05evt.c. Hoisted
   into its own predicate so other blocks can share the gate (the
   inlined init-eq body references eqFunction_N symbols that the
   still-clang'd _05evt.c calls externally, so _06inz.c can only be
   safely displaced when _05evt.c is too)."
  input SimCode.SimCode simCode;
  output Boolean ok;
protected
  list<BackendDAE.ZeroCrossing> zcs, rels;
algorithm
  (zcs, rels) := match simCode
    case SimCode.SIMCODE(zeroCrossings = zcs, relations = rels) then (zcs, rels);
  end match;
  ok := listEmpty(zcs) and listEmpty(rels);
end modelHasNoEvents;

protected function classifyAlgorithmStatements
  "Recognise the specific SES_ALGORITHM shapes SCTL can lower inline.
   Currently:
     [STMT_ASSERT(DAE.RELATION(CREF(p), GREATEREQ, RCONST(b)), ...)]
       => EQ_PARAM_RANGE_ASSERT(slot, true,  b)
     [STMT_ASSERT(DAE.RELATION(CREF(p), LESSEQ,    RCONST(b)), ...)]
       => EQ_PARAM_RANGE_ASSERT(slot, false, b)
   when p resolves to a VK_PARAM slot in the layout.

   Anything else (more than one statement, a different relation, a
   non-cref LHS, ...) stays EQ_UNSUPPORTED so the .c file falls back
   to clang."
  input list<DAE.Statement> stmts;
  input Integer eqIndex;
  input VarLayout layout;
  output EqRecipe recipe;
algorithm
  recipe := match stmts
    local DAE.Exp cond;
          DAE.ComponentRef paramCref;
          DAE.Operator op;
          Real bound;
          Option<VarSlot> os;
          VarSlot vs;
          Integer slot;
    case {DAE.STMT_ASSERT(cond = DAE.RELATION(
            exp1 = DAE.CREF(componentRef = paramCref),
            operator = op,
            exp2 = DAE.RCONST(real = bound)))}
      algorithm
        os := lookupSlot(paramCref, layout);
      then match os
        case SOME(vs as VAR_SLOT(kind = VK_PARAM()))
          algorithm
            slot := absoluteSlot(vs.kind, vs.index, layout);
          then match op
            case DAE.GREATEREQ() then EQ_PARAM_RANGE_ASSERT(slot, true,  bound);
            case DAE.LESSEQ()    then EQ_PARAM_RANGE_ASSERT(slot, false, bound);
            else EQ_UNSUPPORTED("STMT_ASSERT relation operator not recognised");
          end match;
        else EQ_UNSUPPORTED("STMT_ASSERT cref does not resolve to a Real parameter");
      end match;
    else EQ_UNSUPPORTED("algorithm not in the recognised parameter-range assert shape");
  end match;
end classifyAlgorithmStatements;

protected function classifyParamEq
  "Variant of classifySimEq for the parameterEquations block. For
   SES_ALGORITHM the statements are routed through a synthetic
   SimCodeFunction.FUNCTION + DAEToMid + MidToLLVM (the same pipeline
   emitUserFunctions uses for Modelica user functions); the recipe is
   EQ_ALG_CALL(synthName, synthFn). emitBoundParametersBlock collects
   the synthFns and routes them via emitSyntheticFunctions so their
   bodies land in the same in-memory module.

   For other equation blocks (ODE, initial, etc.) the regular
   classifySimEq path is used so SES_ALGORITHM stays UNSUPPORTED
   until the same plumbing is wired there."
  input SimCode.SimEqSystem eq;
  input VarLayout layout;
  input Absyn.Path modelName;
  output EqRecipe recipe;
algorithm
  recipe := match eq
    local list<DAE.Statement> stmts;
          String synthName;
          SimCodeFunction.Function synthFn;
    /* SES_ALGORITHM is wired through the synthetic-function pipeline
     * (buildSyntheticAlgFunction + extractAlgorithmLocals +
     * emitSyntheticFunctions + EQ_ALG_CALL) but currently routes to
     * EQ_UNSUPPORTED because DAEToMid.ExpToMid throws on the
     * string-concatenation in the assert msg
     * ("Variable violating min constraint: ..." + String(x, "g")).
     * The single-statement MinAssert repro
     *
     *   model M parameter Real x(min=0)=1; Real y; equation der(y)=x; end M;
     *
     * produces exactly:
     *   assert(x >= 0.0, "...: 0.0 <= x, has value: " + String(x, "g"));
     *
     * Flipping the case below to the active branch is one line, but
     * needs DAEToMid's ExpToMid to grow string-typed DAE.ADD and/or
     * DAE.CALL(String, ...) coverage first.
     *
     *   case SimCode.SES_ALGORITHM(statements = stmts)
     *     algorithm
     *       (synthFn, synthName) := buildSyntheticAlgFunction(modelName, eq.index, stmts);
     *     then EQ_ALG_CALL(synthName, synthFn);
     */
    case SimCode.SES_ALGORITHM(statements = stmts)
      then classifyAlgorithmStatements(stmts, eq.index, layout);
    else classifySimEq(eq, layout);
  end match;
end classifyParamEq;

protected function emitBoundParametersBlock
  "Emit the two _08bnd.c entry points:
     _updateBoundParameters         -- inlined parameterEquations
     _updateBoundVariableAttributes -- stub
   when every recipe in SimCode.parameterEquations lowers cleanly
   (Real-parameter targets with supported RHS). HelloWorld
   trivially qualifies (empty paramEqs). ChuaCircuit has boolean
   parameter assignments that classifySimEq does not recognise; the
   gate fails there and _08bnd.c stays on clang.

   Records _08bnd.c into the dynamic skip list on success."
  input SimCode.SimCode simCode;
  input VarLayout layout;
protected
  list<SimCode.SimEqSystem> paramEqs;
  list<EqRecipe> recipes;
  String prefix;
  Absyn.Path name;
  Boolean ok;
algorithm
  paramEqs := match simCode
    case SimCode.SIMCODE(parameterEquations = paramEqs) then paramEqs;
  end match;
  name := simCodeName(simCode);
  recipes := list(classifyParamEq(eq, layout, name) for eq in paramEqs);
  /* Same two-stage gate as the initial-eq block. */
  ok := List.fold(recipes, countUnsupportedAsBoolean, true);
  if not ok then
    return;
  end if;
  for r in recipes loop
    if not canLowerEquation(r, layout) then
      return;
    end if;
  end for;
  prefix := modelSymbolPrefix(name);
  /* Emit any synthetic SimCodeFunction.Function the classifier built
   * (one per SES_ALGORITHM) before the call sites reference them.
   * The synthetics ride the same DAEToMid + MidToLLVM pipeline as
   * user functions; the calls SCTL emits next resolve to them at
   * JIT link time. */
  emitSyntheticFunctions(collectAlgSynths(recipes), name);
  /* emitEquationFunction emits a return at the end whether or not
   * every recipe body lowered, so the LLVM function is always
   * well-formed. ok=false means some equation body was skipped --
   * the runtime then sees stale parameter values for that
   * equation -- but the _updateBoundParameters symbol is in our
   * bitcode either way. Recording _08bnd.c unconditionally is
   * required for symbol uniqueness: leaving it on the clang path
   * after we already emitted the IR symbol triggers a JIT
   * duplicate-definition error. */
  _ := emitEquationFunction(prefix + "_updateBoundParameters",
                            recipes, layout, MODELICA_INTEGER);
  emitRuntimeIntStub(prefix + "_updateBoundVariableAttributes");
  recordDisplacedSegment("_08bnd.c");
end emitBoundParametersBlock;

protected function collectAlgSynths
  "Pull the SimCodeFunction.Function out of every EQ_ALG_CALL recipe."
  input list<EqRecipe> recipes;
  output list<SimCodeFunction.Function> synths = {};
algorithm
  for r in recipes loop
    () := match r
      case EQ_ALG_CALL() algorithm synths := r.synthFn :: synths; then ();
      else ();
    end match;
  end for;
  synths := listReverse(synths);
end collectAlgSynths;

protected function emitJacobianBlock
  "Emit the 22 _12jac.c entries. The 15 column-emit / DAG / const
   helpers are pure stubs (only called when an analytic Jacobian is
   available, which we are not providing). The 7
   _initialAnalyticJacobianX entries call back into the runtime to
   stamp jacobian->availability = JACOBIAN_NOT_AVAILABLE so DASKR
   falls back to numerical differencing rather than aborting on
   JACOBIAN_UNKNOWN. The stubs are semantically faithful for every
   model: they describe the runtime-fallback path DASKR would take
   anyway when no analytic Jacobian is exposed. Sparsity-pattern
   hints emitted by codegen are not preserved, which costs perf on
   large models but does not change results.

   Skipped when the model carries any linear or nonlinear systems:
   those generate extra _functionJacLSJac<N>_column /
   _initialAnalyticJacobianLSJac<N> entries that are not in the
   fixed stub set above. Falling back to clang for the whole
   _12jac.c is safer than emitting an incomplete stub set."
  input SimCode.SimCode simCode;
protected
  String prefix;
  Absyn.Path name;
  list<SimCode.SimEqSystem> linSys, nonlinSys;
algorithm
  (linSys, nonlinSys) := match simCode
    case SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(linearSystems = linSys, nonLinearSystems = nonlinSys))
      then (linSys, nonlinSys);
  end match;
  if not (listEmpty(linSys) and listEmpty(nonlinSys)) then
    return;
  end if;
  name := simCodeName(simCode);
  prefix := modelSymbolPrefix(name);
  /* column / DAG / const helpers -- never called when no analytic
   * Jacobian is exposed */
  emitStub(prefix + "_functionJacA_column",       MODELICA_INTEGER, {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_functionJacA_constantEqns", MODELICA_INTEGER, {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_JacA_DAG",                  MODELICA_VOID,    {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_functionJacB_column",       MODELICA_INTEGER, {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_JacB_DAG",                  MODELICA_VOID,    {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_functionJacC_column",       MODELICA_INTEGER, {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_JacC_DAG",                  MODELICA_VOID,    {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_functionJacD_column",       MODELICA_INTEGER, {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_JacD_DAG",                  MODELICA_VOID,    {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_functionJacF_column",       MODELICA_INTEGER, {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_JacF_DAG",                  MODELICA_VOID,    {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_functionJacH_column",       MODELICA_INTEGER, {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_JacH_DAG",                  MODELICA_VOID,    {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_functionJacADJ_column",     MODELICA_INTEGER, {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  emitStub(prefix + "_JacADJ_DAG",                MODELICA_VOID,    {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
  /* The seven initialAnalyticJacobianX entries set the JACOBIAN
   * struct's availability field to JACOBIAN_NOT_AVAILABLE so DASKR
   * knows to fall back to numerical differencing. */
  emitJacobianUnavailable(prefix + "_initialAnalyticJacobianA");
  emitJacobianUnavailable(prefix + "_initialAnalyticJacobianB");
  emitJacobianUnavailable(prefix + "_initialAnalyticJacobianC");
  emitJacobianUnavailable(prefix + "_initialAnalyticJacobianD");
  emitJacobianUnavailable(prefix + "_initialAnalyticJacobianF");
  emitJacobianUnavailable(prefix + "_initialAnalyticJacobianH");
  emitJacobianUnavailable(prefix + "_initialAnalyticJacobianADJ");
  recordDisplacedSegment("_12jac.c");
end emitJacobianBlock;

protected function emitEventBlock
  "Emit the _05evt.c entry points. When the model has no zero
   crossings and no relations the entries are pure stubs. When the
   model has zero crossings whose relations are simple DAE.RELATION
   shapes SCTL can lower (the common min/max-event shape that
   BouncingBall + ChuaCircuit use), _function_ZeroCrossings gets a
   real body that writes the residuals via omc_jit_zc_set; the
   other entries stay stubs because the runtime only consults them
   from descriptive log scopes.

   On any unsupported zero-crossing relation the gate fails and
   _05evt.c stays on clang."
  input SimCode.SimCode simCode;
  input VarLayout layout;
protected
  String prefix;
  Absyn.Path name;
  list<BackendDAE.ZeroCrossing> zcs;
  list<BackendDAE.ZeroCrossing> rels;
algorithm
  (zcs, rels) := match simCode
    case SimCode.SIMCODE(zeroCrossings = zcs, relations = rels) then (zcs, rels);
  end match;
  name := simCodeName(simCode);
  prefix := modelSymbolPrefix(name);
  if listEmpty(zcs) and listEmpty(rels) then
    /* No events -- pure-stub set, runtime never reads gout. */
    emitRuntimeVoidStub(prefix + "_function_initSample");
    emitRuntimeIntStub(prefix + "_function_ZeroCrossingsEquations");
    emitStub(prefix + "_function_ZeroCrossings",  MODELICA_INTEGER, {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_METATYPE});
    emitStub(prefix + "_function_updateRelations", MODELICA_INTEGER, {MODELICA_METATYPE, MODELICA_METATYPE, MODELICA_INTEGER});
    emitStub(prefix + "_zeroCrossingDescription",  MODELICA_METATYPE, {MODELICA_INTEGER, MODELICA_METATYPE});
    emitStub(prefix + "_relationDescription",      MODELICA_METATYPE, {MODELICA_INTEGER});
    recordDisplacedSegment("_05evt.c");
    return;
  end if;
  /* Model has events. Lower zero crossings + the relations update
   * if every relation is in the simple DAE.RELATION shape SCTL
   * understands. */
  if not allZeroCrossingsLowerable(zcs, layout) then
    return;
  end if;
  emitRuntimeVoidStub(prefix + "_function_initSample");
  emitRuntimeIntStub(prefix + "_function_ZeroCrossingsEquations");
  emitZeroCrossingsBody(prefix + "_function_ZeroCrossings", zcs, layout);
  emitUpdateRelationsBody(prefix + "_function_updateRelations", zcs, layout);
  emitStub(prefix + "_zeroCrossingDescription",  MODELICA_METATYPE, {MODELICA_INTEGER, MODELICA_METATYPE});
  emitStub(prefix + "_relationDescription",      MODELICA_METATYPE, {MODELICA_INTEGER});
  recordDisplacedSegment("_05evt.c");
end emitEventBlock;

protected function allZeroCrossingsLowerable
  "True iff every zero-crossing's relation is a DAE.RELATION whose
   operands fall in the narrow shape emitZeroCrossingResidual is
   actually wired to lower: each side is either a real constant or
   a cref that resolves in the layout. canLowerExp also accepts
   BINARY / CALL nodes that emitExp threads through SSA, but the
   downstream genRSub in emitZeroCrossingResidual needs both
   operands to be alloca-backed variables -- a SSA temp returned
   from a binop dst slot makes binopInit dereference a null
   AllocaInst. Until emitZeroCrossingResidual learns to materialise
   intermediate allocas itself the gate stays restrictive."
  input list<BackendDAE.ZeroCrossing> zcs;
  input VarLayout layout;
  output Boolean ok = true;
algorithm
  for zc in zcs loop
    () := match zc
      local DAE.Exp e1, e2;
            DAE.Operator op;
      case BackendDAE.ZERO_CROSSING(relation_ = DAE.RELATION(exp1 = e1, operator = op, exp2 = e2))
        algorithm
          if not (isLowerableRelationOp(op)
                  and isZeroCrossingOperand(e1, layout)
                  and isZeroCrossingOperand(e2, layout)) then
            ok := false;
          end if;
        then ();
      else
        algorithm ok := false; then ();
    end match;
    if not ok then return; end if;
  end for;
end allZeroCrossingsLowerable;

protected function isZeroCrossingOperand
  "True iff <e> is a real constant or a cref in the layout. Used
   by allZeroCrossingsLowerable to reject zero-crossing relations
   whose operands cannot be passed directly to genRSub."
  input DAE.Exp e;
  input VarLayout layout;
  output Boolean ok;
algorithm
  ok := match e
    local DAE.ComponentRef cref;
    case DAE.RCONST() then true;
    case DAE.ICONST() then true;
    case DAE.CREF(componentRef = cref) then canLowerCref(cref, layout);
    else false;
  end match;
end isZeroCrossingOperand;

protected function isLowerableRelationOp
  "True for the four monotonic comparison operators SCTL emits as
   gout residuals (LESS / LESSEQ / GREATER / GREATEREQ)."
  input DAE.Operator op;
  output Boolean b;
algorithm
  b := match op
    case DAE.LESS()      then true;
    case DAE.LESSEQ()    then true;
    case DAE.GREATER()   then true;
    case DAE.GREATEREQ() then true;
    else false;
  end match;
end isLowerableRelationOp;

protected function emitZeroCrossingsBody
  "Emit  int <fname>(DATA *data, threadData_t *threadData, double *gout) {
            gout[0] = <residual for zc 0>;
            gout[1] = <residual for zc 1>;
            ...
            return 0;
         }
   into the active in-memory module. The residual encoding is
   positive when the relation is currently satisfied (matches the
   sign convention CodegenC uses through LessEqZC / GreaterEqZC):
     LESS(lhs, rhs) / LESSEQ(lhs, rhs)       -> rhs - lhs
     GREATER(lhs, rhs) / GREATEREQ(lhs, rhs) -> lhs - rhs"
  input String fname;
  input list<BackendDAE.ZeroCrossing> zcs;
  input VarLayout layout;
protected
  EmitCtx ctx;
  Integer i = 0;
  String valTmp;
  Boolean ok;
algorithm
  EXT_LLVM.startFuncGen(fname);
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "data");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "threadData");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "gout");
  EXT_LLVM.genFunctionType(MODELICA_INTEGER);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);
  ctx := EMIT_CTX(layout, 0);
  /* The whole per-zc emission runs inside try/else: a deep
   * MMC_THROW from emitExp would otherwise skip the genReturnZero
   * + finnishGen below, leaving the LLVM function without a
   * terminator -- which crashes the optimizer pass that runs at
   * JIT materialization time. */
  for zc in zcs loop
    try
      (ctx, valTmp, ok) := emitZeroCrossingResidual(zc, ctx);
      if not ok then
        (ctx, valTmp) := freshTmp(ctx);
        EXT_LLVM.genAllocaModelicaReal(valTmp, false);
        EXT_LLVM.genStoreLiteralReal(0.0, valTmp);
      end if;
      EXT_LLVM.genCallArg("gout");
      EXT_LLVM.genCallArgConstInt(i);
      EXT_LLVM.genCallArg(valTmp);
      EXT_LLVM.genCall("omc_jit_zc_set", MODELICA_VOID, "", false);
    else end try;
    i := i + 1;
  end for;
  EXT_LLVM.genReturnZero();
  EXT_LLVM.finnishGen();
end emitZeroCrossingsBody;

protected function emitUpdateRelationsBody
  "Emit  int <fname>(DATA *data, threadData_t *threadData, int evalForZeroCross) {
            <for each zc>
              residual_i = <residual emission>;
              omc_jit_relation_set(data, i, residual_i);
            return 0;
         }
   into the active in-memory module. The runtime compares
   data->simulationInfo->relations[] against ->relationsPre[] to
   determine which event-action eqFunctions to fire; SCTL only
   needs to populate the current side of the comparison. The
   evalForZeroCross arg is ignored in the lowered body -- the
   residual emission is correct in both branches CodegenC takes."
  input String fname;
  input list<BackendDAE.ZeroCrossing> zcs;
  input VarLayout layout;
protected
  EmitCtx ctx;
  Integer i = 0;
  String valTmp;
  Boolean ok;
algorithm
  EXT_LLVM.startFuncGen(fname);
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "data");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "threadData");
  EXT_LLVM.genFunctionArg(MODELICA_INTEGER, "evalForZeroCross");
  EXT_LLVM.genFunctionType(MODELICA_INTEGER);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);
  ctx := EMIT_CTX(layout, 0);
  /* See emitZeroCrossingsBody: per-zc try/else so a deep MMC_THROW
   * does not skip the genReturnZero + finnishGen below. */
  for zc in zcs loop
    try
      (ctx, valTmp, ok) := emitZeroCrossingResidual(zc, ctx);
      if not ok then
        (ctx, valTmp) := freshTmp(ctx);
        EXT_LLVM.genAllocaModelicaReal(valTmp, false);
        EXT_LLVM.genStoreLiteralReal(0.0, valTmp);
      end if;
      EXT_LLVM.genCallArg("data");
      EXT_LLVM.genCallArgConstInt(i);
      EXT_LLVM.genCallArg(valTmp);
      EXT_LLVM.genCall("omc_jit_relation_set", MODELICA_VOID, "", false);
    else end try;
    i := i + 1;
  end for;
  EXT_LLVM.genReturnZero();
  EXT_LLVM.finnishGen();
end emitUpdateRelationsBody;

protected function emitZeroCrossingResidual
  "Emit (rhs - lhs) or (lhs - rhs) depending on the relation
   direction and return the name of the alloca holding the result.
   ok is false when either operand failed to lower (emitExp
   returned a placeholder dst); callers must propagate the failure
   so the surrounding function is not committed half-built."
  input BackendDAE.ZeroCrossing zc;
  input EmitCtx ctxIn;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
protected
  DAE.Exp e1, e2;
  DAE.Operator op;
  EmitCtx ctx1, ctx2;
  String dst1, dst2;
  Boolean ok1, ok2;
  Boolean isPositiveWhenLessThan;
algorithm
  BackendDAE.ZERO_CROSSING(relation_ = DAE.RELATION(exp1 = e1, operator = op, exp2 = e2)) := zc;
  isPositiveWhenLessThan := match op
    case DAE.LESS()   then true;
    case DAE.LESSEQ() then true;
    else false;  /* GREATER / GREATEREQ */
  end match;
  (ctx1, dst1, ok1) := emitExp(e1, ctxIn);
  (ctx2, dst2, ok2) := emitExp(e2, ctx1);
  ok := ok1 and ok2;
  if not ok then
    outCtx := ctx2;
    dst := "<zc-residual-unlowerable>";
    return;
  end if;
  (outCtx, dst) := freshTmp(ctx2);
  EXT_LLVM.genAllocaModelicaReal(dst, false);
  if isPositiveWhenLessThan then
    EXT_LLVM.genRSub(dst, dst2, dst1);  /* rhs - lhs */
  else
    EXT_LLVM.genRSub(dst, dst1, dst2);  /* lhs - rhs */
  end if;
end emitZeroCrossingResidual;

protected function countUnsupportedAsBoolean
  "List.fold seed: stays true while every recipe is supported."
  input EqRecipe r;
  input Boolean accIn;
  output Boolean accOut;
algorithm
  accOut := match r
    case EQ_UNSUPPORTED() then false;
    else accIn;
  end match;
end countUnsupportedAsBoolean;

protected function recipeKindString
  input EqRecipe r;
  output String s;
algorithm
  s := match r
    local String why;
    case EQ_DERIVATIVE_ASSIGN() then "DERIV(" + intString(r.slotIndex) + ")";
    case EQ_STATE_ASSIGN()      then "STATE(" + intString(r.slotIndex) + ")";
    case EQ_ALG_ASSIGN()        then "ALG(" + intString(r.slotIndex) + ")";
    case EQ_PARAM_ASSIGN()      then "PARAM(" + intString(r.slotIndex) + ")";
    case EQ_BOOL_PARAM_ASSIGN() then "BPARM(" + intString(r.slotIndex) + ")";
    case EQ_NOOP()              then "NOOP";
    case EQ_ALG_CALL()          then "ALG_CALL(" + r.synthName + ")";
    case EQ_PARAM_RANGE_ASSERT() then "PARAM_RANGE_ASSERT(slot=" + intString(r.slotIndex) +
                                       (if r.isGreaterEq then ", >=, " else ", <=, ") +
                                       realString(r.bound) + ")";
    case EQ_UNSUPPORTED(reason = why) then "UNSUPPORTED(" + why + ")";
  end match;
end recipeKindString;

protected function recipeRhsStr
  input EqRecipe r;
  output String s;
algorithm
  s := match r
    local DAE.Exp e;
    case EQ_DERIVATIVE_ASSIGN(rhs=e) then ExpressionBasics.printExpStr(e);
    case EQ_STATE_ASSIGN(rhs=e)      then ExpressionBasics.printExpStr(e);
    case EQ_ALG_ASSIGN(rhs=e)        then ExpressionBasics.printExpStr(e);
    case EQ_PARAM_ASSIGN(rhs=e)      then ExpressionBasics.printExpStr(e);
    case EQ_BOOL_PARAM_ASSIGN(rhs=e) then ExpressionBasics.printExpStr(e);
    else "";
  end match;
end recipeRhsStr;

protected function emitInitialEquationsWrapper
  "Emit  int <wrapper>(DATA *data, threadData_t *threadData) {
            <inner>(data, threadData);
            return 0;
         }
   into the current in-memory module."
  input String wrapperName;
  input String innerName;
algorithm
  EXT_LLVM.startFuncGen(wrapperName);
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "data");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "threadData");
  EXT_LLVM.genFunctionType(MODELICA_INTEGER);
  EXT_LLVM.genFunctionPrototype(wrapperName);
  EXT_LLVM.genFunctionBody(wrapperName);
  EXT_LLVM.genCallArg("data");
  EXT_LLVM.genCallArg("threadData");
  EXT_LLVM.genCall(innerName, MODELICA_VOID, "", false);
  EXT_LLVM.genReturnZero();
  EXT_LLVM.finnishGen();
end emitInitialEquationsWrapper;

protected function buildSyntheticAlgFunction
  "Package the statements of a SES_ALGORITHM as a synthetic
   SimCodeFunction.FUNCTION suitable for DAEToMid + MidToLLVM
   consumption. The resulting function takes no args, returns
   nothing, and carries the algorithm body as-is.

   StmtsToMid requires every cref the body writes to to be declared
   as a local; extractAlgorithmLocals walks the statements to
   collect them.

   The mangled symbol name returned matches what
   MidToLLVM.genFunction produces: \"omc_\" plus the path
   underscore-joined."
  input Absyn.Path modelName;
  input Integer eqIdx;
  input list<DAE.Statement> stmts;
  output SimCodeFunction.Function fn;
  output String mangledName;
protected
  Absyn.Path synthPath;
  list<SimCodeFunction.Variable> locals;
algorithm
  synthPath := AbsynUtil.suffixPath(modelName, "synthAlg_" + intString(eqIdx));
  locals := extractAlgorithmLocals(stmts);
  fn := SimCodeFunction.FUNCTION(
    synthPath,
    {} /* outVars        */,
    {} /* funcArgs       */,
    locals,
    stmts,
    SCode.PUBLIC(),
    sourceInfo());
  mangledName := "omc_" + modelSymbolPrefix(synthPath);
end buildSyntheticAlgFunction;

protected function extractAlgorithmLocals
  "Walk a DAE.Statement list and collect distinct STMT_ASSIGN LHS
   crefs (with their declared types) as SimCodeFunction.Variable
   entries. Recursively descends through STMT_IF / STMT_FOR /
   STMT_WHILE branches. Deduplication is keyed on the
   cref's print-string so the same tmp referenced from multiple
   branches lands once.

   The returned list is in insertion order (first occurrence first)
   so MidCode's variable-numbering is stable."
  input list<DAE.Statement> stmts;
  output list<SimCodeFunction.Variable> vars = {};
protected
  list<String> seen = {};
algorithm
  for s in stmts loop
    (vars, seen) := collectAssignLhs(s, vars, seen);
  end for;
  vars := listReverse(vars);
end extractAlgorithmLocals;

protected function collectAssignLhs
  "One step of extractAlgorithmLocals. Recursive on the compound
   statement shapes (STMT_IF / STMT_FOR / STMT_WHILE)."
  input DAE.Statement stmt;
  input list<SimCodeFunction.Variable> varsIn;
  input list<String> seenIn;
  output list<SimCodeFunction.Variable> varsOut = varsIn;
  output list<String> seenOut = seenIn;
algorithm
  () := match stmt
    local DAE.Type ty;
          DAE.Exp lhs;
          DAE.ComponentRef cref;
          String key;
          list<DAE.Statement> tBranch, fBranch, body;
          list<tuple<DAE.Exp, list<DAE.Statement>>> elseIfs;
          tuple<DAE.Exp, list<DAE.Statement>> ei;
    case DAE.STMT_ASSIGN(type_ = ty, exp1 = DAE.CREF(componentRef = cref))
      algorithm
        key := ComponentReferenceBasics.printComponentRefStr(cref);
        if not listMember(key, seenOut) then
          varsOut := SimCodeFunction.VARIABLE(cref, ty, NONE(), {},
                                              DAE.NON_PARALLEL(),
                                              DAE.VARIABLE(), false) :: varsOut;
          seenOut := key :: seenOut;
        end if;
        then ();
    case DAE.STMT_IF(statementLst = tBranch, else_ = DAE.NOELSE())
      algorithm
        for s in tBranch loop
          (varsOut, seenOut) := collectAssignLhs(s, varsOut, seenOut);
        end for;
        then ();
    case DAE.STMT_IF(statementLst = tBranch, else_ = DAE.ELSEIF(statementLst = body))
      algorithm
        for s in tBranch loop (varsOut, seenOut) := collectAssignLhs(s, varsOut, seenOut); end for;
        for s in body    loop (varsOut, seenOut) := collectAssignLhs(s, varsOut, seenOut); end for;
        then ();
    case DAE.STMT_IF(statementLst = tBranch, else_ = DAE.ELSE(fBranch))
      algorithm
        for s in tBranch loop (varsOut, seenOut) := collectAssignLhs(s, varsOut, seenOut); end for;
        for s in fBranch loop (varsOut, seenOut) := collectAssignLhs(s, varsOut, seenOut); end for;
        then ();
    case DAE.STMT_FOR(statementLst = body)
      algorithm
        for s in body loop (varsOut, seenOut) := collectAssignLhs(s, varsOut, seenOut); end for;
        then ();
    case DAE.STMT_WHILE(statementLst = body)
      algorithm
        for s in body loop (varsOut, seenOut) := collectAssignLhs(s, varsOut, seenOut); end for;
        then ();
    /* STMT_ASSERT / STMT_NORETCALL / STMT_TERMINATE etc.: no LHS to
     * collect. */
    else ();
  end match;
end collectAssignLhs;

protected function emitSyntheticFunctions
  "Run a list of synthetic SimCodeFunction.Functions through
   DAEToMid + MidToLLVM.genProgram so their bodies land in the
   currently-active in-memory module."
  input list<SimCodeFunction.Function> synths;
  input Absyn.Path modelName;
protected
  String moduleName;
  MidCode.Program midProgram;
algorithm
  if listEmpty(synths) then
    return;
  end if;
  moduleName := modelSymbolPrefix(modelName) + "_synth";
  midProgram := DAEToMid.daeProgramToMid(moduleName, synths, {});
  MidToLLVM.genProgram(midProgram);
end emitSyntheticFunctions;

protected function emitUserFunctions
  "Lower the model's user-defined Modelica functions to LLVM IR in
   the current in-memory module by re-using the existing function-JIT
   pipeline DAEToMid -> MidToLLVM.genProgram. The same pipeline drives
   the top-level function JIT under -d=jit_eval_func, so SCTL does not
   re-implement function-body lowering.

   When the SIMCODE contains no user functions and no record
   declarations there is nothing to do. The CodegenC counterpart of
   this work lives in <Model>_functions.c (and <Model>_records.c)."
  input SimCode.SimCode simCode;
protected
  list<SimCodeFunction.Function> simFuncs;
  list<SimCodeFunction.RecordDeclaration> recordDecls;
  Absyn.Path modelName;
  String moduleName;
  MidCode.Program midProgram;
algorithm
  (simFuncs, recordDecls, modelName) := match simCode
    case SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(name = modelName, functions = simFuncs),
                         recordDecls = recordDecls)
      then (simFuncs, recordDecls, modelName);
  end match;
  if listEmpty(simFuncs) and listEmpty(recordDecls) then
    return;
  end if;
  moduleName := modelSymbolPrefix(modelName) + "_userfuncs";
  midProgram := DAEToMid.daeProgramToMid(moduleName, simFuncs, recordDecls);
  MidToLLVM.genProgram(midProgram);
end emitUserFunctions;

protected function emitDisplacingStubs
  "Walk the runtimeEntryCatalog and emit IR for every entry whose body
   is not EB_TODO. The catalog is the single source of truth; this
   function just drives EXT_LLVM through it.

   Keep-in-sync invariant: the set of distinct segmentFile fields on
   non-EB_TODO entries (returned by displacedSegmentFiles) must equal
   the set of files compileModelToBitcode skips. CevalScriptBackend
   currently mirrors the list manually; closing that loop is in
   progress."
  input Absyn.Path modelName;
protected
  String prefix;
algorithm
  prefix := modelSymbolPrefix(modelName);
  for e in runtimeEntryCatalog() loop
    emitRuntimeEntry(prefix, e);
  end for;
end emitDisplacingStubs;

protected function emitRuntimeEntry
  "Emit one RuntimeEntry from the catalog into the active in-memory
   module. EB_STUB and EB_NULL_PTR both lower through emitStub (zero
   of an opaque pointer is null). EB_RETURN_MINUS_ONE lowers through
   emitStubMinusOne for entries whose return value the runtime checks
   as a sentinel (e.g. <Model>_initialAnalyticJacobianA returning -1
   to mean 'no analytic Jacobian, fall back to numerical
   differencing'). EB_TODO entries are skipped here -- the matching
   .c file stays in compileModelToBitcode's clang loop."
  input String prefix;
  input RuntimeEntry entry;
algorithm
  () := match entry.body
    case EB_STUB() algorithm
      emitStub(prefix + entry.nameSuffix, entry.retTy, entry.argTys);
      then ();
    case EB_NULL_PTR() algorithm
      emitStubNullPtr(prefix + entry.nameSuffix, entry.retTy, entry.argTys);
      then ();
    case EB_RETURN_MINUS_ONE() algorithm
      emitStubMinusOne(prefix + entry.nameSuffix, entry.argTys);
      then ();
    case EB_JAC_UNAVAILABLE() algorithm
      emitJacobianUnavailable(prefix + entry.nameSuffix);
      then ();
    case EB_TODO() then ();
  end match;
end emitRuntimeEntry;

protected function emitJacobianUnavailable
  "Emit  int <fname>(DATA*, threadData_t*, JACOBIAN *jacobian) {
            omc_jit_jacobian_set_unavailable(jacobian);
            return 1;
         }
   The third argument is positional -- IR name 'jacobian' so the
   genCallArg below picks the same alloca."
  input String fname;
protected
  constant String RETVAR = "tmp_ret_one";
algorithm
  EXT_LLVM.startFuncGen(fname);
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "data");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "threadData");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "jacobian");
  EXT_LLVM.genFunctionType(MODELICA_INTEGER);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);
  EXT_LLVM.genCallArg("jacobian");
  EXT_LLVM.genCall("omc_jit_jacobian_set_unavailable", MODELICA_VOID, "", false);
  EXT_LLVM.genAllocaModelicaInt(RETVAR, false);
  EXT_LLVM.genStoreLiteralInt(1, RETVAR);
  EXT_LLVM.genReturn(RETVAR);
  EXT_LLVM.finnishGen();
end emitJacobianUnavailable;

protected function emitStubMinusOne
  "Emit  int <fname>(<argTys...>) { return -1; }  into the active
   module. Sentinel for runtime-checked unavailable-analytic-Jacobian
   et al."
  input String fname;
  input list<Integer> argTys;
protected
  Integer i = 0;
  constant String RETVAR = "tmp_ret_neg1";
algorithm
  EXT_LLVM.startFuncGen(fname);
  for ty in argTys loop
    EXT_LLVM.genFunctionArg(ty, "a" + intString(i));
    i := i + 1;
  end for;
  EXT_LLVM.genFunctionType(MODELICA_INTEGER);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);
  EXT_LLVM.genAllocaModelicaInt(RETVAR, false);
  EXT_LLVM.genStoreLiteralInt(-1, RETVAR);
  EXT_LLVM.genReturn(RETVAR);
  EXT_LLVM.finnishGen();
end emitStubMinusOne;

protected function emitEquation
  "Emit one EqRecipe's IR. Returns updated EmitCtx + Boolean ok.
   On a recipe we cannot lower, ok is set to false and the caller
   short-circuits the loop."
  input EqRecipe r;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output Boolean ok;
algorithm
  (outCtx, ok) := match r
    local Integer slot;
          DAE.Exp rhs;
          EmitCtx ctx2;
          String rhsTmp;
          Boolean exprOk;
    case EQ_DERIVATIVE_ASSIGN(slotIndex=slot, rhs=rhs)
      algorithm
        (ctx2, rhsTmp, exprOk) := emitExp(rhs, ctx);
        if exprOk then
          emitWriteRealVar(absoluteSlot(VK_DERIVATIVE(), slot, ctx2.layout),
                           rhsTmp);
        end if;
      then (ctx2, exprOk);
    case EQ_STATE_ASSIGN(slotIndex=slot, rhs=rhs)
      algorithm
        (ctx2, rhsTmp, exprOk) := emitExp(rhs, ctx);
        if exprOk then
          emitWriteRealVar(absoluteSlot(VK_STATE(), slot, ctx2.layout),
                           rhsTmp);
        end if;
      then (ctx2, exprOk);
    case EQ_ALG_ASSIGN(slotIndex=slot, rhs=rhs)
      algorithm
        (ctx2, rhsTmp, exprOk) := emitExp(rhs, ctx);
        if exprOk then
          emitWriteRealVar(absoluteSlot(VK_ALG(), slot, ctx2.layout),
                           rhsTmp);
        end if;
      then (ctx2, exprOk);
    case EQ_PARAM_ASSIGN(slotIndex=slot, rhs=rhs)
      algorithm
        (ctx2, rhsTmp, exprOk) := emitExp(rhs, ctx);
        if exprOk then
          emitWriteRealParam(slot, rhsTmp);
        end if;
      then (ctx2, exprOk);
    case EQ_BOOL_PARAM_ASSIGN(slotIndex=slot, rhs=rhs)
      algorithm
        (ctx2, rhsTmp, exprOk) := emitExp(rhs, ctx);
        if exprOk then
          emitWriteBoolParam(slot, rhsTmp);
        end if;
      then (ctx2, exprOk);
    case EQ_NOOP()        then (ctx, true);
    case EQ_ALG_CALL()    algorithm emitAlgCall(r.synthName); then (ctx, true);
    case EQ_PARAM_RANGE_ASSERT()
      algorithm emitParamRangeAssert(r.slotIndex, r.isGreaterEq, r.bound);
      then (ctx, true);
    case EQ_UNSUPPORTED() then (ctx, false);
  end match;
end emitEquation;

protected function emitParamRangeAssert
  "Emit  call void @omc_jit_assert_real_<ge|le>(ptr %data, i64 slot, double bound)
   into the active function body. The helper compares
   data->simulationInfo->realParameter[slot] against bound and emits
   a warning on violation; in-range values are silent."
  input Integer slot;
  input Boolean isGreaterEq;
  input Real bound;
protected
  String boundTmp;
algorithm
  /* Use a fresh tmp name so each emission is unique within the
   * function. The name is local to the current basic block. */
  boundTmp := "assertBoundTmp" + intString(slot);
  EXT_LLVM.genAllocaModelicaReal(boundTmp, false);
  EXT_LLVM.genStoreLiteralReal(bound, boundTmp);
  EXT_LLVM.genCallArg("data");
  EXT_LLVM.genCallArgConstInt(slot);
  EXT_LLVM.genCallArg(boundTmp);
  EXT_LLVM.genCall(if isGreaterEq then "omc_jit_assert_real_ge"
                                   else "omc_jit_assert_real_le",
                   MODELICA_VOID, "", false);
end emitParamRangeAssert;

protected function emitAlgCall
  "Emit  call void @<synthName>(ptr %threadData)  into the active
   function body. The synthName already has the omc_ prefix and the
   underscore-mangled path, matching MidToLLVM.genFunction's naming."
  input String synthName;
algorithm
  EXT_LLVM.genCallArg("threadData");
  EXT_LLVM.genCall(synthName, MODELICA_VOID, "", false);
end emitAlgCall;

protected function absoluteSlot
  "Translate a (kind, sub-index) into the absolute realVars[] slot
   the C runtime uses. SimCodeVar.SimVar.index for stateVars,
   derivativeVars, and algVars is already the absolute slot in the
   localData[0]->realVars flat buffer (states 0..nStates-1, then
   derivatives nStates..2*nStates-1, then algebraics). No further
   offset is needed -- the (kind, subIndex) pair is kept so future
   variants (e.g. parameter storage in simulationInfo->realParameter,
   which lives in a different buffer) can be lowered through a
   different access helper without touching the recipe layer."
  input VarKind kind;
  input Integer subIndex;
  input VarLayout layout;
  output Integer slot;
algorithm
  slot := match kind
    case VK_STATE()      then subIndex;
    case VK_DERIVATIVE() then subIndex;
    case VK_ALG()        then subIndex;
    case VK_PARAM()      then subIndex;
    case VK_BOOL_PARAM() then subIndex;
  end match;
end absoluteSlot;

protected function emitReadRealVar
  "Emit  %dst = call double @omc_jit_get_real_var(ptr %data, i64 slot)
   into the active function body, returning the name of the freshly
   alloca'd double the call result is stored to."
  input Integer slot;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
algorithm
  (outCtx, dst) := freshTmp(ctx);
  EXT_LLVM.genAllocaModelicaReal(dst, false);
  EXT_LLVM.genCallArg("data");
  EXT_LLVM.genCallArgConstInt(slot);
  EXT_LLVM.genCall("omc_jit_get_real_var", MODELICA_REAL, dst, true);
end emitReadRealVar;

protected function emitReadRealParam
  "Same as emitReadRealVar but routes through omc_jit_get_real_param,
   which reads data->simulationInfo->realParameter[] instead of the
   realVars buffer. Used when a CREF resolves to a VK_PARAM slot."
  input Integer slot;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
algorithm
  (outCtx, dst) := freshTmp(ctx);
  EXT_LLVM.genAllocaModelicaReal(dst, false);
  EXT_LLVM.genCallArg("data");
  EXT_LLVM.genCallArgConstInt(slot);
  EXT_LLVM.genCall("omc_jit_get_real_param", MODELICA_REAL, dst, true);
end emitReadRealParam;

protected function emitWriteRealVar
  "Emit  call void @omc_jit_set_real_var(ptr %data, i64 slot, double %src)
   into the active function body. No return value."
  input Integer slot;
  input String src;
algorithm
  EXT_LLVM.genCallArg("data");
  EXT_LLVM.genCallArgConstInt(slot);
  EXT_LLVM.genCallArg(src);
  EXT_LLVM.genCall("omc_jit_set_real_var", MODELICA_VOID, "", false);
end emitWriteRealVar;

protected function emitWriteRealParam
  "Emit  call void @omc_jit_set_real_param(ptr %data, i64 slot, double %src)
   into the active function body. Writes into the parameter array
   data->simulationInfo->realParameter[] rather than realVars."
  input Integer slot;
  input String src;
algorithm
  EXT_LLVM.genCallArg("data");
  EXT_LLVM.genCallArgConstInt(slot);
  EXT_LLVM.genCallArg(src);
  EXT_LLVM.genCall("omc_jit_set_real_param", MODELICA_VOID, "", false);
end emitWriteRealParam;

protected function emitWriteBoolParam
  "Emit  call void @omc_jit_set_bool_param(ptr %data, i64 slot, double %src)
   into the active function body. The boolean RHS arrives as a Real
   (0.0 or 1.0) via emitExp's DAE.BCONST arm; the runtime accessor
   casts it back to int when writing booleanParameter[]."
  input Integer slot;
  input String src;
algorithm
  EXT_LLVM.genCallArg("data");
  EXT_LLVM.genCallArgConstInt(slot);
  EXT_LLVM.genCallArg(src);
  EXT_LLVM.genCall("omc_jit_set_bool_param", MODELICA_VOID, "", false);
end emitWriteBoolParam;

protected function canLowerEquation
  "Pre-validation mirror of emitEquation: return true iff lowering the
   recipe to IR would succeed. Used before opening an LLVM function
   for a block of equations so we never commit a partial body that
   collides with the CodegenC version."
  input EqRecipe r;
  input VarLayout layout;
  output Boolean ok;
algorithm
  ok := match r
    case EQ_DERIVATIVE_ASSIGN() then canLowerExp(r.rhs, layout);
    case EQ_STATE_ASSIGN()      then canLowerExp(r.rhs, layout);
    case EQ_ALG_ASSIGN()        then canLowerExp(r.rhs, layout);
    case EQ_PARAM_ASSIGN()      then canLowerExp(r.rhs, layout);
    case EQ_BOOL_PARAM_ASSIGN() then canLowerExp(r.rhs, layout);
    case EQ_NOOP()              then true;
    case EQ_ALG_CALL()          then true;
    case EQ_PARAM_RANGE_ASSERT() then true;
    case EQ_UNSUPPORTED()       then false;
  end match;
end canLowerEquation;

protected function canLowerExp
  "Pre-validation mirror of emitExp: true iff every node in <e> falls
   into a case emitExp already handles, with operands the supporting
   helpers (emitCrefRead, emitBinaryReal) accept."
  input DAE.Exp e;
  input VarLayout layout;
  output Boolean ok;
algorithm
  ok := match e
    local DAE.Exp e1, e2, sub;
          DAE.Operator op;
          DAE.ComponentRef cref;
          String name;
    case DAE.RCONST() then true;
    case DAE.ICONST() then true;
    case DAE.BCONST() then true;
    case DAE.CREF(componentRef = cref) then canLowerCref(cref, layout);
    case DAE.UNARY(operator = DAE.UMINUS(), exp = sub)
      then canLowerExp(sub, layout);
    case DAE.BINARY(exp1 = e1, operator = op, exp2 = e2)
      then canLowerOp(op) and canLowerExp(e1, layout) and canLowerExp(e2, layout);
    case DAE.CALL(path = Absyn.IDENT(name = name), expLst = {sub})
      guard isLibmUnaryReal(name)
      then canLowerExp(sub, layout);
    case DAE.CALL(path = Absyn.IDENT(name = name), expLst = {e1, e2})
      guard isLibmBinaryReal(name)
      then canLowerExp(e1, layout) and canLowerExp(e2, layout);
    else false;
  end match;
end canLowerExp;

protected function canLowerCref
  "True if emitCrefRead would handle this cref. The supported shapes
   mirror the three branches in emitCrefRead: 'time', $START.<var>
   whose inner resolves in the layout, or any cref that itself
   resolves in the layout."
  input DAE.ComponentRef cref;
  input VarLayout layout;
  output Boolean ok;
protected
  Option<VarSlot> os;
  Option<DAE.ComponentRef> innerOpt;
  DAE.ComponentRef innerCref;
algorithm
  if isTimeCref(cref) then
    ok := true;
    return;
  end if;
  innerOpt := startCrefInner(cref);
  if isSome(innerOpt) then
    SOME(innerCref) := innerOpt;
    os := lookupSlot(innerCref, layout);
    ok := match os
      case SOME(_) then true;
      case NONE()  then false;
    end match;
    return;
  end if;
  os := lookupSlot(cref, layout);
  ok := match os
    case SOME(_) then true;
    case NONE()  then false;
  end match;
end canLowerCref;

protected function canLowerOp
  "True if emitBinaryReal handles this operator."
  input DAE.Operator op;
  output Boolean ok;
algorithm
  ok := match op
    case DAE.ADD() then true;
    case DAE.SUB() then true;
    case DAE.MUL() then true;
    case DAE.DIV() then true;
    case DAE.POW() then true;
    else false;
  end match;
end canLowerOp;

protected function emitExp
  "Minimal DAE.Exp -> LLVM lowering. Recognises:
     RCONST, ICONST                       -> literal store into a fresh alloca
     CREF                                 -> emitReadRealVar via layout lookup
     UNARY(UMINUS_REAL, e)                -> emitExp e, fneg
     BINARY(e1, +/-/*//, e2)              -> emitExp both, fadd/fsub/fmul/fdiv
   Returns the name of the alloca holding the result + Boolean ok.
   Unsupported constructs return ok=false and a placeholder name so
   the caller short-circuits without inspecting the alloca."
  input DAE.Exp e;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
algorithm
  (outCtx, dst, ok) := match e
    local
      Real r;
      Integer i;
      Boolean b;
      DAE.ComponentRef cref;
      DAE.Exp e1, e2, sub;
      DAE.Operator op;
      Option<VarSlot> os;
      VarSlot vs;
      EmitCtx ctx1, ctx2;
      String tmp, dst1, dst2;
      Boolean ok1, ok2;
      Integer absSlot;
    case DAE.RCONST(real=r)
      algorithm
        (ctx1, tmp) := freshTmp(ctx);
        EXT_LLVM.genAllocaModelicaReal(tmp, false);
        EXT_LLVM.genStoreLiteralReal(r, tmp);
      then (ctx1, tmp, true);
    case DAE.ICONST(integer=i)
      algorithm
        (ctx1, tmp) := freshTmp(ctx);
        EXT_LLVM.genAllocaModelicaReal(tmp, false);
        EXT_LLVM.genStoreLiteralReal(intReal(i), tmp);
      then (ctx1, tmp, true);
    case DAE.BCONST(bool=b)
      algorithm
        (ctx1, tmp) := freshTmp(ctx);
        EXT_LLVM.genAllocaModelicaReal(tmp, false);
        EXT_LLVM.genStoreLiteralReal(if b then 1.0 else 0.0, tmp);
      then (ctx1, tmp, true);
    case DAE.CREF(componentRef=cref)
      algorithm
        (ctx1, tmp, ok1) := emitCrefRead(cref, ctx);
      then (ctx1, tmp, ok1);
    case DAE.UNARY(operator=DAE.UMINUS(), exp=sub)
      algorithm
        (ctx1, dst1, ok1) := emitExp(sub, ctx);
        if ok1 then
          (ctx2, tmp) := freshTmp(ctx1);
          EXT_LLVM.genAllocaModelicaReal(tmp, false);
          EXT_LLVM.genRUminus(dst1, tmp);
        else
          ctx2 := ctx1;
          tmp := dst1;
        end if;
      then (ctx2, tmp, ok1);
    case DAE.BINARY(exp1=e1, operator=op, exp2=e2)
      algorithm
        (ctx1, dst1, ok1) := emitExp(e1, ctx);
        (ctx2, dst2, ok2) := emitExp(e2, ctx1);
        if ok1 and ok2 then
          (outCtx, tmp) := freshTmp(ctx2);
          EXT_LLVM.genAllocaModelicaReal(tmp, false);
          ok := emitBinaryReal(op, dst1, dst2, tmp);
          dst := tmp;
        else
          outCtx := ctx2;
          dst := "<sub-failed>";
          ok := false;
        end if;
      then (outCtx, dst, ok);
    case DAE.CALL(path=Absyn.IDENT(name=tmp), expLst={sub})
      guard isLibmUnaryReal(tmp)
      algorithm
        (ctx1, dst1, ok1) := emitExp(sub, ctx);
        if ok1 then
          (ctx2, dst) := emitCallUnaryReal(tmp, dst1, ctx1);
          ok := true;
        else
          ctx2 := ctx1;
          dst := "<libm-arg-failed>";
          ok := false;
        end if;
      then (ctx2, dst, ok);
    case DAE.CALL(path=Absyn.IDENT(name=tmp), expLst={e1, e2})
      guard isLibmBinaryReal(tmp)
      algorithm
        (ctx1, dst1, ok1) := emitExp(e1, ctx);
        (ctx2, dst2, ok2) := emitExp(e2, ctx1);
        if ok1 and ok2 then
          (outCtx, dst) := emitCallBinaryReal(tmp, dst1, dst2, ctx2);
          ok := true;
        else
          outCtx := ctx2;
          dst := "<libm2-arg-failed>";
          ok := false;
        end if;
      then (outCtx, dst, ok);
    else
      then (ctx, "<unsupported-exp>", false);
  end match;
end emitExp;

protected function isLibmUnaryReal
  "Recognise libm-style single-argument Real -> Real functions whose
   names are resolvable in the host process. The names match libm
   symbols exactly so DynamicLibrarySearchGenerator::GetForCurrentProcess
   resolves the call against libm at JIT lookup time."
  input String name;
  output Boolean b;
algorithm
  b := match name
    case "sin"  then true;
    case "cos"  then true;
    case "tan"  then true;
    case "asin" then true;
    case "acos" then true;
    case "atan" then true;
    case "sinh" then true;
    case "cosh" then true;
    case "tanh" then true;
    case "exp"  then true;
    case "log"  then true;
    case "log10" then true;
    case "sqrt" then true;
    case "fabs" then true;
    case "abs"  then true;
    else false;
  end match;
end isLibmUnaryReal;

protected function emitCallUnaryReal
  "Emit  %dst = call double @<fn>(double <src>)  into the active body."
  input String fn;
  input String src;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
algorithm
  (outCtx, dst) := freshTmp(ctx);
  EXT_LLVM.genAllocaModelicaReal(dst, false);
  EXT_LLVM.genCallArg(src);
  EXT_LLVM.genCall(rewriteToLibm(fn), MODELICA_REAL, dst, true);
end emitCallUnaryReal;

protected function isLibmBinaryReal
  "Two-arg libm-style Real -> Real functions. Symbols resolve against
   the host libm via DynamicLibrarySearchGenerator at JIT lookup."
  input String name;
  output Boolean b;
algorithm
  b := match name
    case "pow"   then true;
    case "atan2" then true;
    case "hypot" then true;
    case "fmod"  then true;
    case "fmin"  then true;
    case "fmax"  then true;
    /* Modelica spelling */
    case "min"   then true;
    case "max"   then true;
    else false;
  end match;
end isLibmBinaryReal;

protected function emitCallBinaryReal
  "Emit  %dst = call double @<fn>(double <a>, double <b>)."
  input String fn;
  input String a;
  input String b;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
algorithm
  (outCtx, dst) := freshTmp(ctx);
  EXT_LLVM.genAllocaModelicaReal(dst, false);
  EXT_LLVM.genCallArg(a);
  EXT_LLVM.genCallArg(b);
  EXT_LLVM.genCall(rewriteToLibm(fn), MODELICA_REAL, dst, true);
end emitCallBinaryReal;

protected function rewriteToLibm
  "Map Modelica spellings to libm symbol names so the JIT resolves
   them via the host process search generator. For functions whose
   Modelica name already matches libm, the input is returned as-is."
  input String name;
  output String libm;
algorithm
  libm := match name
    case "min" then "fmin";
    case "max" then "fmax";
    case "abs" then "fabs";
    else name;
  end match;
end rewriteToLibm;

protected function emitCrefRead
  "Resolve a cref via the layout, then emit a realVars load.
   Special cases:
     - the builtin 'time'        -> omc_jit_get_time(data)
     - $START.<var> (start attr) -> omc_jit_get_realvar_start(data, slot)
   Both paths reach an EXT_LLVM call rather than a layout-slot load."
  input DAE.ComponentRef cref;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
protected
  Option<VarSlot> os;
  Option<DAE.ComponentRef> innerOpt;
  DAE.ComponentRef innerCref;
  VarSlot vs;
  Integer absSlot;
algorithm
  if isTimeCref(cref) then
    (outCtx, dst) := emitReadTime(ctx);
    ok := true;
    return;
  end if;
  innerOpt := startCrefInner(cref);
  if isSome(innerOpt) then
    SOME(innerCref) := innerOpt;
    os := lookupSlot(innerCref, ctx.layout);
    (outCtx, dst, ok) := match os
      case SOME(vs)
        algorithm
          absSlot := absoluteSlot(vs.kind, vs.index, ctx.layout);
          (outCtx, dst) := emitReadRealVarStart(absSlot, ctx);
        then (outCtx, dst, true);
      case NONE() then (ctx, "<unmapped-start-cref>", false);
    end match;
    return;
  end if;
  os := lookupSlot(cref, ctx.layout);
  (outCtx, dst, ok) := match os
    case SOME(vs)
      algorithm
        absSlot := absoluteSlot(vs.kind, vs.index, ctx.layout);
        if Flags.isSet(Flags.FAILTRACE) then
          print("SCTL emitCrefRead: '" +
                ComponentReferenceBasics.printComponentRefStr(cref) +
                "' -> kind=" + anyString(vs.kind) +
                " idx=" + intString(vs.index) +
                " absSlot=" + intString(absSlot) + "\n");
        end if;
        /* Parameters live in a separate buffer
         * (data->simulationInfo->realParameter[]) and need the
         * parameter accessor; everything else (states, derivatives,
         * algebraic vars) reads through omc_jit_get_real_var. */
        (outCtx, dst) := match vs.kind
          case VK_PARAM() then emitReadRealParam(absSlot, ctx);
          else                emitReadRealVar(absSlot, ctx);
        end match;
      then (outCtx, dst, true);
    case NONE()
      algorithm
        if Flags.isSet(Flags.FAILTRACE) then
          print("SCTL emitCrefRead: cref not in layout: '" +
                ComponentReferenceBasics.printComponentRefStr(cref) + "'\n");
        end if;
      then (ctx, "<unmapped-cref>", false);
  end match;
end emitCrefRead;

protected function isTimeCref
  "True iff cref is the builtin scalar 'time'."
  input DAE.ComponentRef cref;
  output Boolean b;
algorithm
  b := match cref
    case DAE.CREF_IDENT(ident = "time") then true;
    else false;
  end match;
end isTimeCref;

protected function startCrefInner
  "If cref is $START.<inner> return SOME(<inner>); otherwise NONE().
   <inner> is the cref of the variable whose start attribute is being
   read; its slot in the realVars layout is the right slot to pass to
   omc_jit_get_realvar_start because the runtime indexes the start
   attribute by the same simVar slot as the variable itself."
  input DAE.ComponentRef cref;
  output Option<DAE.ComponentRef> innerCref;
algorithm
  innerCref := match cref
    local DAE.ComponentRef sub;
    case DAE.CREF_QUAL(ident = "$START", componentRef = sub) then SOME(sub);
    else NONE();
  end match;
end startCrefInner;

protected function emitReadRealVarStart
  "Emit  %dst = call double @omc_jit_get_realvar_start(ptr %data, i64 slot)
   into the active function body."
  input Integer slot;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
algorithm
  (outCtx, dst) := freshTmp(ctx);
  EXT_LLVM.genAllocaModelicaReal(dst, false);
  EXT_LLVM.genCallArg("data");
  EXT_LLVM.genCallArgConstInt(slot);
  EXT_LLVM.genCall("omc_jit_get_realvar_start", MODELICA_REAL, dst, true);
end emitReadRealVarStart;

protected function emitReadTime
  "Emit  %dst = call double @omc_jit_get_time(ptr %data)
   into the active function body."
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
algorithm
  (outCtx, dst) := freshTmp(ctx);
  EXT_LLVM.genAllocaModelicaReal(dst, false);
  EXT_LLVM.genCallArg("data");
  EXT_LLVM.genCall("omc_jit_get_time", MODELICA_REAL, dst, true);
end emitReadTime;

protected function emitBinaryReal
  "Dispatch a real-arithmetic binop to the EXT_LLVM primitive."
  input DAE.Operator op;
  input String lhs;
  input String rhs;
  input String dst;
  output Boolean ok;
algorithm
  ok := match op
    case DAE.ADD()
      algorithm EXT_LLVM.genRAdd(dst, lhs, rhs); then true;
    case DAE.SUB()
      algorithm EXT_LLVM.genRSub(dst, lhs, rhs); then true;
    case DAE.MUL()
      algorithm EXT_LLVM.genRMul(dst, lhs, rhs); then true;
    case DAE.DIV()
      algorithm EXT_LLVM.genRDiv(dst, lhs, rhs); then true;
    case DAE.POW()
      algorithm
        EXT_LLVM.genCallArg(lhs);
        EXT_LLVM.genCallArg(rhs);
        EXT_LLVM.genCall("pow", MODELICA_REAL, dst, true);
      then true;
    else false;
  end match;
end emitBinaryReal;

protected function odeEntryName
  "Underscore-flatten the model's Absyn.Path and append the C-runtime
   functionODE suffix. Mirrors what CodegenUtil.symbolName produces
   on the legacy C side -- e.g. HelloWorldSim -> HelloWorldSim_functionODE,
   M.Sub.X -> M_Sub_X_functionODE -- so when the solver call binds
   through data->callback->functionODE the JIT-emitted symbol is the
   one solver_main.c expects."
  input Absyn.Path modelName;
  output String name;
algorithm
  name := modelSymbolPrefix(modelName) + "_functionODE";
end odeEntryName;

/* ====================================================================== *
 *  SimCode field extractors (single-record uniontypes, so match)         *
 * ====================================================================== */

protected function simCodeName
  input SimCode.SimCode simCode;
  output Absyn.Path name;
algorithm
  name := match simCode
    case SimCode.SIMCODE(modelInfo=SimCode.MODELINFO(name=name)) then name;
  end match;
end simCodeName;

protected function modelSymbolPrefix
  "C symbol prefix matching CodegenC's makeC89Identifier
   (pathString(name)) for the model name. Dots become single
   underscores; embedded underscores in identifiers are preserved
   as-is. AbsynUtil.pathStringUnquoteReplaceDot, by contrast,
   doubles embedded underscores, which produces wrong symbols for
   models with '_' in their path (Modelica.Blocks.Examples
   .PID_Controller, Modelica.Mechanics.Translational.Examples
   .Friction, ...). The JIT linker only finds symbols when SCTL's
   IR emission and CodegenC's clang'd C use identical names, so
   every SCTL caller that builds a symbol from a model name
   should route through this helper."
  input Absyn.Path name;
  output String prefix;
algorithm
  prefix := System.makeC89Identifier(AbsynUtil.pathString(name));
end modelSymbolPrefix;

protected function simCodeVars
  input SimCode.SimCode simCode;
  output SimCodeVar.SimVars vars;
algorithm
  vars := match simCode
    case SimCode.SIMCODE(modelInfo=SimCode.MODELINFO(vars=vars)) then vars;
  end match;
end simCodeVars;

protected function flattenOdeEquations
  "Collapse the list<list<SimEqSystem>> ode partitions into a single
   list. The outer list is over partitions -- for the explicit-ODE
   scope there is one partition, but flattening keeps the traversal
   robust against multi-partition models the upper layer will reject."
  input SimCode.SimCode simCode;
  output list<SimCode.SimEqSystem> eqs;
algorithm
  eqs := match simCode
    local list<list<SimCode.SimEqSystem>> parts;
    case SimCode.SIMCODE(odeEquations=parts)
      then List.flatten(parts);
  end match;
end flattenOdeEquations;

/* ====================================================================== *
 *  VarLayout build                                                       *
 * ====================================================================== */

protected function buildVarLayout
  "Walk the SIMVARS buckets we currently care about and accumulate
   the cref -> slot entries. SimVar.index is already 1-based-per-kind
   in master; we keep that as-is and the IR layer will subtract 1
   when generating GEP offsets."
  input SimCodeVar.SimVars vars;
  output VarLayout layout;
protected
  list<SimCodeVar.SimVar> stateVars, derivativeVars, algVars, paramVars, boolParamVars;
  list<tuple<DAE.ComponentRef, VarSlot>> entries = {};
algorithm
  (stateVars, derivativeVars, algVars, paramVars, boolParamVars) := match vars
    case SimCodeVar.SIMVARS(stateVars=stateVars,
                            derivativeVars=derivativeVars,
                            algVars=algVars,
                            paramVars=paramVars,
                            boolParamVars=boolParamVars)
      then (stateVars, derivativeVars, algVars, paramVars, boolParamVars);
  end match;

  for v in stateVars      loop entries := addEntry(v, VK_STATE(),      entries); end for;
  for v in derivativeVars loop entries := addEntry(v, VK_DERIVATIVE(), entries); end for;
  for v in algVars        loop entries := addEntry(v, VK_ALG(),        entries); end for;
  for v in paramVars      loop entries := addEntry(v, VK_PARAM(),      entries); end for;
  for v in boolParamVars  loop entries := addEntry(v, VK_BOOL_PARAM(), entries); end for;

  layout := VAR_LAYOUT(entries,
                      listLength(stateVars),
                      listLength(algVars),
                      listLength(paramVars));
  if Flags.isSet(Flags.JIT_DUMP_IR) then
    dumpLayout(layout);
  end if;
end buildVarLayout;

protected function dumpLayout
  input VarLayout layout;
protected
  DAE.ComponentRef cr;
  VarSlot s;
  String kindStr;
algorithm
  Error.addInternalError("SimCodeToLLVM layout dump (nStates=" + intString(layout.nStates) +
    " nAlgs=" + intString(layout.nAlgs) + " nParams=" + intString(layout.nParams) + ")\n",
    sourceInfo());
  for entry in layout.entries loop
    (cr, s) := entry;
    kindStr := match s.kind
      case VK_STATE()      then "STATE";
      case VK_DERIVATIVE() then "DERIV";
      case VK_ALG()        then "ALG";
      case VK_PARAM()      then "PARAM";
      case VK_BOOL_PARAM() then "BPARM";
    end match;
    Error.addInternalError("  " + ComponentReferenceBasics.printComponentRefStr(cr) +
      " -> " + kindStr + "(simVarIndex=" + intString(s.index) + ")\n", sourceInfo());
  end for;
end dumpLayout;

protected function addEntry
  input SimCodeVar.SimVar v;
  input VarKind kind;
  input list<tuple<DAE.ComponentRef, VarSlot>> entries;
  output list<tuple<DAE.ComponentRef, VarSlot>> outEntries;
algorithm
  outEntries := match v
    local DAE.ComponentRef cr;
          Integer i;
          DAE.Type ty;
    case SimCodeVar.SIMVAR(name=cr, index=i, type_=ty)
      then (cr, VAR_SLOT(kind, i, ty)) :: entries;
  end match;
end addEntry;

public function lookupSlot
  "Linear scan; the table is small for the explicit-ODE scope.
   Returns NONE() rather than failing so the caller propagates a
   Boolean ok instead of jumping out via exception."
  input DAE.ComponentRef cref;
  input VarLayout layout;
  output Option<VarSlot> slot;
algorithm
  slot := lookupSlotEntries(cref, layout.entries);
end lookupSlot;

protected function lookupSlotEntries
  input DAE.ComponentRef cref;
  input list<tuple<DAE.ComponentRef, VarSlot>> entries;
  output Option<VarSlot> slot = NONE();
protected
  DAE.ComponentRef cr;
  VarSlot s;
algorithm
  for entry in entries loop
    (cr, s) := entry;
    if ComponentReferenceBasics.crefEqual(cref, cr) then
      slot := SOME(s);
      return;
    end if;
  end for;
end lookupSlotEntries;

/* ====================================================================== *
 *  Equation classification                                               *
 * ====================================================================== */

protected function classifySimEq
  "Map a SimEqSystem to an EqRecipe. The only directly-lowerable
   shape for Phase 4 is SES_SIMPLE_ASSIGN with a CREF lhs that
   resolves to a state derivative, a state, or an algebraic var.
   Anything else is marked UNSUPPORTED with a short reason string
   so the diagnostic in genSim is informative when falling back."
  input SimCode.SimEqSystem eq;
  input VarLayout layout;
  output EqRecipe recipe;
algorithm
  recipe := match eq
    local DAE.ComponentRef cref;
          DAE.Exp rhs;
          Option<VarSlot> os;
          VarSlot s;
    case SimCode.SES_SIMPLE_ASSIGN(cref=cref, exp=rhs)
      algorithm
        os := lookupSlot(cref, layout);
      then match os
        case SOME(s as VAR_SLOT(kind=VK_DERIVATIVE()))
          then EQ_DERIVATIVE_ASSIGN(s.index, rhs);
        case SOME(s as VAR_SLOT(kind=VK_STATE()))
          then EQ_STATE_ASSIGN(s.index, rhs);
        case SOME(s as VAR_SLOT(kind=VK_ALG()))
          then EQ_ALG_ASSIGN(s.index, rhs);
        case SOME(s as VAR_SLOT(kind=VK_PARAM()))
          then EQ_PARAM_ASSIGN(s.index, rhs);
        case SOME(s as VAR_SLOT(kind=VK_BOOL_PARAM()))
          then EQ_BOOL_PARAM_ASSIGN(s.index, rhs);
        else
          then EQ_UNSUPPORTED("cref not found in layout: "
                              + ComponentReferenceBasics.printComponentRefStr(cref));
      end match;
    case SimCode.SES_RESIDUAL()
      then EQ_UNSUPPORTED("SES_RESIDUAL requires solver, deferred");
    case SimCode.SES_LINEAR()
      then EQ_UNSUPPORTED("SES_LINEAR requires solver, deferred");
    case SimCode.SES_NONLINEAR()
      then EQ_UNSUPPORTED("SES_NONLINEAR requires solver, deferred");
    case SimCode.SES_MIXED()
      then EQ_UNSUPPORTED("SES_MIXED requires solver, deferred");
    case SimCode.SES_WHEN()
      then EQ_UNSUPPORTED("SES_WHEN requires event handling, deferred");
    case SimCode.SES_IFEQUATION()
      then EQ_UNSUPPORTED("SES_IFEQUATION requires event handling, deferred");
    case SimCode.SES_ALGORITHM()
      then EQ_UNSUPPORTED("SES_ALGORITHM requires statement lowering, deferred");
    case SimCode.SES_ARRAY_CALL_ASSIGN()
      then EQ_UNSUPPORTED("SES_ARRAY_CALL_ASSIGN requires array lowering, deferred");
    case SimCode.SES_FOR_LOOP()
      then EQ_UNSUPPORTED("SES_FOR_LOOP requires loop lowering, deferred");
    case SimCode.SES_FOR_EQUATION()
      then EQ_UNSUPPORTED("SES_FOR_EQUATION requires loop lowering, deferred");
    case SimCode.SES_ALIAS(aliasOf = _)
      /* Aliased equations share a body with another equation that is
       * emitted in its own right (typically an ODE eq referenced from
       * the initial-equation dispatch). The runtime tolerates not
       * re-running it during initialisation because the integrator
       * calls functionODE again on its first step. */
      then EQ_NOOP(eq.aliasOf);
    else
      then EQ_UNSUPPORTED("unhandled SimEqSystem variant");
  end match;
end classifySimEq;

protected function countSupported
  input EqRecipe r;
  input Integer acc;
  output Integer out;
algorithm
  out := match r
    case EQ_UNSUPPORTED() then acc;
    else acc + 1;
  end match;
end countSupported;

protected function countUnsupported
  input EqRecipe r;
  input Integer acc;
  output Integer out;
algorithm
  out := match r
    case EQ_UNSUPPORTED() then acc + 1;
    else acc;
  end match;
end countUnsupported;

annotation(__OpenModelica_Interface="backend");
end SimCodeToLLVM;
