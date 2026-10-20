# Instructions for coding agents

This file is for AI coding agents (and the humans steering them) working on
OpenModelica. Read [CONTRIBUTING.md](CONTRIBUTING.md) as well; everything in it
applies to agent-written changes too. When this file and a more specific README
disagree, the README closer to the code wins. Some directories have their own
AGENTS.md with what applies only there, e.g.
[OMCompiler/SimulationRuntime/c/AGENTS.md](OMCompiler/SimulationRuntime/c/AGENTS.md).

If you are unsure about a design decision, ask the human you are working with
instead of guessing. Pull requests are reviewed by people, so a small change
that does one thing is far more likely to be merged than a large one.

## Repository layout

OpenModelica.git is a superproject with submodules.
Update with `git submodule update --init --recursive`.

| Path                                   | Contents                                            |
| -------------------------------------- | --------------------------------------------------- |
| `OMCompiler/Compiler/`                 | The compiler `omc`, written in MetaModelica (`.mo`) |
| `OMCompiler/Compiler/NFFrontEnd/`      | The (new) frontend: instantiation and flattening    |
| `OMCompiler/Compiler/BackEnd/`         | The old backend                                     |
| `OMCompiler/Compiler/NBackEnd/`        | The new backend (`--newBackend`)                    |
| `OMCompiler/Compiler/Template/`        | Code generators, Susan templates (`.tpl`)           |
| `OMCompiler/Compiler/Script/`          | The scripting API (`CevalScriptBackend.mo`, ...)    |
| `OMCompiler/Compiler/boot/`            | `bomc`, the bootstrapping compiler                  |
| `OMCompiler/Compiler/OpenModelica.rs/` | Experimental Rust port of `omc` (off by default)    |
| `OMCompiler/SimulationRuntime/c/`      | The C simulation runtime (`C`, the default)         |
| `OMCompiler/SimulationRuntime/rust/`   | The Rust simulation runtime (`C+Rust`, `wasm-jit`)  |
| `OMCompiler/SimulationRuntime/cpp/`    | The C++ simulation runtime                          |
| `OMEdit/`, `OMShell/`, `OMPlot/`, ...  | The Qt GUI clients                                  |
| `testsuite/`                           | The regression testsuite                            |
| `libraries/`                           | The pinned Modelica libraries used by the testsuite |

## Building

CMake is the only build system. The default build is the bootstrapped C
compiler: `bomc` is built from pre-translated C sources and then translates
`OMCompiler/Compiler/**/*.mo` into `omc`. Platform dependencies are listed in
[OMCompiler/README.Linux.md](OMCompiler/README.Linux.md),
[OMCompiler/README-macOS.md](OMCompiler/README-macOS.md) and
[OMCompiler/README.Windows.md](OMCompiler/README.Windows.md); the options are in
[README.cmake.md](README.cmake.md). By default, assume dependencies are installed;
if they are not, ask the user how they should be installed (by you or the user).

```sh
cmake -S . -B build_cmake -DCMAKE_BUILD_TYPE=Release -DOM_ENABLE_GUI_CLIENTS=OFF
cmake --build build_cmake --target install --parallel <N>
```

- Always build the `install` target and run the installed
  `build_cmake/install_cmake/bin/omc`. `omc` locates its libraries, builtin
  files and runtime relative to the install tree; binaries in the build tree
  do not work on their own.
- Turn off what you do not need to keep the build short:
  `-DOM_ENABLE_GUI_CLIENTS=OFF` unless you work on a GUI client,
  `-DOM_OMC_ENABLE_CPP_RUNTIME=OFF` unless you work on the C++ runtime,
  `-DOM_ENABLE_OMSIMULATOR=OFF` unless you need OMSimulator.
- To only type-check MetaModelica changes, build the `OpenModelicaCompiler`
  target. `bomc` checks interfaces and unused/undefined variables, so a
  successful build catches most mistakes. Do this before running any tests.
- Build one target at a time and do not run the testsuite while building. Both
  are memory hungry.
