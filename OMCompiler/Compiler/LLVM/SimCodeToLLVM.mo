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
import SimCode;

protected
import Absyn;
import AbsynUtil;
import ComponentReferenceBasics;
import DAE;
import Error;
import Flags;
import List;
import SimCodeVar;
import SimCodeFunction;

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

  record EQ_UNSUPPORTED
    "Reason the equation cannot be lowered in the current scope."
    String reason;
  end EQ_UNSUPPORTED;
end EqRecipe;

/* ====================================================================== *
 *  Entry point                                                           *
 * ====================================================================== */

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
  if Flags.isSet(Flags.JIT_SIMULATE) and nUnsupported == 0 then
    /* Pass 1: in-memory functionODE for the Phase 5/6 smoke test. The
     * module is consumed (moved) by jitFinalizeNoEntry into the
     * function-JIT, so it cannot be serialised after this. */
    EXT_LLVM.initGen(AbsynUtil.pathStringUnquoteReplaceDot(name, "_") + "_ode");
    if emitODEEntryShell(name, recipes, layout) then
      if Flags.isSet(Flags.JIT_DUMP_IR) then EXT_LLVM.dumpIR(); end if;
      finalizeAndReport(name, layout, vars);
    end if;
    /* Pass 2: a fresh module containing only the entry points that
     * displace .c files from compileModelToBitcode. _functionODE is
     * deliberately not re-emitted here -- the C path still owns it
     * until SCTL can prove out the full ODE call site. Every stub
     * emitted here lets the matching .c file be dropped from the
     * clang loop in CevalScriptBackend.compileModelToBitcode. */
    EXT_LLVM.initGen(AbsynUtil.pathStringUnquoteReplaceDot(name, "_") + "_sctl");
    emitDisplacingStubs(name);
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
      sctlBcPath := AbsynUtil.pathStringUnquoteReplaceDot(name, "_") + "_sctl.bc";
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
  odeSym := AbsynUtil.pathStringUnquoteReplaceDot(name, "_") + "_functionODE";
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
protected
  String fname;
  EmitCtx ctx;
algorithm
  fname := odeEntryName(modelName);
  EXT_LLVM.startFuncGen(fname);
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "data");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "threadData");
  EXT_LLVM.genFunctionType(MODELICA_INTEGER);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);

  ctx := EMIT_CTX(layout, 0);
  ok := true;
  for r in recipes loop
    if ok then
      (ctx, ok) := emitEquation(r, ctx);
    end if;
  end for;

  EXT_LLVM.genReturnZero();
  EXT_LLVM.finnishGen();
end emitODEEntryShell;

protected function emitTrivialDataReturnZero
  "Emit  int <fname>(DATA *, threadData_t *) { return 0; }
   into the current in-memory module. Used for the many segment
   entry points whose only body in CodegenC is 'return 0' (plus
   bookkeeping like stat counters that the runtime tolerates being
   missing). Once SimCodeToLLVM emits the stub the matching .c file
   can be dropped from compileModelToBitcode's clang loop."
  input String fname;
algorithm
  EXT_LLVM.startFuncGen(fname);
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "data");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "threadData");
  EXT_LLVM.genFunctionType(MODELICA_INTEGER);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);
  EXT_LLVM.genReturnZero();
  EXT_LLVM.finnishGen();
end emitTrivialDataReturnZero;

protected function emitTrivialIntPtrPtrVoid
  "Emit  void <fname>(int, ptr, ptr) { }  into the current in-memory
   module. The (int, ptr, ptr) signature is widened to (i64, ptr, ptr)
   in IR (no MODELICA_INT32); on x86-64 the unused i64-vs-i32 arg slot
   uses the same register so the ABI mismatch is harmless when the
   body discards the argument."
  input String fname;
algorithm
  EXT_LLVM.startFuncGen(fname);
  EXT_LLVM.genFunctionArg(MODELICA_INTEGER, "n");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "a");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "b");
  EXT_LLVM.genFunctionType(MODELICA_VOID);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);
  EXT_LLVM.genReturnVoid();
  EXT_LLVM.finnishGen();
