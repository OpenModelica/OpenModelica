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
import CodegenUtil.{underscorePath};
import ComponentReference;
import ComponentReferenceBasics;
import DAE;
import DAEDump;
import ExpressionBasics;
import Tpl.{textString};
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
  record VK_STATE         end VK_STATE;
  record VK_DERIVATIVE    end VK_DERIVATIVE;
  record VK_ALG           end VK_ALG;
  record VK_PARAM         end VK_PARAM;
  record VK_BOOL_PARAM    end VK_BOOL_PARAM;
  record VK_BOOL_DISCRETE
    "A discrete Boolean variable living in
     data->localData[0]->booleanVars[index] (the boolAlgVars bucket:
     when conditions, relation results like `impact`, ...)."
  end VK_BOOL_DISCRETE;
  record VK_INT_DISCRETE
    "A discrete Integer variable living in
     data->localData[0]->integerVars[index] (the intAlgVars bucket,
     e.g. a when-counter `n_bounce`)."
  end VK_INT_DISCRETE;
  record VK_INT_PARAM
    "An Integer parameter living in
     data->simulationInfo->integerParameter[index] (the intParamVars
     bucket, e.g. a scalarised colour-array element
     world.gravitySphereColor[1]). Read into a Real context via sitofp
     and into an integer context directly."
  end VK_INT_PARAM;
end VarKind;

/* Cached singleton instances of every no-field VarKind variant.
 * Reuse these throughout SCTL instead of allocating a fresh
 * VK_STATE() / VK_PARAM() / ... per call site -- the records have
 * no fields so referenceEqual against the singleton is equivalent
 * to a tag check and avoids the heap allocation that constructing
 * a new immutable record would otherwise incur on hot paths like
 * buildVarLayout and emitCrefRead. */
public constant VarKind VKS_STATE      = VK_STATE();
public constant VarKind VKS_DERIVATIVE = VK_DERIVATIVE();
public constant VarKind VKS_ALG        = VK_ALG();
public constant VarKind VKS_PARAM      = VK_PARAM();
public constant VarKind VKS_BOOL_PARAM = VK_BOOL_PARAM();
public constant VarKind VKS_BOOL_DISCRETE = VK_BOOL_DISCRETE();
public constant VarKind VKS_INT_DISCRETE = VK_INT_DISCRETE();
public constant VarKind VKS_INT_PARAM  = VK_INT_PARAM();

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

  record EQ_INT_PARAM_ASSIGN
    "integerParameter[idx] := exp. The RHS is lowered in the integer
     domain (emitIntExp) and stored as a modelica_integer. Covers
     scalarised Integer-parameter binding equations (e.g.
     world.gravitySphereColor[1] := 0)."
    Integer slotIndex;
    DAE.Exp rhs;
  end EQ_INT_PARAM_ASSIGN;

  record EQ_ARRAY_CALL2
    "<realVars array> := fn(<const vec>, <const vec>), a SES_ARRAY_CALL_ASSIGN
     whose RHS is a call to a real_array-returning function with two constant
     real-vector arguments (e.g. MultiBody
     world.z_label.R_lines = Frames.TransformationMatrices.from_nxy(n_x, n_y)).
     Lowered to the omc_jit_array_call2_real adapter: it builds the operand
     descriptors, calls fnName (in the still-clang'd <Model>_functions.c), and
     copies the result into the realVars block at destSlot. eqIndex names the
     per-equation operand globals."
    String fnName;
    list<Real> aData;
    list<Real> bData;
    Integer destSlot;
    Integer ndims;
    Integer d0;
    Integer d1;
    Integer eqIndex;
  end EQ_ARRAY_CALL2;

  record EQ_BOOL_DISCRETE_ASSIGN
    "booleanVars[slot] := <Boolean expression>, a discrete Boolean
     assignment (e.g. `impact = h <= 0.0`, `b = c and x >= 0.1`). The RHS
     is lowered by emitBoolExp into a modelica_boolean (i32) value and
     stored into the booleanVars buffer. Supported RHS nodes: zero-crossing
     relations (via omc_jit_relationhysteresis), discrete-Boolean cref
     reads, and / or / not, and Boolean literals."
    Integer slotIndex "absolute booleanVars[] slot";
    DAE.Exp rhs;
  end EQ_BOOL_DISCRETE_ASSIGN;

  record EQ_WHEN
    "A when-equation, lowered by predication (no basic-block branch):
     each body statement runs as `lhs = edge ? rhs : lhs`, identical to
     CodegenC's `if (edge) { lhs = rhs; }`. `conditions` are the discrete
     Boolean cref conditions; the edge is the OR over them of
     `cond and not pre(cond)`. `whenStmts` are ASSIGN / REINIT operators;
     REINIT also sets simulationInfo->needToIterate (predicated)."
    list<DAE.ComponentRef> conditions;
    list<BackendDAE.WhenOperator> whenStmts;
  end EQ_WHEN;

  record EQ_SOLVE_NONLINEAR
    "A nonlinear tearing system with any iteration-variable count >= 1.
     Lowered to one call to the omc_jit_solve_nonlinear_system_n adapter:
     each iteration variable seeded from realVars[varSlots[i]] into
     nlsxOld, runtime solve_nonlinear_system runs, throws on failure,
     writes nlsx[i] back to realVars[varSlots[i]]. The residual / setup /
     Jacobian stay on clang in _02nls.c / _12jac.c. sysIndex is the
     indexNonLinearSystem; varSlots are the flat realVars slots in the
     same order as NONLINEARSYSTEM.crefs (the iteration variables, not
     the larger nUnknowns set that also counts torn-away vars)."
    Integer sysIndex;
    list<Integer> varSlots;
  end EQ_SOLVE_NONLINEAR;

  record EQ_SOLVE_LINEAR
    "A linear tearing system with any iteration-variable count >= 1.
     Lowered to one call to the omc_jit_solve_linear_system_n adapter
     (runtime solve_linear_system + throwStreamPrint, with a length-N
     stack aux_x buffer for the iteration-variable exchange). sysIndex
     is the indexLinearSystem; varSlots are the flat realVars slots in
     the same order as LINEARSYSTEM.vars."
    Integer sysIndex;
    list<Integer> varSlots;
  end EQ_SOLVE_LINEAR;

  record EQ_ALGORITHM
    "An algorithm section whose statements are all simple scalar
     assignments `cref := expr` to a layout-resolved variable. Lowered
     statement-by-statement as unconditional writes, in order (the same
     dispatch as a when-body ASSIGN, minus the edge predicate). Anything
     else (if / for / while statements, assignment to a local temporary
     not in the layout, ...) keeps the recipe out of the supported set."
    list<DAE.Statement> statements;
  end EQ_ALGORITHM;

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

/* Catalog-driven enumeration of Modelica features that disqualify a
 * stub from being semantically equivalent to its CodegenC body.
 * featureFor maps each catalog nameSuffix to one of these; safety
 * reduces to checking that the model does not exhibit it. NONE is
 * the sentinel for stubs whose body is identical regardless of model
 * content (e.g. _checkForAsserts, _linear_model_frame).
 *
 * The enum is the single keyspace for both the user-facing wording
 * (featureName) and the SimCode probe (featureIsAbsent); the catalog
 * never spells out the same Modelica feature string twice. */
public type Feature = enumeration(
  NONE,
  DELAY_EXPRS,
  SPATIAL_DISTRIBUTION,
  CLOCKED_PARTITIONS,
  STATE_SETS,
  INPUT_VARS,
  OUTPUT_VARS,
  DATA_RECON_INPUTS,
  DATA_RECON_SET_B,
  DATA_RECON_SET_C,
  LOCAL_KNOWN_VARS);

/* Human-readable name for each Feature, cached as a module-level
 * constant so each diagnostic warning reuses the same String value
 * instead of building it from a literal on every call. featureName()
 * is now a plain enum-to-pointer dispatch. */
protected constant String FEATURE_NAME_NONE                 = "an SCTL-unsupported feature";
protected constant String FEATURE_NAME_DELAY_EXPRS          = "delay() expressions";
protected constant String FEATURE_NAME_SPATIAL_DISTRIBUTION = "spatialDistribution() operator";
protected constant String FEATURE_NAME_CLOCKED_PARTITIONS   = "synchronous (clocked) partitions";
protected constant String FEATURE_NAME_STATE_SETS           = "dynamic state selection (state sets)";
protected constant String FEATURE_NAME_INPUT_VARS           = "input variables (Modelica `input` declarations)";
protected constant String FEATURE_NAME_OUTPUT_VARS          = "output variables (Modelica `output` declarations)";
protected constant String FEATURE_NAME_DATA_RECON_INPUTS    = "data-reconciliation input variables";
protected constant String FEATURE_NAME_DATA_RECON_SET_B     = "data-reconciliation set-B variables";
protected constant String FEATURE_NAME_DATA_RECON_SET_C     = "data-reconciliation set-C variables";
protected constant String FEATURE_NAME_LOCAL_KNOWN_VARS     = "local-known-variable equations";

public uniontype EntryBody
  record EB_STUB end EB_STUB;
  record EB_STUB_LINKONCE
    "Same body as EB_STUB but the emitted function gets linkonce_odr
     linkage. Used for stubs that share <Model>.c with content SCTL
     does not yet emit -- both definitions exist after llvm-link,
     the strong one (CodegenC) wins, ours is discarded. The IR is
     in place for the day CodegenC stops emitting this symbol."
  end EB_STUB_LINKONCE;
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
    Boolean displaceFile = true "False when the segment .c file shares content SCTL does not yet emit, so emitting this stub must NOT trigger file-level displacement. <Model>.c is the canonical case today (holds the callback table, setupDataStruc, main, ... besides any leaf stubs).";
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
    RUNTIME_ENTRY("_symbolicInlineSystem", MI, {MM, MM}, EB_RETURN_MINUS_ONE(), "_17inl.c", true),

    /* -- _10asr.c -------------------------------------------------- */
    RUNTIME_ENTRY("_checkForAsserts", MI, {MM, MM}, EB_STUB(), "_10asr.c", true),

    /* -- _07dly.c -------------------------------------------------- */
    RUNTIME_ENTRY("_function_storeDelayed", MI, {MM, MM}, EB_STUB(), "_07dly.c", true),

    /* -- _18spd.c -------------------------------------------------- */
    RUNTIME_ENTRY("_function_storeSpatialDistribution", MI, {MM, MM}, EB_STUB(), "_18spd.c", true),
    RUNTIME_ENTRY("_function_initSpatialDistribution",  MI, {MM, MM}, EB_STUB(), "_18spd.c", true),

    /* -- _16dae.c -- CodegenC body is  return -1  (no DAE mode data); the
                     runtime treats negative as "DAE mode unavailable" and
                     stays on the ODE path. */
    RUNTIME_ENTRY("_initializeDAEmodeData", MI, {MM, MM}, EB_RETURN_MINUS_ONE(), "_16dae.c", true),

    /* -- _04set.c -- (int nStateSets, STATE_SET_DATA*, DATA*) -> void.
                     int widens to i64 (no MODELICA_INT32); the unused
                     arg sits in the same register on x86-64. */
    RUNTIME_ENTRY("_initializeStateSets", MV, {MI, MM, MM}, EB_STUB(), "_04set.c", true),

    /* -- _08bnd.c -- bound-parameter / bound-attribute updates. Empty
                      in CodegenC for HelloWorld but populates
                      data->simulationInfo->realParameter[] for models
                      with parameter equations (ChuaCircuit:
                      Ra/Rb/L/C1/C2). Stubbing leaves parameters at 0
                      and simulation diverges. Leaving _08bnd.c to
                      clang until real parameter-equation lowering
                      lands. */
    RUNTIME_ENTRY("_bnd_handled_by_clang", MV, {}, EB_TODO("parameter equations need real body for ChuaCircuit"), "_08bnd.c", true),

    /* -- _09alg.c -- functionAlgebraics recomputes the *continuous*
                     algebraic equations every step (e.g. y = delay(x)).
                     A no-op stub only matched ODE-only models and froze
                     any continuous algebraic var; emitModelEquationsBlock
                     now emits a real functionAlgebraics from
                     algebraicEquations and displaces _09alg.c, so this is
                     EB_TODO (Block-emitter-owned). */
    RUNTIME_ENTRY("_functionAlgebraics", MI, {MM, MM}, EB_TODO("emitModelEquationsBlock"), "_09alg.c", true),

    /* -- _15syn.c -- synchronous-language support. Empty bodies for
                     non-synchronous models. */
    RUNTIME_ENTRY("_function_savePreSynchronous",  MV, {MM, MM},          EB_STUB(), "_15syn.c", true),
    RUNTIME_ENTRY("_function_initSynchronous",     MV, {MM, MM},          EB_STUB(), "_15syn.c", true),
    RUNTIME_ENTRY("_function_updateSynchronous",   MV, {MM, MM, MI},      EB_STUB(), "_15syn.c", true),
    RUNTIME_ENTRY("_function_equationsSynchronous",MI, {MM, MM, MI, MI},  EB_STUB(), "_15syn.c", true),

    /* -- _13opt.c -- optimization (Optimica) callbacks. Stubs sit in
                     the function pointer table populated by
                     setupDataStruc but never get called for ODE-only
                     simulation. */
    RUNTIME_ENTRY("_mayer",                              MI, {MM, MM, MM},                       EB_STUB(), "_13opt.c", true),
    RUNTIME_ENTRY("_lagrange",                           MI, {MM, MM, MM, MM},                   EB_STUB(), "_13opt.c", true),
    RUNTIME_ENTRY("_getInputVarIndicesInOptimization",   MI, {MM, MM},                           EB_STUB(), "_13opt.c", true),
    RUNTIME_ENTRY("_pickUpBoundsForInputsInOptimization",MI, {MM, MM, MM, MM, MM, MM, MM, MM},   EB_STUB(), "_13opt.c", true),
    RUNTIME_ENTRY("_setInputData",                       MI, {MM, MI},                           EB_STUB(), "_13opt.c", true),
    RUNTIME_ENTRY("_getTimeGrid",                        MI, {MM, MM, MM},                       EB_STUB(), "_13opt.c", true),

    /* -- _05evt.c -- event handling. Trivially-stub'd entries work for
                      models with no zero crossings (HelloWorld, UserFn).
                      For models with piecewise nonlinearities
                      (ChuaCircuit, hybrid systems) _function_ZeroCrossings
                      must populate the gout buffer; the stubs cause
                      DASKR's bisection logic to misfire and abort with
                      "R IS ILL-DEFINED". Leaving _05evt.c to clang until
                      the bodies are lowered. */
    RUNTIME_ENTRY("_evt_handled_by_clang", MV, {}, EB_TODO("zero-crossings need real body for hybrid models"), "_05evt.c", true),

    /* -- _14lnz.c -- linearization frame strings. Returned only from
                     -d=linearization paths; null suffices for ODE. */
    RUNTIME_ENTRY("_linear_model_frame",               MM, {}, EB_NULL_PTR(), "_14lnz.c", true),
    RUNTIME_ENTRY("_linear_model_datarecovery_frame", MM, {}, EB_NULL_PTR(), "_14lnz.c", true),

    /* -- _06inz.c -- initial-equation block. emitInitialEquationsBlock
                      runs alongside the catalog walk and emits the three
                      entries below when SimCode.initialEquations all
                      lower cleanly. The catalog rows stay EB_TODO so
                      displacedSegmentFiles continues to leave _06inz.c
                      on clang by default; the dynamic skip wiring needs
                      one more piece before they can flip. */
    RUNTIME_ENTRY("_functionInitialEquations_0",      MV, {MM, MM}, EB_TODO("emitInitialEquationsBlock handles it"), "_06inz.c", true),
    RUNTIME_ENTRY("_functionInitialEquations",        MI, {MM, MM}, EB_TODO("emitInitialEquationsBlock handles it"), "_06inz.c", true),
    RUNTIME_ENTRY("_functionRemovedInitialEquations", MI, {MM, MM}, EB_TODO("emitInitialEquationsBlock handles it"), "_06inz.c", true),

    /* -- _01exo.c -- external object destructors. CodegenC emits
                     `if (extObjs) { free(extObjs); extObjs = 0; }`;
                     for models with no ExternalObject declarations
                     (HelloWorld / UserFn / ChuaCircuit / ...) extObjs
                     is NULL and the call is a no-op. The stub matches
                     that behaviour. Models that use ExternalObject
                     will need an omc_jit_destroy_extobjs(DATA*)
                     accessor before this can keep its EB_STUB tag. */
    RUNTIME_ENTRY("_callExternalObjectDestructors", MV, {MM, MM}, EB_TODO("emitExternalObjectDestructorsBlock handles it"), "_01exo.c", true),

    /* -- _12jac.c -- analytic Jacobian. SCTL can emit stubs that
                      mark the JACOBIAN struct as NOT_AVAILABLE so
                      HelloWorld-class non-stiff models accept the
                      numerical-differencing fallback, but stiff
                      nonlinear models (ChuaCircuit, VDP at long t)
                      need a populated sparsity pattern to converge.
                      Leaving _12jac.c on clang until real analytic
                      Jacobian lowering lands. */
    RUNTIME_ENTRY("_jacobian_handled_by_clang", MV, {}, EB_TODO("real analytic Jacobian lowering needed"), "_12jac.c", true),

    /* -- <Model>.c -- leaf return-0 stubs co-resident with the driver,
                       callback table, setupDataStruc, main, and the
                       inlined perform_simulation.c.inc template. SCTL
                       cannot displace <Model>.c yet (those other items
                       still come from CodegenC), so each leaf goes in
                       with EB_STUB_LINKONCE and displaceFile=false:
                       both bitcodes define the symbol, llvm-link picks
                       CodegenC's strong copy, SCTL's is discarded. The
                       IR is positioned for the future commit that has
                       CodegenC drop these per a JIT-aware template
                       guard, at which point SCTL becomes the sole
                       source. Per-entry safety guards still apply --
                       a model with inputs would have a non-trivial
                       _input_function body in CodegenC, and emitting a
                       ret-0 linkonce_odr stub against it violates ODR.
                       Each safety case maps to a SimCode list being
                       empty (no input vars, no output vars, ...). */
    RUNTIME_ENTRY("_input_function",                       MI, {MM, MM}, EB_STUB_LINKONCE(), "<Model>.c", false),
    RUNTIME_ENTRY("_input_function_init",                  MI, {MM, MM}, EB_STUB_LINKONCE(), "<Model>.c", false),
    RUNTIME_ENTRY("_input_function_updateStartValues",     MI, {MM, MM}, EB_STUB_LINKONCE(), "<Model>.c", false),
    RUNTIME_ENTRY("_inputNames",                           MI, {MM, MM}, EB_STUB_LINKONCE(), "<Model>.c", false),
    RUNTIME_ENTRY("_data_function",                        MI, {MM, MM}, EB_STUB_LINKONCE(), "<Model>.c", false),
    RUNTIME_ENTRY("_dataReconciliationInputNames",         MI, {MM, MM}, EB_STUB_LINKONCE(), "<Model>.c", false),
    RUNTIME_ENTRY("_dataReconciliationUnmeasuredVariables",MI, {MM, MM}, EB_STUB_LINKONCE(), "<Model>.c", false),
    RUNTIME_ENTRY("_output_function",                      MI, {MM, MM}, EB_STUB_LINKONCE(), "<Model>.c", false),
    RUNTIME_ENTRY("_setc_function",                        MI, {MM, MM}, EB_STUB_LINKONCE(), "<Model>.c", false),
    RUNTIME_ENTRY("_setb_function",                        MI, {MM, MM}, EB_STUB_LINKONCE(), "<Model>.c", false),
    RUNTIME_ENTRY("_functionLocalKnownVars",               MI, {MM, MM}, EB_STUB_LINKONCE(), "<Model>.c", false)

  /* Entries still owned entirely by <Model>.c and <Model>_12jac.c are
     not in the catalog yet; they need real codegen
     (functionODE_system0, setupDataStruc, main, the eqFunction_N
     bodies, the function-pointer table, the Jacobian etc.). */
  };
