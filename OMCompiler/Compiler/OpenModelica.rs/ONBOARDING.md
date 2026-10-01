# Onboarding: the Rust omc for MetaModelica developers

This guide is for people who know the OpenModelica compiler from the
MetaModelica side and are new to Rust. It covers the editor setup, where the
parts of the compiler you know ended up, what mmtorust does to your code, and
the rules for writing Rust here. Build instructions are in
[README.md](README.md).

The most important point first: **the MetaModelica sources are still the
source of truth.** The `.mo` files under `OMCompiler/Compiler/` are transpiled
to Rust by `mmtorust` on every build. To fix a bug in the frontend or backend
you usually still edit `.mo`. You write Rust only for the parts the C compiler
implemented in C (the runtime), for the build tools, and for the Rust-only
features.

## 1. VS Code and rust-analyzer

### Install

1. The pinned toolchain and the system packages from
   [README.md#setup](README.md#setup), including the `rust-analyzer`
   component.
2. VS Code extensions (inside WSL, install them in the "WSL" section of the
   extensions view, not "Local"):
   - **rust-analyzer** (`rust-lang.rust-analyzer`): completion, go to
     definition, inline types and errors.
   - **Even Better TOML** (`tamasfe.even-better-toml`): formats `Cargo.toml`
     with the repository's [`.taplo.toml`](../../../.taplo.toml).
   - **CodeLLDB** (`vadimcn.vscode-lldb`), optional: a debugger for Rust.
3. `taplo` for formatting TOML from the command line:
   `cargo install taplo-cli --locked`.

### Build once, then point rust-analyzer at the build copy

rust-analyzer cannot load `OMCompiler/Compiler/OpenModelica.rs` from a fresh
checkout. Most crates have no `src/lib.rs` until mmtorust has generated it, and
cargo refuses to load a workspace with a member that has no target (`no
targets specified in the manifest`). The CMake build never builds in the source
tree. It mirrors the sources into a per-build copy,
`<build>/OMCompiler/Compiler/rust-src/Compiler/OpenModelica.rs`, and generates
the code there (see `.cmake/rust_omc.cmake`).

So build once (README, "For development") and give rust-analyzer the build
copy's workspace. In `.vscode/settings.json` at the repository root, with
`build_cmake` replaced by your build directory:

```json
{
  "rust-analyzer.linkedProjects": [
    "build_cmake/OMCompiler/Compiler/rust-src/Compiler/OpenModelica.rs/Cargo.toml",
    "OMCompiler/SimulationRuntime/rust/Cargo.toml"
  ],
  // Use the rust-analyzer of the pinned nightly (absolute path, replace
  // <user>). The one bundled with the extension may not be able to expand the
  // proc macros (metamodelica_derive) compiled by this nightly.
  "rust-analyzer.server.path": "/home/<user>/.rustup/toolchains/nightly-2026-05-31-x86_64-unknown-linux-gnu/bin/rust-analyzer",
  "[rust]": { "editor.formatOnSave": true },
  "[toml]": { "editor.formatOnSave": true }
}
```

The second entry is the simulation runtime workspace. It has no generated code
and works straight from the checkout.

Be careful when you edit files. Go to definition takes you into the build copy,
and the build overwrites that copy:

| You want to change                       | Edit                                                                 |
| ---------------------------------------- | -------------------------------------------------------------------- |
| compiler logic (frontend, backend, ...)  | the `.mo` file under `OMCompiler/Compiler/`                          |
| a hand-written Rust file                 | the file under `OMCompiler/Compiler/OpenModelica.rs/` (in git)       |
| a generated Rust file                    | nothing: change the `.mo`, or mmtorust if the translation is wrong   |

A generated file starts with `// Auto-generated from MetaModelica source` and is
listed in [`.gitignore`](.gitignore). After editing, rebuild with CMake and
rust-analyzer picks up the new copy.

Tips:

- Ctrl+T (workspace symbol) finds a MetaModelica function by its name.
  mmtorust keeps the names, so `Util.getOption` is the Rust function
  `getOption` in `Util.rs`.
- The generated crates are very large, and rust-analyzer needs a few minutes
  and several GB of memory to index them the first time.
- rust-analyzer runs `cargo check` in the build copy with its own `target/`, so
  it does not lock or invalidate the CMake build's target directory.

## 2. Where did my module go?

### The rule

Every MetaModelica package declares the crate it belongs to:

```modelica
encapsulated package Util
  ...
  annotation(__OpenModelica_Interface="util");
end Util;
```

mmtorust maps the interface name `xyz` to the crate `openmodelica_xyz` (the
table is `interface_to_crate` in [`mmtorust/src/MM.rs`](mmtorust/src/MM.rs);
the exception is `parser`, which maps to `openmodelica_ast`). A package `Foo` in
`Foo.mo` becomes the module `<crate>/src/Foo.rs`. Functions, records and
constants keep their MetaModelica names. Each crate's `lib.rs` declares the
modules, so from another crate you write `openmodelica_util::Util::getOption`.

To find a package's crate, run `grep __OpenModelica_Interface Foo.mo`.

### Old directories to crates

The C build compiled everything into one binary. The Rust build splits it into
crates so that cargo can compile them in parallel and recompile only what
changed. The split follows the interface annotations, not the directories, so
some directories feed several crates:

| `OMCompiler/Compiler/...`   | Crate(s) (`openmodelica_` prefix omitted)                                                                                                      |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `FrontEnd/`                 | `frontend` (Inst, Lookup, Static, Ceval, ...), `frontend_dump` (Dump, SCodeUtil, AbsynUtil, ...), `frontend_base` (Expression, ComponentReference, Types, ...), `frontend_types` (DAE, SCode, Values, ClassInf), `frontend_inst`, `loader`, `dump_extra`, `script_util` |
| `FrontEnd/Absyn.mo`, `FrontEnd/ParserExt.mo`, `Script/GlobalScript.mo` | `openmodelica_ast` (interface `parser`), together with the hand-written Modelica parser. Generated, but kept in git because mmtorust itself depends on it |
| `FFrontEnd/`                | `frontend` (FGraph, FNode, FLookup, ...)                                                                                                     |
| `NFFrontEnd/`               | `nf_frontend` (all `NF*` modules); `NFApi.mo` → `nf_api`                                                                                      |
| `BackEnd/`                  | `backend` (BackendDAE*, Matching, Tearing, Initialization, ...), `backend_types` (BackendDAE, ZeroCrossings), `backend_util`, `backend_tools`   |
| `NBackEnd/`, `NSimCode/`    | `nbackend`                                                                                                                                   |
| `SimCode/`                  | `simcode_types` (SimCode, SimCodeVar, ...), `simcode_util`, `codegen_util`, `backend` (SimCodeUtil), `backend_main` (SimCodeMain)             |
| `Template/*.tpl`            | the `codegen_*` crates; see below                                                                                                            |
| `Script/`                   | `backend_main` (CevalScript*, Interactive, ...), `backend_tools`, `script_util`, `program_util`, `frontend`                                  |
| `Main/Main.mo`              | `backend_main`. The whole compiler is linked into `libopenmodelica_compiler` (`libOpenModelicaCompiler.so`, also loaded by OMEdit); the `omc` executable (`openmodelica` crate) is a thin launcher around it |
| `Util/`                     | mostly `util` (Util, Flags, Error, System, Print, ...), `util_datatypes_basic` (List, Array, DoubleEnded), `ast_collections`, `openmodelica_error` (ErrorExt, ErrorTypes; also kept in git), plus a few in `frontend*`, `backend`, `script_util` |
| `MidCode/`                  | `backend_tools`, `codegen_util`                                                                                                              |
| `Lexers/`, `Parsers/`       | `backend_tools`, `util`. The Modelica parser itself is hand-written Rust in `openmodelica_ast/src/parser/`                                    |
| `runtime/*.c` (C runtime)   | hand-written Rust: `openmodelica_util/src/System.rs`, `Print.rs`, `Settings.rs`, ..., `openmodelica_error` (errorext.cpp)                     |
| `Global/`                   | `openmodelica_util/src/Global.rs` (hand-written)                                                                                             |
| `SimulationRuntime/c/meta/` | the MetaModelica runtime (lists, strings, arrays, builtin functions such as `listReverse`) is the hand-written `metamodelica` crate          |
| `SimulationRuntime/c/`      | the Rust simulation runtime in `OMCompiler/SimulationRuntime/rust/` (solvers, result writers, ...)                                           |

`Stubs/` is only used to bootstrap the C build and is not transpiled.

### Templates (Susan)

In the C build, `susan` turned `CodegenC.tpl` into `CodegenC.mo`, which omc
then compiled. In the Rust build, `susan` writes Rust directly:
`Template/CodegenC.tpl` becomes `openmodelica_codegen_c/src/CodegenC.rs`, and
the crate again comes from the template's `__OpenModelica_Interface`
(`codegen_c`, `codegen_cpp`, `codegen_fmu`, ...). mmtorust skips these
packages. Template functions show up as `fn lm_61(...)` helpers and functions
that thread `Tpl::Text` through `Tpl::writeTok(...)` calls.

### Hand-written Rust

Some packages cannot be generated, because their bodies are `external "C"` in
MetaModelica and the C compiler linked them against C. These are written in Rust
directly and mmtorust does not generate them. The list is
`HANDWRITTEN_TOP_PACKAGES` in [`mmtorust/src/codegen.rs`](mmtorust/src/codegen.rs):
`System`, `Print`, `Settings`, `File`, `Global`, `ErrorExt`, `Mutable`,
`Pointer`, `Vector`, ... Every `external "C"` function must also be listed in
[`mmtorust/src/external_c_calls.rs`](mmtorust/src/external_c_calls.rs), which
says whether it can fail (see "Fallibility" below).

## 3. How mmtorust works

### Pipeline

```
compilerSources.txt (.mo files)
  │  parse with the Rust parser (openmodelica_ast)
  │  splice in X.rust.mo overrides                     (overrides.rs)
  ▼
MM classes  ──  hierarchy: resolve names, flatten extends, find recursive types,
  │             types containing Mutable/array/function values
  │  analyses:  fallibility     which functions can fail → `Result<T>` or `T`
  │             borrow_params   which parameters can be `&T` instead of `T`
  │             visibility      `pub` vs `pub(crate)`
  │             const_patterns, mutable_cycles, unused_functions, ...
  ▼
codegen (one file per top-level package, in parallel)   (codegen.rs, typedexp.rs)
  │  + `<Package>.handwritten.rs` replacements
  ▼
rustfmt (rustfmt.rs)  →  <crate>/src/<Package>.rs  and  <crate>/src/lib.rs
```

Files are written only when their content changed, so cargo recompiles only the
crates whose generated code is actually different.

### Types

| MetaModelica                   | Rust                                                                                       |
| ------------------------------ | ------------------------------------------------------------------------------------------ |
| `Integer`                      | `i32` (MMC uses 63 bits; overflow wraps, as in the C runtime)                              |
| `Real`                         | `f64` in signatures; `metamodelica::Real` (`OrderedFloat<f64>`) in records, so records can be compared and hashed |
| `Boolean`                      | `bool`                                                                                     |
| `String`                       | `ArcStr` (reference-counted, cheap to clone)                                               |
| `list<T>`                      | `metamodelica::List<T>` (`Nil` / `Cons { head, tail }`)                                     |
| `Option<T>`                    | `Option<T>` (`SOME(x)` → `Some(x)`, `NONE()` → `None`)                                      |
| `array<T>`                     | `metamodelica::Array<T>` (`Rc<RefCell<Vec<T>>>`, mutable and shared)                       |
| `tuple<A, B>`                  | `(A, B)`                                                                                   |
| `uniontype` with records       | `enum`, one variant per record; recursive fields are behind `metamodelica::Ref` (an `Arc`) |
| `uniontype` with one record    | `struct`, plus `type RECORDNAME = Struct;`                                                 |
| function type / `partial function` | `&dyn Fn(...) -> Result<T>` (parameter) or `Arc<dyn Fn ...>` (stored)                  |
| polymorphic `<T>`              | generic `<T: Clone + 'static + MMTrace>`                                                   |
| `Mutable<T>`, `Pointer<T>`     | hand-written cell types `Mutable::Mutable<T>`, `Pointer::Pointer<T>`                       |
| `fail()`, failed match         | `return Err("...")`, passed up to callers with `?`                                         |

### Example: a uniontype

```modelica
public uniontype Status "Used to signal success or failure of a function call"
  record SUCCESS end SUCCESS;
  record FAILURE end FAILURE;
end Status;
```

```rust
/// Used to signal success or failure of a function call
#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Status {
    SUCCESS,
    FAILURE,
}
// ... generated impls of MMTrace (for the cycle collector) and Default ...
pub use self::Status::{FAILURE, SUCCESS};
```

The string comment becomes a doc comment (`///`), which rust-analyzer shows on
hover. The `pub use` lets other code write `Util.SUCCESS()` as `Util::SUCCESS`,
as in MetaModelica.

### Example: fallibility

Two functions from `Util/Util.mo`. One can fail, the other cannot:

```modelica
public function getOption<T>
  "Returns an option value if SOME, otherwise fails"
  input Option<T> inOption;
  output T outValue;
algorithm
  SOME(outValue) := inOption;
end getOption;

public function getOptionOrDefault<T>
  "Returns an option value if SOME, otherwise the default"
  input Option<T> inOption;
  input T inDefault;
  output T outValue;
algorithm
  outValue := match inOption
    local
      T value;
    case SOME(value) then value;
    else inDefault;
  end match;
end getOptionOrDefault;
```

```rust
pub fn getOption<T: Clone + 'static + metamodelica::gc::MMTrace>(mut inOption: Option<T>) -> Result<T> {
    let mut outValue: T;
    let __pa0 = ::match_deref::match_deref! { match &(inOption) {
        Some(__pa0) => __pa0.clone(),
        _ => return Err("pattern mismatch"),
    } };
    outValue = metamodelica::Own::own(__pa0);
    Ok(outValue)
}

pub fn getOptionOrDefault<T: Clone + 'static + metamodelica::gc::MMTrace>(
    mut inOption: Option<T>,
    mut inDefault: T,
) -> T {
    let mut outValue: T;
    outValue = (match inOption {
        Some(mut value) => value,
        _ => inDefault,
    });
    outValue
}
```

MetaModelica functions can always fail. Rust has no such hidden control flow:
a function that can fail returns `Result<T>`, and every caller has to deal with
the error, usually by passing it on with `?`. The fallibility analysis
classifies each function. `getOption` contains a pattern that can fail, so it
returns `Result<T>`. `getOptionOrDefault` cannot fail, so it returns a plain
`T` and its callers need no `?`. A function is fallible if it can call `fail()`,
has a non-exhaustive `match` or pattern assignment, a `matchcontinue` whose
cases can all fail, or calls something fallible (including `external "C"`
functions classified as fallible in `external_c_calls.rs`). Making
a commonly used function infallible (for example by adding an `else` case)
removes error checks from all of its callers.

The output variable becomes a local and the function ends with `Ok(outValue)`,
which is why generated code reads like the MetaModelica code it came from.

### Example: matchcontinue

```modelica
public function stringDelimitListPrintBuf
  input list<String> inStringLst;
  input String inDelimiter;
algorithm
  () := matchcontinue inStringLst
    local
      String f;
      list<String> r;
    case {} then ();
    case {f} algorithm Print.printBuf(f); then ();
    case f :: r
      algorithm
        stringDelimitListPrintBuf(r, inDelimiter);
        Print.printBuf(f);
        Print.printBuf(inDelimiter);
      then ();
  end matchcontinue;
end stringDelimitListPrintBuf;
```

```rust
pub(crate) fn stringDelimitListPrintBuf(
    mut inStringLst: &metamodelica::List<ArcStr>,
    mut inDelimiter: &ArcStr,
) -> Result<()> {
    let () = 'mc: {
        let __mc_input = &**inStringLst;
        if let Ok(__v) = (|| -> Result<_> {
            ::match_deref::match_deref! { match &__mc_input {
                Deref @ metamodelica::ListNode::Nil => {
                    Ok(())
                }
                _ => return Err("nomatch"),
            }}
        })() {
            break 'mc __v;
        }
        // ... the same for `{f}` and `f :: r` ...
        return Err("matchcontinue: no arm matched");
    };
    Ok(())
}
```

Each case becomes a closure. If a case fails, its `Err` is discarded and the
next case is tried, which is exactly the backtracking of `matchcontinue`. This
costs more than a plain `match`. mmtorust reports every `matchcontinue` that
could safely be a `match`, and `mmtorust --fix` rewrites those in the `.mo`
sources.

Also visible here:

- `borrow_params` found that the list and the delimiter are only read, so they
  are passed as `&` references (borrowed) instead of being moved or cloned.
- The visibility analysis found no caller outside the crate, hence
  `pub(crate)`.
- rustfmt does not format inside macro calls such as `match_deref! { ... }`,
  so those blocks keep mmtorust's own layout.

### Changing what mmtorust generates

| Need                                                    | Mechanism                                                                                                                         |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Implement a few items of a package in Rust              | `<Package>.handwritten.rs` next to the generated file, with `// mmtorust-replaces: a b` and `// mmtorust-drops: c` header lines (examples: `openmodelica_util/src/Flags.handwritten.rs`, `openmodelica_tpl/src/Tpl.handwritten.rs`) |
| A different declaration for Rust only                   | `X.rust.mo` next to `X.mo` replaces single records/functions before analysis; the C build never reads it ([`mmtorust/src/overrides.rs`](mmtorust/src/overrides.rs)) |
| A construct the Rust port does not need                 | `annotation(__OpenModelica_Retired = true)` on the class                                                                          |
| A new `external "C"` function                           | implement it in the hand-written module and register it in `external_c_calls.rs`                                                  |
| A translation bug                                       | fix `mmtorust/src/codegen.rs` / `typedexp.rs`. Run `cmake --build <build> --target rust_codegen` to regenerate, and compare with `MMTORUST_RUSTFMT=off` if you want the raw output |

## 4. Style guide

### Formatting is automatic

- **rustfmt** formats all Rust ([`rustfmt.toml`](rustfmt.toml), width 120) and
  **taplo** formats all TOML ([`.taplo.toml`](../../../.taplo.toml)). CI
  (`.github/workflows/rust-format.yml`) rejects unformatted files.
- Before committing, run [`./format.sh`](format.sh) (or `./format.sh --check`).
  It works on a clean checkout. `cargo fmt` only works in the build copy,
  because it needs a loadable workspace.
- Generated code is formatted by mmtorust and susan themselves, so it looks the
  same as hand-written code.
- Put formatting-only changes in their own commit.

### Generated code

- Never edit generated files. Your change is lost on the next build, and the
  files are not in git anyway.
- Generated code keeps MetaModelica naming (`camelCase` functions, `UPPER`
  record names) and allows the matching lints (`non_snake_case`, ...). Do not
  "fix" the names.

### Hand-written code

- **Naming.** Code that replaces a MetaModelica item keeps its MetaModelica
  name and signature, because generated callers use `Package::item`. Everything
  else uses normal Rust naming: `snake_case` for functions, variables and
  modules, `CamelCase` for types, `SCREAMING_SNAKE_CASE` for constants.
- **Signatures must match the `.mo` declaration**, including whether the
  function can fail. A replacement that returns `T` where the `.mo` version can
  fail (or the reverse) does not compile against the generated callers.
- **Errors.** Report failure that MetaModelica code can observe as
  `metamodelica::Result<T>` (`Err(&'static str)`) and pass errors on with `?`.
  Use `panic!`, `unwrap()` and `expect()` only for broken invariants, never for
  user input or I/O. Report messages for the user through `Error`/`ErrorExt`,
  the same as in MetaModelica.
- **Integers.** `Integer` is `i32`, and overflow wraps (the dev profile sets
  `overflow-checks = false` to match the C runtime and release builds). Use
  `wrapping_*` explicitly where you depend on wrapping.
- **Cloning.** MetaModelica values are reference-counted (`Arc`, `ArcStr`,
  `List`), so `.clone()` copies a pointer, not the data. Cloning is the normal
  way to deal with ownership errors here. Avoid real deep copies (`Vec` of
  large data) in hot paths.
- **Comments.** Explain why, not what. Give public items a `///` doc comment.
  When porting C code, name the original file
  (`// mirrors OMCompiler/Compiler/runtime/printimpl.c`), as the existing files
  do.
- **`unsafe`** only for FFI and with a `// SAFETY:` comment that explains why
  it is sound.
- **Dependencies.** Add new crates to `[workspace.dependencies]` in
  [`Cargo.toml`](Cargo.toml) with a comment saying what they are for, and refer
  to them with `foo.workspace = true` in the crate. `check-unused-deps.py` finds
  dependencies that are no longer used.
- **Tests.** Unit tests live in `src/unittests/` of the crate (for example
  `openmodelica_frontend_dump/src/unittests/`). Run them with
  `cargo test -p <crate>` in the build copy. The testsuite runs through ctest
  (README).

## 5. A few Rust terms

| You see                 | Meaning                                                                                       |
| ----------------------- | --------------------------------------------------------------------------------------------- |
| `&T` / `&mut T`         | a borrowed reference; the caller still owns the value                                         |
| `?`                     | "if this is `Err`, return it from the current function", MetaModelica's implicit failure, made explicit |
| `Result<T>`             | either `Ok(value)` or `Err(reason)`                                                           |
| `'mc: { ... break 'mc v }` | a labelled block that produces the value `v`                                               |
| `impl Trait for Type`   | Type implements an interface (Trait); `#[derive(...)]` generates common ones                  |
| `pub(crate)`            | visible inside the crate only, like `protected` at package level                              |
| `Rc`/`Arc`, `RefCell`   | shared ownership (single-threaded / thread-safe); interior mutability                         |
| `macro!(...)`           | a macro call (`literal!`, `match_deref!`, `format!`)                                          |

The Rust Book (<https://doc.rust-lang.org/book/>) chapters 4 (ownership), 6
(enums and `match`), 9 (error handling) and 10 (generics and traits) cover
almost everything you meet in the generated code.
