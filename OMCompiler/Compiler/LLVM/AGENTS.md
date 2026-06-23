# AGENTS.md — OMCompiler/Compiler/LLVM

Conventions for code in this folder and in the matching C++ runtime
under `OMCompiler/Compiler/runtime/llvm_gen{.cpp,.hpp,_util.hpp,_wrappers.{c,h}}`.

## Vision

**SimCode → LLVM IR in memory → LLJIT in-process → simulation.**
The compiler emits native code through the LLVM IR pipeline
directly; no C source, no clang invocation, no `.c` / `.bc` files
on disk in the default path. The current CodegenC + clang
pipeline is **legacy** and is being replaced piece by piece by
SCTL IR emission.

This is non-negotiable:

- The compiler does not generate C. New entry points, new
  equations, new data tables — all of it is LLVM IR built by
  SimCodeToLLVM via the EXT_LLVM primitives. If a proposal
  involves "emit C and have clang compile it", that proposal
  is out of scope. "Embed clang as a library to speed up the
  C path" is also out of scope: clang has no role in the final
  vision.
- Pre-compiled C runtime libraries that already exist on the
  system are fine to call into: libSimulationRuntimeC,
  libModelicaStandardTables, libModelicaIO, libModelicaMatIO,
  libModelicaExternalC, libm, libc. The JIT loads them with
  `LoadLibraryPermanently` and the LLJIT's
  `DynamicLibrarySearchGenerator` resolves symbol references in
  the SCTL bitcode to those libraries at link time. The SCTL
  module never re-emits any of their code; it just emits calls
  to them.
- Optional AoT side-effect: `+d=jit_dump_ir` writes the IR to
  a `.ll` / `.bc` file for inspection or external linking. That
  is for debug / tooling, not the path the JIT executes from.

The CodegenC `<Model>.c` / `<Model>_NN.c` / `_functions.c` /
`_records.c` output and the `<Model>_jitcompile.sh` clang
fan-out + `llvm-link` step exist only as a transitional shim
that fills in the entry points SCTL has not yet displaced.
Every commit that adds an SCTL-emitted entry point removes one
or more `.c` segments from the clang loop. The end state is
zero `.c` segments and the transitional shim deleted.

## Scope

This package owns the SimCode → LLVM IR / LLJIT path:

- `EXT_LLVM.mo` — MetaModelica external-function bindings into
  `omcruntime`'s `llvm_gen.*` C++ glue.
- `MidToLLVM.mo`, `MidToLLVMUtil.mo` — Mid-code → LLVM IR lowering used by
  the function-JIT (`+d=jit_eval_func`) and reused by `SimCodeToLLVM`.
- `SimCodeToLLVM.mo` — SimCode → in-memory LLVM module emission for the
  `+d=jitSimulate` simulation path.

The C++ side lives in `Compiler/runtime/llvm_gen.cpp` and is the single
LLVM-API consumer. Stubs in `Compiler/Stubs/{EXT_LLVM,SimCodeToLLVM,MidToLLVM}.mo`
keep the dependency optional; signatures here must round-trip cleanly
with the stub package.

## Roadmap to the vision

A SimCode → IR pipeline reaches the vision when SimCodeToLLVM
emits, for every model:

1. Per-equation function bodies for the **dynamic** equations
   (today only init equations get per-eq lowering; dynamic eqs
   still come from CodegenC).
2. `setupDataStruc` as LLVM constants — the static `MODEL_DATA`,
   the `STATIC_REAL_DATA` arrays, the var-info tables, etc., all
   emitted as IR globals at codegen time.
3. The callback function-pointer table as an LLVM constant
   struct populated with the addresses of the SCTL-emitted entry
   points.
4. Record descriptors (the `struct record_description` data
   that today lives in `_records.c`) as LLVM globals.
5. User-defined Modelica function bodies through
   `DAEToMid + MidToLLVM` directly into the SCTL module. The
   `external "C"` functions resolve via the process symbol
   generator instead of being re-emitted.
6. An entry shim that replaces `main` so the JIT can call into
   the model without the CodegenC driver. The simulation runtime
   (DASSL et al.) is already linked into omc, so we only need to
   hand it the same `DATA*` the driver would have.

Once those exist, the `compileModelToBitcode` step disappears:
no `<Model>.c`, no `<Model>_NN.c`, no `<Model>.makefile`, no
clang fork/exec, no `<Model>.bc` on disk. The SCTL bitcode is
the only LLVM module added to the LLJIT, and `lookup("main")`
returns the SCTL-emitted entry point.