end runtimeEntryCatalog;

/* ====================================================================== *
 *  Entry point                                                           *
 * ====================================================================== */

public function canCoverModel
  "Preflight: returns true iff the JIT will materialise without a
   'Symbols not found' error for `simCode`. Used by SimCodeMain purely to
   decide whether to emit the up-front coverage warning -- the cutover
   itself always skips <Model>.c. The predicate mirrors the gates the
   emitters actually use, so a model that runs (BouncingBall, delay, ...)
   no longer warns:

     - no clocked partitions and no state sets (unsupported features
       whose symbols SCTL neither emits nor delegates to a kept .c file);
     - every equation in the ODE partition (functionODE) and the full
       allEquations set (functionDAE) classifies as a lowerable recipe.

   functionODE and functionDAE live only in the now-skipped <Model>.c, so
   an unlowerable member of either set leaves the symbol undefined -> loud
   JIT-link error, which is exactly what the warning forecasts. The other
   satellites are *graceful fallbacks*, not disqualifiers: a zero-crossing
   residual SCTL cannot lower keeps _05evt.c on clang, an unlowerable
   algebraic/initial equation keeps _09alg.c/_06inz.c on clang, and those
   kept files reference the SCTL-emitted allEquations eqFunctions, so the
   model still runs. Structural only: no SCTL state mutation, no IR."
  input SimCode.SimCode simCode;
  output Boolean ok;
protected
  VarLayout layout;
algorithm
  ok := listEmpty(simCode.clockedPartitions) and listEmpty(simCode.stateSets);
  if not ok then
    return;
  end if;
  layout := buildVarLayout(simCodeVars(simCode));
  ok := allRecipesLower(flattenOdeEquations(simCode), layout)
    and allRecipesLower(allSimCodeEquations(simCode), layout);
end canCoverModel;

protected function allRecipesLower
  "True iff every equation in `eqs` classifies as a recipe canLowerEquation
   accepts. An empty list is vacuously coverable."
  input list<SimCode.SimEqSystem> eqs;
  input VarLayout layout;
  output Boolean ok;
algorithm
  ok := List.all(List.map1(eqs, classifySimEq, layout),
                 function canLowerEquation(layout = layout));
end allRecipesLower;

public function displacedSegmentFiles
  "Distinct list of CodegenC segment .c files SCTL fully covers for
   the model whose genSim just ran. Every displacement -- whether
   driven by the runtimeEntryCatalog (in emitDisplacingStubs after
   the per-file safety scan) or by a Block emitter
   (recordDisplacedSegment from emitInitialEquationsBlock etc.) --
   goes through the dynamic skip list, so this function is just an
   accessor on that list."
  output list<String> files;
algorithm
  files := getDynamicSkips();
end displacedSegmentFiles;

protected function uniqueAppend
  "Append seg to files iff files does not already contain seg.
   Preserves order."
  input list<String> filesIn;
  input String seg;
  output list<String> filesOut;
algorithm
  filesOut := if List.contains(filesIn, seg, stringEqual) then filesIn else listAppend(filesIn, {seg});
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

  if Flags.isSet(Flags.FAILTRACE) and nUnsupported > 0 then
    print("SCTL genSim: unsupported ODE recipes for '" + AbsynUtil.pathString(name) + "':\n");
    for r in recipes loop
      _ := match r
        case EQ_UNSUPPORTED() algorithm
          print("  - " + r.reason + "\n");
        then ();
        else ();
      end match;
    end for;
  end if;
  if Flags.isSet(Flags.FAILTRACE) then
    dumpUnsupportedBucket("allEquations",      simCode.allEquations,             layout, name);
    dumpUnsupportedBucket("initialEquations",  simCode.initialEquations,         layout, name);
    dumpUnsupportedBucket("algebraicEqs",      List.flatten(simCode.algebraicEquations), layout, name);
  end if;

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
    emitDisplacingStubs(simCode, name);
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
    try _ := emitInitialEquationsBlock(simCode, layout); else reportBlockFailure("emitInitialEquationsBlock", name); end try;
    try _ := emitDynamicEquationsBlock(simCode, layout); else reportBlockFailure("emitDynamicEquationsBlock", name); end try;
    try emitBoundParametersBlock(simCode, layout); else reportBlockFailure("emitBoundParametersBlock", name); end try;
    try emitEventBlock(simCode, layout); else reportBlockFailure("emitEventBlock", name); end try;
    try emitJacobianBlock(simCode); else reportBlockFailure("emitJacobianBlock", name); end try;
    try emitRecordsBlock(simCode); else reportBlockFailure("emitRecordsBlock", name); end try;
    try emitFunctionsBlock(simCode); else reportBlockFailure("emitFunctionsBlock", name); end try;
    try emitNonlinearSystemsBlock(simCode); else reportBlockFailure("emitNonlinearSystemsBlock", name); end try;
    try emitLinearSystemsBlock(simCode); else reportBlockFailure("emitLinearSystemsBlock", name); end try;
    try emitMixedSystemsBlock(simCode); else reportBlockFailure("emitMixedSystemsBlock", name); end try;
    try emitExternalObjectDestructorsBlock(simCode, name); else reportBlockFailure("emitExternalObjectDestructorsBlock", name); end try;
    try emitModelEquationsBlock(simCode, recipes, layout, name); else reportBlockFailure("emitModelEquationsBlock", name); end try;
    try emitCallbackTableBlock(simCode, name); else reportBlockFailure("emitCallbackTableBlock", name); end try;
    try emitSetupDataStrucShellBlock(name, simCode); else reportBlockFailure("emitSetupDataStrucShellBlock", name); end try;
    try emitMainShimBlock(name, simCode); else reportBlockFailure("emitMainShimBlock", name); end try;
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

  if Flags.isSet(Flags.JIT_DUMP_IR) then
    Error.addInternalError(
      "SimCodeToLLVM: model '" + AbsynUtil.pathString(name) +
      "' layout: nStates=" + intString(layout.nStates) +
      " nAlgs=" + intString(layout.nAlgs) +
      " nParams=" + intString(layout.nParams) +
      "; eqs: supported=" + intString(nSupported) +
      " unsupported=" + intString(nUnsupported) + "\n",
      sourceInfo());
  end if;
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
  /* Phase 6 (smoke-invoke functionODE) is intentionally disabled.
   * It was useful while bootstrapping the IR emission but is now a
   * liability: the inlined DATA-struct accessors (genReadRealParam,
   * genReadTime) chase data->simulationInfo and data->localData[0]
   * through real GEP / load chains, which crash against the fake
   * DATA struct omc_jit_invoke_functionODE used to fabricate (it
   * left simulationInfo == NULL). Pass 1 still proves
   * materialisation via jitFinalizeNoEntry above; the actual
   * correctness check is the real DASSL simulation in Pass 2. */
  rvIn := List.fill(1.0, 2 * layout.nStates + layout.nAlgs + layout.nParams);
  /* (rvOut, ..., realVarsString) intentionally unused after the
   * smoke-invoke was removed; the locals stay so the bind shapes
   * around the call site do not shift if Phase 6 returns. */
  if Flags.isSet(Flags.JIT_DUMP_IR) then
    Error.addInternalError(
      "SimCodeToLLVM Phase 5: materialised '" + odeSym + "'\n",
      sourceInfo());
  end if;
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
   (return void).

   daePrologue brackets the body with the discrete-step bookkeeping
   CodegenC's functionDAE emits: clear needToIterate at entry and set
   discreteCall = 1 .. 0 around the equations. Without the needToIterate
   reset the runtime's event-iteration loop spins on a fired reinit."
  input String fname;
  input list<EqRecipe> recipes;
  input VarLayout layout;
  input Integer retTy;
  input Boolean daePrologue = false;
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

  if daePrologue then
    EXT_LLVM.genSetNeedToIterateZero("data");
    EXT_LLVM.genSetDiscreteCall("data", 1);
  end if;

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

  if daePrologue then
    EXT_LLVM.genSetDiscreteCall("data", 0);
  end if;

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
  /* An equation index can appear in more than one block (e.g. both
   * initialEquations and allEquations). The first emitter wins; a second
   * definition in the same module would be silently renamed by LLVM and
   * waste space, so skip if the symbol already has a body. */
  if EXT_LLVM.functionDefined(fname) then
    ok := true;
    return;
  end if;
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
  /* linkonce_odr so the emission coexists with CodegenC's strong
   * <Model>_eqFunction_N when <Model>.c is still being emitted
   * (the canCoverModel preflight is conservative and many models
   * keep going through the C path even after the cutover landed
   * for HelloWorld). When CodegenC's copy is gone the SCTL one
   * becomes the sole definition; when both are present llvm-link
   * picks the strong CodegenC copy and discards ours. */
  _ := EXT_LLVM.setLinkonceOdr(fname);
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
    case SimCode.SES_LINEAR()            then nonlinearOrLinearIndex(eq);
    case SimCode.SES_NONLINEAR()         then nonlinearOrLinearIndex(eq);
    case SimCode.SES_MIXED()             then eq.index;
    case SimCode.SES_WHEN()              then eq.index;
    case SimCode.SES_IFEQUATION()        then eq.index;
    case SimCode.SES_ARRAY_CALL_ASSIGN() then eq.index;
    case SimCode.SES_ALIAS()             then eq.index;
    else 0;
  end match;
end simEqIndex;

protected function nonlinearOrLinearIndex
  "The eqFunction_<idx> number for a SES_LINEAR / SES_NONLINEAR is the
   torn system's `index` (the source equation index), not the solver's
   indexLinearSystem / indexNonLinearSystem. The still-clang'd
   _09alg.c / _06inz.c reference that eqFunction_<idx> symbol."
  input SimCode.SimEqSystem eq;
  output Integer index;
algorithm
  index := match eq
    case SimCode.SES_NONLINEAR(nlSystem = SimCode.NONLINEARSYSTEM(index = index)) then index;
    case SimCode.SES_LINEAR(lSystem = SimCode.LINEARSYSTEM(index = index)) then index;
    else 0;
  end match;
end nonlinearOrLinearIndex;

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
  ok := List.all(recipes, function canLowerEquation(layout = layout));
  if not ok then return; end if;
  /* Emit each equation as its own  <Model>_eqFunction_<idx>
   * (DATA*, threadData_t*) -> void  function and a
   * <Model>_functionInitialEquations_0 dispatcher that calls them
   * in order. The per-equation symbols make cross-file extern
   * references from still-clang'd files (_05evt.c, the driver)
   * resolve at JIT link time -- the previous inline-only emission
   * left those symbols undefined and forced the modelHasNoEvents
   * gate. */
  ok := List.all(List.zip(initEqs, recipes), function emitNamedEquationFunction(prefix = prefix, layout = layout));
  if not ok then return; end if;
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

protected function emitDynamicEquationsBlock
  "Emit one <prefix>_eqFunction_<idx>(DATA *, threadData_t *) per
   equation in simCode.allEquations that lowers cleanly, using the
   emitNamedEquationFunction machinery. allEquations (not just the ODE
   partition) is the right source: the still-clang'd segment files
   (_05evt.c, _06inz.c, _09alg.c, ...) take `extern` references to the
   algebraic / discrete eqFunction_<idx> symbols that CodegenC otherwise
   defines only in the now-skipped <Model>.c, so SCTL must supply them.

   Each emission is linkonce_odr: where a clang'd file still carries the
   strong CodegenC definition the linker keeps that; where <Model>.c was
   the sole definer (the common case under the cutover) SCTL's becomes
   the live one.

   Only equations whose recipe passes canLowerEquation are emitted.
   Unsupported ones are deliberately left undefined so the JIT-link error
   names exactly which eqFunction_<idx> still needs lowering, instead of a
   silently-wrong empty stub (AGENTS.md section 4). SES_ALIAS (EQ_NOOP)
   shares another equation's body and gets no standalone symbol, matching
   emitInitialEquationsDispatcher.

   Returns true iff every (non-alias) equation lowered cleanly."
  input SimCode.SimCode simCode;
  input VarLayout layout;
  output Boolean ok;
protected
  list<SimCode.SimEqSystem> allEqs;
  list<EqRecipe> recipes;
  String prefix;
  Absyn.Path name;
  EqRecipe recipe;
algorithm
  name := simCodeName(simCode);
  prefix := modelSymbolPrefix(name);
  allEqs := allSimCodeEquations(simCode);
  if listEmpty(allEqs) then
    ok := true;
    return;
  end if;
  recipes := List.map1(allEqs, classifySimEq, layout);
  ok := true;
  for tup in List.zip(allEqs, recipes) loop
    (_, recipe) := tup;
    if isNoopRecipe(recipe) then
      /* alias / no-op: no standalone symbol to emit */
    elseif canLowerEquation(recipe, layout) then
      if not emitNamedEquationFunction(prefix, tup, layout) then
        ok := false;
      end if;
    else
      /* leave the symbol undefined -- loud JIT-link error if referenced */
      ok := false;
    end if;
  end for;
end emitDynamicEquationsBlock;

protected function isNoopRecipe
  input EqRecipe r;
  output Boolean b;
algorithm
  b := match r case EQ_NOOP() then true; else false; end match;
end isNoopRecipe;

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
  if not List.all(recipes, function canLowerEquation(layout = layout)) then return; end if;
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
      (ctx, valTmp, ok) := emitZeroCrossingGout(zc, i, ctx);
      if not ok then
        (ctx, valTmp) := freshTmp(ctx);
        EXT_LLVM.genAllocaModelicaReal(valTmp, false);
        EXT_LLVM.genStoreLiteralReal(0.0, valTmp);
      end if;
      EXT_LLVM.genZcSet("gout", i, valTmp);
    else end try;
    i := i + 1;
  end for;
  EXT_LLVM.genReturnZero();
  EXT_LLVM.finnishGen();
