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

   functionODE / functionDAE are each emitted **only when every one of
   their recipes lowers** (`List.all(..., canLowerEquation)`). A partial
   functionDAE that inlines the lowerable equations and drops the rest
   is silently wrong -- the dropped equation (a `when` reinit, an
   undelegated `delay()`) just does not happen and the solver integrates
   a different model. Leaving the symbol undefined makes the JIT fail
   loudly instead (so the whole `allEquations` set must lower, which is
   why `canCoverModel` now checks it, not just the ODE partition).
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
   A `delay()`-using model fails *loudly* (`Symbols not found:
   [ <M>_functionDAE ]`): the `y = delay(x, ...)` equation is defined
   only in the skipped `<Model>.c`, nothing else computes it, so a
   functionDAE that dropped it would leave `y` frozen. The functionDAE
   gate refuses the partial body; `delay()` becomes a real lift (lower
   `delayImpl` to IR) rather than a silently-wrong "it runs".

   **No silent fallback.** `target == "llvm-jit"` always skips
   `<Model>.c`. `canCoverModel(simCode)` returning false triggers a
   loud compiler warning naming the missing constructs; the
   eventual JIT-link "Symbols not found" error then points at the
   specific `eqFunction_<idx>` (or other) symbol the user is
   missing. No quiet C-path re-emission masquerading as a JIT
   success.

   **Per-recipe emission.** `emitDynamicEquationsBlock` and
   `emitInitialEquationsBlock` emit each `eqFunction_<idx>` that
   classifies cleanly; unsupported recipes leave the symbol
   undefined on purpose, so the JIT-link error names exactly which
   one. Earlier behaviour was to short-circuit the whole block on
   the first `EQ_UNSUPPORTED`, which made every dynamic symbol
   missing instead of just the one with the unsupported construct.

   **BouncingBall.** Currently fails JIT *loudly* with `Symbols not
   found: [ BouncingBall_functionDAE ]`: SCTL refuses to emit a
   functionDAE it cannot fully lower (the `SES_WHEN` bodies below), so
   the model never silently integrates without its bounce `when`.
   (Before the if-expression lift it failed earlier, at `eqFunction_21`;
   that arm now lowers, which exposed the partial-functionDAE problem
   and the gate that fixes it.) The blockers, in order of how much new
   SCTL machinery each requires:

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

     3. `SES_WHEN` bodies (`eq_18`/`_19`/`_20`): edge detection on a
        discrete Boolean (`b and not pre(b)`), conditional reinit of a
        state variable, integer-var assignment (`n_bounce`), and a
        `needToIterate` store on `simulationInfo`. Needs `pre()` reads,
        integer var layout, and a `reinit` emit path. **This is BB's
        current loud blocker** -- the unlowered `SES_WHEN` recipes keep
        `canLowerEquation` false for `allEquations`, so functionDAE is
        left undefined. Hours more.

     4. Initial equations `eq_1`, `_3`, `_5`: `$START.X` cref
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
Boolean observed from a relation (`over = x <= 0.5`) and a Boolean
conjunction (`b = c and x >= 0.1`) and a Real if-expression over a
discrete Boolean (`y = if x <= 0.5 then 2 else 1`) -- all three lower
fully and are checked JIT-vs-C; BouncingBall (zero crossings / `when`
events) and a `delay()`-using model are the loud-failure cases
(functionDAE undefined until those constructs lower). Performance work
uses 10-run samples on HelloWorld + CoupledClutches and the JIT-cache
hot/cold split.

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