Every commit should either advance one of those six items or
solidify the IR-emit primitives that those items will rely on.
"Make clang faster" is a dead end.

## Style rules

### Type declarations

Declare full types. Avoid `auto`.

Reason: readability across the MetaModelica / C++ interop boundary,
auditable lifetime semantics (especially for the LLJIT cache and the
`std::unique_ptr<llvm::orc::LLJIT>` ownership chains), and easier review
diffs when the LLVM API shifts between releases. `auto` hides the
distinction between `Expected<X>`, `unique_ptr<X>`, raw `X*`, and `X`,
all of which appear together in the JIT setup. Spell them out.

OK:

```cpp
std::unique_ptr<llvm::orc::LLJIT> jit = std::move(*jitOrErr);
llvm::Expected<llvm::orc::ExecutorAddr> mainSym = jit->lookup("main");
llvm::Type *retTy = getLLVMType(type, structName);
```

Not OK:

```cpp
auto jit = std::move(*jitOrErr);          // unique_ptr<LLJIT> hidden
auto mainSym = jit->lookup("main");       // Expected<ExecutorAddr> hidden
auto retTy = getLLVMType(...);            // Type* hidden
```

Exceptions:

- Range-based `for` loop variables where the type is obvious from the
  range expression (`for (llvm::Argument &arg : f->args())` is fine).
- Lambdas captured by `auto` because there is no nameable type for them.
- Iterators with verbose nested template types when the surrounding code
  makes the element type obvious.

### Const-correctness

Apply `const` aggressively in both C and C++:

- **Function arguments that are not modified.** Pointer / reference
  parameters take `const` unless the function intentionally writes
  through them. `const char *name` not `char *name`. Same for
  `const std::string &s` over `std::string &s` when the function only
  reads. C `offsetof()`-helper exports are `extern const size_t ...`,
  never plain `extern size_t ...`.
- **Local variables that are assigned once.** Local `llvm::Type *`,
  `llvm::Value *`, `size_t`, etc. that are computed once and read
  many times take `const`. Local raw pointers into the LLVM IR (e.g.
  the result of `getelementptr`) similarly take `const`.
- **Pointer-to-const through structural chains.** If the function
  reads `data->localData[0]->realVars[idx]`, the chain pointers
  should be `const SIMULATION_DATA *`, `const modelica_real *`, ...
  Avoid casting away const just to call a non-const-correct callee;
  fix the callee instead.
- **Member functions in C++ helpers.** Mark const if they don't
  mutate `*this`. The runtime-side `Variable::getAllocaInst()`,
  `isVolatile()`, and similar accessors must be const.
- **C++ references over pointers when nullability is not part of
  the contract.** A `const llvm::Module &mod` better expresses
  "must be valid, won't be modified" than `const llvm::Module *mod`.

Two things `const` does NOT cover here:

- LLVM API objects (`llvm::IRBuilder<>`, `llvm::Function*` returned
  by `getFunction()`, ...) often must be non-const because the API
  is not const-clean. That's a library limitation; do not paper over
  it by casting. Pass them through as the LLVM API expects.
- `std::unique_ptr<T>` moved into a container — the unique_ptr is
  non-const at the call site so it can be `std::move`'d. Const goes
  on the *pointee* type instead: `std::unique_ptr<const T>` where
  the value is read-only after construction.

### Immutable records without fields

Modelica-style: cache singleton instances of no-field records and route
through `referenceEqual` (or pattern matching, which compiles to the
same tag check). Do not allocate a fresh `VK_STATE()` etc. on every call
site. See `VKS_STATE` and friends in `SimCodeToLLVM.mo`.

### MMC failures vs C++ exceptions

The LLVM C++ side raises failures via `MMC_THROW()`. Never abort the
process for recoverable conditions (missing variable in symtab, unknown
type, malformed bitcode). The MetaModelica caller catches the throw via
`try ... else ... end try` and routes the failing block to the legacy
buildModel fallback. Add a diagnostic `fprintf(stderr, ...)` next to
every `MMC_THROW()` so users see what went wrong.

### Symbol-name mangling

