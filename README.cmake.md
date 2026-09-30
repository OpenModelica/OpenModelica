# OpenModelica CMake build instructions

- [OpenModelica CMake build instructions](#openmodelica-cmake-build-instructions)
- [1. Quick start](#1-quick-start)
- [2. ccache](#2-ccache)
- [3. Usage](#3-usage)
  - [3.1. General Notes](#31-general-notes)
  - [3.2. Platform specific instructions](#32-platform-specific-instructions)
- [4. Configuration Options.](#4-configuration-options)
  - [4.1. OpenModelica Specific Configuration Options](#41-openmodelica-specific-configuration-options)
    - [4.1.1. OpenModelica Options](#411-openmodelica-options)
    - [4.1.2. OpenModelica/OMCompiler Options](#412-openmodelicaomcompiler-options)
    - [4.1.3. OpenModelica/OMEdit Options](#413-openmodelicaomedit-options)
    - [4.1.4. OpenModelica/OMShell Options](#414-openmodelicaomshell-options)
    - [4.1.5. Other OpenModelica specific Options](#415-other-openmodelica-specific-options)
  - [4.2. Useful CMake Configuration Options](#42-useful-cmake-configuration-options)
    - [4.2.1. Disabling Colors for Makefile Generators](#421-disabling-colors-for-makefile-generators)
    - [4.2.2 Enabling Verbose Output](#422-enabling-verbose-output)
- [5. Integration with Editors/Tools](#5-integration-with-editorstools)
- [6. Running Tests](#6-running-tests)
- [7. Modelica libraries (omlibrary)](#7-modelica-libraries-omlibrary)
- [8. Packing with CPack](#8-packing-with-cpack)
- [9. Code Coverage](#9-code-coverage)

## 1. Quick start

We recommend you read the [instructions for your Operating System](#32-platform-specific-instructions)
as they contain some tips and workarounds for some common pitfalls.

That said, if you are familiar with CMake and have all the dependencies installed you can
compile OpenModelica using the standard CMake flow.

```sh
git clone --recurse-submodules https://github.com/OpenModelica/OpenModelica.git
cd OpenModelica
cmake -S . -B build_cmake
cmake --build build_cmake --target install --parallel <Nr. of cores>

# Default install dir is a directory named install_cmake inside the build directory.
./build_cmake/install_cmake/bin/omc --help
```

By default, if you do not specify anything, the configuration will chose an installation
directory named `install_cmake` inside of your build dir.

## 2. ccache

[ccache](https://ccache.dev/) is a compiler cache. It speeds up recompilation by caching
previous compilations and detecting when the same compilation is being done again.

Technically speaking it is not a blocking requirement but in paractice you should assume
it is. If it is available for your system you should use it.

MetaModelica compilation involves a lot of recompilation of unmodified C files because of
new time stamps for generated header files. ccache will practically reduce the cost of
these types of recompilations to a no-op.

It is available for Linux, for macOS (MacPorts and Homebrew) and for MSYS/UCRT64
(mingw-w64-ucrt-x86_64-ccache).

[sccache](https://github.com/mozilla/sccache) does the same job and can keep the cache on
an S3 server instead of on disk, so that several machines share it. Select it with
`-DOM_COMPILER_CACHE=sccache` and point it at a cache through its own environment
(`SCCACHE_BUCKET`, `SCCACHE_ENDPOINT`, ...).

## 3. Usage

### 3.1. General Notes

- In source build is not recommended. Always create a dedicated build directory, e.g.
  `OpenModelica/build_cmake`

- Add `-Wno-dev` to your CMake configuration command to silence CMake warnings from
  3rdParty libraries.

  ```sh
  cmake -S . -B build_cmake -Wno-dev
  ```

- CMake is the only supported build system for OpenModelica. The `autotools + Makefile`
  build (`configure`, `Makefile.in`, ...) has been removed.

### 3.2. Platform specific instructions

Dependencies and platform specific configuration are documented per operating system:

- [Linux/WSL](OMCompiler/README.Linux.md)
- [macOS](OMCompiler/README-macOS.md)
- [Windows (MSYS2/UCRT64 and experimental MSVC)](OMCompiler/README.Windows.md)

## 4. Configuration Options

### 4.1. OpenModelica Specific Configuration Options

There are a handful OpenModelica specific options that you can adjust to your needs.

The main ones (with their default values) are

```cmake
OM_USE_CCACHE=ON
OM_COMPILER_CACHE=                 # empty: ccache, unless OM_USE_CCACHE=OFF
OM_ENABLE_GUI_CLIENTS=ON
OM_ENABLE_OMSIMULATOR=ON
OM_ENABLE_ENCRYPTION=OFF
OM_ENABLE_DOCS=OFF
OM_ENABLE_TESTSUITE=ON             # OFF if there is no testsuite/
OM_OMC_ENABLE_COMPILER=ON
OM_OMC_ENABLE_CPP_RUNTIME=ON
OM_OMC_ENABLE_C_OLD_RUNTIME=ON
OM_OMC_ENABLE_PARMODELICA=ON
OM_OMC_ENABLE_FORTRAN=ON
OM_OMC_ENABLE_OPTIMIZATION=ON
OM_OMC_ENABLE_MOO=ON
OM_OMC_ENABLE_PRIMME=ON
OM_OMC_ENABLE_COLPACK=ON
OM_FETCH_BOOST=OFF                 # ON when cross-compiling
OM_OMEDIT_INSTALL_RUNTIME_DLLS=ON
OM_OMEDIT_ENABLE_TESTS=OFF
OM_OMEDIT_ANIMATION_QUICK3D=OFF
OM_OMSHELL_ENABLE_TERMINAL=ON
```

#### 4.1.1. OpenModelica Options

`OM_USE_CCACHE` option is for enabling/disabling compiler cache support as explained in
[2. ccache](#2-ccache). It is recommended that you install ccache and set this to ON.

`OM_COMPILER_CACHE` picks which cache to use: `ccache`, `sccache` or `none`. Left empty it
follows `OM_USE_CCACHE`; set explicitly it overrides it.

`OM_ENABLE_GUI_CLIENTS` allows you to enable/disable the configuration and build of the qt
based GUI clients and their dependencies. These include: OMEdit, OMNotebook, OMParser,
OMPlot, OMShell. You will need to install and make available the necessary packages (and
their dependencies) such as the Qt libs ...

`OM_ENABLE_OMSIMULATOR` allows you to enable/disable building OMSimulator.

`OM_ENABLE_DOCS` enables the User's Guide target. It needs Sphinx, pandoc, inkscape and
gnuplot.

`OM_ENABLE_TESTSUITE` configures the testsuite and the C runtime unit tests
(`testsuite-depends`, `ctestsuite-depends`, `omc-diff`). It defaults to whether `testsuite/`
exists, so a source tarball without it still configures. Turn it off in a full checkout to
keep `omc-diff` out of `all` and out of the installation, e.g. when packaging. The shipped
PDFs in `doc/` are likewise skipped when `doc/` is absent.

`OM_ENABLE_ENCRYPTION` allows you to enable/disable building OpenModelica with library
encryption support. Note that, for this to work, you need an additional module which is
not distributed in the default OpenModelcia source repository. Contact the OpenModelica
team if you need encryption support.

The build needs `cargo` on the `PATH` (a stable toolchain of version 1.85 or newer): result
files are read and written through `libomc_result`, the Rust result-file library, and
`--simCodeTarget=C` links the Rust simulation runtime, `libSimulationRuntimeRust`.

The Rust port of the compiler itself (`OM_OMC_ENABLE_RUST`) is a separate option, off by
default. It needs a pinned nightly toolchain; see
[4.1.2](#412-openmodelicaomcompiler-options).

#### 4.1.2. OpenModelica/OMCompiler Options

`OM_OMC_ENABLE_CPP_RUNTIME` allows you to enable/disable the building of the C++ based
simulation runtime. This requires multiple Boost library components (filesystem,
program_options, ...)

`OM_OMC_ENABLE_C_OLD_RUNTIME` allows you to enable/disable the building of
`libSimulationRuntimeC`, the C simulation runtime `--simCodeTarget=C.old` links.

`OM_OMC_ENABLE_PARMODELICA` allows you to enable/disable the ParModelica (`--parmodauto`)
runtime. It needs the Boost components graph and chrono.

`OM_FETCH_BOOST` downloads and builds Boost as part of OpenModelica instead of using an
installed one. It is `ON` by default only when cross-compiling.

`OM_OMC_ENABLE_COMPILER` set to `OFF` builds only the simulation runtime, not `omc` itself.

`OM_OMC_ENABLE_PRIMME` allows you to enable/disable sparse singular value support with
PRIMME. `OM_OMC_ENABLE_COLPACK` allows you to enable/disable graph coloring with ColPack.

`OM_OMC_ENABLE_FORTRAN` allows you to enable/disable Fortran support. If your system does
not have a Fortran compiler you can disable this. Fortran is required if you enable IPOPT
support (`OM_OMC_ENABLE_OPTIMIZATION`, `OM_OMC_ENABLE_MOO`).

`OM_OMC_ENABLE_OPTIMIZATION` allows you to enable/disable support for dynamic optimization
support with Ipopt. Enabling this requires having a working Fortran compiler and requires
MOO (`OM_OMC_ENABLE_MOO`).

`OM_OMC_ENABLE_MOO` allows you to enable/disable support for dynamic optimization
support with MOO. Enabling this requires having a working Fortran compiler.

`OM_OMC_ENABLE_RUST` (`OFF` by default) builds the Rust (mmtorust) port of `omc` instead of
the bootstrapped C one. It needs `rustup` and the pinned nightly toolchain, not the stable
one used for the Rust result files; see
[OMCompiler/Compiler/OpenModelica.rs/README.md](OMCompiler/Compiler/OpenModelica.rs/README.md).

#### 4.1.3. OpenModelica/OMEdit Options

`OM_OMEDIT_ENABLE_TESTS` Enable testing and build the OMEdit Testsuite.

`OM_OMEDIT_INSTALL_RUNTIME_DLLS` allows you to enable/disable the installation of the
required runtime DLLs for MSYS/UCRT64 builds.

`OM_OMEDIT_ANIMATION_QUICK3D` uses the Qt Quick 3D animation backend instead of
OpenSceneGraph.

#### 4.1.4. OpenModelica/OMShell Options

`OM_OMSHELL_ENABLE_TERMINAL` allows you to enable/disable the building of the
OMShell-terminal command-line REPL application. This requires the GNU readline library.
Note that this is different from the Qt based OMShell GUI application.

#### 4.1.5. Other OpenModelica specific Options

There are also some additional options that are left over from the removed `autotools`
build system.

```cmake
OM_OMC_USE_LAPACK=ON
```

These options are not guaranteed to work properly if they are changed from their default
values as of now.

### 4.2. Useful CMake Configuration Options

#### 4.2.1. Disabling Colors for Makefile Generators

If you do not like colors you can disable them.

```sh
cmake -S . -B build_cmake -DCMAKE_COLOR_MAKEFILE=OFF
```

This can be useful if you want to redirect output to a file for example.

#### 4.2.2 Enabling Verbose Output

Sometimes you might want to get a verbose output to see what CMake is actually doing and
what exact commands it is issuing.

If you are using CMake itself to issue builds (recommended) instead of invoking the
generator directly, you can specify `-v` to the build command

```sh
cmake --build build_cmake -v
```

For Makefile generators (which, probably, is by far the most common usage), you can tell
GNU Make itself to give you verbose output at compile time:

```sh
make VERBOSE=1
```

The above two approaches have the advantage of allowing you to get verbose output only
when you want it.

If you instead want to see verbose output every time you compile any change then you can
tell CMake at configure time to always do that:

```sh
cmake -S . -B build_cmake -DCMAKE_VERBOSE_MAKEFILE=ON
```

## 5. Integration with Editors/Tools

The CMake configuration is set to always generate the compile command-line for each target
it discovers in to a file named `compile_commands.json`. This file is known and understood
by a number of editors and tools such as vscode, Vim, emacs, clang-tidy ...

Editors can use this file to give you a better interpretation of your source files. For
example, #includes can now be pinpointed because the editor knows exactly which includes
directories are given to the file when compiled. It can also understand things like CXX
stadnards and preprocessor defines enabled on command line ...

Some editors and tools will check for the existence of this file automatically. If not, it
is recommended that you check your editor instructions to see if you can take advantage of
it.

## 6. Running Tests

### Testsuite (partest)

The regression testsuite in `testsuite/` needs a few extra targets (the Modelica libraries
used for testing, `omc-diff` and the reference files). Build them, then run the tests:

```sh
cmake --build build_cmake --target testsuite-depends --parallel <Nr. of cores>
cd testsuite/partest
./runtests.pl
```

Some tests depend on the OS and on the versions of third-party tools, and many of them only
pass on Linux, so a few failing tests are not necessarily a problem.

### rtest

`rtest` finds an `omc` installed to `<OpenModelica>/build_cmake/install_cmake` or
`<OpenModelica>/build/install_cmake` without any changes. If you use a different build
directory or `CMAKE_INSTALL_PREFIX`, adjust the `$OPENMODELICAHOME` lines in
[testsuite/rtest](testsuite/rtest) to point to your installation directory, e.g.,

```perl
$OPENMODELICAHOME = "$1build_cmake_release/install_cmake";
```

### CTest

A few unit tests are registered with CTest. Build their dependencies first, then run them:

```sh
cmake --build build_cmake --target ctestsuite-depends --parallel <Nr. of cores>
ctest --test-dir build_cmake --output-on-failure
```

The Makefile testsuite can also be run through CTest; see
[testsuite/CTest/Readme.md](testsuite/CTest/Readme.md).

## 7. Modelica libraries (omlibrary)

An OpenModelica installation ships a cache of Modelica libraries in
`<prefix>/share/omlibrary/cache` so that `installPackage` works without network access.
The `omlibrary` target downloads the libraries listed in `libraries/install-index.json` and
stages them in the build directory, from where `install` copies them to the installation.

Since it uses the installed `omc` to do the downloading, OpenModelica has to be built and
installed first.

```sh
cmake --build build_cmake --target install --parallel <Nr. of cores>
cmake --build build_cmake --target omlibrary
# Copy the downloaded libraries into the installation. Either install everything again
cmake --build build_cmake --target install
# or only the libraries
cmake --install build_cmake --component omlibrary
```

Installing honors `DESTDIR`, e.g., `make install DESTDIR=/some/where`.

The libraries used by the testsuite are a different, larger set (`libraries/index.json`) and
are handled by the `libs-for-testing` target instead.

## 8. Packing with CPack

CPack turns an OpenModelica installation into `.deb`, `.rpm` or archive packages. It is
configured in [cmake/packaging/](cmake/packaging/) and needs no separate build: it runs the
project's own install rules into a staging directory and packs the result.

### What gets packed

Every `install()` rule in the tree is tagged with a _component_, and CPack builds one
package per component. The components, their contents and what they depend on are declared
in [cmake/packaging/components.cmake](cmake/packaging/components.cmake):

| Component | Package | Contents |
| --- | --- | --- |
| `omc` | `openmodelica-omc` | The compiler: `omc`, its libraries, the builtin `.mo` files, the scripting API header |
| `simrt` | `openmodelica-simrt` | The C simulation runtime and the libraries generated code links against |
| `simrtcpp` | `openmodelica-simrtcpp` | The C++ simulation runtime |
| `fmu` | `openmodelica-fmu` | The headers and libraries needed to build an FMU, including source-code FMUs |
| `omsimulator` | `openmodelica-omsimulator` | `OMSimulator`, its library and the Python bindings |
| `omlibrary` | `openmodelica-omlibrary` | The Modelica library cache, so `installPackage()` works offline |
| `omplot` | `openmodelica-omplot` | `OMPlot`, which `plot()` needs |
| `omedit` | `openmodelica-omedit` | The connection editor |
| `omshell` / `omshellterminal` | `openmodelica-omshell…` | The Qt and the readline shell |
| `omnotebook` | `openmodelica-omnotebook` | OMNotebook and DrModelica |
| `omsens` | `openmodelica-omsens` | The OMSens sensitivity-analysis plugin for OMEdit |
| `omoptim` | `openmodelica-omoptim` | The legacy optimization GUI (off by default) |

Only the components this build actually configured are packed, so a build with
`-DOM_ENABLE_GUI_CLIENTS=OFF` produces no `omedit` package. Components belonging to the
third-party projects built in-tree (SuiteSparse, libzmq, oneTBB, zlib, …) are deliberately
left out; see the list at the top of `components.cmake`.

`Depends:` is worked out by `dpkg-shlibdeps` from what the binaries link, plus a short
hand-written list for what `omc` needs at _run_ time — a compiler, `make` and `cmake`, which
it shells out to when it compiles a model.

> **Note**
> The packages are not yet a drop-in replacement for the ones on
> [build.openmodelica.org](https://build.openmodelica.org/apt/): they install under
> `/usr/local`, they are named `openmodelica-<component>` rather than `omc`, `omedit`, …,
> and there is no `openmodelica` metapackage. See
> [#16377](https://github.com/OpenModelica/OpenModelica/issues/16377).

### Building the packages

The packages contain what `install` installs, so build and install first. `omlibrary` needs
an installed `omc` to download with, so it comes after that (see
[7. Modelica libraries](#7-modelica-libraries-omlibrary)):

```sh
cmake -S . -B build_cmake -DCMAKE_BUILD_TYPE=Release
cmake --build build_cmake --target install --parallel <Nr. of cores>
cmake --build build_cmake --target omlibrary   # optional, for the omlibrary package
cd build_cmake && cpack -G DEB                 # or: cpack --config build_cmake/CPackConfig.cmake -G DEB
```

The packages land in `build_cmake/_packages/`. Use `-G RPM` for RPMs, `-G TXZ` for a plain
archive, and `cpack -G DEB -D CPACK_COMPONENTS_ALL="omc;simrt"` to pack only some components.

A package is only usable on the distribution it was built on — it links that distribution's
glibc and Qt — so build it in a container of the distribution you are targeting rather than
on the host, unless the two happen to match.

### Trying the packages in a clean container

```sh
docker run --rm -it -v "$PWD/build_cmake/_packages:/pkg:ro" ubuntu:26.04 bash
```

Inside the container, put the packages in a local apt repository. That is what lets apt
resolve the dependencies _between_ them, so you find out whether the packaging is right:

```sh
apt-get update && apt-get install -y dpkg-dev
mkdir /repo && cp /pkg/*.deb /repo/ && (cd /repo && dpkg-scanpackages . > Packages)
echo "deb [trusted=yes] file:/repo ./" > /etc/apt/sources.list.d/local.list
apt-get update

apt-get install -y openmodelica-omc     # pulls openmodelica-simrt with it
omc --version
```

Two ways to get this wrong:

- `dpkg -i` does not resolve dependencies at all. It reports success and leaves you with an
  `omc` that cannot start, or that fails at the first `simulate()` with
  `fatal error: 'omc_simulation_settings.h' file not found`.
- `apt-get install /pkg/openmodelica-omc_*.deb` installs a _file_. apt pulls the missing
  system libraries, but it does not go looking for `openmodelica-simrt` in `/pkg` — it only
  knows about the file you named — so it stops with an unmet dependency. Either name every
  package you want on the command line, or use the local repository above.

### Source packages

Not supported. `cpack --config build_cmake/CPackSourceConfig.cmake` stops with an error
telling you so.

CPack's source packaging archives the whole source directory while ignoring only the VCS
directories, which includes the build directory — and therefore the multi-gigabyte archive it
is at that moment writing into it. It never errors, it just grows, which looks like `cpack`
hanging. Release tarballs are made with `git-archive-all` in the `apt-build` repository
instead.

For an archive of an _installation_ rather than of the sources, use an archive generator on
the normal config: `cpack --config build_cmake/CPackConfig.cmake -G TXZ`.

## 9. Code Coverage

`-DOM_ENABLE_COVERAGE=ON` builds OpenModelica with [gcov] instrumentation and adds targets
that turn the collected counters into a report. Three things are covered:

| Component    | Sources reported                    |
| ------------ | ----------------------------------- |
| The compiler | `OMCompiler/Compiler/**.mo`         |
| C runtime    | `OMCompiler/SimulationRuntime/c/`   |
| C++ runtime  | `OMCompiler/SimulationRuntime/cpp/` |

You need GCC or Clang, and [gcovr] (`pip install gcovr`, or your package manager).

Coverage is only as good as what you run: the numbers come from whatever the instrumented
binaries executed since the last reset, so run the testsuite - or the subset you care
about - in between.

### How MetaModelica is covered

The compiler is written in MetaModelica, which `omc` translates to C before anything is
compiled, so gcov would normally only ever see the generated
`build_cmake/OMCompiler/Compiler/c_files/*.c`.

A coverage build therefore also turns on `omc -d=gendebugsymbols`. The code generator then
emits `/*#modelicaLine <file>:<line>*/` markers, which `Print` writes out as C `#line`
directives naming the `.mo` file (see `modelicaLine` in
`Compiler/Template/CodegenCFunctions.tpl`, and `printimpl.c`). gcov follows those, so the
report shows `NFFlatten.mo` and friends rather than `NFFlatten.c`. It costs nothing at
runtime: the `mmc_set_current_pos()` calls that would need `OMC_RECORD_ALLOC_WORDS` on top.

Since the report filters on the source tree, the leftover generated C - boilerplate that
has no `#line` of its own - stays out of it.

### Susan templates

The code generator is written as Susan templates, which are translated to
MetaModelica (`*Tpl.mo`) and only then to C, so gcov reports the generated
MetaModelica and never the templates. Susan keeps no line mapping back to the
`.tpl` - it records template positions only at a handful of error sites - but it
does keep the _names_: every `template foo` becomes a `public function foo`.

`OpenModelicaCoverageTemplates.py` uses that. For each generated function it
takes the coverage of its lines and attributes it to the `template foo` line in
the `.tpl`, and `coverage-report` merges the result into the report as another
tracefile. Coverage of a `.tpl` therefore reads as _how many of its templates
ran_, which is what separates dead templates from live ones. It is not line
coverage _within_ a template - that would need Susan to emit a real line map.

The generated `*Tpl.mo` are reported too, so per-line detail is still available,
just against the generated MetaModelica rather than the template.

This needs the compiler to record absolute paths for the generated
MetaModelica, which lives in the build tree: `-fprofile-abs-path` on GCC, and a
`-ffile-compilation-dir` pointing outside the tree on Clang (see
`OM_COVERAGE_CLANG_COMPILATION_DIR`). Without it gcov cannot find the generated
`.mo` from the object directory and the templates silently drop out.

### Running it

Configure and build as usual, with coverage on:

```sh
cmake -S . -B build_cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=build \
      -DOM_ENABLE_COVERAGE=ON
cmake --build build_cmake --target install --parallel $(nproc)
```

Discard counters left over from earlier runs, so the report covers only what you are about
to run:

```sh
cmake --build build_cmake --target coverage-reset
```

Then run something. For the whole testsuite through CTest (see
[testsuite/CTest/Readme.md](testsuite/CTest/Readme.md)):

```sh
cmake -DTESTSUITE_DIR="$PWD/testsuite" -DOUTPUT_DIR="$PWD/build-testsuite-ctest" \
      -P testsuite/CTest/Partest/GenerateCTestFile.cmake
ctest --test-dir build-testsuite-ctest -j$(nproc) --output-on-failure
```

While iterating, `ctest -R <regex>` or `-L <label>` narrows that down - e.g. `-L flattening`
for just the flattening tests. Counters accumulate until the next `coverage-reset`, so
several runs can be combined into one report. Finally:

```sh
cmake --build build_cmake --target coverage-report
```

It prints a summary and writes `build_cmake/coverage/`: `index.html` (browsable, per-file
and per-line) and `coverage.xml` (Cobertura, for tooling).

### Viewing the report

```sh
cmake --build build_cmake --target coverage-serve
```

serves it on <http://localhost:8000/> until you Ctrl-C; override the port with
`-DOM_COVERAGE_PORT=9000`. This also works over an SSH port forward or from a container,
where opening the file directly would not. Otherwise just open
`build_cmake/coverage/index.html` in a browser.

### Notes

- The build type's optimization level is left alone, because `omc` and the simulation
  runtime are on the hot path of every test and an unoptimized coverage build makes a
  testsuite run far slower. For exact per-line attribution (no inlining) at that cost,
  configure with `-DOM_COVERAGE_COMPILE_OPTIONS="--coverage;-fprofile-update=atomic;-O0"`.
- With Clang the report is read back with `llvm-cov gcov`; this is picked automatically and
  can be overridden with `-DOM_COVERAGE_GCOV=...`.
- Turning `OM_ENABLE_COVERAGE` on or off changes the generated C (`-d=gendebugsymbols`), so
  the compiler is retranslated and rebuilt. Counters collected before such a switch carry no
  `.mo` mapping and report the compiler as 0%: rebuild, `coverage-reset`, then re-run.
- `gcov` also wants to read the _generated_ `c_files/*.c` behind each translation unit.
  Those are build artifacts, filtered out of the report, and not present when the report is
  produced somewhere other than the build (as in CI), so `--gcov-ignore-errors` is passed to
  let gcov not find them - without it, it discards the whole `.gcda`, `.mo` data included.
  It still prints a complaint per file; the line data is unaffected.
- A coverage build also appends `--coverage` to the link flags omc uses for generated code
  (`Autoconf.ldflags_runtime*` and `SYSTEM_LDFLAGS` in the C++ runtime's
  `ModelicaConfig_gcc.inc`). Simulations that link the runtime _dynamically_ would not need
  it - libgcov is inside the shared library - but source FMUs link the static runtime, and
  without it they fail with undefined references to `__gcov_*` / `llvm_gcda_*`.
- Jenkins does all of this on every PR, from the `testsuite-gcc` shard; see
  `coverageReportStage()` in [.CI/common.groovy](.CI/common.groovy). That shard runs half of
  the testsuite - the other half runs in the clang shard, which is not instrumented - so
  CI's numbers cover roughly half the tests a full local run would.

[gcov]: https://gcc.gnu.org/onlinedocs/gcc/Gcov.html
[gcovr]: https://gcovr.com/
