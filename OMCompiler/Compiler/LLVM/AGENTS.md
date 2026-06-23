# AGENTS.md — OMCompiler/Compiler/LLVM

Hard rules for everyone touching this folder and the matching C++ runtime
under `OMCompiler/Compiler/runtime/llvm_gen{.cpp,.hpp,_util.hpp,_wrappers.{c,h}}`,
`OMCompiler/Compiler/runtime/llvm_gen_layout.{c,h}`,
`OMCompiler/Compiler/LLVM/{EXT_LLVM.mo,SimCodeToLLVM.mo,MidToLLVM.mo,MidToLLVMUtil.mo}`,
and the matching stubs in `OMCompiler/Compiler/Stubs/EXT_LLVM.mo`.

This is not a "what we have today" snapshot. It is **what we are building**.
Use it as a fence, not a map. If something in the codebase contradicts this
file, the codebase is wrong.

---

## 1. The vision

**SimCode / MidCode -> LLVM IR -> simulation. No C codegen. No clang
invocation. No subprocess. No `.bc` round-trip on disk.**

The end state is HelloWorld (and beyond) simulating with:

- No `<Model>*.c` ever written to disk by OMC's compile path.
- No spawned `clang`, no spawned `llvm-link`, no shell script.
- One in-memory LLVM module built by `SimCodeToLLVM` (Pass 2: the `_sctl`
  module that arrives in `omc_runModelViaJIT`) plus zero or more pre-built
  bitcode files that ship with the runtime.
- The model runs against the existing C runtime (libSimulationRuntimeC,
  DASSL, the solver pool) through `data->callback->...`. No parallel
  solver universe inside SCTL.

Every commit moves us closer to that. If a commit would make us further,
it is rejected, even if it is "convenient" or "would help right now".

The optional artifacts are:

- A `.bc` or `.ll` file written **only** when the user asks for it
  (e.g. `-d=jit_dump_ir`, `-d=jit_dump_bc`) so they can `llvm-dis` and
  read it. These are diagnostics. The simulation does not consume them.

---

## 2. The "No shim" rule

No glue layer between SCTL and the simulation. In particular:

- No spawned `clang`, `clang++`, `opt`, `llvm-link`, `llc`, `ld`,
  `gcc`, or any other compiler / linker subprocess.
- No "compile this C string to bitcode via libclang at simulate time"
  rescue path. libclang is a build-time tool, not a runtime dependency.
- No `.bc` written, then read, then linked from disk during the
  simulate path. The bitcode lives in `program->module`, becomes
  `g_sctlBitcodeBytes` via `stashCurrentModuleAsBitcode()`, and is
  consumed in-process by `omc_runModelViaJIT` through
  `parseBitcode + addIRModule`.
- No orchestrator script that emits `.c`, calls `clang`, calls
  `llvm-link`, and finally hands a `.bc` to the JIT. The current
  `compileModelToBitcode` script is a relic; it goes away as more of
  `<Model>.c` lifts into IR.
- No "embed a copy of clang and call it as a library to compile our
  generated C". If we are tempted to do that, we are doing the wrong
  thing: we should be emitting the IR directly.
- No `OMC_FOR_JIT` or `OMC_SCTL_OWNS_X` `#ifdef` shrapnel in the C
  runtime to "skip the bits SCTL takes over". If CodegenC needs to
  stop emitting something, it stops emitting it. The CodegenC change
  and the SCTL emission land together.

If you find yourself adding any of the above, stop. Whatever you are
fighting is one of the items in the roadmap below; tackle that item
directly.

---

## 3. The "No C codegen" rule

The compiler does not generate C. Period.

- Do not add new templates to `CodegenC.tpl` or any sibling. Edits to
  remove emission of something SCTL now owns are fine and expected.
- Do not write helper `.c` files at simulate time. Pre-built runtime
  helpers compiled at OMC build time and shipped in
  `libSimulationRuntimeC` (or a sibling `.so`) are fine and expected.
- Do not generate inline C in any form (printf-stitched source, string
  templates, comment-decorated code blobs). Emit LLVM IR directly via
  the EXT_LLVM primitives or via a new C++ helper in `llvm_gen.cpp`.

