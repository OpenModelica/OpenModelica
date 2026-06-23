# AGENTS.md — OMCompiler/Compiler/LLVM

Conventions for code in this folder and in the matching C++ runtime
under `OMCompiler/Compiler/runtime/llvm_gen{.cpp,.hpp,_util.hpp,_wrappers.{c,h}}`.

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