end emitZeroCrossingsBody;

protected function emitZeroCrossingGout
  "Emit the gout value the solver root-finds for a single zero crossing,
   matching CodegenC's function_ZeroCrossings:
     gout[idx] = <op>ZC(lhs, rhs, lhs_nom, rhs_nom, storedRelations[idx]) ? 1 : -1
   via the omc_jit_zc_value adapter. Using the hysteresis +1/-1 step rather
   than the raw continuous residual (lhs - rhs) is what makes state events
   fire inside the tolZC band exactly as the C path does; the raw residual
   fired events at the exact crossing, diverging every event-model trace.
   zcIndex is the storedRelations / gout slot (the zero-crossing's position
   in simCode.zeroCrossings)."
  input BackendDAE.ZeroCrossing zc;
  input Integer zcIndex;
  input EmitCtx ctxIn;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
protected
  DAE.Exp e1, e2;
  DAE.Operator op;
  Integer opc;
  Option<Integer> oc;
  EmitCtx ctx1, ctx2;
  String dst1, dst2;
  Boolean ok1, ok2;
algorithm
  BackendDAE.ZERO_CROSSING(relation_ = DAE.RELATION(exp1 = e1, operator = op, exp2 = e2)) := zc;
  oc := opCodeForRelationOp(op);
  if not isSome(oc) then
    outCtx := ctxIn;
    dst := "<zc-op-unsupported>";
    ok := false;
    return;
  end if;
  SOME(opc) := oc;
  (ctx1, dst1, ok1) := emitExp(e1, ctxIn);
  (ctx2, dst2, ok2) := emitExp(e2, ctx1);
  ok := ok1 and ok2;
  if not ok then
    outCtx := ctx2;
    dst := "<zc-gout-unlowerable>";
    return;
  end if;
  (outCtx, dst) := freshTmp(ctx2);
  EXT_LLVM.genAllocaModelicaReal(dst, false);
  EXT_LLVM.genZcValue("data", dst, dst1, dst2,
    relationOperandNominal(e1), relationOperandNominal(e2), zcIndex, opc);
end emitZeroCrossingGout;

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
      EXT_LLVM.genRelationSet("data", i, valTmp);
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
    case EQ_INT_PARAM_ASSIGN()  then "IPARM(" + intString(r.slotIndex) + ")";
    case EQ_ARRAY_CALL2()       then "ARRCALL2(" + r.fnName + " -> slot " + intString(r.destSlot) + ")";
    case EQ_BOOL_DISCRETE_ASSIGN() then "BDISC(" + intString(r.slotIndex) + ")";
    case EQ_WHEN() then "WHEN(" + intString(listLength(r.conditions)) + " cond, " +
                               intString(listLength(r.whenStmts)) + " stmt)";
    case EQ_ALGORITHM() then "ALGORITHM(" + intString(listLength(r.statements)) + " stmt)";
    case EQ_SOLVE_NONLINEAR() then "SOLVE_NLS(sys=" + intString(r.sysIndex) +
                               ", n=" + intString(listLength(r.varSlots)) + ")";
    case EQ_SOLVE_LINEAR() then "SOLVE_LS(sys=" + intString(r.sysIndex) +
                               ", n=" + intString(listLength(r.varSlots)) + ")";
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
    case EQ_INT_PARAM_ASSIGN(rhs=e)  then ExpressionBasics.printExpStr(e);
    case EQ_BOOL_DISCRETE_ASSIGN(rhs=e) then ExpressionBasics.printExpStr(e);
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

protected function emitRecordsBlock
  "Displace <Model>_records.c when the SimCode has no record
   declarations. The CodegenC template emits an
   include-and-extern-C-only stub in that case (no exported
   symbols), so dropping it from the clang loop is a pure win:
   one fewer clang invocation per JIT-simulate, no IR change
   required.

   When recordDecls is non-empty SCTL must instead emit the
   record_description globals as LLVM constants (roadmap item 4)
   before _records.c can be displaced for those models. Today
   we only handle the empty case to make progress on simple
   models like HelloWorld, BouncingBall, ChuaCircuit."
  input SimCode.SimCode simCode;
protected
  list<SimCodeFunction.RecordDeclaration> recordDecls;
algorithm
  recordDecls := match simCode
    case SimCode.SIMCODE(recordDecls = recordDecls) then recordDecls;
  end match;
  if listEmpty(recordDecls) then
    recordDisplacedSegment("_records.c");
  end if;
end emitRecordsBlock;

protected function emitExternalObjectDestructorsBlock
  "Lift  <Model>_callExternalObjectDestructors  from CodegenC's
   _01exo.c into the active LLVM module as native IR. Only handles
   the no-extObj-vars case today, which matches HelloWorld /
   BouncingBall / ChuaCircuit. Models that own external objects
   keep the segment on the clang path until SCTL learns to emit
   the per-class  omc_<class>_destructor  call chain.

   On success records the segment displacement so compileModelToBitcode
   drops _01exo.c from the clang loop. On a non-empty vars list throws
   so the surrounding try/else leaves the segment in place."
  input SimCode.SimCode simCode;
  input Absyn.Path modelName;
protected
  SimCode.ExtObjInfo extObjInfo;
  list<SimCodeVar.SimVar> vars;
  String prefix;
  Integer st;
algorithm
  extObjInfo := match simCode case SimCode.SIMCODE(extObjInfo = extObjInfo) then extObjInfo; end match;
  vars := match extObjInfo case SimCode.EXTOBJINFO(vars = vars) then vars; end match;
  if not listEmpty(vars) then
    fail();
  end if;
  prefix := modelSymbolPrefix(modelName);
  st := EXT_LLVM.genCallExternalObjectDestructors(prefix);
  if st <> 0 then
    fail();
  end if;
  recordDisplacedSegment("_01exo.c");
end emitExternalObjectDestructorsBlock;

protected function emitModelEquationsBlock
  "Lift  <Model>_functionODE,  <Model>_functionDAE  and
   <Model>_ODE_DAG  into the active Pass-2 module as linkonce_odr
   definitions. Bodies inline the dynamic-equation recipes the same
   way emitODEEntryShell does for Pass 1's smoke test, but the
   emission target is the _sctl module that ships to llvm-link, so
   the IR is positioned to take over from CodegenC.

   linkonce_odr keeps the merge sound while <Model>.c is still on the
   clang path: CodegenC's strong copies arrive in the linked bitcode,
   the linker keeps those and discards ours. When CodegenC gains a
   JIT-aware template guard that drops the functionODE / functionDAE
   bodies, SCTL's IR becomes the sole definition without any
   further change here.

   Skips  <Model>_functionODE_system0  (CodegenC declares it static,
   so it has internal linkage and never collides) and the per-
   equation  <Model>_eqFunction_N  helpers (their indices come from
   the SimEqSystem.index numbering the EqRecipe pipeline does not
   currently track; functionODE / functionDAE inline the equation
   bodies anyway). Equation lowering re-uses the existing
   emitEquationFunction primitive -- no new C++ machinery.

   functionODE inlines the ODE-partition recipes (continuous state
   derivatives). functionDAE inlines the full allEquations set --
   CodegenC's functionDAE iterates allEquations under the discrete
   context, evaluating the discrete/algebraic equations (relation
   results, when conditions, ...) the ODE partition omits. Lowering
   functionDAE from the ODE recipes alone left every discrete Boolean
   stuck at its initial value; classifying allEquations here is what
   lets a model whose only events are observed relations
   (e.g. `over = x <= 0.5`) report correctly.

   Each function is emitted only when *every* one of its recipes
   lowers. A partial functionODE / functionDAE would be silently wrong
   -- it would drop the equations it cannot lower (a `when` body, an
   unsupported call) and the solver would integrate a model missing
   those updates (e.g. BouncingBall falling through the floor because
   its reinit `when` never ran). Leaving the symbol undefined instead
   makes the JIT fail loudly at materialization (AGENTS.md sections 4,
   13), so an uncovered model never masquerades as a JIT success."
  input SimCode.SimCode simCode;
  input list<EqRecipe> recipes;
  input VarLayout layout;
  input Absyn.Path modelName;
protected
  String prefix;
  String fname;
  list<EqRecipe> daeRecipes, algRecipes;
  list<SimCode.SimEqSystem> algEqs;
algorithm
  prefix := modelSymbolPrefix(modelName);

  fname := prefix + "_functionODE";
  if List.all(recipes, function canLowerEquation(layout = layout)) then
    if emitEquationFunction(fname, recipes, layout, MODELICA_INTEGER) then
      _ := EXT_LLVM.setLinkonceOdr(fname);
    end if;
  end if;

  daeRecipes := List.map1(allSimCodeEquations(simCode), classifySimEq, layout);
  fname := prefix + "_functionDAE";
  if List.all(daeRecipes, function canLowerEquation(layout = layout)) then
    if emitEquationFunction(fname, daeRecipes, layout, MODELICA_INTEGER, daePrologue = true) then
      _ := EXT_LLVM.setLinkonceOdr(fname);
    end if;
  end if;

  /* functionAlgebraics recomputes the continuous algebraic equations
   * every step (updateContinuousSystem calls it each integrator step);
   * a stub froze any continuous algebraic var (e.g. y = delay(x)). Emit
   * it from algebraicEquations when they all lower, and only then
   * displace _09alg.c. */
  algEqs := algebraicSimCodeEquations(simCode);
  algRecipes := List.map1(algEqs, classifySimEq, layout);
  fname := prefix + "_functionAlgebraics";
  if List.all(algRecipes, function canLowerEquation(layout = layout)) then
    if emitEquationFunction(fname, algRecipes, layout, MODELICA_INTEGER) then
      _ := EXT_LLVM.setLinkonceOdr(fname);
      recordDisplacedSegment("_09alg.c");
    end if;
  end if;

  /* ODE_DAG: empty body. The C version calls buildEvalDAG_ODE with a
   * constant eqMap to populate an evalSelection hint. The runtime
   * tolerates no DAG hint -- HelloWorld-class non-evalSelection
   * models do not consult it. */
  fname := prefix + "_ODE_DAG";
  emitStub(fname, MODELICA_VOID, {MODELICA_METATYPE, MODELICA_METATYPE});
  _ := EXT_LLVM.setLinkonceOdr(fname);
end emitModelEquationsBlock;

protected function emitCallbackTableBlock
  "Emit the <Model>_callback constant struct global into the active
   Pass-2 module via the C++ helper createCallbackTable. Linkage is
   linkonce_odr -- CodegenC's strong copy wins at llvm-link while
   <Model>.c remains on the clang path, and SCTL's IR takes over
   the day CodegenC stops emitting the table.

   isFmu is hardcoded false: the -d=jitSimulate path does not target
   Model-Exchange FMUs (the FMU runtime supplies its own simulation
   driver). homotopyMethodCode = 3 mirrors LOCAL_EQUIDISTANT_HOMOTOPY
   (the default for models without `homotopy()`); HelloWorld and
   friends never consult the field. The has<Sys>Systems flags drive
   the conditional NULL slots for initialNonLinearSystem /
   initialLinearSystem / initialMixedSystem; hasInitialLambda0 gates
   functionInitialEquations_lambda0.

   The seven INDEX_JAC_* slots carry the analyticJacobians[] index of
   each named model-wide jacobian (A, ADJ, B, C, D, F, H), matching
   CodegenC's `#define <Model>_INDEX_JAC_<name> <jac.jacobianIndex>`.
   Models with both a model-wide A jacobian and per-tearing-system
   LSJacN jacobians cannot share the slot-0 sentinel SCTL used to
   hardcode: DASSL init writes through INDEX_JAC_A and would otherwise
   clobber the LSJacN sparsePattern, leading to a singular linear-system
   matrix at the first solve_linear_system call."
  input SimCode.SimCode simCode;
  input Absyn.Path modelName;
protected
  SimCode.VarInfo vinfo;
  Integer hasNls, hasLs, hasMs, hasLambda0;
  Integer idxJacA, idxJacADJ, idxJacB, idxJacC, idxJacD, idxJacF, idxJacH;
  list<SimCode.JacobianMatrix> jacs;
  Integer st;
algorithm
  vinfo := match simCode.modelInfo case SimCode.MODELINFO(varInfo = vinfo) then vinfo; end match;
  jacs := simCode.jacobianMatrices;
  hasNls := if vinfo.numNonLinearSystems > 0 then 1 else 0;
  hasLs  := if vinfo.numLinearSystems    > 0 then 1 else 0;
  hasMs  := if vinfo.numMixedSystems     > 0 then 1 else 0;
  hasLambda0 := if listEmpty(simCode.initialEquations_lambda0) then 0 else 1;
  idxJacA   := lookupJacIndex(jacs, "A");
  idxJacADJ := lookupJacIndex(jacs, "ADJ");
  idxJacB   := lookupJacIndex(jacs, "B");
  idxJacC   := lookupJacIndex(jacs, "C");
  idxJacD   := lookupJacIndex(jacs, "D");
  idxJacF   := lookupJacIndex(jacs, "F");
  idxJacH   := lookupJacIndex(jacs, "H");
  st := EXT_LLVM.genCallbackTable(
    modelSymbolPrefix(modelName),
    0      /* isFmu */,
    hasNls,
    hasLs,
    hasMs,
    hasLambda0,
    3      /* homotopyMethodCode = LOCAL_EQUIDISTANT_HOMOTOPY */,
    idxJacA, idxJacADJ, idxJacB, idxJacC, idxJacD, idxJacF, idxJacH);
  if st <> 0 then
    fail();
  end if;
end emitCallbackTableBlock;

protected function lookupJacIndex
  "Find the jacobianIndex of the JacobianMatrix whose matrixName
   matches `name`. Returns 0 if no such entry (matching CodegenC's
   behaviour: HelloWorld-class models with no analytic jacobians get
   the 0 sentinel and the runtime's initialAnalyticJacobian* return
   -1, so the slot is never read)."
  input list<SimCode.JacobianMatrix> jacs;
  input String name;
  output Integer idx = 0;
protected
  String mn;
  Integer ji;
algorithm
  for jac in jacs loop
    () := match jac
      case SimCode.JAC_MATRIX(matrixName = mn, jacobianIndex = ji)
        algorithm
          if stringEq(mn, name) then
            idx := ji;
            return;
          end if;
        then ();
    end match;
  end for;
end lookupJacIndex;