Always use `modelSymbolPrefix(modelName)` in `SimCodeToLLVM.mo` (which
routes through `System.makeC89Identifier(AbsynUtil.pathString(...))`)
when building C symbol names for an `Absyn.Path`. Never use
`pathStringUnquoteReplaceDot(name, "_")` — it doubles embedded
underscores, so `Modelica.Blocks.Examples.PID_Controller` mangles to
`PID__Controller` in the IR while CodegenC produces `PID_Controller` in
the clang'd C, breaking JIT linkage.

### Alloca symtab keys

`allocaDouble` / `allocaInt` / `allocaBoolean` / `allocaInt8PtrTy` /
`allocaInt8PtrPtrTy` MUST key the C++ `symTab` by the **requested** name
(the `name` argument), not by `alloci->getName()`. LLVM appends a
numeric suffix silently when the requested name collides with an
existing value in the same function; SCTL's downstream
`createStoreInst` / `createLoadInst` / `binopInit` look the alloca back
up by the originally-requested name and must find it.

### freshTmp and per-function scope

`SimCodeToLLVM.freshTmp` produces `"%t_N"` names that may collide with
LLVM-internal names within the same function (LLVM auto-renames in that
case; see the symtab-key rule above). Each `startFuncGen` is a fresh
function scope so the per-`ctx` tmpCounter resets cleanly. Do not share
an `EmitCtx` across `startFuncGen` boundaries.

### Per-block displacement order

In `genSim` Pass 2 the per-block emit calls (`emitInitialEquationsBlock`,
`emitBoundParametersBlock`, `emitEventBlock`, `emitJacobianBlock`) are
wrapped in `try ... else end try`. Inside each, emit the function body
first and call `recordDisplacedSegment(...)` only after the body
finished cleanly. If you record the displacement first and then the
emission throws, the JIT module ends up with a partial / un-terminated
function while the corresponding `.c` file is still skipped from clang
— LLVM's optimiser then crashes on the malformed IR.

### Stub package parity

Anything added to `LLVM/EXT_LLVM.mo` that is also referenced from
outside this folder (`CevalScriptBackend`, `SimCodeMain`, ...) must have
a matching stub in `Stubs/EXT_LLVM.mo`. Same for `SimCodeToLLVM` and
`MidToLLVM`. The CI builds with `OPENMODELICA_LLVM_JIT != "Yes"` by
default and loads the stub package; missing stub functions surface as

    Error: Class EXT_LLVM.<fname> not found in scope
           CevalScriptBackend.runModelViaLLVMJIT

at the boot-omc compile step.

### Loading sources gate

The `if ... then llvmfiles ... else stubs ...` selector in
`LoadCompilerSources.mos` is parsed by the older bootstrap omc Jenkins
uses. That parser is stricter than the locally-built omc and rejects
chained `==`/`<>` combinations with parentheses. Mirror the
`backendfiles` shape exactly: a single env-var check with the same
operator. Compound conditions trip the cryptic

    Type error in conditional 'true'. Expected Boolean, got Boolean.

which then cascades into `writeFile not found` from `MakeSources.mos`
and breaks the bootstrap-from-tarball build before reaching the C
codegen.

## Performance principles

- Parallel clang for the model's per-segment `.c → .bc` compiles in
  `CevalScriptBackend.compileModelToBitcode`. The per-process clang
  startup cost dominates for trivial-but-numerous segments.
- LLJIT cache keyed on `modelName` in `omc_runModelViaJIT` so a repeated
  `simulate()` in the same omc session collapses to a `lookup("main")`
  plus the model run.
- SCTL emits the in-memory module via `stashCurrentModuleAsBitcode` and
  hands it to the C++ runtime through a process-global `vector<char>`.
  No disk hop for the SCTL-emitted half of the model.
- Symbol prefix `modelSymbolPrefix` must match CodegenC's
  `makeC89Identifier` exactly so the JIT linker resolves cross-file
  references between the SCTL-emitted IR and the clang'd C segments.

## When NOT to displace a CodegenC `.c` segment

The dynamic-skip list (`displacedSegmentFiles`) is the single source of
truth for which `<Model>_NN.c` files SCTL has taken over. Adding a file
to that list without emitting every symbol the file would have provided
makes the JIT link fail with a "Symbols not found" error. The catalog
in `runtimeEntryCatalog()` is the authoritative list of pure-stub
entries SCTL produces unconditionally; the per-block emitters
(`emitInitialEquationsBlock` et al.) record their displacement inside
the block only after every emission step has succeeded.