The C runtime under `OMCompiler/SimulationRuntime/c/` is a **library we
link against**, not a codegen target. We may modify the C runtime to add
a generic non-prefixed entry point (e.g. the eventual
`performSimulation` lift), but we do not produce C from the compiler.

---

## 4. The "Real LLVM IR" rule

Every primitive emits proper LLVM IR. No NOOPs, no `ret 0` shortcuts
where the real behaviour matters, no "we will fix this later"
fallbacks that silently break simulation.

When SCTL cannot lower a feature today:

- If the missing piece is a runtime-helper primitive, **add the
  primitive** to EXT_LLVM and `llvm_gen.cpp` and emit the proper IR.
- If the missing piece is a Modelica feature whose stub would be
  semantically wrong for some models (`delay()`,
  `spatialDistribution()`, clocked partitions, dynamic state sets),
  gate emission behind a Feature predicate in `SimCodeToLLVM.mo`
  (the `Feature` enum + `featureFor` + `featureIsAbsent`) and emit a
  `Warning: SimCodeToLLVM: model <M> uses <feature>; ...` so the
  user sees the C-path fallback. **Never** emit a silently-wrong stub
  in its place.

A `ret 0` is only correct when CodegenC's body would also be `ret 0`
for this model. Prove that with a Feature predicate, not by guessing.

---

## 5. The "Layout via offsetof" rule

Field offsets into the C runtime structs (`DATA`, `SIMULATION_DATA`,
`SIMULATION_INFO`, `OpenModelicaGeneratedFunctionCallbacks`, ...) live
in **one place**: `OMCompiler/Compiler/runtime/llvm_gen_layout.c`, with
the matching `extern` declarations in `llvm_gen_layout.h`.

- `llvm_gen.cpp` never hardcodes a struct offset. It includes
  `llvm_gen_layout.h` and reads the `omc_layout_*` constants.
- `llvm_gen_layout.c` does not duplicate `extern` declarations of
  variables it defines; it `#include`s `llvm_gen_layout.h` so the
  header is the single source of truth for the symbol list.
- Adding a new offset is two edits: one line in the header (`extern
  const size_t omc_layout_X;`) and one line in the .c
  (`offsetof(struct Y, X)`). Anything more is a smell.

The `<Model>_callback` IR emission follows the same rule: it uses a
packed anonymous struct with `[pad x i8] zeroinitializer` gaps sized by
the `omc_layout_callback_*` offsets so layout matches the C struct
byte-for-byte without reproducing field types inside the LLVM emitter.

---

## 6. The catalog and Feature mechanism

Every runtime-contract symbol SCTL emits is one row in
`runtimeEntryCatalog()` in `SimCodeToLLVM.mo`. The row carries:

- `nameSuffix`. The `<Model>_X` suffix.
- `retTy` / `argTys`. EXT_LLVM type codes.
- `body`. `EntryBody` constructor: `EB_STUB`, `EB_STUB_LINKONCE`,
  `EB_NULL_PTR`, `EB_RETURN_MINUS_ONE`, `EB_JAC_UNAVAILABLE`, or
  `EB_TODO("...")` for entries owned by a Block emitter or by clang.
- `segmentFile`. The CodegenC `.c` file the symbol lives in.
- `displaceFile`. False when the segment file shares content SCTL
  does not yet emit (today: `<Model>.c`).

Adding a new SCTL-owned symbol is one row plus, when its body depends
on a Modelica feature, one `case` in `featureFor` plus (if the feature
is new) one enumerator in `Feature` plus one `case` in `featureIsAbsent`
plus one `protected constant String FEATURE_NAME_X = "..."` plus one
`case` in `featureName`. The diagnostic warning string is **never**
spelled out at the case site; it lives in the `FEATURE_NAME_*` constant
so every warning of the same kind shares the same `String` value.

If you find yourself spelling out the same Modelica feature string in
two places, the Feature enum is missing an enumerator. Add it.

---

## 7. Modelica-side style

These rules apply to MetaModelica code under `OMCompiler/Compiler/LLVM/`
and to the related sites in `SimCodeToLLVM.mo` / `MidToLLVM.mo` /
`EXT_LLVM.mo`.

- **No `auto`-equivalent.** Every variable carries an explicit type at
  declaration. `String name = ...;` not `var name = ...;`.