protected function emitSetupDataStrucShellBlock
  "Emit the linkonce_odr <Model>_setupDataStruc full body into the
   active Pass-2 module. Wires the two critical pointers (callback,
   threadData->localRoots[SIMULATION_DATA]) plus the canonical
   sequence of MODEL_DATA integer counter stores (nStatesArray,
   nVariablesRealArray, ..., nRelatedBoundaryConditions). The counter
   list order is locked to omc_modeldata_int_offsets[] in
   llvm_gen_layout.c -- any change there demands a matching change
   here. Skipped (still on CodegenC's strong copy): modelName /
   modelGUID strings, XML data, the OpenModelica_updateUriMapping
   resource call, modelDataXml.* fields (populated by the runtime
   from the on-disk _info.json), linearizationDumpLanguage.

   Must run after emitCallbackTableBlock so the @<Model>_callback
   global the body references exists in the module."
  input Absyn.Path modelName;
  input SimCode.SimCode simCode;
protected
  Integer st;
  list<Integer> counters;
algorithm
  counters := modelDataCounters(simCode);
  st := EXT_LLVM.genSetupDataStrucFull(modelSymbolPrefix(modelName), counters);
  if st <> 0 then
    fail();
  end if;
end emitSetupDataStrucShellBlock;

protected function modelDataCounters
  "Extract the 41 MODEL_DATA n<X> values from SimCode in the order
   declared by omc_modeldata_int_offsets[] in llvm_gen_layout.c.
   Every counter is destructured into a local Integer up front; the
   list literal references only locals so the MetaModelica elaborator
   does not have to type-resolve dot-projections inside a long list."
  input SimCode.SimCode simCode;
  output list<Integer> counters;
protected
  Integer cStates, cDiscReal, cVarsRArr, cVarsIArr, cVarsBArr, cVarsSArr;
  Integer cParRArr, cParIArr, cParBArr, cParSArr;
  Integer cAliasRArr, cAliasIArr, cAliasBArr, cAliasSArr;
  Integer cInVars, cOutVars, cZc, cRel, cMathEv, cExtObj;
  Integer cMix, cLin, cNln, cStSets, cOptC, cOptFC;
  Integer cSensV, cSetc, cDataRec, cSetb, cBC;
  Integer cJac, cDelay, cSpatial;
algorithm
  () := match simCode.modelInfo
    case SimCode.MODELINFO(varInfo = SimCode.VARINFO(
        numStateVars             = cStates,
        numDiscreteReal          = cDiscReal,
        numAlgVars               = cVarsRArr,
        numIntAlgVars            = cVarsIArr,
        numBoolAlgVars           = cVarsBArr,
        numStringAlgVars         = cVarsSArr,
        numParams                = cParRArr,
        numIntParams             = cParIArr,
        numBoolParams            = cParBArr,
        numStringParamVars       = cParSArr,
        numAlgAliasVars          = cAliasRArr,
        numIntAliasVars          = cAliasIArr,
        numBoolAliasVars         = cAliasBArr,
        numStringAliasVars       = cAliasSArr,
        numInVars                = cInVars,
        numOutVars               = cOutVars,
        numZeroCrossings         = cZc,
        numRelations             = cRel,
        numMathEventFunctions    = cMathEv,
        numExternalObjects       = cExtObj,
        numMixedSystems          = cMix,
        numLinearSystems         = cLin,
        numNonLinearSystems      = cNln,
        numStateSets             = cStSets,
        numOptimizeConstraints   = cOptC,
        numOptimizeFinalConstraints = cOptFC,
        numSensitivityParameters = cSensV,
        numSetcVars              = cSetc,
        numDataReconVars         = cDataRec,
        numSetbVars              = cSetb,
        numRelatedBoundaryConditions = cBC))
      then ();
  end match;
  cVarsRArr := cVarsRArr + 2 * cStates;
  cJac      := listLength(simCode.jacobianMatrices);
  cDelay    := delayedExpCount(simCode);
  cSpatial  := spatialDistributionCount(simCode);
  /* Order matches omc_modeldata_int_offsets[] in llvm_gen_layout.c.
   * The two duplicate parameter slots (nParametersReal* + nParameters*)
   * use the same source values; CodegenC emits them identically too. */
  counters := listAppend(listAppend({
    cStates, cDiscReal, cVarsRArr, cVarsIArr, cVarsBArr, cVarsSArr,
    cParRArr, cParIArr, cParBArr, cParSArr,
    cParRArr, cParIArr, cParBArr, cParSArr},
  {cAliasRArr, cAliasIArr, cAliasBArr, cAliasSArr,
    cInVars, cOutVars, cZc, 0, cRel, cMathEv, cExtObj,
    cMix, cLin, cNln, cStSets}),
  {cJac, cOptC, cOptFC, cDelay, 0, cSpatial,
    cSensV, cSensV, cSetc, cDataRec, cSetb, cBC});
end modelDataCounters;

protected function delayedExpCount
  input SimCode.SimCode simCode;
  output Integer n;
protected
  list<tuple<Integer, tuple<DAE.Exp, DAE.Exp, DAE.Exp>>> ds;
algorithm
  ds := match simCode.delayedExps case SimCode.DELAYED_EXPRESSIONS(delayedExps = ds) then ds; end match;
  n := listLength(ds);
end delayedExpCount;

protected function spatialDistributionCount
  input SimCode.SimCode simCode;
  output Integer n;
protected
  list<SimCode.SpatialDistribution> sds;
algorithm
  sds := match simCode.spatialInfo case SimCode.SPATIAL_DISTRIBUTION_INFO(spatialDistributions = sds) then sds; end match;
  n := listLength(sds);
end spatialDistributionCount;

protected function emitMainShimBlock
  "Emit  int main(int, char**)  into the active Pass-2 module. Must
   run after emitSetupDataStrucShellBlock so the shim's call to
   <Model>_setupDataStruc resolves within the same module. The
   adapter reads the model GUID out of <filePrefix>_init.xml at runtime
   so SCTL never has to coordinate with SerializeInitXML.

   Two prefixes: the symbol prefix (model path with dots -> underscores)
   names the <prefix>_setupDataStruc symbol the shim calls; the file
   prefix (simCode.fileNamePrefix, the dotted model name for a plain
   simulate()) names the on-disk <filePrefix>_init.xml / _info.json the
   runtime reads. They coincide for a dot-free model name (HelloWorld)
   but not for a qualified one (Modelica.Mechanics...Engine1a), where the
   init.xml is written with dots."
  input Absyn.Path modelName;
  input SimCode.SimCode simCode;
protected
  Integer st;
  String filePrefix;
algorithm
  filePrefix := match simCode case SimCode.SIMCODE(fileNamePrefix = filePrefix) then filePrefix; end match;
  st := EXT_LLVM.genMainShim(modelSymbolPrefix(modelName), filePrefix);
  if st <> 0 then
    fail();
  end if;
end emitMainShimBlock;

protected function emitNonlinearSystemsBlock
  "Displace <Model>_02nls.c when the SimCode carries no nonlinear
   systems. Empty in that case (include / extern-C only), same
   logic as emitRecordsBlock. Models with real NLS keep the
   segment on the clang path until SCTL learns to emit NLS
   residuals + Jacobian columns directly."
  input SimCode.SimCode simCode;
protected
  list<SimCode.SimEqSystem> nls;
algorithm
  nls := match simCode
    case SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(nonLinearSystems = nls))
      then nls;
  end match;
  if listEmpty(nls) then
    recordDisplacedSegment("_02nls.c");
  end if;
end emitNonlinearSystemsBlock;

protected function emitLinearSystemsBlock
  "Displace <Model>_03lsy.c when the SimCode carries no linear
   systems. Mirrors emitNonlinearSystemsBlock; gated on
   modelInfo.linearSystems being empty so models with real LSY
   (Modelica.Mechanics.Rotational.Examples.First, ...) keep the
   segment on clang until SCTL emits the LSY entry points."
  input SimCode.SimCode simCode;
protected
  list<SimCode.SimEqSystem> lsy;
algorithm
  lsy := match simCode
    case SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(linearSystems = lsy))
      then lsy;
  end match;
  if listEmpty(lsy) then
    recordDisplacedSegment("_03lsy.c");
  end if;
end emitLinearSystemsBlock;

protected function reportBlockFailure
  "Diagnostic for a Pass-2 emitter that raised an MMC failure.
   The block-level try/else above catches the failure so the
   remaining blocks can still run, but we want the user to see
   WHICH block failed and for which model so they can either
   open a bug or arrange a fallback. The message routes through
   Error.addInternalError so it lands in the SimulationResult
   diagnostics, not just stderr."
  input String blockName;
  input Absyn.Path modelName;
algorithm
  Error.addInternalError(
    "SimCodeToLLVM Pass 2: " + blockName + " raised MMC failure on '" +
    AbsynUtil.pathString(modelName) +
    "' -- this block's segment stays on the clang path; other " +
    "blocks continue normally. Set +d=failtrace for the deeper trace.\n",
    sourceInfo());
end reportBlockFailure;

protected function eqIsMixed
  "True iff this equation system is a mixed continuous/discrete
   SES_MIXED. Used by emitMixedSystemsBlock to decide whether
   _11mix.c is structurally empty."
  input SimCode.SimEqSystem eq;
  output Boolean isMixed;
algorithm
  isMixed := match eq
    case SimCode.SES_MIXED() then true;
    else false;
  end match;
end eqIsMixed;

protected function hasAnyMixedSystem
  "True iff the SimCode has any SES_MIXED in the equation lists
   that _11mix.c would otherwise expose. CodegenC's _11mix
   template covers initial, initial_lambda0, parameter, model,
   and jacobian mixed systems, so we look across all the
   equation lists that feed those template branches."
  input SimCode.SimCode simCode;
  output Boolean any;
protected
  list<SimCode.SimEqSystem> allEqs, initEqs, initLambda0, paramEqs, jacEqs;
algorithm
  (allEqs, initEqs, initLambda0, paramEqs, jacEqs) := match simCode
    case SimCode.SIMCODE(allEquations = allEqs,
                         initialEquations = initEqs,
                         initialEquations_lambda0 = initLambda0,
                         parameterEquations = paramEqs,
                         jacobianEquations = jacEqs)
      then (allEqs, initEqs, initLambda0, paramEqs, jacEqs);
  end match;
  any := List.any(allEqs, eqIsMixed)
      or List.any(initEqs, eqIsMixed)
      or List.any(initLambda0, eqIsMixed)
      or List.any(paramEqs, eqIsMixed)
      or List.any(jacEqs, eqIsMixed);
end hasAnyMixedSystem;

protected function emitMixedSystemsBlock
  "Displace <Model>_11mix.c when the SimCode has no SES_MIXED
   equations anywhere. CodegenC's _11mix template emits a
   comment-and-include-only stub in that case (no exported
   symbols). Mirrors emitNonlinearSystemsBlock / emitLinearSystemsBlock."
  input SimCode.SimCode simCode;
algorithm
  if not hasAnyMixedSystem(simCode) then
    recordDisplacedSegment("_11mix.c");
  end if;
end emitMixedSystemsBlock;