- `rtest` looks for `omc` in `build_cmake/install_cmake` or
  `build/install_cmake` (see [Running tests](#running-tests)). If you use a
  different build directory, do not edit `testsuite/rtest`; use one of those
  names or a symlink.

## Running omc

`omc` is mostly driven by `.mos` scripts:

```modelica
loadModel(Modelica, {"4.1.0"}); getErrorString();
loadString("
model M
  Real x(start = 1);
equation
  der(x) = -x;
end M;
"); getErrorString();
simulate(M, stopTime = 1); getErrorString();
```

```sh
build_cmake/install_cmake/bin/omc script.mos
```

- Call `getErrorString()` after each call; errors are otherwise silent.
- `omc --help` and `omc --help=debug` list the flags, e.g. `-d=failtrace`.
- Libraries are installed with the package manager,
  `installPackage(Modelica, "4.1.0")`, into `$HOME/.openmodelica/libraries`.
  Load with an explicit version so that the result does not depend on which
  versions happen to be installed.
- A simulation can hang. Run ad-hoc `omc` invocations under `timeout`.

## Running tests

### Dependencies (libraries and reference files)

The testsuite runs against a pinned set of Modelica libraries listed in
[libraries/index.json](libraries/index.json). Install them, `omc-diff` and the
reference result files with an already built and installed `omc`:

```sh
cmake --build build_cmake --target testsuite-depends --parallel <N>
```

This downloads the libraries into `libraries/.openmodelica/libraries`, which
`rtest` uses as `HOME` and `OPENMODELICALIBRARY`.

- Re-run `testsuite-depends` (or only `libs-for-testing`) whenever
  `libraries/index.json` changes, e.g. after rebasing. Test output that only
  differs in which library version was loaded ("Automatically loaded package
  Complex 3.2.1" instead of 4.1.0, "Failed to load package ...") means the
  installed libraries are stale, not that `omc` or the test is broken.
- Never `installPackage` anything into `libraries/.openmodelica/libraries`
  yourself: every test that loads a library without a version would pick it
  up. Use your own `HOME` for exploratory libraries.
- A library the testsuite needs is added through
  [libraries/update.py](libraries/update.py); see
  [libraries/README.md](libraries/README.md). That is a separate PR.

### rtest and runtests.pl

Tests are `.mo`/`.mos` files whose expected output is a comment at the end of
the file. Each directory's `Makefile` lists the tests that run in
`TESTFILES`; the other lists (`FAILINGTESTFILES`, ...) are tests that are
known to fail or hang, tagged `// suite: disabled`. Do not run those unless you
are working on them. See [testsuite/README.md](testsuite/README.md).

```sh
cd testsuite/flattening/modelica/scodeinst
../../../rtest MyTest.mos       # one test; -v shows the diff
../../../rtest -b MyTest.mos    # write the actual output into the test
```

- `rtest` compares numbers with a tolerance, so a plain diff of the output is
  not the same check.
- `rtest` cannot run concurrently with other `rtest` runs. For several tests,
  list them (paths relative to `testsuite/`) in a file and use partest:

  ```sh
  cd testsuite/partest
  ./runtests.pl -file=tests.txt -j<N>
  ```

  A failing test leaves a log file to read. `./runtests.pl -h` lists the
  options. The full testsuite is slow and CI runs it on every PR, so locally
  run the tests related to your change.
- Check the tests you touched with partest before pushing, even if `rtest`
  passes: partest, like CI, runs each test in a `<test>_temp<N>` copy one
  directory deeper and links its dependencies in, so relative paths and extra
  files a test uses only resolve correctly there.
- Update expected output (`rtest -b`) only after reading the diff and
  understanding why it changed. Never rebaseline to make a regression pass.
- Simulation reference files must be small: use `filterSimulationResults` to
  keep only the needed variables and points (see CONTRIBUTING.md).
- New tests go in the directory that matches what they test and are added to
  `TESTFILES` in its `Makefile`. Extra files a test needs go in
  `DEPENDENCIES`.
- Tests that build external C code use `$OMC_CC` and the other variables
  documented in [testsuite/README.md](testsuite/README.md), not `gcc`.

### Simulation targets

A change must pass the testsuite with three values of `--simCodeTarget`:

| Target     | Runtime                                    | `omc` built with          |
| ---------- | ------------------------------------------ | ------------------------- |
| `C`        | `SimulationRuntime/c/` (the default)       | the default options       |
| `C+Rust`   | `SimulationRuntime/rust/`, linked natively | the default options       |
| `wasm-jit` | `SimulationRuntime/rust/`, JIT-compiled    | `-DOM_OMC_ENABLE_RUST=ON` |

```sh
cd testsuite/partest
./runtests.pl -file=tests.txt -j<N> -simCodeTarget=C+Rust
cd ../flattening/modelica/scodeinst
OPENMODELICA_TEST_SIMCODETARGET=C+Rust RTEST_OMCFLAGS=--simCodeTarget=C+Rust \
  ../../../rtest MyTest.mos
```

Only the Rust port of `omc` implements `wasm-jit`; it needs the toolchain
described in [README.cmake.md](README.cmake.md). If you change the simulation
runtime or code generation and cannot build it, say so and leave `wasm-jit`
to CI.

### CI

Jenkins runs the full testsuite on every PR at
<https://test.openmodelica.org/jenkins/>, once per simulation target (`C`,
`C+Rust` and `wasm-jit`). When a test fails there, read its log rather than
guessing; the failure is often platform or library specific.
Windows and macOS builds are only run when the PR has the
`CI/Build MSYS2-UCRT64` or `CI/Build OSX` label.

Some failures only show up in CI because the default local build does not
build the Rust port of `omc`:

- `OMCompiler/Compiler/OpenModelica.rs` transpiles each package into the crate
  named by its `__OpenModelica_Interface` annotation. A new backend file
  (`"nbackend"`) must not import an old backend package (`"backend"`), as
  `openmodelica_nbackend` does not depend on `openmodelica_backend`. Code
  shared by both backends goes in `SimCode/SimCodeUtilShared.mo`.
- A new root index in `Global/Global.mo` needs its hand-written `thread_local`
  in `OpenModelica.rs/openmodelica_util/src/Globals.rs`, and its reset in
  `Global.rs` if `Global.initialize` resets it.
- The modules listed in `WASM_GATED_TOP_MODULES` in
  `OpenModelica.rs/mmtorust/src/codegen.rs` are replaced by hand-written
  `*_wasm.rs` stubs on wasm32. A function added to such a module must also be
  added to its stub.
- The wasm-jit stage runs a 32-bit `omc`, where MetaModelica Integers are 32
  bits (31 when boxed). Keep Integer intermediates below 2^30 when the value
  is printed, stored or compared, e.g. hashes, checksums and IDs.

## Making changes

- Fix the cause, not the symptom. A change that only makes one test pass
  (special-casing a model name, loosening a check) will not be accepted.
- Standard Modelica takes priority over MetaModelica-only features.
- Code must keep working on Linux, macOS and Windows (MSYS2/UCRT64).
- Match the surrounding code: naming, indentation, idioms. Keep unrelated
  refactoring and reformatting out of the change.
- Do not edit generated files. `Template/*.mo` comes from `Template/*.tpl`,
  and the C sources under `OMCompiler/Compiler/boot/bomc` are regenerated as
  described in CONTRIBUTING.md.
- A scripting API function is declared in both
  `FrontEnd/ModelicaBuiltin.mo` and `NFFrontEnd/NFModelicaBuiltin.mo` (keep
  them in sync) and implemented in `Script/CevalScriptBackend.mo`. OMEdit
  calls many of these functions; changing a signature can break it.
- Add a regression test for a bug fix and for new behavior.
- Keep the description of a new flag to one line, and do not put issue
  numbers in flag text.
- Keep `SimulationRuntime/c/` and `SimulationRuntime/rust/` in step: a fix
  or feature in one runtime usually belongs in the other as well.

### Comments

Agents add far too many comments. Keep them few and brief.

- Comment only what the code cannot say itself: a non-obvious invariant, a
  reference to the specification, a workaround for an external bug.
- Comments describe the code as it is. Why it was changed, what it looked like
  before and what was tried belong in the commit message.
- Before finishing, review the added lines of your diff and remove comments
  that restate the code.

## Git

- Work on a topic branch, never on `master`. Rebase on `master` instead of
  merging it.
- Stage files explicitly. Do not use `git add -A`, `git add .`,
  `git commit -a`, `git reset --hard`, `git clean` or `git checkout .`: the
  working tree may contain someone else's work and untracked build output.
- Do not commit submodule pointer changes unless the change is about that
  submodule. `git status` often shows submodules as modified after a build.
- Do not commit build output, generated files, logs, simulation results or
  other binaries.
- Use UTF-8 and no trailing whitespace. The hooks in `common/` check this and
  the commit message format (see CONTRIBUTING.md). Install both hooks.

### Commit messages

- The first line is a summary of at most 50 characters. Prefix it with the
  area when the change belongs to one, e.g. `[NF]` frontend, `[OB]` old
  backend, `[NB]` new backend, `[RT]` simulation runtime, `[API]` scripting
  API, `[OMEdit]`.
- The second line is blank.
- The remaining lines are at most 72 characters.
- The body explains what was wrong and why the change fixes it. GitHub renders
  it as Markdown; tables need a header row and aligned columns.
- Reference the issue (`#1234`) the commit addresses.
- Name the model that assisted with a trailer, and do not add a
  `Co-authored-by` trailer for it:

  ```text
  Assisted-by: <model name and version>
  ```

## Issues and pull requests

- Do not push, open pull requests or issues, or comment on GitHub without the
  approval of the human you are working with.
- Search the existing issues before opening a new one or starting on a fix.
- A pull request should reference an issue that explains the problem. If there
  is none, write one first: what goes wrong, a minimal model or script that
  shows it, and the expected behavior.
- Fill in the [pull request template](.github/pull_request_template.md).
- One topic per pull request. Two unrelated fixes are two pull requests.
- Pull requests are squash-merged. Branch every pull request off `master`,
  never off another open pull request's branch: once that one is squashed,
  yours conflicts. If one depends on another, say which goes first and rebase
  on `master` after it is merged.
- Disclose in the PR description that an AI agent was used, and which parts
  were tested locally.
- All contributions are made under the
  [contributor license agreement](https://openmodelica.org/osmc-pl/osmc-pl-1.8.txt).

## Running commands

- Do not start commands that can block forever (simulations, interactive
  programs, servers) without a timeout, and clean up the processes you start.
- Build directories other than `build_cmake` may belong to the human you are
  working with; ask before reusing or deleting them.