- **`referenceEqual` for no-field records.** Cache singleton instances
  of `VarKind` (`VKS_STATE`, `VKS_DERIVATIVE`, ...) and friends; route
  identity checks through `referenceEqual` against the cached
  singleton, not `match` on the constructor. The cached singleton
  pattern is the same one MetaModelica uses for `DAE.OPERATOR` and
  the like.
- **`ListUtil` over hand-rolled loops.** `List.contains`, `List.fold`,
  `List.all`, `List.any`, `List.filterMap` with partial application
  (`function f(arg = value)`). A four-line `for ... loop` accumulator
  is almost always a `List.fold` with partial application; a
  one-line for-loop append-if-not-present is `List.contains` plus
  `listAppend`.
- **No column-aligned whitespace.** Single space between tokens.
  Compact single-line `try ...; else ...; end try;` is the preferred
  shape for per-block emission lists; multi-line `else` blocks are
  fine when the recovery is non-trivial, but do not pad columns to
  make a list "look pretty". The block-emission list shape is:
  `try emitFooBlock(...); else reportBlockFailure("emitFooBlock", name); end try;`
- **Strings are cached.** When the same Modelica string appears in more
  than one `case` arm or more than one warning site, it lives in a
  `protected constant String CONST_NAME = "...";` near the related
  enum / catalog, and the case sites return `CONST_NAME`. See
  `FEATURE_NAME_*` for the established pattern.
- **Enumerations use `type X = enumeration(A, B, C);`.** Use the
  Modelica enumeration syntax (see `NBJacobian.JacobianType`,
  `NBVariable.VarType`, `NBPartition.Kind`), not a uniontype of
  no-field records, when the goal is a fixed set of tags. Values are
  `SCREAMING_SNAKE_CASE`. The enum is the keyspace; per-tag data
  (display string, predicate, ...) lives in small dispatch functions
  that all key off the enum.

---

## 8. C / C++ side style

These rules apply to `llvm_gen.cpp`, `llvm_gen_layout.{c,h}`,
`llvm_gen_util.hpp`, `llvm_gen_wrappers.{c,h}`, and any new helper file
under `OMCompiler/Compiler/runtime/`.

- **Type every variable.** `auto` is banned: write `llvm::Value *const
  v = ...;` not `auto v = ...;`. The reader should never have to chase
  the source of a type through IDE tooling.
- **Const-correctness throughout.** Pointer parameters that are not
  reassigned: `const char *const fname`. Local variables that are
  computed once and read many times: `llvm::Type *const i8 = ...;`.
  Member functions that do not mutate state: `const`-qualified.
  Same rules in the C files.
- **Helpers stay small and composable.** `emitGEPLoadPtr`,
  `emitLoadPtr`, `loadFromSymtab`, `emitChainToRealVars`,
  `storeIntoSymtab` in `llvm_gen.cpp` are the model: each one does
  one obvious thing, takes typed parameters, and returns the obvious
  type. New emit primitives compose these; they do not duplicate them.
- **`MMC_THROW()` for failures that should propagate to MetaModelica
  `try/else`.** Use `fprintf(stderr, "...")` for the diagnostic
  message, then `MMC_THROW()`. The MM side catches with
  `try ... else reportBlockFailure(...); end try;`.

---

## 9. The "in-memory" rule

The simulate path has zero disk I/O for compilation artifacts.

- SCTL's bitcode lives in `program->module` until
  `stashCurrentModuleAsBitcode` copies it to `g_sctlBitcodeBytes`.
- `omc_runModelViaJIT` consumes `g_sctlBitcodeBytes` via
  `parseBitcode + addIRModule`. No `<Model>_sctl.bc` ever lands on
  disk.
- The per-session LLJIT cache (`g_jitCache` in `llvm_gen.cpp`) keeps
  the materialized `llvm::orc::LLJIT` keyed on `modelName` so
  repeated `simulate()` calls reuse the compiled module: first fire
  ~150 ms, subsequent fires under 1 ms.
- `-d=jit_dump_ir` (text IR) and `-d=jit_dump_bc` (binary bitcode)
  are the only ways anything compilation-related touches the disk on
  the simulate path. They are diagnostic, gated, optional.