protected function emitFunctionsBlock
  "Displace <Model>_functions.c when the SimCode has no
   user-defined Modelica functions. The CodegenC template emits
   only the include / extern-C scaffolding in that case (no
   exported symbols), so dropping it is a pure win -- same
   logic as emitRecordsBlock for the records segment.

   Models with user functions (Friction's
   ExternalCombiTable1D_constructor, ChuaCircuit's Nf, ...) keep
   _functions.c on the clang path until DAEToMid + MidToLLVM
   can lower the full SimCodeFunction signature (arrays, complex
   / ExternalObject types, external \"C\" bindings) -- that is
   roadmap item 5."
  input SimCode.SimCode simCode;
protected
  list<SimCodeFunction.Function> simFuncs;
algorithm
  simFuncs := match simCode
    case SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(functions = simFuncs))
      then simFuncs;
  end match;
  if listEmpty(simFuncs) then
    recordDisplacedSegment("_functions.c");
  end if;
end emitFunctionsBlock;

protected function emitDisplacingStubs
  "Walk the runtimeEntryCatalog and emit IR for every entry that is
   safe to stub for *this* model. A catalog entry is safe to stub when
   its CodegenC body is semantically equivalent to the stub for the
   features the model actually uses -- e.g. _function_storeDelayed is
   safe iff the model has no delay() expressions, _function_*Synchronous
   are safe iff the model has no clocked partitions, etc. See
   entryIsSafeToStub for the per-entry rules.

   Per-file accounting: a segment .c file is displaced only when ALL
   its catalog entries pass the safety check. If any entry is unsafe
   (or EB_TODO), the whole file stays on the clang path so the linker
   sees a single definition of every symbol in that file. The catalog
   was previously the only source of displacements; today every
   displacement goes through recordDisplacedSegment so the dynamic
   skip list is the single source of truth for displacedSegmentFiles.

   For each unsafe entry the function emits one compiler warning
   identifying the feature that blocks the stub, so a user simulating
   a delay()-using model gets a clear  'SimCodeToLLVM: ... requires
   delay() ...'  diagnostic instead of silently-wrong stub IR."
  input SimCode.SimCode simCode;
  input Absyn.Path modelName;
protected
  String prefix;
  list<RuntimeEntry> catalog;
  list<String> blockedFiles = {};
  list<String> displaceCandidates = {};
algorithm
  prefix := modelSymbolPrefix(modelName);
  catalog := runtimeEntryCatalog();
  /* Pass 1: classify each entry. An entry is blocked when its body is
   * EB_TODO (file owned by a Block emitter or by clang) or when the
   * safety predicate rejects it for this model. Blocking only taints
   * the file for displacement when the entry carries displaceFile=true;
   * <Model>.c entries (displaceFile=false) just skip emission without
   * affecting anyone else's displacement decision. */
  for e in catalog loop
    if isTodoBody(e.body) then
      if e.displaceFile then
        blockedFiles := uniqueAppend(blockedFiles, e.segmentFile);
      end if;
    elseif not entryIsSafeToStub(e, simCode) then
      if e.displaceFile then
        blockedFiles := uniqueAppend(blockedFiles, e.segmentFile);
      end if;
      emitUnsupportedWarning(e, modelName);
    elseif e.displaceFile then
      displaceCandidates := uniqueAppend(displaceCandidates, e.segmentFile);
    end if;
  end for;
  /* Pass 2: emit stubs for entries that are not blocked at the file
   * level (when displaceFile=true) or that pass the safety check alone
   * (when displaceFile=false). EB_TODO is never emitted here -- the
   * matching Block emitter or clang owns those symbols. */
  for e in catalog loop
    if not isTodoBody(e.body) and entryIsSafeToStub(e, simCode) then
      if (not e.displaceFile) or (not List.contains(blockedFiles, e.segmentFile, stringEqual)) then
        emitRuntimeEntry(prefix, e);
      end if;
    end if;
  end for;
  for f in displaceCandidates loop
    if not List.contains(blockedFiles, f, stringEqual) then
      recordDisplacedSegment(f);
    end if;
  end for;
end emitDisplacingStubs;

protected function entryIsSafeToStub
  "True when the stub body declared for `entry` is semantically
   equivalent to CodegenC's body for this model. Each entry has a
   Feature tag derived from its nameSuffix; the entry is safe iff the
   model does not exhibit that feature. FEATURE_NONE -- the catalog
   default -- means the stub is always safe (e.g. _checkForAsserts,
   _linear_model_frame return the same sentinel regardless of model
   content)."
  input RuntimeEntry entry;
  input SimCode.SimCode simCode;
  output Boolean safe;
algorithm
  safe := featureIsAbsent(featureFor(entry.nameSuffix), simCode);
end entryIsSafeToStub;

protected function featureFor
  "Map a catalog entry's nameSuffix to the Modelica feature that, when
   present in the SimCode, makes the stub semantically incorrect.
   Single dispatch table -- both featureName and featureIsAbsent key
   off the resulting tag, so the per-feature wording and the per-
   feature SimCode probe live in one place each."
  input String nameSuffix;
  output Feature feature;
algorithm
  feature := match nameSuffix
    case "_function_storeDelayed"                 then Feature.DELAY_EXPRS;
    case "_function_storeSpatialDistribution"     then Feature.SPATIAL_DISTRIBUTION;
    case "_function_initSpatialDistribution"      then Feature.SPATIAL_DISTRIBUTION;
    case "_function_savePreSynchronous"           then Feature.CLOCKED_PARTITIONS;
    case "_function_initSynchronous"              then Feature.CLOCKED_PARTITIONS;
    case "_function_updateSynchronous"            then Feature.CLOCKED_PARTITIONS;
    case "_function_equationsSynchronous"         then Feature.CLOCKED_PARTITIONS;
    case "_initializeStateSets"                   then Feature.STATE_SETS;
    case "_input_function"                        then Feature.INPUT_VARS;
    case "_input_function_init"                   then Feature.INPUT_VARS;
    case "_input_function_updateStartValues"      then Feature.INPUT_VARS;
    case "_inputNames"                            then Feature.INPUT_VARS;
    case "_output_function"                       then Feature.OUTPUT_VARS;
    case "_data_function"                         then Feature.DATA_RECON_INPUTS;
    case "_dataReconciliationInputNames"          then Feature.DATA_RECON_INPUTS;
    case "_dataReconciliationUnmeasuredVariables" then Feature.DATA_RECON_SET_B;
    case "_setc_function"                         then Feature.DATA_RECON_SET_C;
    case "_setb_function"                         then Feature.DATA_RECON_SET_B;
    case "_functionLocalKnownVars"                then Feature.LOCAL_KNOWN_VARS;
    else Feature.NONE;
  end match;
end featureFor;

protected function featureIsAbsent
  "True when `feature` is not exhibited by the model."
  input Feature feature;
  input SimCode.SimCode simCode;
  output Boolean absent;
protected
  SimCodeVar.SimVars vars;
  list<tuple<Integer, tuple<DAE.Exp, DAE.Exp, DAE.Exp>>> dxs;
  list<SimCode.SpatialDistribution> sds;
algorithm
  vars := getSimVars(simCode);
  absent := match feature
    case Feature.NONE then true;
    case Feature.DELAY_EXPRS algorithm
      dxs := match simCode.delayedExps case SimCode.DELAYED_EXPRESSIONS(delayedExps = dxs) then dxs; end match;
    then listEmpty(dxs);
    case Feature.SPATIAL_DISTRIBUTION algorithm
      sds := match simCode.spatialInfo case SimCode.SPATIAL_DISTRIBUTION_INFO(spatialDistributions = sds) then sds; end match;
    then listEmpty(sds);
    case Feature.CLOCKED_PARTITIONS  then listEmpty(simCode.clockedPartitions);
    case Feature.STATE_SETS          then listEmpty(simCode.stateSets);
    case Feature.LOCAL_KNOWN_VARS    then listEmpty(simCode.localKnownVars);
    case Feature.INPUT_VARS          then listEmpty(vars.inputVars);
    case Feature.OUTPUT_VARS         then listEmpty(vars.outputVars);
    case Feature.DATA_RECON_INPUTS   then listEmpty(vars.dataReconinputVars);
    case Feature.DATA_RECON_SET_C    then listEmpty(vars.dataReconSetcVars);
    case Feature.DATA_RECON_SET_B    then listEmpty(vars.dataReconSetBVars);
  end match;
end featureIsAbsent;

protected function featureName
  "Human-readable Modelica feature name for the diagnostic warning."
  input Feature feature;
  output String name;
algorithm
  name := match feature
    case Feature.DELAY_EXPRS           then FEATURE_NAME_DELAY_EXPRS;
    case Feature.SPATIAL_DISTRIBUTION  then FEATURE_NAME_SPATIAL_DISTRIBUTION;
    case Feature.CLOCKED_PARTITIONS    then FEATURE_NAME_CLOCKED_PARTITIONS;
    case Feature.STATE_SETS            then FEATURE_NAME_STATE_SETS;
    case Feature.INPUT_VARS            then FEATURE_NAME_INPUT_VARS;
    case Feature.OUTPUT_VARS           then FEATURE_NAME_OUTPUT_VARS;
    case Feature.DATA_RECON_INPUTS     then FEATURE_NAME_DATA_RECON_INPUTS;
    case Feature.DATA_RECON_SET_B      then FEATURE_NAME_DATA_RECON_SET_B;
    case Feature.DATA_RECON_SET_C      then FEATURE_NAME_DATA_RECON_SET_C;
    case Feature.LOCAL_KNOWN_VARS      then FEATURE_NAME_LOCAL_KNOWN_VARS;
    case Feature.NONE                  then FEATURE_NAME_NONE;
  end match;
end featureName;

protected function getSimVars
  "Convenience: project simCode -> modelInfo -> vars in one place so
   the featureIsAbsent dispatch reads as a flat field chain."
  input SimCode.SimCode simCode;
  output SimCodeVar.SimVars vars;
algorithm
  vars := match simCode.modelInfo case SimCode.MODELINFO(vars = vars) then vars; end match;
end getSimVars;

protected function emitUnsupportedWarning
  "One-line compiler warning per blocked entry. Tells the user which
   model + feature + segment file is keeping the C path alive, so the
   '.c is being clang'd even though SCTL is on' is never a silent
   surprise."
  input RuntimeEntry entry;
  input Absyn.Path modelName;
algorithm
  Error.addCompilerWarning(
    "SimCodeToLLVM: model " + AbsynUtil.pathString(modelName) +
    " uses " + featureName(featureFor(entry.nameSuffix)) +
    "; runtime entry " + entry.nameSuffix +
    " in " + entry.segmentFile +
    " stays on the C/clang path until SCTL learns to lower it.");
end emitUnsupportedWarning;

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
    case EB_STUB_LINKONCE() algorithm
      emitStub(prefix + entry.nameSuffix, entry.retTy, entry.argTys);
      _ := EXT_LLVM.setLinkonceOdr(prefix + entry.nameSuffix);
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
          emitWriteRealVar(absoluteSlot(VKS_DERIVATIVE, slot, ctx2.layout),
                           rhsTmp);
        end if;
      then (ctx2, exprOk);
    case EQ_STATE_ASSIGN(slotIndex=slot, rhs=rhs)
      algorithm
        (ctx2, rhsTmp, exprOk) := emitExp(rhs, ctx);
        if exprOk then
          emitWriteRealVar(absoluteSlot(VKS_STATE, slot, ctx2.layout),
                           rhsTmp);
        end if;
      then (ctx2, exprOk);
    case EQ_ALG_ASSIGN(slotIndex=slot, rhs=rhs)
      algorithm
        (ctx2, rhsTmp, exprOk) := emitExp(rhs, ctx);
        if exprOk then
          emitWriteRealVar(absoluteSlot(VKS_ALG, slot, ctx2.layout),
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
    case EQ_INT_PARAM_ASSIGN(slotIndex=slot, rhs=rhs)
      algorithm
        (ctx2, rhsTmp, exprOk) := emitIntExp(rhs, ctx);
        if exprOk then
          EXT_LLVM.genWriteIntParam("data", slot, rhsTmp);
        end if;
      then (ctx2, exprOk);
    case EQ_ARRAY_CALL2()
      algorithm
        EXT_LLVM.genArrayCall2Real("data", "threadData", r.fnName,
          r.aData, r.bData, "sctl_arr_" + intString(r.eqIndex),
          r.destSlot, r.ndims, r.d0, r.d1);
      then (ctx, true);
    case EQ_BOOL_DISCRETE_ASSIGN(slotIndex=slot, rhs=rhs)
      algorithm
        (ctx2, rhsTmp, exprOk) := emitBoolExp(rhs, ctx);
        if exprOk then
          EXT_LLVM.genStoreBoolVar("data",
            absoluteSlot(VKS_BOOL_DISCRETE, slot, ctx2.layout), rhsTmp);
        end if;
      then (ctx2, exprOk);
    case EQ_WHEN()
      algorithm
        (ctx2, exprOk) := emitWhenEquation(r.conditions, r.whenStmts, ctx);
      then (ctx2, exprOk);
    case EQ_ALGORITHM()
      algorithm
        (ctx2, exprOk) := emitAlgorithmStmts(r.statements, ctx);
      then (ctx2, exprOk);
    case EQ_SOLVE_NONLINEAR()
      algorithm
        EXT_LLVM.genSolveNonlinearN("data", "threadData", r.sysIndex,
                                    r.varSlots,
                                    solveSlotArrName(ctx.layout, r.sysIndex, true));
      then (ctx, true);
    case EQ_SOLVE_LINEAR()
      algorithm
        EXT_LLVM.genSolveLinearN("data", "threadData", r.sysIndex,
                                 r.varSlots,
                                 solveSlotArrName(ctx.layout, r.sysIndex, false));
      then (ctx, true);
    case EQ_NOOP()        then (ctx, true);
    case EQ_ALG_CALL()    algorithm emitAlgCall(r.synthName); then (ctx, true);
    case EQ_PARAM_RANGE_ASSERT()
      algorithm emitParamRangeAssert(r.slotIndex, r.isGreaterEq, r.bound);
      then (ctx, true);
    case EQ_UNSUPPORTED() then (ctx, false);
  end match;
end emitEquation;

protected function solveSlotArrName
  "Per-system stable LLVM global name for the constant [N x i64] slot
   array passed to the multi-unknown solver adapter. Each linear /
   nonlinear system gets one private global; later calls with the same
   name reuse the existing definition via getNamedGlobal."
  input VarLayout layout;
  input Integer sysIndex;
  input Boolean isNonlinear;
  output String name;
algorithm
  name := if isNonlinear
    then "sctl_nlsys_" + intString(sysIndex) + "_slots"
    else "sctl_lsys_"  + intString(sysIndex) + "_slots";
end solveSlotArrName;

protected function emitWhenEquation
  "Lower a when-equation by predication. First materialise the edge
   condition (OR over the conditions of `cond and not pre(cond)`), then
   emit each body statement as `lhs = edge ? rhs : lhs`."
  input list<DAE.ComponentRef> conditions;
  input list<BackendDAE.WhenOperator> whenStmts;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output Boolean ok;
protected
  String edgeTmp;
  Boolean ok1;
algorithm
  (outCtx, edgeTmp, ok) := emitWhenEdge(conditions, ctx);
  if not ok then
    return;
  end if;
  for st in whenStmts loop
    (outCtx, ok1) := emitWhenStmt(st, edgeTmp, outCtx);
    ok := ok and ok1;
  end for;
end emitWhenEquation;

protected function emitWhenEdge
  "Materialise the when activation edge into an i32 alloca:
   OR over the conditions of  booleanVars[c] and not booleanVarsPre[c].
   Each condition must resolve to a discrete-Boolean slot."
  input list<DAE.ComponentRef> conditions;
  input EmitCtx ctx;
  output EmitCtx outCtx = ctx;
  output String edgeTmp = "<no-when-condition>";
  output Boolean ok = true;
protected
  String curTmp, preTmp, notPreTmp, edgeI, newAcc;
  Boolean okc, okp, haveAcc = false;
algorithm
  for cond in conditions loop
    (outCtx, curTmp, okc) := emitBoolCrefRead(cond, outCtx);
    (outCtx, preTmp, okp) := emitBoolPreRead(cond, outCtx);
    if not (okc and okp) then
      ok := false;
      return;
    end if;
    (outCtx, notPreTmp) := freshTmp(outCtx);
    EXT_LLVM.genBoolNot(preTmp, notPreTmp);
    (outCtx, edgeI) := freshTmp(outCtx);
    EXT_LLVM.genBoolBinop(curTmp, notPreTmp, edgeI, 0 /* AND */);
    if haveAcc then
      (outCtx, newAcc) := freshTmp(outCtx);
      EXT_LLVM.genBoolBinop(edgeTmp, edgeI, newAcc, 1 /* OR */);
      edgeTmp := newAcc;
    else
      edgeTmp := edgeI;
      haveAcc := true;
    end if;
  end for;
  ok := haveAcc;
end emitWhenEdge;

protected function emitWhenStmt
  "Emit one predicated when-body statement. ASSIGN to a Real / discrete
   Real / state writes  realVars[slot] = edge ? rhs : realVars[slot];
   ASSIGN to a discrete Boolean writes booleanVars; REINIT writes the
   state and sets needToIterate (predicated)."
  input BackendDAE.WhenOperator stmt;
  input String edgeTmp;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output Boolean ok;
algorithm
  (outCtx, ok) := match stmt
    local DAE.ComponentRef cref;
          DAE.Exp rhs;
          EmitCtx c1;
          Boolean ok1;
    case BackendDAE.ASSIGN(left = DAE.CREF(componentRef = cref), right = rhs)
      algorithm
        (c1, ok1) := emitWhenAssign(cref, rhs, edgeTmp, ctx);
      then (c1, ok1);
    case BackendDAE.REINIT(stateVar = cref, value = rhs)
      algorithm
        (c1, ok1) := emitWhenReinitStmt(cref, rhs, edgeTmp, ctx);
      then (c1, ok1);
    else (ctx, false);
  end match;
end emitWhenStmt;

protected function emitWhenAssign
  "Dispatch a when-body ASSIGN by the LHS slot kind: discrete Boolean
   stores into booleanVars, every other resolved kind into realVars."
  input DAE.ComponentRef cref;
  input DAE.Exp rhs;
  input String edgeTmp;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output Boolean ok;
protected
  Option<VarSlot> os;
  VarSlot vs;
algorithm
  os := lookupSlot(cref, ctx.layout);
  (outCtx, ok) := match os
    case SOME(vs as VAR_SLOT(kind = VK_BOOL_DISCRETE()))
      algorithm (outCtx, ok) := emitWhenBoolAssign(vs, rhs, edgeTmp, ctx); then (outCtx, ok);
    case SOME(vs as VAR_SLOT(kind = VK_INT_DISCRETE()))
      algorithm (outCtx, ok) := emitWhenIntAssign(vs, rhs, edgeTmp, ctx); then (outCtx, ok);
    case SOME(vs as VAR_SLOT(kind = VK_STATE()))
      algorithm (outCtx, ok) := emitWhenRealAssign(vs, rhs, edgeTmp, ctx); then (outCtx, ok);
    case SOME(vs as VAR_SLOT(kind = VK_DERIVATIVE()))
      algorithm (outCtx, ok) := emitWhenRealAssign(vs, rhs, edgeTmp, ctx); then (outCtx, ok);
    case SOME(vs as VAR_SLOT(kind = VK_ALG()))
      algorithm (outCtx, ok) := emitWhenRealAssign(vs, rhs, edgeTmp, ctx); then (outCtx, ok);
    else (ctx, false);
  end match;
end emitWhenAssign;

protected function emitWhenReinitStmt
  input DAE.ComponentRef cref;
  input DAE.Exp value;
  input String edgeTmp;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output Boolean ok;
protected
  Option<VarSlot> os;
  VarSlot vs;
algorithm
  os := lookupSlot(cref, ctx.layout);
  (outCtx, ok) := match os
    case SOME(vs as VAR_SLOT(kind = VK_STATE()))
      algorithm (outCtx, ok) := emitWhenReinit(vs, value, edgeTmp, ctx); then (outCtx, ok);
    else (ctx, false);
  end match;
end emitWhenReinitStmt;

protected function emitWhenRealAssign
  "realVars[slot] = edge ? rhs : realVars[slot]  (predicated Real assign)."
  input VarSlot vs;
  input DAE.Exp rhs;
  input String edgeTmp;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output Boolean ok;
protected
  String rhsTmp, curTmp, selTmp;
  Integer slot;
algorithm
  slot := absoluteSlot(vs.kind, vs.index, ctx.layout);
  (outCtx, rhsTmp, ok) := emitExp(rhs, ctx);
  if ok then
    (outCtx, curTmp) := emitReadRealVar(slot, outCtx);
    (outCtx, selTmp) := freshTmp(outCtx);
    EXT_LLVM.genAllocaModelicaReal(selTmp, false);
    EXT_LLVM.genSelectReal(edgeTmp, rhsTmp, curTmp, selTmp);
    emitWriteRealVar(slot, selTmp);
  end if;
end emitWhenRealAssign;

protected function emitWhenBoolAssign
  "booleanVars[slot] = edge ? rhs : booleanVars[slot]  (predicated Bool)."
  input VarSlot vs;
  input DAE.Exp rhs;
  input String edgeTmp;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output Boolean ok;
protected
  String rhsTmp, curTmp, selTmp;
  Integer slot;
algorithm
  slot := absoluteSlot(vs.kind, vs.index, ctx.layout);
  (outCtx, rhsTmp, ok) := emitBoolExp(rhs, ctx);
  if ok then
    (outCtx, curTmp) := emitReadBoolVarSlot(slot, outCtx);
    (outCtx, selTmp) := freshTmp(outCtx);
    EXT_LLVM.genSelectBool(edgeTmp, rhsTmp, curTmp, selTmp);
    EXT_LLVM.genStoreBoolVar("data", slot, selTmp);
  end if;
end emitWhenBoolAssign;

protected function emitReadBoolVarSlot
  "Read booleanVars[slot] into a fresh i32 alloca (slot already absolute)."
  input Integer slot;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
algorithm
  (outCtx, dst) := freshTmp(ctx);
  EXT_LLVM.genReadBoolVar("data", slot, dst);
end emitReadBoolVarSlot;

protected function emitWhenIntAssign
  "integerVars[slot] = edge ? rhs : integerVars[slot]  (predicated Integer)."
  input VarSlot vs;
  input DAE.Exp rhs;
  input String edgeTmp;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output Boolean ok;
protected
  String rhsTmp, curTmp, selTmp;
  Integer slot;
algorithm
  slot := absoluteSlot(vs.kind, vs.index, ctx.layout);
  (outCtx, rhsTmp, ok) := emitIntExp(rhs, ctx);
  if ok then
    (outCtx, curTmp) := freshTmp(outCtx);
    EXT_LLVM.genReadIntVar("data", slot, curTmp);
    (outCtx, selTmp) := freshTmp(outCtx);
    EXT_LLVM.genSelectInt(edgeTmp, rhsTmp, curTmp, selTmp);
    EXT_LLVM.genStoreIntVar("data", slot, selTmp);
  end if;
end emitWhenIntAssign;

protected function emitWhenReinit
  "reinit(state, value): realVars[state] = edge ? value : realVars[state]
   and simulationInfo->needToIterate = edge ? 1 : needToIterate."
  input VarSlot vs;
  input DAE.Exp value;
  input String edgeTmp;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output Boolean ok;
protected
  String rhsTmp, curTmp, selTmp;
  Integer slot;
algorithm
  slot := absoluteSlot(vs.kind, vs.index, ctx.layout);
  (outCtx, rhsTmp, ok) := emitExp(value, ctx);
  if ok then
    (outCtx, curTmp) := emitReadRealVar(slot, outCtx);
    (outCtx, selTmp) := freshTmp(outCtx);
    EXT_LLVM.genAllocaModelicaReal(selTmp, false);
    EXT_LLVM.genSelectReal(edgeTmp, rhsTmp, curTmp, selTmp);
    emitWriteRealVar(slot, selTmp);
    EXT_LLVM.genSetNeedToIterate("data", edgeTmp);
  end if;
end emitWhenReinit;

protected function emitAlgorithmStmts
  "Emit each statement of an algorithm section as an unconditional
   assignment, in order. ok is the conjunction over the statements."
  input list<DAE.Statement> stmts;
  input EmitCtx ctx;
  output EmitCtx outCtx = ctx;
  output Boolean ok = true;
protected
  Boolean ok1;
algorithm
  for st in stmts loop
    (outCtx, ok1) := emitStmt(st, outCtx);
    ok := ok and ok1;
  end for;
end emitAlgorithmStmts;

protected function emitStmt
  "Emit one algorithm statement. Only scalar `cref := expr` assignments
   to a layout-resolved variable are lowered (unconditional write,
   dispatched by slot kind); anything else fails the recipe."
  input DAE.Statement stmt;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output Boolean ok;
algorithm
  (outCtx, ok) := match stmt
    local DAE.ComponentRef cref;
          DAE.Exp rhs, cond;
          EmitCtx c1;
          Boolean ok1;
          String condTmp, msg;
    case DAE.STMT_ASSIGN(exp1 = DAE.CREF(componentRef = cref), exp = rhs)
      algorithm
        (c1, ok1) := emitStmtAssign(cref, rhs, ctx);
      then (c1, ok1);
    case DAE.STMT_ASSERT(cond = cond, msg = DAE.SCONST(string = msg))
      algorithm
        (c1, condTmp, ok1) := emitBoolExp(cond, ctx);
        if ok1 then
          EXT_LLVM.genAssert("threadData", condTmp, msg);
        end if;
      then (c1, ok1);
    else (ctx, false);
  end match;
end emitStmt;

protected function emitStmtAssign
  "Unconditional `lhs := rhs` write, dispatched by the LHS slot kind --
   the same real / discrete-Boolean / discrete-Integer split as the
   when-body assign but without the edge select."
  input DAE.ComponentRef cref;
  input DAE.Exp rhs;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output Boolean ok;
protected
  Option<VarSlot> os;
  VarSlot vs;
  String rhsTmp;
  Integer slot;
algorithm
  os := lookupSlot(cref, ctx.layout);
  (outCtx, ok) := match os
    case SOME(vs as VAR_SLOT(kind = VK_BOOL_DISCRETE()))
      algorithm
        (outCtx, rhsTmp, ok) := emitBoolExp(rhs, ctx);
        if ok then
          EXT_LLVM.genStoreBoolVar("data", absoluteSlot(vs.kind, vs.index, ctx.layout), rhsTmp);
        end if;
      then (outCtx, ok);
    case SOME(vs as VAR_SLOT(kind = VK_INT_DISCRETE()))
      algorithm
        (outCtx, rhsTmp, ok) := emitIntExp(rhs, ctx);
        if ok then
          EXT_LLVM.genStoreIntVar("data", absoluteSlot(vs.kind, vs.index, ctx.layout), rhsTmp);
        end if;
      then (outCtx, ok);
    case SOME(vs as VAR_SLOT())
      algorithm
        slot := absoluteSlot(vs.kind, vs.index, ctx.layout);
        (outCtx, rhsTmp, ok) := emitExp(rhs, ctx);
        if ok then
          if referenceEq(vs.kind, VKS_PARAM) then
            emitWriteRealParam(slot, rhsTmp);
          else
            emitWriteRealVar(slot, rhsTmp);
          end if;
        end if;
      then (outCtx, ok);
    else (ctx, false);
  end match;
end emitStmtAssign;

protected function canLowerStmt
  "Pre-validation mirror of emitStmt."
  input DAE.Statement stmt;
  input VarLayout layout;
  output Boolean ok;
algorithm
  ok := match stmt
    local DAE.ComponentRef cref;
          DAE.Exp rhs, cond;
    case DAE.STMT_ASSIGN(exp1 = DAE.CREF(componentRef = cref), exp = rhs)
      then match lookupSlot(cref, layout)
        case SOME(VAR_SLOT(kind = VK_BOOL_DISCRETE())) then canLowerBoolExp(rhs, layout);
        case SOME(VAR_SLOT(kind = VK_INT_DISCRETE())) then canLowerIntExp(rhs, layout);
        case SOME(VAR_SLOT()) then canLowerExp(rhs, layout);
        else false;
      end match;
    /* assert(cond, "<static msg>") -- lowerable when the condition is a
     * supported Boolean expression and the message is a string literal. */
    case DAE.STMT_ASSERT(cond = cond, msg = DAE.SCONST())
      then canLowerBoolExp(cond, layout);
    else false;
  end match;
end canLowerStmt;

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
    case VK_BOOL_DISCRETE() then subIndex;
    case VK_INT_DISCRETE() then subIndex;
    case VK_INT_PARAM() then subIndex;
  end match;
end absoluteSlot;

protected function emitReadRealVar
  "Inline the read of
     data->localData[0]->realVars[data->simulationInfo->realVarsIndex[slot]]
   into the active function body via createInlinedReadRealVar, then
   return the alloca name holding the loaded double. Replaces the
   former omc_jit_get_real_var runtime call so the LLVM optimizer can
   fold redundant loads of the realVars / realVarsIndex base pointers
   across multiple reads in the same function."
  input Integer slot;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
algorithm
  (outCtx, dst) := freshTmp(ctx);
  EXT_LLVM.genAllocaModelicaReal(dst, false);
  EXT_LLVM.genReadRealVar("data", slot, dst);
end emitReadRealVar;

protected function emitReadRealParam
  "Inline  data->simulationInfo->realParameter[slot]  read. Replaces
   the former omc_jit_get_real_param runtime call. Used when a CREF
   resolves to a VK_PARAM slot."
  input Integer slot;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
algorithm
  (outCtx, dst) := freshTmp(ctx);
  EXT_LLVM.genAllocaModelicaReal(dst, false);
  EXT_LLVM.genReadRealParam("data", slot, dst);
end emitReadRealParam;

protected function emitReadIntParamReal
  "Inline  (modelica_real)data->simulationInfo->integerParameter[slot]
   read. Widens the Integer parameter to a double (sitofp) so it
   composes with the Real-domain emitExp accessors. Used when a CREF
   resolves to a VK_INT_PARAM slot inside a Real-context expression."
  input Integer slot;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
algorithm
  (outCtx, dst) := freshTmp(ctx);
  EXT_LLVM.genAllocaModelicaReal(dst, false);
  EXT_LLVM.genReadIntParamReal("data", slot, dst);
end emitReadIntParamReal;

protected function emitWriteRealVar
  "Inline  data->localData[0]->realVars[slot] = src  store. Replaces
   the former omc_jit_set_real_var runtime call."
  input Integer slot;
  input String src;
algorithm
  EXT_LLVM.genWriteRealVar("data", slot, src);
end emitWriteRealVar;

protected function emitWriteRealParam
  "Inline  data->simulationInfo->realParameter[slot] = src  store.
   Replaces the former omc_jit_set_real_param runtime call."
  input Integer slot;
  input String src;
algorithm
  EXT_LLVM.genWriteRealParam("data", slot, src);
end emitWriteRealParam;

protected function emitWriteBoolParam
  "Inline  data->simulationInfo->booleanParameter[slot] = (src != 0)
   store. SCTL's call sites stage Modelica Booleans as 0.0/1.0
   doubles (the DAE.BCONST arm in emitExp); the inlined IR mirrors
   the runtime coercion via fcmp ONE + zext. Replaces the former
   omc_jit_set_bool_param runtime call."
  input Integer slot;
  input String src;
algorithm
  EXT_LLVM.genWriteBoolParam("data", slot, src);
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
    case EQ_INT_PARAM_ASSIGN()  then canLowerIntExp(r.rhs, layout);
    case EQ_ARRAY_CALL2()       then true;
    case EQ_BOOL_DISCRETE_ASSIGN() then canLowerBoolExp(r.rhs, layout);
    case EQ_WHEN()
      then List.all(r.conditions, function isBoolDiscreteCref(layout = layout))
           and List.all(r.whenStmts, function canLowerWhenStmt(layout = layout));
    case EQ_ALGORITHM()
      then List.all(r.statements, function canLowerStmt(layout = layout));
    case EQ_SOLVE_NONLINEAR()   then true;
    case EQ_SOLVE_LINEAR()      then true;
    case EQ_NOOP()              then true;
    case EQ_ALG_CALL()          then true;
    case EQ_PARAM_RANGE_ASSERT() then true;
    case EQ_UNSUPPORTED()       then false;
  end match;
end canLowerEquation;

protected function isBoolDiscreteCref
  "True iff cref resolves to a discrete-Boolean slot (a valid when
   condition / Boolean LHS)."
  input DAE.ComponentRef cref;
  input VarLayout layout;
  output Boolean ok;
algorithm
  ok := match lookupSlot(cref, layout)
    case SOME(VAR_SLOT(kind = VK_BOOL_DISCRETE())) then true;
    else false;
  end match;
end isBoolDiscreteCref;

protected function canLowerWhenStmt
  "True iff a when-body operator lowers: an ASSIGN to a layout-resolved
   cref (Boolean RHS for a discrete Boolean, Real RHS otherwise) or a
   REINIT of a state with a lowerable Real value. ASSERT / TERMINATE /
   NORETCALL are not lowered."
  input BackendDAE.WhenOperator stmt;
  input VarLayout layout;
  output Boolean ok;
algorithm
  ok := match stmt
    local DAE.ComponentRef cref;
          DAE.Exp rhs;
    case BackendDAE.ASSIGN(left = DAE.CREF(componentRef = cref), right = rhs)
      then match lookupSlot(cref, layout)
        case SOME(VAR_SLOT(kind = VK_BOOL_DISCRETE())) then canLowerBoolExp(rhs, layout);
        case SOME(VAR_SLOT(kind = VK_INT_DISCRETE())) then canLowerIntExp(rhs, layout);
        case SOME(VAR_SLOT(kind = VK_STATE())) then canLowerExp(rhs, layout);
        case SOME(VAR_SLOT(kind = VK_DERIVATIVE())) then canLowerExp(rhs, layout);
        case SOME(VAR_SLOT(kind = VK_ALG())) then canLowerExp(rhs, layout);
        else false;
      end match;
    case BackendDAE.REINIT(stateVar = cref, value = rhs)
      then match lookupSlot(cref, layout)
        case SOME(VAR_SLOT(kind = VK_STATE())) then canLowerExp(rhs, layout);
        else false;
      end match;
    else false;
  end match;
end canLowerWhenStmt;

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
    case DAE.CALL(path = Absyn.IDENT(name = "pre"), expLst = {DAE.CREF(componentRef = cref)})
      then canLowerPreReal(cref, layout);
    case DAE.CALL(path = Absyn.IDENT(name = "noEvent"), expLst = {sub})
      then canLowerExp(sub, layout);
    case DAE.CALL(path = Absyn.IDENT(name = "delay"), expLst = {DAE.ICONST(), e1, e2, sub})
      then canLowerExp(e1, layout) and canLowerExp(e2, layout) and canLowerExp(sub, layout);
    case DAE.IFEXP(expCond = e1, expThen = e2, expElse = sub)
      then canLowerBoolExp(e1, layout)
           and canLowerExp(e2, layout) and canLowerExp(sub, layout);
    /* A cast into a Real context (e.g. Real(intParam[2])): emitExp
     * lowers the inner expression, which already materialises a double
     * (an Integer parameter read widens via sitofp). */
    case DAE.CAST(exp = sub) then canLowerExp(sub, layout);
    else false;
  end match;
end canLowerExp;

protected function canLowerPreReal
  "pre() of a real cref is lowerable iff the cref resolves to a real-buffer
   slot (state / derivative / algebraic, incl. discrete-Real)."
  input DAE.ComponentRef cref;
  input VarLayout layout;
  output Boolean ok;
algorithm
  ok := match lookupSlot(cref, layout)
    case SOME(VAR_SLOT(kind = VK_STATE())) then true;
    case SOME(VAR_SLOT(kind = VK_DERIVATIVE())) then true;
    case SOME(VAR_SLOT(kind = VK_ALG())) then true;
    else false;
  end match;
end canLowerPreReal;

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
    /* Discrete Booleans / Integers are not real-readable (see emitCrefRead);
     * an Integer *parameter* is, via sitofp (VK_INT_PARAM in emitCrefRead). */
    case SOME(VAR_SLOT(kind=VK_BOOL_DISCRETE())) then false;
    case SOME(VAR_SLOT(kind=VK_INT_DISCRETE())) then false;
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

protected function canLowerBoolExp
  "Pre-validation mirror of emitBoolExp: true iff every node of the
   discrete-Boolean expression falls into a case emitBoolExp handles."
  input DAE.Exp e;
  input VarLayout layout;
  output Boolean ok;
algorithm
  ok := match e
    local DAE.Exp e1, e2, sub;
          DAE.Operator op;
          DAE.ComponentRef cref;
    case DAE.BCONST() then true;
    case DAE.CREF(componentRef=cref)
      then match lookupSlot(cref, layout)
        case SOME(VAR_SLOT(kind=VK_BOOL_DISCRETE())) then true;
        else false;
      end match;
    case DAE.CALL(path=Absyn.IDENT(name="pre"), expLst={DAE.CREF(componentRef=cref)})
      then match lookupSlot(cref, layout)
        case SOME(VAR_SLOT(kind=VK_BOOL_DISCRETE())) then true;
        else false;
      end match;
    case DAE.CALL(path=Absyn.IDENT(name="noEvent"), expLst={sub})
      then canLowerBoolExp(sub, layout);
    case DAE.RELATION(exp1=e1, operator=op, exp2=e2)
      then isSome(opCodeForRelationOp(op))
           and canLowerExp(e1, layout) and canLowerExp(e2, layout);
    case DAE.LBINARY(exp1=e1, operator=op, exp2=e2)
      then isSome(boolBinopCode(op))
           and canLowerBoolExp(e1, layout) and canLowerBoolExp(e2, layout);
    case DAE.LUNARY(operator=DAE.NOT(), exp=sub)
      then canLowerBoolExp(sub, layout);
    else false;
  end match;
end canLowerBoolExp;

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
      EmitCtx ctx1, ctx2, ctx3;
      String tmp, dst1, dst2, condTmp;
      Boolean ok1, ok2, ok3;
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
    case DAE.CALL(path=Absyn.IDENT(name="delay"),
                  expLst={DAE.ICONST(integer=i), e1, e2, sub})
      algorithm
        (outCtx, dst, ok) := emitDelay(i, e1, e2, sub, ctx);
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
    case DAE.CALL(path=Absyn.IDENT(name="pre"), expLst={DAE.CREF(componentRef=cref)})
      algorithm
        (ctx1, tmp, ok1) := emitPreReal(cref, ctx);
      then (ctx1, tmp, ok1);
    /* noEvent(<real>) is transparent for evaluation. */
    case DAE.CALL(path=Absyn.IDENT(name="noEvent"), expLst={sub})
      algorithm
        (ctx1, tmp, ok1) := emitExp(sub, ctx);
      then (ctx1, tmp, ok1);
    case DAE.CAST(exp=sub)
      algorithm
        (ctx1, tmp, ok1) := emitExp(sub, ctx);
      then (ctx1, tmp, ok1);
    case DAE.IFEXP(expCond=e1, expThen=e2, expElse=sub)
      algorithm
        (ctx1, condTmp, ok1) := emitBoolExp(e1, ctx);
        (ctx2, dst1, ok2) := emitExp(e2, ctx1);
        (ctx3, dst2, ok3) := emitExp(sub, ctx2);
        if ok1 and ok2 and ok3 then
          (outCtx, tmp) := freshTmp(ctx3);
          EXT_LLVM.genAllocaModelicaReal(tmp, false);
          EXT_LLVM.genSelectReal(condTmp, dst1, dst2, tmp);
          dst := tmp;
          ok := true;
        else
          outCtx := ctx3;
          dst := "<ifexp-arm-failed>";
          ok := false;
        end if;
      then (outCtx, dst, ok);
    else
      then (ctx, "<unsupported-exp>", false);
  end match;
end emitExp;

protected function emitDelay
  "Lower  delay(exprNumber, value, delayTime, delayMax)  into a fresh
   double alloca via the runtime delayImpl. The matching
   <Model>_function_storeDelayed (still on clang) feeds the ring buffer
   through the callback table; this emits the read side only."
  input Integer exprNumber;
  input DAE.Exp valExp;
  input DAE.Exp dtExp;
  input DAE.Exp dmaxExp;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
protected
  String valTmp, dtTmp, dmaxTmp;
  Boolean ok1, ok2, ok3;
algorithm
  (outCtx, valTmp, ok1) := emitExp(valExp, ctx);
  (outCtx, dtTmp, ok2) := emitExp(dtExp, outCtx);
  (outCtx, dmaxTmp, ok3) := emitExp(dmaxExp, outCtx);
  ok := ok1 and ok2 and ok3;
  if ok then
    (outCtx, dst) := freshTmp(outCtx);
    EXT_LLVM.genAllocaModelicaReal(dst, false);
    EXT_LLVM.genDelay("data", "threadData", exprNumber, valTmp, dtTmp, dmaxTmp, dst);
  else
    dst := "<delay-arg-failed>";
  end if;
end emitDelay;

protected function emitPreReal
  "Lower  pre(<real cref>)  into a fresh double alloca via
   data->simulationInfo->realVarsPre[slot]. Only state / derivative /
   algebraic (incl. discrete-Real) crefs have a realVarsPre slot; anything
   else is left unsupported."
  input DAE.ComponentRef cref;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
protected
  Option<VarSlot> os;
  VarSlot vs;
  Integer absSlot;
algorithm
  os := lookupSlot(cref, ctx.layout);
  (outCtx, dst, ok) := match os
    case SOME(vs as VAR_SLOT(kind=VK_STATE()))
      then emitPreRealSlot(vs, ctx);
    case SOME(vs as VAR_SLOT(kind=VK_DERIVATIVE()))
      then emitPreRealSlot(vs, ctx);
    case SOME(vs as VAR_SLOT(kind=VK_ALG()))
      then emitPreRealSlot(vs, ctx);
    else (ctx, "<pre-of-non-real-var>", false);
  end match;
end emitPreReal;

protected function emitPreRealSlot
  input VarSlot vs;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok = true;
algorithm
  (outCtx, dst) := freshTmp(ctx);
  EXT_LLVM.genAllocaModelicaReal(dst, false);
  EXT_LLVM.genReadRealVarPre("data", absoluteSlot(vs.kind, vs.index, ctx.layout), dst);
end emitPreRealSlot;

protected function emitBoolExp
  "Lower a discrete-Boolean-valued DAE.Exp into a modelica_boolean (i32)
   alloca, returning its symtab name + Boolean ok. Mirrors emitExp but
   for the Boolean domain; each node produces an i32 value the bool
   primitives in llvm_gen.cpp combine by name:
     RELATION(e1,relop,e2) w/ zc index -> omc_jit_relationhysteresis
     CREF (VK_BOOL_DISCRETE)           -> booleanVars[slot] load
     LBINARY(and/or)                   -> genBoolBinop
     LUNARY(not)                       -> genBoolNot
     BCONST                            -> genBoolConst
   The relation operands themselves are Real, so they go through emitExp."
  input DAE.Exp e;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
algorithm
  (outCtx, dst, ok) := match e
    local
      Boolean bval;
      DAE.ComponentRef cref;
      DAE.Exp sub;
      EmitCtx ctx1, ctx2;
      String tmp, a;
      Boolean ok1;
    case DAE.BCONST(bool=bval)
      algorithm
        (ctx1, tmp) := freshTmp(ctx);
        EXT_LLVM.genBoolConst(if bval then 1 else 0, tmp);
      then (ctx1, tmp, true);
    case DAE.CREF(componentRef=cref)
      algorithm
        (ctx1, tmp, ok1) := emitBoolCrefRead(cref, ctx);
      then (ctx1, tmp, ok1);
    case DAE.CALL(path=Absyn.IDENT(name="pre"), expLst={DAE.CREF(componentRef=cref)})
      algorithm
        (ctx1, tmp, ok1) := emitBoolPreRead(cref, ctx);
      then (ctx1, tmp, ok1);
    /* noEvent(<bool>) is transparent for evaluation -- it only tells the
     * backend not to register a zero crossing, which is already reflected
     * in the inner relation carrying no zc index (a plain fcmp). */
    case DAE.CALL(path=Absyn.IDENT(name="noEvent"), expLst={sub})
      algorithm
        (ctx1, tmp, ok1) := emitBoolExp(sub, ctx);
      then (ctx1, tmp, ok1);
    case DAE.RELATION()
      algorithm
        (ctx1, tmp, ok1) := emitBoolRelation(e, ctx);
      then (ctx1, tmp, ok1);
    case DAE.LBINARY()
      algorithm
        (ctx1, tmp, ok1) := emitBoolBinary(e, ctx);
      then (ctx1, tmp, ok1);
    case DAE.LUNARY(operator=DAE.NOT(), exp=sub)
      algorithm
        (ctx1, a, ok1) := emitBoolExp(sub, ctx);
        if ok1 then
          (ctx2, tmp) := freshTmp(ctx1);
          EXT_LLVM.genBoolNot(a, tmp);
        else
          ctx2 := ctx1;
          tmp := "<lunary-operand-failed>";
        end if;
      then (ctx2, tmp, ok1);
    else (ctx, "<unsupported-bool-exp>", false);
  end match;
end emitBoolExp;

protected function emitBoolCrefRead
  "Lower a discrete-Boolean cref read: booleanVars[slot] into a fresh i32
   alloca. Non-VK_BOOL_DISCRETE crefs are not Boolean-readable here."
  input DAE.ComponentRef cref;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
protected
  Option<VarSlot> os;
  VarSlot vs;
  Integer absSlot;
algorithm
  os := lookupSlot(cref, ctx.layout);
  (outCtx, dst, ok) := match os
    case SOME(vs as VAR_SLOT(kind=VK_BOOL_DISCRETE()))
      algorithm
        (outCtx, dst) := freshTmp(ctx);
        absSlot := absoluteSlot(vs.kind, vs.index, ctx.layout);
        EXT_LLVM.genReadBoolVar("data", absSlot, dst);
      then (outCtx, dst, true);
    else (ctx, "<non-discrete-bool-cref>", false);
  end match;
end emitBoolCrefRead;

protected function emitBoolPreRead
  "Lower  pre(<discrete-Boolean cref>)  into a fresh i32 alloca via
   data->simulationInfo->booleanVarsPre[slot]."
  input DAE.ComponentRef cref;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
protected
  Option<VarSlot> os;
  VarSlot vs;
algorithm
  os := lookupSlot(cref, ctx.layout);
  (outCtx, dst, ok) := match os
    case SOME(vs as VAR_SLOT(kind=VK_BOOL_DISCRETE()))
      algorithm
        (outCtx, dst) := freshTmp(ctx);
        EXT_LLVM.genReadBoolVarPre("data", absoluteSlot(vs.kind, vs.index, ctx.layout), dst);
      then (outCtx, dst, true);
    else (ctx, "<pre-of-non-discrete-bool>", false);
  end match;
end emitBoolPreRead;

protected function emitBoolRelation
  "Lower a relation (exp1 <relop> exp2) into an i32 alloca. A relation that
   carries a zero-crossing index (index >= 0) goes through
   omc_jit_relationhysteresis; one without (index = -1, e.g. a relation
   inside a when body that the backend did not register as a crossing,
   `flying = v_new > 0`) lowers to a plain fp compare. Operands are Real,
   so they go through emitExp."
  input DAE.Exp e;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
protected
  DAE.Exp e1, e2;
  DAE.Operator op;
  Integer idx, opc;
  Option<Integer> oc;
  EmitCtx ctx1, ctx2;
  String a, bnm;
  Boolean ok1, ok2;
algorithm
  DAE.RELATION(exp1=e1, operator=op, exp2=e2, index=idx) := e;
  oc := opCodeForRelationOp(op);
  if not isSome(oc) then
    outCtx := ctx;
    dst := "<unsupported-relation>";
    ok := false;
    return;
  end if;
  SOME(opc) := oc;
  (ctx1, a, ok1) := emitExp(e1, ctx);
  (ctx2, bnm, ok2) := emitExp(e2, ctx1);
  ok := ok1 and ok2;
  if ok then
    (outCtx, dst) := freshTmp(ctx2);
    if idx >= 0 then
      EXT_LLVM.genRelationHysteresisBool("data", dst, a, bnm,
        relationOperandNominal(e1), relationOperandNominal(e2), idx, opc);
    else
      EXT_LLVM.genBoolFcmp(a, bnm, dst, opc);
    end if;
  else
    outCtx := ctx2;
    dst := "<rel-operand-failed>";
  end if;
end emitBoolRelation;

protected function emitBoolBinary
  "Lower a logical AND/OR (exp1 <op> exp2) over two Boolean subexpressions
   into an i32 alloca via genBoolBinop."
  input DAE.Exp e;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
protected
  DAE.Exp e1, e2;
  DAE.Operator op;
  Integer opc;
  Option<Integer> oc;
  EmitCtx ctx1, ctx2;
  String a, bnm;
  Boolean ok1, ok2;
algorithm
  DAE.LBINARY(exp1=e1, operator=op, exp2=e2) := e;
  oc := boolBinopCode(op);
  if not isSome(oc) then
    outCtx := ctx;
    dst := "<unsupported-lbinary>";
    ok := false;
    return;
  end if;
  SOME(opc) := oc;
  (ctx1, a, ok1) := emitBoolExp(e1, ctx);
  (ctx2, bnm, ok2) := emitBoolExp(e2, ctx1);
  ok := ok1 and ok2;
  if ok then
    (outCtx, dst) := freshTmp(ctx2);
    EXT_LLVM.genBoolBinop(a, bnm, dst, opc);
  else
    outCtx := ctx2;
    dst := "<lbinary-operand-failed>";
  end if;
end emitBoolBinary;

protected function emitIntExp
  "Lower an Integer-valued DAE.Exp into a modelica_integer alloca. The
   integer-domain mirror of emitExp / emitBoolExp, covering the small
   arithmetic a discrete Integer when-assign needs (`n_bounce =
   1 + pre(n_bounce)`): ICONST, discrete-Integer cref reads, pre() of an
   Integer, and + / - / * over them."
  input DAE.Exp e;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
algorithm
  (outCtx, dst, ok) := match e
    local Integer i;
          DAE.ComponentRef cref;
          EmitCtx ctx1;
          String tmp;
          Boolean ok1;
    case DAE.ICONST(integer=i)
      algorithm
        (ctx1, tmp) := freshTmp(ctx);
        EXT_LLVM.genIntConst(i, tmp);
      then (ctx1, tmp, true);
    case DAE.CREF(componentRef=cref)
      algorithm
        (ctx1, tmp, ok1) := emitIntCrefRead(cref, ctx);
      then (ctx1, tmp, ok1);
    case DAE.CALL(path=Absyn.IDENT(name="pre"), expLst={DAE.CREF(componentRef=cref)})
      algorithm
        (ctx1, tmp, ok1) := emitIntPreRead(cref, ctx);
      then (ctx1, tmp, ok1);
    case DAE.BINARY()
      algorithm
        (ctx1, tmp, ok1) := emitIntBinary(e, ctx);
      then (ctx1, tmp, ok1);
    else (ctx, "<unsupported-int-exp>", false);
  end match;
end emitIntExp;

protected function emitIntCrefRead
  "Read an Integer cref into a fresh modelica_integer alloca. A discrete
   Integer comes from integerVars[slot]; an Integer parameter from
   simulationInfo->integerParameter[slot]."
  input DAE.ComponentRef cref;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
protected
  VarSlot vs;
algorithm
  (outCtx, dst, ok) := match lookupSlot(cref, ctx.layout)
    case SOME(vs as VAR_SLOT(kind=VK_INT_DISCRETE()))
      algorithm
        (outCtx, dst) := freshTmp(ctx);
        EXT_LLVM.genReadIntVar("data", absoluteSlot(vs.kind, vs.index, ctx.layout), dst);
      then (outCtx, dst, true);
    case SOME(vs as VAR_SLOT(kind=VK_INT_PARAM()))
      algorithm
        (outCtx, dst) := freshTmp(ctx);
        EXT_LLVM.genReadIntParam("data", absoluteSlot(vs.kind, vs.index, ctx.layout), dst);
      then (outCtx, dst, true);
    else (ctx, "<non-discrete-int-cref>", false);
  end match;
end emitIntCrefRead;

protected function emitIntPreRead
  "Lower  pre(<discrete-Integer cref>)  via integerVarsPre[slot]."
  input DAE.ComponentRef cref;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
protected
  VarSlot vs;
algorithm
  (outCtx, dst, ok) := match lookupSlot(cref, ctx.layout)
    case SOME(vs as VAR_SLOT(kind=VK_INT_DISCRETE()))
      algorithm
        (outCtx, dst) := freshTmp(ctx);
        EXT_LLVM.genReadIntVarPre("data", absoluteSlot(vs.kind, vs.index, ctx.layout), dst);
      then (outCtx, dst, true);
    else (ctx, "<pre-of-non-discrete-int>", false);
  end match;
end emitIntPreRead;

protected function emitIntBinary
  "Lower an Integer + / - / * over two Integer subexpressions."
  input DAE.Exp e;
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
  output Boolean ok;
protected
  DAE.Exp e1, e2;
  DAE.Operator op;
  Integer opc;
  Option<Integer> oc;
  EmitCtx ctx1, ctx2;
  String a, bnm;
  Boolean ok1, ok2;
algorithm
  DAE.BINARY(exp1=e1, operator=op, exp2=e2) := e;
  oc := intBinopCode(op);
  if not isSome(oc) then
    outCtx := ctx;
    dst := "<unsupported-int-binop>";
    ok := false;
    return;
  end if;
  SOME(opc) := oc;
  (ctx1, a, ok1) := emitIntExp(e1, ctx);
  (ctx2, bnm, ok2) := emitIntExp(e2, ctx1);
  ok := ok1 and ok2;
  if ok then
    (outCtx, dst) := freshTmp(ctx2);
    EXT_LLVM.genIntBinop(a, bnm, dst, opc);
  else
    outCtx := ctx2;
    dst := "<int-operand-failed>";
  end if;
end emitIntBinary;

protected function intBinopCode
  "Map an integer DAE.Operator to genIntBinop's opCode: 0=+ 1=- 2=*.
   NONE() for any other operator (DIV / POW are not lowered here)."
  input DAE.Operator op;
  output Option<Integer> code;
algorithm
  code := match op
    case DAE.ADD() then SOME(0);
    case DAE.SUB() then SOME(1);
    case DAE.MUL() then SOME(2);
    else NONE();
  end match;
end intBinopCode;

protected function canLowerIntExp
  "Pre-validation mirror of emitIntExp."
  input DAE.Exp e;
  input VarLayout layout;
  output Boolean ok;
algorithm
  ok := match e
    local DAE.Exp e1, e2;
          DAE.Operator op;
          DAE.ComponentRef cref;
    case DAE.ICONST() then true;
    case DAE.CREF(componentRef=cref) then isIntReadableCref(cref, layout);
    case DAE.CALL(path=Absyn.IDENT(name="pre"), expLst={DAE.CREF(componentRef=cref)})
      then isIntDiscreteCref(cref, layout);
    case DAE.BINARY(exp1=e1, operator=op, exp2=e2)
      then isSome(intBinopCode(op))
           and canLowerIntExp(e1, layout) and canLowerIntExp(e2, layout);
    else false;
  end match;
end canLowerIntExp;

protected function isIntDiscreteCref
  input DAE.ComponentRef cref;
  input VarLayout layout;
  output Boolean ok;
algorithm
  ok := match lookupSlot(cref, layout)
    case SOME(VAR_SLOT(kind=VK_INT_DISCRETE())) then true;
    else false;
  end match;
end isIntDiscreteCref;

protected function isIntReadableCref
  "An Integer cref readable in emitIntCrefRead: a discrete Integer
   (integerVars) or an Integer parameter (integerParameter)."
  input DAE.ComponentRef cref;
  input VarLayout layout;
  output Boolean ok;
algorithm
  ok := match lookupSlot(cref, layout)
    case SOME(VAR_SLOT(kind=VK_INT_DISCRETE())) then true;
    case SOME(VAR_SLOT(kind=VK_INT_PARAM())) then true;
    else false;
  end match;
end isIntReadableCref;

protected function boolBinopCode
  "Map a logical DAE.Operator to genBoolBinop's isOr flag: 0 for AND,
   1 for OR. NONE() for any other operator."
  input DAE.Operator op;
  output Option<Integer> code;
algorithm
  code := match op
    case DAE.AND() then SOME(0);
    case DAE.OR()  then SOME(1);
    else NONE();
  end match;
end boolBinopCode;

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
    /* Discrete Booleans / Integers live in their own buffers, not
     * realVars; a real read of one would load the wrong buffer.
     * emitBoolExp / emitIntExp handle them in their own context, so
     * reject here rather than emit a wrong load. */
    case SOME(VAR_SLOT(kind=VK_BOOL_DISCRETE()))
      then (ctx, "<bool-discrete-in-real-ctx>", false);
    case SOME(VAR_SLOT(kind=VK_INT_DISCRETE()))
      then (ctx, "<int-discrete-in-real-ctx>", false);
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
          case VK_INT_PARAM() then emitReadIntParamReal(absSlot, ctx);
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
  "Inline  data->localData[0]->timeValue  load. Replaces the former
   omc_jit_get_time runtime call."
  input EmitCtx ctx;
  output EmitCtx outCtx;
  output String dst;
algorithm
  (outCtx, dst) := freshTmp(ctx);
  EXT_LLVM.genAllocaModelicaReal(dst, false);
  EXT_LLVM.genReadTime("data", dst);
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

protected function dumpUnsupportedBucket
  "Diagnostic helper -- gated on -d=failtrace -- that classifies every
   SimEqSystem in `eqs` and prints the unsupported reasons. Used by
   genSim to surface what is still blocking the JIT path beyond the
   ODE partition (allEquations / initialEquations / algebraicEquations).
   Reasons are de-duplicated by string so a 50-equation set with one
   blocking construct prints once, not 50 times."
  input String bucketName;
  input list<SimCode.SimEqSystem> eqs;
  input VarLayout layout;
  input Absyn.Path modelName;
protected
  list<EqRecipe> rcps;
  list<String> seen = {};
  String reason;
  Integer total;
algorithm
  if listEmpty(eqs) then return; end if;
  rcps := List.map1(eqs, classifySimEq, layout);
  total := List.fold(rcps, countUnsupported, 0);
  if total == 0 then return; end if;
  print("SCTL genSim: unsupported " + bucketName + " for '" +
        AbsynUtil.pathString(modelName) + "' (" + intString(total) +
        " of " + intString(listLength(rcps)) + " total):\n");
  for r in rcps loop
    () := match r
      case EQ_UNSUPPORTED(reason = reason)
        algorithm
          if not List.contains(seen, reason, stringEqual) then
            seen := reason :: seen;
            print("  - " + reason + "\n");
          end if;
        then ();
      else ();
    end match;
  end for;
end dumpUnsupportedBucket;

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

protected function allSimCodeEquations
  "The model's full allEquations list -- the discrete-context equation
   set CodegenC's functionDAE iterates (continuous derivatives plus the
   discrete/algebraic equations the ODE partition omits)."
  input SimCode.SimCode simCode;
  output list<SimCode.SimEqSystem> eqs;
