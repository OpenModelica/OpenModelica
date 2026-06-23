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

## 3. No C codegen

The compiler does not generate C. Templates may stop emitting things
SCTL now owns; no new C templates. Pre-built runtime helpers in
`libSimulationRuntimeC` are fine. No inline-C-string emission.

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
4. **`<Model>_setupDataStruc`.** TODO. Needs `createSetupDataStruc`
   driven by `llvm_gen_layout.h`'s MODEL_DATA / DATA offsets, plus
   MMC-literal emit primitives for the resource literal table.
5. **`<Model>_dummyVAR_INFO` + `_OMC_LIT_RESOURCE_*`.** TODO. Global
   alias for `dummyVAR_INFO`; MMC_DEFSTRINGLIT / MMC_DEFSTRUCTLIT
   layout primitives for the resource literals.
6. **`main()` shim.** TODO. Stack-alloc DATA/MODEL_DATA/SIMULATION_INFO,
   wire pointers, call `setupDataStruc`, tail-call
   `_main_SimulationRuntime`. Decide on the `MMC_TRY_TOP`/`STACK`
   setjmp dance (expand to IR or punt under `-d=jitSimulate`).
7. **`_performSimulation` / `_performQSSSimulation` /
   `_updateContinuousSystem`.** TODO. **Do not** emit 600 lines of
   solver IR per model. Lift `perform_simulation.c.inc` and
   `perform_qss_simulation.c.inc` into regular `.c` files in
   `libSimulationRuntimeC` as non-prefixed
   `omc_performSimulation` / `omc_performQSSSimulation` /
   `omc_updateContinuousSystem` that call
   `data->callback->updateContinuousSystem` rather than the
   prefixed-inline version. Callback table then points at the generic
   functions; SCTL emits nothing per model for these slots.
8. **CodegenC suppression.** Final. With 1-7 done, gate
   `simulationFile` for `<Model>.c` on `Flags.isSet(Flags.JIT_SIMULATE)`
   and SCTL becomes the sole emitter. `compileModelToBitcode` can be
   deleted once `_functions.c` / `_08bnd.c` / `_05evt.c` / `_12jac.c`
   lift through real-IR emission.

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
message. Canonical models: HelloWorld (baseline ODE), BouncingBall
(zero crossings / events), a `delay()`-using model (Feature warning).
Performance work uses 10-run samples on HelloWorld + CoupledClutches
and the JIT-cache hot/cold split.

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