end emitTrivialIntPtrPtrVoid;

protected function emitTrivialDataVoid
  "Emit  void <fname>(DATA *, threadData_t *) { }  -- the void
   counterpart of emitTrivialDataReturnZero."
  input String fname;
algorithm
  EXT_LLVM.startFuncGen(fname);
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "data");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "threadData");
  EXT_LLVM.genFunctionType(MODELICA_VOID);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);
  EXT_LLVM.genReturnVoid();
  EXT_LLVM.finnishGen();
end emitTrivialDataVoid;

protected function emitTrivialDataIntVoid
  "Emit  void <fname>(DATA *, threadData_t *, long base_idx) { } "
  input String fname;
algorithm
  EXT_LLVM.startFuncGen(fname);
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "data");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "threadData");
  EXT_LLVM.genFunctionArg(MODELICA_INTEGER, "base_idx");
  EXT_LLVM.genFunctionType(MODELICA_VOID);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);
  EXT_LLVM.genReturnVoid();
  EXT_LLVM.finnishGen();
end emitTrivialDataIntVoid;

protected function emitTrivialDataIntIntReturnZero
  "Emit  int <fname>(DATA *, threadData_t *, long, long) { return 0; }"
  input String fname;
algorithm
  EXT_LLVM.startFuncGen(fname);
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "data");
  EXT_LLVM.genFunctionArg(MODELICA_METATYPE, "threadData");
  EXT_LLVM.genFunctionArg(MODELICA_INTEGER, "base_idx");
  EXT_LLVM.genFunctionArg(MODELICA_INTEGER, "sub_idx");
  EXT_LLVM.genFunctionType(MODELICA_INTEGER);
  EXT_LLVM.genFunctionPrototype(fname);
  EXT_LLVM.genFunctionBody(fname);
  EXT_LLVM.genReturnZero();
  EXT_LLVM.finnishGen();
end emitTrivialDataIntIntReturnZero;

protected function emitInlineSystemStub
  "<Model>_symbolicInlineSystem -- whole content of <Model>_17inl.c."
  input Absyn.Path modelName;
protected
  String prefix;
algorithm
  prefix := AbsynUtil.pathStringUnquoteReplaceDot(modelName, "_");
  emitTrivialDataReturnZero(prefix + "_symbolicInlineSystem");
end emitInlineSystemStub;

protected function emitDisplacingStubs
  "Emit the SCTL counterparts of every C function whose .c file we
   want to skip in compileModelToBitcode. The keep-in-sync invariant:
   for every entry here there must be a matching `case ... continue ;;`
   in CevalScriptBackend.compileModelToBitcode's bash glob, and vice
   versa. Right now we cover the .c files that contain only trivial
   (DATA*, threadData_t*) -> int { return 0; } bodies."
  input Absyn.Path modelName;
protected
  String prefix;