algorithm
  eqs := match simCode
    case SimCode.SIMCODE(allEquations=eqs) then eqs;
  end match;
end allSimCodeEquations;

protected function algebraicSimCodeEquations
  "The flattened algebraicEquations partitions -- the continuous-time
   algebraic equations CodegenC's functionAlgebraics recomputes every
   integrator step (e.g. y = delay(x))."
  input SimCode.SimCode simCode;
  output list<SimCode.SimEqSystem> eqs;
algorithm
  eqs := match simCode
    local list<list<SimCode.SimEqSystem>> parts;
    case SimCode.SIMCODE(algebraicEquations=parts) then List.flatten(parts);
  end match;
end algebraicSimCodeEquations;

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
  list<SimCodeVar.SimVar> stateVars, derivativeVars, algVars, discreteAlgVars, intAlgVars, paramVars, intParamVars, boolParamVars, boolAlgVars;
  list<tuple<DAE.ComponentRef, VarSlot>> entries = {};
algorithm
  (stateVars, derivativeVars, algVars, discreteAlgVars, intAlgVars, paramVars, intParamVars, boolParamVars, boolAlgVars) := match vars
    case SimCodeVar.SIMVARS(stateVars=stateVars,
                            derivativeVars=derivativeVars,
                            algVars=algVars,
                            discreteAlgVars=discreteAlgVars,
                            intAlgVars=intAlgVars,
                            paramVars=paramVars,
                            intParamVars=intParamVars,
                            boolParamVars=boolParamVars,
                            boolAlgVars=boolAlgVars)
      then (stateVars, derivativeVars, algVars, discreteAlgVars, intAlgVars, paramVars, intParamVars, boolParamVars, boolAlgVars);
  end match;

  entries := List.fold(stateVars, function addEntry(kind = VKS_STATE), entries);
  entries := List.fold(derivativeVars, function addEntry(kind = VKS_DERIVATIVE), entries);
  entries := List.fold(algVars, function addEntry(kind = VKS_ALG), entries);
  /* Discrete Reals (when-assigned, e.g. v_new) live in the same flat
   * realVars buffer right after the continuous algebraics, so they read
   * and write through the VK_ALG accessors. */
  entries := List.fold(discreteAlgVars, function addEntry(kind = VKS_ALG), entries);
  entries := List.fold(intAlgVars, function addEntry(kind = VKS_INT_DISCRETE), entries);
  entries := List.fold(paramVars, function addEntry(kind = VKS_PARAM), entries);
  entries := List.fold(intParamVars, function addEntry(kind = VKS_INT_PARAM), entries);
  entries := List.fold(boolParamVars, function addEntry(kind = VKS_BOOL_PARAM), entries);
  entries := List.fold(boolAlgVars, function addEntry(kind = VKS_BOOL_DISCRETE), entries);

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
      case VK_BOOL_DISCRETE() then "BDISC";
      case VK_INT_DISCRETE() then "IDISC";
      case VK_INT_PARAM()    then "IPARM";
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
          DAE.Exp rhs, lhsExp;
          Option<VarSlot> os;
          VarSlot s;
          list<DAE.ComponentRef> cwhen;
          list<BackendDAE.WhenOperator> wstmts;
          list<DAE.Statement> stmts;
          SimCode.NonlinearSystem nlsys;
          SimCode.LinearSystem lsys;
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
        case SOME(s as VAR_SLOT(kind=VK_INT_PARAM()))
          then EQ_INT_PARAM_ASSIGN(s.index, rhs);
        case SOME(s as VAR_SLOT(kind=VK_BOOL_DISCRETE()))
          then classifyBoolDiscrete(s.index, rhs);
        else
          then EQ_UNSUPPORTED("cref not found in layout: "
                              + ComponentReferenceBasics.printComponentRefStr(cref));
      end match;
    case SimCode.SES_RESIDUAL()
      then EQ_UNSUPPORTED("SES_RESIDUAL requires solver, deferred");
    case SimCode.SES_LINEAR(lSystem = lsys)
      then classifyLinear(lsys, layout);
    case SimCode.SES_NONLINEAR(nlSystem = nlsys)
      then classifyNonlinear(nlsys, layout);
    case SimCode.SES_MIXED()
      then EQ_UNSUPPORTED("SES_MIXED requires solver, deferred");
    case SimCode.SES_WHEN(elseWhen = SOME(_))
      then EQ_UNSUPPORTED("SES_WHEN with else-when not lowered yet");
    case SimCode.SES_WHEN(conditions = cwhen, whenStmtLst = wstmts)
      then EQ_WHEN(cwhen, wstmts);
    case SimCode.SES_IFEQUATION()
      then EQ_UNSUPPORTED("SES_IFEQUATION requires event handling, deferred");
    case SimCode.SES_ALGORITHM(statements = stmts)
      then EQ_ALGORITHM(stmts);
    case SimCode.SES_ARRAY_CALL_ASSIGN(lhs = lhsExp, exp = rhs)
      then classifyArrayCallAssign(eq.index, lhsExp, rhs, layout);
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