`compileModelToBitcode` (in `CevalScriptBackend.mo`) is the bridge
during the transition. It exists only because `<Model>.c` is not yet
fully lifted. **Its termination condition is the roadmap below.** When
the roadmap is done, `compileModelToBitcode` is deleted.

---

## 10. Roadmap to `<Model>.c` displacement

The single remaining `.c` file SCTL has not displaced is `<Model>.c`
itself (the "driver" file CodegenC emits per model). Displacing it
means lifting every symbol it defines into SCTL IR, then teaching
CodegenC to stop emitting it under `-d=jitSimulate`. The pieces, in
the order they are most useful to land:

1. **Callback function-pointer table.** `@<Model>_callback` as a
   `linkonce_odr` constant struct. **DONE** (`createCallbackTable`
   in `llvm_gen.cpp`, `emitCallbackTableBlock` in
   `SimCodeToLLVM.mo`, layout via `llvm_gen_layout.h`). The IR
   exists; CodegenC suppression lands together with step 8.

2. **Leaf return-0 functions.** `_input_function`,
   `_input_function_init`, `_input_function_updateStartValues`,
   `_inputNames`, `_data_function`,
   `_dataReconciliationInputNames`,
   `_dataReconciliationUnmeasuredVariables`, `_output_function`,
   `_setc_function`, `_setb_function`, `_functionLocalKnownVars`.
   **DONE** (11 `EB_STUB_LINKONCE` catalog entries, Feature-gated).

3. **Equation functions.** `_functionODE`, `_functionDAE`,
   `_ODE_DAG`. **DONE** (`emitModelEquationsBlock` re-using
   `emitEquationFunction` from Pass 1; `_ODE_DAG` is a void stub
   since the C body's `buildEvalDAG_ODE` hint is advisory).

4. **`<Model>_setupDataStruc`.** The function that wires the DATA
   struct's nested pointers and reads the `modelData` literal
   tables. Needs a new C++ helper (`createSetupDataStruc`) that
   stores into named struct fields at byte offsets driven by
   `llvm_gen_layout.h`. The literal tables (`<Model>_modelData`
   etc.) need their own emit primitives or, equivalently, an MMC
   literal helper.

5. **`<Model>_dummyVAR_INFO`** and the resource literals
   (`_OMC_LIT_RESOURCE_*`). Small globals; an alias-emit primitive
   (`@<Model>_dummyVAR_INFO = alias %struct.VAR_INFO, ptr
   @omc_dummyVarInfo`) covers the dummy. Resource literals use
   `MMC_DEFSTRINGLIT` / `MMC_DEFSTRUCTLIT`, so they need MMC-literal
   emit primitives.

6. **`main()` shim.** Emits the few-line entry point that allocates
   `DATA`, `MODEL_DATA`, `SIMULATION_INFO` on the stack, wires the
   pointers, calls `<Model>_setupDataStruc`, and tail-calls
   `_main_SimulationRuntime`. The `MMC_TRY_TOP` / `MMC_TRY_STACK`
   setjmp dance is the awkward bit; either expand the macros into IR
   (`setjmp` + `longjmp` extern calls) or skip the stack-overflow
   catch under `-d=jitSimulate` (the production path will reinstate
   it via a runtime helper).

7. **`<Model>_performSimulation` / `_performQSSSimulation` /
   `_updateContinuousSystem`.** The 600-line inlined template
   currently brought in by `#include
   <simulation/solver/perform_simulation.c.inc>`. **Do not** emit
   600 lines of solver IR per model. Instead: lift the .inc files
   into regular `.c` files in `libSimulationRuntimeC` with
   non-prefixed names (`omc_performSimulation`,
   `omc_updateContinuousSystem`, `omc_performQSSSimulation`) that
   call `data->callback->updateContinuousSystem` instead of the
   prefixed-inline version. Then the callback table just points at
   the generic library function; SCTL emits nothing per model for
   these slots.

8. **CodegenC suppression.** The final commit, once 1 through 7 are
   in place. Add a `Flags.isSet(Flags.JIT_SIMULATE)` guard in
   `CodegenC.tpl` around the entire `simulationFile` body for
   `<Model>.c`. SCTL becomes the sole emitter. `<Model>.c` no longer
   appears on disk; `compileModelToBitcode`'s clang loop drops it.
   `displacedSegmentFiles` includes `<Model>.c`.
   `compileModelToBitcode` itself can be deleted shortly thereafter
   once the remaining files (`<Model>_functions.c` user bodies,
   `<Model>_08bnd.c` real parameter equations, `<Model>_05evt.c`
   real zero-crossings, `<Model>_12jac.c` analytic Jacobian) lift
   through real-IR emission rather than `EB_TODO`.

---

## 11. The dynamic-skip list

`displacedSegmentFiles()` returns the set of `<Model>_*.c` files
`compileModelToBitcode` skips. The single source of truth is the
process-global `Global.simCodeToLLVMDynamicSkips` slot, populated by
`recordDisplacedSegment` from inside Block emitters and from
`emitDisplacingStubs` after its per-file safety scan succeeds.

`emitDisplacingStubs`'s per-file scan is the only place that decides
whether a catalog-driven file is displaceable: if any entry is
`EB_TODO` or fails its Feature check, the whole file stays on clang
so the linker sees a single definition of every symbol the file
owns. Entries with `displaceFile = false` (today: the 11
`<Model>.c` leaf stubs) emit IR but never trigger displacement.

`CevalScriptBackend.compileModelToBitcode` calls
`SimCodeToLLVM.displacedSegmentFiles()` and skips matching files in
the clang loop. The keep-in-sync invariant is: any file present in
the catalog's set of distinct `segmentFile`s (excluding
`displaceFile = false` entries) must either be displaced for this
model (its catalog rows all passed safety + were emitted) or stay on
the clang path. `<Model>.c` itself is special and listed in the
roadmap above.