algorithm
  prefix := AbsynUtil.pathStringUnquoteReplaceDot(modelName, "_");
  /* _17inl.c -- <prefix>_symbolicInlineSystem */
  emitTrivialDataReturnZero(prefix + "_symbolicInlineSystem");
  /* _10asr.c -- <prefix>_checkForAsserts */
  emitTrivialDataReturnZero(prefix + "_checkForAsserts");
  /* _07dly.c -- <prefix>_function_storeDelayed */
  emitTrivialDataReturnZero(prefix + "_function_storeDelayed");
  /* _18spd.c -- <prefix>_function_storeSpatialDistribution +
                 <prefix>_function_initSpatialDistribution */
  emitTrivialDataReturnZero(prefix + "_function_storeSpatialDistribution");
  emitTrivialDataReturnZero(prefix + "_function_initSpatialDistribution");
  /* _16dae.c -- <prefix>_initializeDAEmodeData(DATA*, DAEMODE_DATA*)
     The C codegen returns -1 ("no DAE residuals"); SCTL emits return 0
     here which the DASSL/ODE path tolerates because data->dae* fields
     are zero-initialised by the runtime when the function is not used.
     The (DAEMODE_DATA*) second argument is opaque-ptr to LLVM, so the
     (DATA*, threadData_t*) -> int signature SCTL emits is ABI-compatible. */
  emitTrivialDataReturnZero(prefix + "_initializeDAEmodeData");
  /* _04set.c -- <prefix>_initializeStateSets(int, STATE_SET_DATA*, DATA*)
     Empty body in CodegenC. The (int, ptr, ptr) signature widens int -> i64;
     on x86-64 both register layouts read from edi/rdi, so the unused
     first arg is ABI-compatible. */
  emitTrivialIntPtrPtrVoid(prefix + "_initializeStateSets");
  /* _08bnd.c -- updateBoundParameters is a trivial return-0 in CodegenC.
     updateBoundVariableAttributes calls infoStreamPrint for OMC_LOG_INIT;
     dropping the logging is harmless when that log scope is not enabled. */
  emitTrivialDataReturnZero(prefix + "_updateBoundParameters");
  emitTrivialDataReturnZero(prefix + "_updateBoundVariableAttributes");
  /* _09alg.c -- functionAlgebraics in CodegenC increments a stat counter
     and calls _function_savePreSynchronous. Dropping both is safe when
     the model has no continuous-time algebraic systems (HelloWorld
     does not). */
  emitTrivialDataReturnZero(prefix + "_functionAlgebraics");
  /* _15syn.c -- all four entries are empty bodies for non-synchronous
     models. Different signatures need different helpers. */
  emitTrivialDataVoid(prefix + "_function_savePreSynchronous");
  emitTrivialDataVoid(prefix + "_function_initSynchronous");
  emitTrivialDataIntVoid(prefix + "_function_updateSynchronous");
  emitTrivialDataIntIntReturnZero(prefix + "_function_equationsSynchronous");
end emitDisplacingStubs;

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
    case EQ_UNSUPPORTED() then (ctx, false);
  end match;
end emitEquation;

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
  "Resolve a cref via the layout, then emit a realVars load. The
   builtin 'time' cref is special-cased to a call into the runtime
   accessor omc_jit_get_time(data) instead of a layout lookup."
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
  if isTimeCref(cref) then
    (outCtx, dst) := emitReadTime(ctx);
    ok := true;
    return;
  end if;
  os := lookupSlot(cref, ctx.layout);
  (outCtx, dst, ok) := match os
    case SOME(vs)
      algorithm
        absSlot := absoluteSlot(vs.kind, vs.index, ctx.layout);
        (outCtx, dst) := emitReadRealVar(absSlot, ctx);
      then (outCtx, dst, true);
    case NONE() then (ctx, "<unmapped-cref>", false);
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
  name := AbsynUtil.pathStringUnquoteReplaceDot(modelName, "_") + "_functionODE";
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
  "Walk the four SIMVARS buckets we currently care about and
   accumulate the cref -> slot entries. SimVar.index is already
   1-based-per-kind in master; we keep that as-is and the IR
   layer will subtract 1 when generating GEP offsets."
  input SimCodeVar.SimVars vars;
  output VarLayout layout;
protected
  list<SimCodeVar.SimVar> stateVars, derivativeVars, algVars, paramVars;
  list<tuple<DAE.ComponentRef, VarSlot>> entries = {};
algorithm
  (stateVars, derivativeVars, algVars, paramVars) := match vars
    case SimCodeVar.SIMVARS(stateVars=stateVars,
                            derivativeVars=derivativeVars,
                            algVars=algVars,
                            paramVars=paramVars)
      then (stateVars, derivativeVars, algVars, paramVars);
  end match;

  for v in stateVars      loop entries := addEntry(v, VK_STATE(),      entries); end for;
  for v in derivativeVars loop entries := addEntry(v, VK_DERIVATIVE(), entries); end for;
  for v in algVars        loop entries := addEntry(v, VK_ALG(),        entries); end for;
  for v in paramVars      loop entries := addEntry(v, VK_PARAM(),      entries); end for;

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
        case SOME(VAR_SLOT(kind=VK_PARAM()))
          then EQ_UNSUPPORTED("simple-assign to parameter not allowed");
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