protected function classifyArrayCallAssign
  "Classify a SES_ARRAY_CALL_ASSIGN of the shape
     <realVars array> = fn(<const vec>, <const vec>)
   where fn returns a real_array (the MultiBody from_nxy pattern). The two
   call arguments must be constant real vectors and the destination array's
   first element must resolve in the layout (a contiguous realVars block).
   Anything else stays UNSUPPORTED so functionDAE keeps falling back."
  input Integer eqIndex;
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input VarLayout layout;
  output EqRecipe recipe;
algorithm
  recipe := match (lhs, rhs)
    local
      DAE.ComponentRef arrCref;
      Absyn.Path fnPath;
      DAE.Exp arg1, arg2;
      Integer d0, d1, destSlot;
      list<Real> aData, bData;
    case (DAE.CREF(componentRef = arrCref,
                   ty = DAE.T_ARRAY(dims = {DAE.DIM_INTEGER(integer = d0),
                                            DAE.DIM_INTEGER(integer = d1)})),
          DAE.CALL(path = fnPath, expLst = {arg1, arg2}))
      then match (extractConstRealVec(arg1), extractConstRealVec(arg2),
                  arrayDestSlot(arrCref, layout))
        case (SOME(aData), SOME(bData), SOME(destSlot))
          then EQ_ARRAY_CALL2(mangleFunctionName(fnPath), aData, bData,
                              destSlot, 2, d0, d1, eqIndex);
        else EQ_UNSUPPORTED("SES_ARRAY_CALL_ASSIGN: non-constant args or destination not in layout");
      end match;
    else EQ_UNSUPPORTED("SES_ARRAY_CALL_ASSIGN: unsupported shape (need fn(constVec, constVec) -> 2-D realVars array)");
  end match;