---

## 12. Empirical evidence for "this fixes / improves X" claims

For any change that claims to fix a bug or improve correctness:
build, run a real before/after on a reproducer that actually triggers
the issue, and include the evidence in the PR / commit message.
Structural pattern-match arguments alone are not enough; past
"theoretical fixes" have been wrong.

For correctness work the canonical test models are:

- `HelloWorld` (`Real x(start=1); equation der(x) = -x;`). The
  baseline simple ODE.
- `BouncingBall` (`testsuite/openmodelica/xml/BouncingBall.mo`). Adds
  zero crossings and event handling.
- A `delay()`-using model. Exercises the Feature warning path and
  the `_07dly.c` fallback.

For performance work:

- 10-run statistical sample on `HelloWorld` and `CoupledClutches`.
- JIT cache hot/cold split (first `simulate()` vs subsequent
  `simulate()` of the same model).

---

## 13. Commit conventions

Every JKRT-driven commit ends with:
```
JKRT refactor -- <one-line summary of the refactor's intent>
```
The commit body explains the change in terms of: what moved, why now,
how verified, and what the next concrete step is. No em-dashes, no
contractions.

The `Co-Authored-By: JKRT_CLAUDE <247156613+SVAGEN26@users.noreply.github.com>`
trailer is required on every commit. The default Claude trailer must
not appear.

No planning docs in the repo. Roadmap items live here in AGENTS.md;
in-progress decisions live in the conversation, `/tmp`, or memory.

---

## 14. Failure modes to recognize and reject

These are real patterns that have come up; do not repeat them.

- "Let me just add a `#ifdef OMC_SKIP_X` to the C runtime to make
  this work." No. Either CodegenC stops emitting it or the runtime
  exposes a generic entry point. No conditional compilation shrapnel.
- "I will spawn clang as a subprocess for this one file." No.
  Subprocess clang is the thing we are eliminating.
- "I will compile this small C string with libclang at runtime." No.
  Emit IR directly.
- "Let me write a `.bc` to disk and read it back." No. In-memory
  via `g_sctlBitcodeBytes`.
- "I will hardcode the struct offset, the layout never changes."
  No. `llvm_gen_layout.{c,h}` owns offsets via `offsetof`.
- "I will duplicate this Modelica feature string in three case
  arms." No. `FEATURE_NAME_*` constants, single point of definition.
- "Let me skip the Feature check; this model is fine." No.
  Feature predicates are mandatory whenever the stub body and the
  CodegenC body diverge for any non-trivial model.
- "I will write a small orchestrator script that knows about the JIT
  plus clang." No. Orchestrator scripts are shims.

If the right fix is more work than you want to do today, do less of
the right fix this commit. Do not do the wrong fix.
