# AGENTS.md — OMCompiler/Compiler/LLVM

Rules for code in this folder and the matching C++ runtime under
`OMCompiler/Compiler/runtime/llvm_gen*` plus the EXT_LLVM bindings in
`OMCompiler/Compiler/LLVM/EXT_LLVM.mo` and its stub mirror in
`OMCompiler/Compiler/Stubs/EXT_LLVM.mo`.

This is the target, not the snapshot. Codebase contradictions are bugs.

---

## 1. Vision

**SimCode / MidCode -> LLVM IR -> simulation. No C codegen. No clang
invocation. No `.bc` round-trip on disk.**

The end state is a model simulating from one in-memory LLVM module
(SCTL's `_sctl` Pass-2 module), against the existing C runtime
(libSimulationRuntimeC, DASSL, the solver pool) through
`data->callback->...`. No parallel solver universe inside SCTL.

Optional artifacts: `.ll` / `.bc` dumps gated on `-d=jit_dump_ir` /
`-d=jit_dump_bc`. Diagnostics only; simulation does not consume them.

---

## 2. No shim

No glue layer between SCTL and the simulation:

- No spawned `clang`, `llvm-link`, `llc`, `ld`, `opt`, or any other
  compiler / linker subprocess.
- No libclang-as-runtime, no string-to-bitcode at simulate time.
- No `.bc` written to disk and read back on the simulate path. SCTL's
  bitcode lives in `program->module`, ships via `g_sctlBitcodeBytes`,
  and gets consumed by `omc_runModelViaJIT` through
  `parseBitcode + addIRModule`.
- No `OMC_SKIP_X` ifdef shrapnel in the C runtime to "skip the bits
  SCTL takes over". CodegenC and SCTL change together.

The current `compileModelToBitcode` is a transitional script; it goes
away as `<Model>.c` lifts into IR (see roadmap).

---

## 3. No C codegen, do not edit the C runtime

The compiler does not generate C. Templates may stop emitting things
SCTL now owns; no new C templates. No inline-C-string emission.

The C runtime under `OMCompiler/SimulationRuntime/c/` is a library we
link against, not a codegen target and not a place to grow new
generic entry points "for SCTL". Changes stay in the LLVM tree
(`OMCompiler/Compiler/LLVM/`, `OMCompiler/Compiler/runtime/llvm_gen*`,
`OMCompiler/Compiler/Stubs/EXT_LLVM.mo`). Reach existing runtime
functionality through the existing callbacks and through the JIT's
`DynamicLibrarySearchGenerator` against the already-linked runtime
library.

**Look for reuse of the existing runtime first, and NEVER do a weird
bespoke thing.** Before emitting IR for some behaviour, find the runtime
function that already does it and call that. Two ways to reach it, in
order of preference:

1. The runtime symbol is a plain `extern` function (e.g. `delayImpl`,
   `solve_nonlinear_system`, `solve_linear_system`): emit the call
   directly from `llvm_gen.cpp` (a `createInlined*` primitive +
   `EXT_LLVM` binding). The `DynamicLibrarySearchGenerator` resolves it
   against omcruntime in-process -- no wrapper needed.
2. The runtime symbol is unreachable from IR (`static inline` in a
   header, e.g. `relationhysteresis`): add a thin **non-static wrapper**
   in `OMCompiler/Compiler/runtime/omc_jit_perform_simulation_adapter.c`
   (e.g. `omc_jit_relationhysteresis`) and call the wrapper. The adapter
   lives in the LLVM tree, not the runtime, and only forwards.

Do not reimplement a runtime algorithm as bespoke IR (no hand-rolled
solver loop, no open-coded ring buffer, no re-deriving a struct's
internal bookkeeping). Bespoke struct *field* access through
`llvm_gen_layout` offsets is fine for reading/writing the model's own
state (realVars, the `nlsx`/`nlsxOld` exchange slots a solver reads); a
bespoke *reimplementation of runtime logic* is not.

---

## 4. Real LLVM IR, never silently-wrong stubs

Missing a primitive? Add it to EXT_LLVM and `llvm_gen.cpp`, emit
proper IR. Missing a Modelica feature whose stub would diverge from
CodegenC's body for some models? Gate behind a `Feature` predicate
(`SimCodeToLLVM.mo`: `Feature` enum + `featureFor` + `featureIsAbsent`)
and emit a `Warning: SimCodeToLLVM: model <M> uses <feature>; ...`.
Never emit a silently-wrong stub.

A `ret 0` is only correct when CodegenC's body would also be `ret 0`
for this model. Prove it with a Feature predicate, not guess.

---

## 5. Layout via offsetof

Field offsets into runtime structs (`DATA`, `SIMULATION_DATA`,
`SIMULATION_INFO`, `OpenModelicaGeneratedFunctionCallbacks`, ...) live
in `OMCompiler/Compiler/runtime/llvm_gen_layout.{c,h}`. `llvm_gen.cpp`
includes the header and reads `omc_layout_*` constants. The .c
includes the header so the symbol list is not duplicated.

Adding a new offset is two edits: one header line, one `offsetof()`
line in the .c. Anything more is a smell.

The `<Model>_callback` IR emission uses a packed anonymous struct with
`[pad x i8] zeroinitializer` gaps sized by `omc_layout_callback_*`, so
the layout matches the C struct byte-for-byte without reproducing
field types inside the LLVM emitter.

---

## 6. Catalog + Feature

Every runtime-contract symbol SCTL emits is one row in
`runtimeEntryCatalog()` (`SimCodeToLLVM.mo`):
`RUNTIME_ENTRY(nameSuffix, retTy, argTys, body, segmentFile, displaceFile)`
where `body` is `EB_STUB | EB_STUB_LINKONCE | EB_NULL_PTR |
EB_RETURN_MINUS_ONE | EB_JAC_UNAVAILABLE | EB_TODO("...")`.
`displaceFile=false` when the file shares content SCTL does not yet
own (today: `<Model>.c`).

When a body depends on a Modelica feature, the catalog row carries
nothing extra; instead `featureFor` maps the `nameSuffix` to a
`Feature` enumerator. Per-feature human strings live in
`protected constant String FEATURE_NAME_*` declarations, referenced
from `featureName`. Same string spelled out in two places is a bug
in the enum coverage.

---

## 7. MetaModelica style

- Explicit types on every variable; no `auto`-equivalent.
- Singleton no-field records (`VKS_STATE`, ...) with `referenceEqual`
  for identity checks.
- `ListUtil` (`List.fold`, `List.contains`, `List.all`, ...) with
  partial application over hand-rolled accumulator loops.
- No column-aligned whitespace. Per-block emission lists use compact
  single-line `try ...; else reportBlockFailure(...); end try;`.
- Repeated strings live in `protected constant String` declarations,
  not at the case site. See `FEATURE_NAME_*`.
- Fixed tag sets use `type X = enumeration(A, B, C);`
  (`NBJacobian.JacobianType` style), `SCREAMING_SNAKE_CASE` values.

---

## 8. C / C++ style

- `auto` is banned; type every variable.
- Const-correctness throughout: `const char *const`, `T *const local`,
  `const`-qualified member functions where applicable.
- Small composable helpers (see `emitGEPLoadPtr`, `emitLoadPtr`,
  `emitChainToRealVars`). New emitters compose; they do not duplicate.
- Failures meant to surface via MM `try/else` use `fprintf(stderr, ...)`
  for the diagnostic then `MMC_THROW()`.

---

## 9. In-memory

Zero disk I/O for compilation artifacts on the simulate path. SCTL
bitcode -> `g_sctlBitcodeBytes` -> `omc_runModelViaJIT`. Per-session
`g_jitCache` keyed on `modelName` makes repeat `simulate()` <1 ms
(first fire ~150 ms). `-d=jit_dump_ir` / `-d=jit_dump_bc` are the
only legitimate disk touches, both gated and diagnostic.

---

## 10. Roadmap to `<Model>.c` displacement

The last `.c` SCTL has not displaced. Lift every symbol it defines,
then have CodegenC stop emitting it under `-d=jitSimulate`.

1. **Callback function-pointer table.** DONE.
   (`createCallbackTable`, `emitCallbackTableBlock`).
2. **Leaf return-0 functions** (`_input_function*`, `_data_function`,
   `_output_function`, `_setc_function`, `_setb_function`,
   `_dataReconciliation*`, `_functionLocalKnownVars`). DONE.
   11 `EB_STUB_LINKONCE` catalog entries, Feature-gated.
3. **Equation functions** (`_functionODE`, `_functionDAE`,
   `_ODE_DAG`). DONE. `emitModelEquationsBlock` re-using
   `emitEquationFunction`; `_ODE_DAG` is a void stub (advisory hint).
   `_functionODE` inlines the ODE-partition recipes; `_functionDAE`
   classifies and inlines the full `allEquations` set (the discrete
   context CodegenC's functionDAE iterates), so discrete/algebraic
   equations -- relation results, observed Booleans -- evaluate
   instead of staying frozen at their initial values. Unsupported
   members of `allEquations` are skipped per-recipe (the function
   stays well-formed); a model whose `allEquations` all lower gets a
   byte-faithful functionDAE.

   `emitDynamicEquationsBlock` additionally emits a standalone
   `<prefix>_eqFunction_<idx>` (linkonce_odr) for every `allEquations`
   member whose recipe passes `canLowerEquation`. The still-clang'd
   segment files (`_05evt.c`, `_06inz.c`, `_09alg.c`, ...) take `extern`
   references to the algebraic / discrete eqFunction symbols CodegenC
   used to define only in the skipped `<Model>.c`; SCTL now supplies
   them. Unsupported equations are left undefined on purpose (loud
   JIT-link error names the missing one); `EXT_LLVM.functionDefined`
   dedups an index that appears in more than one block (e.g. both
   `initialEquations` and `allEquations`).

   functionAlgebraics is likewise a real SCTL function, inlined from
   `algebraicEquations` (the continuous-time algebraic partition
   `updateContinuousSystem` recomputes every integrator step), displacing
   `_09alg.c` when it lowers. A no-op stub there only matched ODE-only
   models; it froze any continuous algebraic var (`y = delay(x)`).

   functionODE / functionDAE / functionAlgebraics are each emitted
   **only when every one of their recipes lowers**
   (`List.all(..., canLowerEquation)`). A partial body that inlines the
   lowerable equations and drops the rest is silently wrong -- the
   dropped equation (a `when` reinit, an unsupported call) just does not
   happen and the solver integrates a different model. Leaving the symbol
   undefined makes the JIT fail loudly instead (so the whole
   `allEquations` set must lower, which is why `canCoverModel` checks it,
   not just the ODE partition).
4. **`<Model>_setupDataStruc`.** DONE for the load-bearing fields.
   `createSetupDataStrucFull` wires the two critical pointers plus
   all 41 modelData integer counters (driven by
   `omc_modeldata_int_offsets[]` in `llvm_gen_layout.c` and the
   matching `modelDataCounters` extractor on the Modelica side).
   Skipped (still on CodegenC's strong copy and not load-bearing
   for ODE simulation today): modelName / modelGUID strings, XML
   blob pointers (NULL is right for runtime-from-file mode),
   `OpenModelica_updateUriMapping` resource call,
   `modelDataXml.*` (the runtime populates these via the on-disk
   `_info.json` read), `linearizationDumpLanguage`.
5. **Resource literals (`_OMC_LIT_RESOURCE_*`).** TODO. Internal
   linkage in `<Model>.c`, only consumed by `setupDataStruc` to feed
   `OpenModelica_updateUriMapping`. Land alongside step 4 via the
   same MMC_DEFSTRINGLIT / MMC_DEFSTRUCTLIT layout primitives.
   `<Model>_dummyVAR_INFO` is unused externally and can be skipped.
6. **`main()` shim.** PARTIAL. `createMainShim` allocas
   DATA / MODEL_DATA / SIMULATION_INFO (sizes from `omc_sizeof_*`),
   wires `data->modelData` + `data->simulationInfo`, calls
   `<Model>_setupDataStruc(&data, NULL)`, returns
   `_main_SimulationRuntime(argc, argv, &data, NULL)`. linkonce_odr
   keeps the linker out of CodegenC's way. Remaining for the full
   lift: `omc_assert` / `omc_terminate` function-pointer
   reassignments, `MMC_INIT` + `omc_alloc_interface.init`, the
   `MMC_TRY_TOP` / `MMC_TRY_STACK` setjmp dance (expand to IR or
   punt under `-d=jitSimulate`), the Optimica branch.
7. **`_performSimulation` / `_performQSSSimulation` /
   `_updateContinuousSystem`.** DONE via adapter.
   `OMCompiler/Compiler/runtime/omc_jit_perform_simulation_adapter.c`
   pulls in `perform_simulation.c.inc` and
   `perform_qss_simulation.c.inc` with the `prefixedName_*` macros
   set to non-prefixed `omc_jit_*` symbols. The internal static
   `omc_jit_updateContinuousSystem_inner` gets a thin external-linkage
   wrapper `omc_jit_updateContinuousSystem` so the callback table
   can address it. The C runtime under `SimulationRuntime/c/` is
   untouched; the adapter lives in the LLVM tree.
   `createCallbackTable` points the three solver-driver slots at
   `omc_jit_*`; the JIT's `DynamicLibrarySearchGenerator` resolves
   them against omcruntime in-process. SCTL emits zero solver IR
   per model.
8. **CodegenC suppression.** DONE for the HelloWorld class.
   `Config.simCodeTarget()` resolves `-d=jitSimulate` to `"llvm-jit"`
   and `SimCodeMain.callTargetTemplates`'s C case gates the
   `<Model>.c` emission on `target <> "llvm-jit"`. The
   `omc_jit_main_runtime` adapter reads the GUID out of
   `<prefix>_init.xml` at startup and writes it to
   `modelData->modelGUID`, so the runtime's GUID cross-check
   matches without any state shared back into CodegenC.

   HelloWorld now runs with no `<Model>.c` on disk and no
   `<prefix>.bc` either (every catalog-displaced satellite
   skips clang too); the JIT consumes the SCTL bitcode alone.
   A `delay()`-using model JIT-simulates == C: `emitExp` lowers the
   `delay(exprNumber, x, dt, dmax)` call to the runtime `delayImpl`
   (`createInlinedDelay`), and `functionAlgebraics` (see step 3) is now a
   real SCTL function that recomputes `y = delay(x, dt)` every integrator
   step. `_07dly.c` (the `storeDelayed` ring-buffer feeder) stays on
   clang behind the `DELAY_EXPRS` Feature, wired through the callback
   table.

   **No silent fallback.** `target == "llvm-jit"` always skips
   `<Model>.c`. `canCoverModel(simCode)` returning false triggers a
   loud compiler warning; the eventual JIT-link "Symbols not found"
   error then points at the specific `eqFunction_<idx>` (or other)
   symbol the user is missing. No quiet C-path re-emission masquerading
   as a JIT success. `canCoverModel` is *predictive*, not conservative:
   it returns true iff functionODE (odeEquations) and functionDAE
   (allEquations) both fully lower -- the two satellites with no clang
   fallback. Zero crossings, algebraic, and initial equations are
   graceful fallbacks (keep _05evt.c / _09alg.c / _06inz.c on clang) so
   they do not block coverage; a model that actually runs no longer
   warns. (It is used only for the warning -- the cutover is
   unconditional.)

   **Per-recipe emission.** `emitDynamicEquationsBlock` and
   `emitInitialEquationsBlock` emit each `eqFunction_<idx>` that
   classifies cleanly; unsupported recipes leave the symbol
   undefined on purpose, so the JIT-link error names exactly which
   one. Earlier behaviour was to short-circuit the whole block on
   the first `EQ_UNSUPPORTED`, which made every dynamic symbol
   missing instead of just the one with the unsupported construct.

   **BouncingBall.** The full testsuite BouncingBall (zero crossings,
   `when` + `reinit`, the integer `n_bounce` counter) now JIT-simulates
   byte-identical to the C path: the height trace matches to ~13 digits
   across the bounces and `n_bounce` matches exactly ({1,1,4,34} at
   t={0.5,1,2,3}). The blockers below all landed; they are kept as a
   record of the order they were lifted. (BouncingBall no longer warns --
   `canCoverModel` is predictive now.) The lifts, in the order they were
   taken:

     1. Discrete-Boolean equations: `boolDiscrete = <Boolean exp>` over
        zero-crossing relations, discrete-Boolean cref reads, and / or /
        not, and literals (e.g. `impact = h <= 0.0`,
        `$whenCondition = impact and v <= 0.0`,
        `$whenCondition3 = h<=0 and v<=0`). **DONE.** Adapter
        `omc_jit_relationhysteresis` in
        `omc_jit_perform_simulation_adapter.c` is the non-static
        wrapper SCTL calls (the runtime's own `relationhysteresis`
        is `static inline` in `model_help.h` and unreachable from
        IR; the wrapper switches on a 0..3 op-code for
        Less/LessEq/Greater/GreaterEq, threading the matching
        function-pointer args through). MetaModelica side:
        `VK_BOOL_DISCRETE` VarKind over the `boolAlgVars` bucket,
        `EQ_BOOL_DISCRETE_ASSIGN(slot, rhs)` recipe, and `emitBoolExp`
        -- an i32-domain mirror of `emitExp` whose nodes compose by
        symtab name via the bool primitives in `llvm_gen.cpp`
        (`createInlinedReadBoolVar` / `...RelationHysteresisBool` /
        `...BoolBinop` / `...BoolNot` / `...BoolConst` /
        `...StoreBoolVar`). Relation operand nominals follow
        `getExpNominal` (constants by magnitude, default 1.0).
        Verified end-to-end byte-identical to C on `Boolean over =
        x <= 0.5` (single relation) and `b = c and x >= 0.1`
        (conjunction over a cref + relation).

     2. If-expressions in a Real RHS reading a discrete Boolean
        condition (`der(v) = if flying then -g else 0`). **DONE.**
        `emitExp` gained a `DAE.IFEXP` case that lowers the condition
        via `emitBoolExp` and the two Real arms via `emitExp`, then
        `createInlinedSelectReal` emits `(cond != 0) ? then : else`
        (eager select, matching CodegenC's scalar ternary). Verified
        byte-identical to C on `y = if (x <= 0.5) then 2 else 1`.

     3. `SES_WHEN` bodies with Real / discrete-Real / Boolean assigns
        and `reinit`. **DONE.** `EQ_WHEN(conditions, whenStmts)` recipe;
        `emitWhenEquation` lowers by *predication* rather than a
        basic-block branch -- the edge `OR(cond and not pre(cond))` is
        materialised once (`emitWhenEdge`), then each body statement is
        `lhs = edge ? rhs : lhs` (`emitWhenRealAssign` /
        `emitWhenBoolAssign` via `genSelectReal` / `genSelectBool`).
        `reinit(state, v)` predicates the state write and sets
        `needToIterate` (`genSetNeedToIterate`). Supporting lifts landed
        here: `pre()` reads (`emitPreReal` / `emitBoolPreRead` over
        `simulationInfo->{real,boolean}VarsPre`); plain (no-ZC, index=-1)
        relations as `fcmp` (`genBoolFcmp`, for `v_new > 0`); the
        `discreteAlgVars` bucket (discrete Reals like `v_new`) folded
        into the layout as `VK_ALG`; and the functionDAE prologue/epilogue
        (`needToIterate = 0`, `discreteCall = 1 .. 0`) without which the
        runtime event-iteration loop spins on a fired reinit. Verified
        end-to-end on `BB2` (a bouncing ball, JIT == C to ~13 digits).

     4. Integer discrete vars + integer when-assign (`n_bounce =
        1 + pre(n_bounce)`). **DONE.** `VK_INT_DISCRETE` over the
        `intAlgVars` bucket; `emitIntExp` -- a modelica_integer-domain
        mirror of `emitExp` (ICONST, discrete-Integer cref reads,
        `pre()` of an Integer, + / - / *) over the int primitives in
        `llvm_gen.cpp` (`createInlinedReadIntVar` / `...ReadIntVarPre` /
        `...StoreIntVar` / `...IntConst` / `...IntBinop` /
        `...SelectInt`); and an integer predicated when-assign
        (`emitWhenIntAssign`). With this the full testsuite BouncingBall
        JIT-simulates == C.

     5. Initial equations `eq_1`, `_3`, `_5`: `$START.X` cref
        lookups (read `realVarsData[idx].attribute.start.data[0]`),
        writes to `simulationInfo->realVarsPre[idx]`, reads from
        `realParameter` into state slots. A handful of EqRecipe
        variants + their emit branches. Hours.

   Each one is a self-contained lift; landing them one by one
   moves BB toward the JIT path without touching unrelated code.

   `compileModelToBitcode` itself can be deleted once
   `_functions.c` / `_08bnd.c` / `_05evt.c` / `_12jac.c` lift
   through real-IR emission so the satellite files stop being
   written to disk.

---

## 11. Dynamic skip list

`SimCodeToLLVM.displacedSegmentFiles()` returns the set of
`<Model>_*.c` files `CevalScriptBackend.compileModelToBitcode` skips.
The single source of truth is the `Global.simCodeToLLVMDynamicSkips`
slot, populated by `recordDisplacedSegment` from Block emitters and
from `emitDisplacingStubs` after its per-file safety scan succeeds.

Per-file scan: a segment file is displaced iff every catalog row for
it (excluding `displaceFile=false` rows) is non-`EB_TODO` and passes
its Feature predicate. Otherwise the file stays on clang so the
linker sees exactly one definition per symbol.

---

## 12. Empirical evidence

Bug-fix or correctness claims require a real before/after on a
reproducer that actually triggers the issue, in the PR / commit
message. Canonical models: HelloWorld (baseline ODE); a discrete
Boolean observed from a relation (`over = x <= 0.5`), a Boolean
conjunction (`b = c and x >= 0.1`), a Real if-expression over a
discrete Boolean (`y = if x <= 0.5 then 2 else 1`), and the full
BouncingBall (zero crossings, `when` + `reinit` + `pre`, discrete-Real
`v_new`, integer `n_bounce`), a `delay()`-using model
(`y = delay(x, 0.5)`, continuous algebraic via the real
functionAlgebraics), an algorithm section (`algorithm y := x*x;`), and a
single-unknown nonlinear system (`y + sin(y) = x + 2`, solved by the
runtime Newton via the `omc_jit_solve_nonlinear_system1` adapter), and a
single-unknown linear tearing system (`x = sin(t) - 2y; y = cos(t) + 3x`,
torn into two scalar `SES_LINEAR`s, solved by `solve_linear_system` via
the `omc_jit_solve_linear_system1` adapter) -- all lower fully and are
checked JIT-vs-C. Performance work uses 10-run samples on HelloWorld +
CoupledClutches and the JIT-cache hot/cold split.

Known still-unsupported (each fails *loudly* with 'Symbols not found',
never silently): algorithm sections that are not scalar `cref := expr`
assignments (if / for / while statement bodies), multi-iteration-variable
nonlinear and linear systems, and `sample()` / time events. A
single-iteration-variable `SES_NONLINEAR` reuses the runtime
`solve_nonlinear_system` (the adapter seeds the iteration var, solves,
throws on failure, writes the solution back); the residual / setup /
Jacobian stay on clang in `_02nls.c` / `_12jac.c`. A single-iteration-
variable `SES_LINEAR` is symmetric -- `omc_jit_solve_linear_system1`
wraps `solve_linear_system` and the runtime's setA / setb / analytic-
Jacobian callbacks stay on the still-clang'd `_03lsy.c` / `_12jac.c`.
SCTL's callback table threads the actual `INDEX_JAC_A` / `_ADJ` / `_B`
/ ... values (looked up by `matrixName` from `simCode.jacobianMatrices`),
rather than the prior zero-sentinel; the hardcoded zero was harmless for
HelloWorld but clobbered the `LSJacN.sparsePattern` slot for any model
whose DASSL `initialAnalyticJacobianA` collided with a tearing-system
jacobian at the same index, producing a singular linear-system matrix
at the first `solve_linear_system` call.

---

## 13. Failure modes to reject

These are real temptations from past sessions. Pattern-match to the
right alternative:

- "Add a `#ifdef OMC_SKIP_X` to the C runtime." No. CodegenC stops
  emitting it, or the runtime exposes a generic entry point.
- "Spawn clang for this one file." No. Subprocess clang is the
  thing being eliminated.
- "Compile a C string with libclang at runtime." No. Emit IR
  directly.
- "Write a `.bc` to disk and read it back." No. In-memory via
  `g_sctlBitcodeBytes`.
- "Hardcode the struct offset." No. `llvm_gen_layout.{c,h}` via
  `offsetof`.
- "Duplicate this Modelica feature string in three case arms." No.
  `FEATURE_NAME_*` constant, single point of definition.
- "Skip the Feature check; this model is fine." No. Feature
  predicates are mandatory when the stub diverges from CodegenC for
  any non-trivial model.
- "Write a small orchestrator script that knows about the JIT plus
  clang." No. Orchestrator scripts are shims.

If the right fix is more work than you want today, do less of the
right fix this commit. Do not do the wrong fix.