end classifyArrayCallAssign;

protected function extractConstRealVec
  "Unwrap a SHARED_LITERAL / ARRAY of Real (or Integer) constants into a
   list<Real>; NONE() if any element is non-constant."
  input DAE.Exp e;
  output Option<list<Real>> vals;
algorithm
  vals := match e
    local DAE.Exp innerExp; list<DAE.Exp> arr;
    case DAE.SHARED_LITERAL(exp = innerExp) then extractConstRealVec(innerExp);
    case DAE.ARRAY(array = arr) then extractRconstList(arr, {});
    else NONE();
  end match;
end extractConstRealVec;

protected function extractRconstList
  input list<DAE.Exp> exps;
  input list<Real> acc;
  output Option<list<Real>> vals;
algorithm
  vals := match exps
    local DAE.Exp e; list<DAE.Exp> rest; Real r; Integer i;
    case {} then SOME(listReverse(acc));
    case DAE.RCONST(real = r) :: rest then extractRconstList(rest, r :: acc);
    case DAE.ICONST(integer = i) :: rest then extractRconstList(rest, intReal(i) :: acc);
    else NONE();
  end match;
end extractRconstList;

protected function arrayDestSlot
  "The flat realVars start slot of <arrCref>[1,1] -- the first element of the
   destination array, which the runtime real_array descriptor wraps as a
   contiguous block. NONE() if it is not in the layout."
  input DAE.ComponentRef arrCref;
  input VarLayout layout;
  output Option<Integer> slot;
protected
  DAE.ComponentRef elemCref;
algorithm
  elemCref := ComponentReference.crefSetLastSubs(arrCref,
                {DAE.INDEX(DAE.ICONST(1)), DAE.INDEX(DAE.ICONST(1))});
  slot := match lookupSlot(elemCref, layout)
    local VarSlot vs;
    case SOME(vs) then SOME(absoluteSlot(vs.kind, vs.index, layout));
    else NONE();
  end match;
end arrayDestSlot;

protected function mangleFunctionName
  "Mangle a function path to its C symbol the way MidToLLVM.genFunction does:
   omc_ + underscorePath (identifier underscores doubled)."
  input Absyn.Path path;
  output String name;
algorithm
  name := "omc_" + textString(underscorePath(Tpl.MEM_TEXT({}, {}), path));
end mangleFunctionName;

protected function classifyBoolDiscrete
  "Classify a discrete-Boolean assignment whose LHS resolved to a
   VK_BOOL_DISCRETE slot as EQ_BOOL_DISCRETE_ASSIGN. Whether the RHS is
   actually lowerable (zero-crossing relations, discrete-Boolean cref
   reads, and / or / not, Boolean literals) is decided by canLowerBoolExp
   in canLowerEquation -- the same classify/validate split the
   EQ_*_ASSIGN recipes use -- so an unhandled RHS leaves the still-clang'd
   segment file with its definition rather than a wrong stub."
  input Integer slotIndex;
  input DAE.Exp rhs;
  output EqRecipe recipe = EQ_BOOL_DISCRETE_ASSIGN(slotIndex, rhs);
end classifyBoolDiscrete;

protected function classifyNonlinear
  "Classify a SES_NONLINEAR with any iteration-variable count >= 1 whose
   crefs all resolve to real (state / derivative / alg) layout slots, to
   EQ_SOLVE_NONLINEAR -> the omc_jit_solve_nonlinear_system_n adapter.
   Crefs that do not resolve (or resolve to a non-real kind) keep the
   system UNSUPPORTED so the model fails loudly rather than mis-solving.
   Gates on the `crefs` list (iteration variables), not `nUnknowns`
   which also counts torn-away vars the residual back-substitutes."
  input SimCode.NonlinearSystem nlsys;
  input VarLayout layout;
  output EqRecipe recipe;
protected
  Integer nidx;
  list<DAE.ComponentRef> crs;
algorithm
  (nidx, crs) := match nlsys
    case SimCode.NONLINEARSYSTEM(indexNonLinearSystem = nidx, crefs = crs)
      then (nidx, crs);
  end match;
  if listEmpty(crs) then
    recipe := EQ_UNSUPPORTED("nonlinear system with empty iteration-variable list");
    return;
  end if;
  recipe := buildSolveRecipe(nidx, crs, layout, true);
end classifyNonlinear;

protected function classifyLinear
  "Classify a SES_LINEAR with any iteration-variable count >= 1 whose
   `vars` all resolve to real (state / derivative / alg) layout slots,
   to EQ_SOLVE_LINEAR -> the omc_jit_solve_linear_system_n adapter.
   Mirrors classifyNonlinear; LINEARSYSTEM.vars carries SimVars (not
   ComponentRefs), so the cref list is the projection of `vars` onto
   their SIMVAR.name field."
  input SimCode.LinearSystem lsys;
  input VarLayout layout;
  output EqRecipe recipe;
protected
  Integer lidx;
  list<SimCodeVar.SimVar> simVars;
  list<DAE.ComponentRef> crs;
algorithm
  (lidx, simVars) := match lsys
    case SimCode.LINEARSYSTEM(indexLinearSystem = lidx, vars = simVars)
      then (lidx, simVars);
  end match;
  if listEmpty(simVars) then
    recipe := EQ_UNSUPPORTED("linear system with empty iteration-variable list");
    return;
  end if;
  crs := List.map(simVars, simVarName);
  recipe := buildSolveRecipe(lidx, crs, layout, false);
end classifyLinear;

protected function simVarName
  "Project a SimCodeVar.SimVar onto its DAE.ComponentRef `name` field."
  input SimCodeVar.SimVar sv;
  output DAE.ComponentRef cr;
algorithm
  cr := match sv case SimCodeVar.SIMVAR(name = cr) then cr; end match;
end simVarName;

protected function buildSolveRecipe
  "Resolve every cref in `crs` to a flat realVars slot via the layout and
   build the matching EQ_SOLVE_NONLINEAR / EQ_SOLVE_LINEAR. Any cref that
   does not resolve to a real layout slot stays the whole system UNSUPPORTED.
   `isNonlinear` picks which recipe variant to emit."
  input Integer sysIndex;
  input list<DAE.ComponentRef> crs;
  input VarLayout layout;
  input Boolean isNonlinear;
  output EqRecipe recipe;
protected
  list<Integer> slots = {};
  Option<VarSlot> os;
  VarSlot vs;
  Integer absSlot;
algorithm
  for cr in crs loop
    os := lookupSlot(cr, layout);
    () := match os
      case SOME(vs as VAR_SLOT(kind = VK_STATE()))
        algorithm
          absSlot := absoluteSlot(vs.kind, vs.index, layout);
          slots := absSlot :: slots;
        then ();
      case SOME(vs as VAR_SLOT(kind = VK_DERIVATIVE()))
        algorithm
          absSlot := absoluteSlot(vs.kind, vs.index, layout);
          slots := absSlot :: slots;
        then ();
      case SOME(vs as VAR_SLOT(kind = VK_ALG()))
        algorithm
          absSlot := absoluteSlot(vs.kind, vs.index, layout);
          slots := absSlot :: slots;
        then ();
      else
        algorithm
          recipe := EQ_UNSUPPORTED(
            (if isNonlinear then "nonlinear" else "linear") +
            " iteration variable does not resolve to a real layout slot: " +
            ComponentReferenceBasics.printComponentRefStr(cr));
        then fail();
    end match;
  end for;
  slots := listReverse(slots);
  recipe := if isNonlinear
    then EQ_SOLVE_NONLINEAR(sysIndex, slots)
    else EQ_SOLVE_LINEAR(sysIndex, slots);
end buildSolveRecipe;

protected function opCodeForRelationOp
  "Map a relational DAE.Operator to the small opcode
   omc_jit_relationhysteresis switches on (0=Less, 1=LessEq, 2=Greater,
   3=GreaterEq). NONE() for non-relational operators (==, <>) which the
   runtime handles through a different helper SCTL does not lower yet."
  input DAE.Operator op;
  output Option<Integer> code;
algorithm
  code := match op
    case DAE.LESS()      then SOME(0);
    case DAE.LESSEQ()    then SOME(1);
    case DAE.GREATER()   then SOME(2);
    case DAE.GREATEREQ() then SOME(3);
    else NONE();
  end match;
end opCodeForRelationOp;

protected function relationOperandNominal
  "Nominal scale factor for a relation operand, mirroring the subset of
   SimCodeUtil.getExpNominal that occurs in zero-crossing relations:
   constants contribute their magnitude, a unary minus is transparent,
   and everything else (notably state/variable crefs without an explicit
   nominal attribute) takes the default 1.0 -- which is exactly what
   getExpNominal yields for default-nominal Reals, so the emitted call is
   byte-identical to CodegenC for such models. Operands carrying an
   explicit nominal attribute fall back to 1.0 (the hysteresis band
   differs sub-epsilon; it does not change which side of the threshold
   the relation reports)."
  input DAE.Exp e;
  output Real nominal;
algorithm
  nominal := match e
    case DAE.RCONST() then abs(e.real);
    case DAE.ICONST() then abs(intReal(e.integer));
    case DAE.UNARY(operator=DAE.UMINUS()) then relationOperandNominal(e.exp);
    case DAE.UNARY(operator=DAE.UMINUS_ARR()) then relationOperandNominal(e.exp);
    else 1.0;
  end match;
end relationOperandNominal;

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
