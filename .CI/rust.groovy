// Rust/wasm CI steps: the Rust omc build, its sccache setup, the wasm web
// bundles, and the Rust test stages. Split out of common.groovy, which keeps
// the C/C++ build steps and the generic helpers.
//
// Loaded by the Jenkinsfile right after common.groovy:
//
//   common = load("${env.workspace}/.CI/common.groovy")
//   rust = load("${env.workspace}/.CI/rust.groovy").init(common)
//
// No `def` on the assignment below: a `def` at script level is a local of the
// generated run() method and the functions here would not see it, whereas an
// undeclared assignment goes to the script binding, which they do.
commonLib = null

// Bind the common.groovy step library these steps call into (standardSetup,
// numPhysicalCPU, tagName, isPR) and return this script, so the Jenkinsfile can
// load and initialise in one expression.
def init(lib) {
  commonLib = lib
  return this
}

// Fixed path for the Rust working copy (rust_omc.cmake's RUST_OMC_DIR): sccache
// hashes CARGO_MANIFEST_DIR into the Rust cache key and SCCACHE_BASEDIRS does not
// rewrite env values, so a per-job path makes every crate of ours a guaranteed
// miss. Outside the workspace; each build gets its own container.
String rustWorkDir() { return '/tmp/omc-rust' }

// sccache config for the cargo builds: a shared S3 (MinIO) compile cache at
// sccache.openmodelica.org, replacing the per-node /cache/sccache volume so the
// cache is shared across agents (see .CI/sccache/). Incremental must be off for
// sccache to hit. The cache size is bounded server-side (bucket TTL + quota);
// SCCACHE_CACHE_SIZE does not apply to the S3 backend.
//
// The commented-out RUSTC_WRAPPER is a selective shim (rustc-sccache-wrapper.sh)
// running our own crates under bare rustc to keep cargo pipelining. It assumed
// they never hit the cache; they do, now that rustWorkDir() keeps
// CARGO_MANIFEST_DIR constant.
//
// AWS_ACCESS_KEY_ID is the scoped, non-secret key (readwrite on the sccache
// bucket only); the matching secret is injected separately by withSccache() from
// the 'sccache-ci-secret-key' Jenkins credential, never stored here.
def sccacheEnv() {
  return [// "RUSTC_WRAPPER=${env.WORKSPACE}/.CI/scripts/rustc-sccache-wrapper.sh",
          'RUSTC_WRAPPER=sccache',
          'SCCACHE_BUCKET=omc-sccache',
          'SCCACHE_ENDPOINT=https://sccache.openmodelica.org',
          'SCCACHE_REGION=auto',
          'SCCACHE_S3_USE_SSL=true',
          'AWS_ACCESS_KEY_ID=sccache-ci',
          'CARGO_INCREMENTAL=0'
          ]
}

// Run `body` with the shared sccache environment plus the S3 secret key bound
// from the Jenkins credential (the access key is non-secret, see sccacheEnv).
// extraEnv is prepended for callers that need build-specific vars.
def withSccache(List extraEnv = [], Closure body) {
  withCredentials([string(credentialsId: 'sccache-ci-secret-key',
                          variable: 'AWS_SECRET_ACCESS_KEY')]) {
    // Normalise the per-job workspace prefix out of the cache keys so the cache is
    // shared across jobs/branches, not just rebuilds at the same checkout path.
    // Without this, sccache hashes the absolute paths embedded in compile commands
    // (-I.../source) and in the C/C++ preprocessor line markers, so every job's
    // workspace path is a distinct key — each job re-populates the bucket with its
    // own copies instead of hitting. SCCACHE_BASEDIRS (sccache's CCACHE_BASEDIR)
    // strips this prefix before hashing; it must be absolute and must be in the
    // environment of *every* sccache call, since a client auto-restarts a
    // timed-out server and the restarted server inherits the env. env.WORKSPACE is
    // unreliable in the docker agent (see makeLibsAndCache), so read it from pwd.
    def basedir = sh(script: 'pwd', returnStdout: true).trim()
    withEnv(extraEnv + sccacheEnv() + ["SCCACHE_BASEDIRS=${basedir}"]) {
      // Preflight: fail fast if the S3 cache backend is not usable. sccache
      // otherwise silently degrades to read-only / no-cache on a backend error
      // (wrong bucket, endpoint, credential, or an unwritable proxy), hiding a
      // broken cache behind a normal-looking but uncached build. A fresh server
      // runs a storage read+write check at startup; surface its failure.
      sh '''
        set -e
        log="$(mktemp)"
        sccache --stop-server >/dev/null 2>&1 || true
        SCCACHE_ERROR_LOG="$log" SCCACHE_LOG=warn sccache --start-server
        sccache --show-stats
        if grep -qiE "storage (write )?check failed|read-only storage|cache storage failed" "$log"; then
          echo "ERROR: sccache S3 cache backend is not usable; failing build:" >&2
          cat "$log" >&2
          rm -f "$log"
          exit 1
        fi
        rm -f "$log"
      '''
      try {
        body()
      } finally {
        // Post-run stats: compile requests, cache hits/misses and S3 errors for
        // this build. In finally so they surface even when the body fails (which
        // is when the hit rate matters most). Best-effort; never fail the build.
        sh 'sccache --show-stats || true'
      }
    }
  }
}

void buildRustOMC() {
  commonLib.standardSetup()
  // RUST_OMC_THREADS=4 parallelises the rustc front-end on the (near-serial)
  // generated-crate chain. Linking uses mold (RUST_OMC_MOLD defaults ON); the
  // image ships a current mold.
  sh """
    cmake -S . -B build_cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DOM_OMC_ENABLE_RUST=ON \
      -DRUST_OMC_CI=ON \
      -DOM_ENABLE_GUI_CLIENTS=OFF \
      -DRUST_OMC_SCRIPTING_API=ON \
      -DOM_USE_CCACHE=OFF \
      -DCMAKE_C_COMPILER_LAUNCHER=sccache \
      -DCMAKE_CXX_COMPILER_LAUNCHER=sccache \
      -DCMAKE_C_COMPILER=clang \
      -DCMAKE_CXX_COMPILER=clang++ \
      -DCMAKE_INSTALL_PREFIX=build \
      -DRUST_OMC_TIMINGS=ON \
      -DRUST_OMC_THREADS=4 \
      -DRUST_OMC_WORK_DIR=${rustWorkDir()} \
      -DRUST_OMC_FMU_NATIVE_TARGETS=${fmuNativeTargets()} \
      -DRUST_OMC_MACOS_SDK=${fmuMacosSdk()} \
      -DRUST_OMC_WASM_RUNTIME_OUT=${env.WORKSPACE}/runtime.wasm
  """
  // O3 is the default release opt-level; CI uses O2 to cut build time.
  withSccache(['CARGO_PROFILE_RELEASE_OPT_LEVEL=2']) {
    // install builds the whole tree (incl. rust_omc + the cdylib) and installs in
    // one pass. Don't also pass rust_omc as a goal: recursive sub-makes would re-run
    // the always-run cdylib custom target a second time (a redundant cargo pass).
    sh "cmake --build build_cmake --parallel ${commonLib.numPhysicalCPU()} --target install"
    sh "build/bin/omc --version"
    sh "cmake --build build_cmake --parallel ${commonLib.numPhysicalCPU()} --target rust_wasm_runtime"
    sh "cmake --build build_cmake --parallel ${commonLib.numPhysicalCPU()} --target testsuite-depends"
  }
  // cargo --timings HTML report for the omc artifact builds (RUST_OMC_TIMINGS=ON).
  archiveArtifacts artifacts: 'build_cmake/OMCompiler/Compiler/rust-target/cargo-timings/cargo-timing-*.html', allowEmptyArchive: true, fingerprint: true
  archiveArtifacts artifacts: 'runtime.wasm', fingerprint: true
  stash name: 'wasm-jit-runtime', includes: 'runtime.wasm'
  // Generated by the SimulationRuntime cmake (skipped in the wasm build); the web
  // codegen reads it from the source tree, so hand it over.
  stash name: 'runtime-sources-mo', includes: 'OMCompiler/SimulationRuntime/c/RuntimeSources.mo'
  // testsuite-depends (above) builds ffi-test-lib into the testsuite source tree;
  // partestRust only unstashes this stash and never rebuilds it, so carry the .so
  // along or the flattening/modelica/ffi tests can't find libFFITestLib.so.
  stash name: 'omc-cmake-rust',
        includes: 'build/**,' +
                  'testsuite/flattening/modelica/ffi/FFITest/Resources/Library/**'
  // The mmtorust/susan-generated .rs, so the unit-tests-rust stage runs cargo test
  // without re-running codegen. stash reaches only inside the workspace, so stage
  // them there first, relative to the working copy root.
  sh """
    rm -rf rust-generated-src && mkdir -p rust-generated-src
    cd ${rustWorkDir()}/rust-src
    find . -path '*/src/*.rs' -print0 |
      tar --null -T - -cf - | tar -C ${env.WORKSPACE}/rust-generated-src -xf -
  """
  stash name: 'rust-generated-src',
        includes: 'rust-generated-src/**,' +
                  'build_cmake/rust-wasi-pic-sysroot/**,' +
                  'build_cmake/rust-sundials-wasm/**,' +
                  'build_cmake/downloads/wasi_snapshot_preview1.reactor.wasm'
  stash name: 'omc-cmake-rust-gui-inputs',
        includes: 'build_cmake/OMCompiler/Compiler/rust-target/release/libOpenModelicaCompiler.so,' +
                  'build_cmake/OMCompiler/Compiler/scripting-api-qt/**'
  // The cross-built FMU loaders for the web stage. Not stashed in place: that is
  // the web build's own staging directory, which it empties before reading them.
  sh 'rm -rf fmu-loaders && cp -a build_cmake/OMCompiler/Compiler/fmu-loaders .'
  stash name: 'fmu-loaders', includes: 'fmu-loaders/**'
}

// Platforms an exported wasm FMU can also serve natively (the host's own
// x86_64-linux is always built, and is not listed). Each is a cross build of the
// FMU loader library, so **the image must carry that platform's toolchain** —
// naming one it cannot build fails the build rather than quietly shipping an omc
// that offers fewer platforms:
//   rustup target add aarch64-unknown-linux-gnu x86_64-pc-windows-msvc \
//                     aarch64-pc-windows-msvc x86_64-apple-darwin aarch64-apple-darwin
//   cargo install cargo-xwin cargo-zigbuild && pip install ziglang
//   ln -s "$(command -v llvm-lib-21)" /usr/local/bin/llvm-lib   # cc-rs looks for this name
//   a macOS SDK at fmuMacosSdk()                                # the darwin triples
// Drop a triple from this list (or set OMC_FMU_NATIVE_OPTIONAL=1) to build
// without one.
// 32-bit platforms are absent on purpose: the component is compiled by cranelift,
// which has no x86-32 backend, so no `.cwasm` can be produced for them.
String fmuNativeTargets() {
  return 'aarch64-unknown-linux-gnu,x86_64-pc-windows-msvc,' +
         'aarch64-pc-windows-msvc,x86_64-apple-darwin,aarch64-apple-darwin'
}

// Where the stages that build loaders bind-mount the agent's macOS SDK (grep the
// Jenkinsfile for MacOSX.sdk when adding one); a build without it fails.
String fmuMacosSdk() {
  return env.OM_FMU_MACOS_SDK ?: '/mnt/MacOSX.sdk'
}

// Shared web cmake configure; `extra` appends stage-specific flags.
void configureWeb(String extra) {
  sh """
    cmake -S . -B build_cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DOM_OMC_WASM=ON \
      -DRUST_OMC_WASM_MODE=web-release \
      ${rustWasmOptCMakeFlag()} \
      -DRUST_OMC_WASM_RUNTIME=${env.WORKSPACE}/runtime.wasm \
      -DRUST_OMC_PREBUILT_GENERATED_SRC=ON \
      -DRUST_OMC_TIMINGS=ON \
      -DRUST_OMC_WORK_DIR=${rustWorkDir()} \
      -DRUST_OMC_FMU_NATIVE_TARGETS=${fmuNativeTargets()} \
      -DRUST_OMC_FMU_LOADERS=${env.WORKSPACE}/fmu-loaders \
      -DRUST_OMC_MACOS_SDK=${fmuMacosSdk()} \
      -DOM_USE_CCACHE=OFF \
      -DCMAKE_INSTALL_PREFIX=install_web \
      ${extra}
  """
}

// Lay the stage-1 generated .rs into the working copy, before the cmake configure
// (which writes a placeholder lib.rs only for the ones still missing).
void restoreGeneratedSrc() {
  unstash 'rust-generated-src'
  sh "mkdir -p ${rustWorkDir()}/rust-src && cp -a rust-generated-src/. ${rustWorkDir()}/rust-src/"
}

// Run an em++ build under sccache via the shim (see em-sccache-wrapper.sh).
void withEmSccache(Closure body) {
  def ws = sh(script: 'pwd', returnStdout: true).trim()
  withSccache(["EM_COMPILER_WRAPPER=${ws}/.CI/scripts/em-sccache-wrapper.sh"]) {
    body()
  }
}

// Main web bundle minus the Qt pages (built separately by buildRustWebQt,
// merged by assembleWeb).
void buildRustWeb() {
  commonLib.standardSetup()
  unstash 'wasm-jit-runtime'
  unstash 'runtime-sources-mo'
  restoreGeneratedSrc()
  unstash 'omc-cmake-rust-gui-inputs'
  unstash 'fmu-loaders'
  configureWeb('-DRUST_OMC_WEB_QT=OFF')
  withEmSccache {
    sh "cmake --build build_cmake --parallel ${commonLib.numPhysicalCPU()}"
  }
  sh "cmake --install build_cmake --component web"
  // cargo --timings HTML report for the wasm crate build (RUST_OMC_TIMINGS=ON).
  archiveArtifacts artifacts: 'build_cmake/OMCompiler/Compiler/rust-target/cargo-timings/cargo-timing-*.html', allowEmptyArchive: true, fingerprint: true
  stash name: 'web-partial', includes: 'install_web/share/omc/web/**'
}

// The Qt web pages (OMShell/OMNotebook/OMEdit-qt) alone, off the stage-1 prebuilt
// omc. OMEDIT_WASM_OPTIMIZE=ON always: an -O0 OMEdit link does not run in the
// browser (see rust_omc.cmake).
void buildRustWebQt() {
  commonLib.standardSetup()
  unstash 'wasm-jit-runtime'
  unstash 'runtime-sources-mo'
  restoreGeneratedSrc()
  unstash 'omc-cmake-rust-gui-inputs'
  configureWeb('-DRUST_OMC_WEB_QT=OFF -DRUST_OMC_WEB_QT_STANDALONE=ON -DOMEDIT_WASM_OPTIMIZE=ON')
  withEmSccache {
    sh "cmake --build build_cmake --parallel ${commonLib.numPhysicalCPU()} --target rust_omshell_qt_web rust_omnotebook_qt_web rust_omedit_qt_web"
  }
  sh "cmake --install build_cmake --component web"
  stash name: 'web-qt', includes: 'install_web/share/omc/web/OMShell-qt/**, install_web/share/omc/web/OMNotebook-qt/**, install_web/share/omc/web/OMEdit-qt/**'
}

// Merge the Qt pages into the main web tree (both unstash to the same path), zip.
void assembleWeb() {
  unstash 'web-partial'
  unstash 'web-qt'
  def webZip = "OpenModelicaCompiler-web-${commonLib.tagName()}.zip"
  sh "rm -f ${webZip} && (cd install_web/share/omc/web && zip -r -9 ${env.WORKSPACE}/${webZip} .)"
  archiveArtifacts artifacts: webZip, fingerprint: true
  stash name: 'web', includes: webZip

  // Merge the Rust-partest partition shards into one sorted failure list,
  // archived so regressions are easy to diff between runs. Here (not a dedicated
  // agent) since the web deliverable is already assembled. Same guard as the
  // testsuite-rust stages, so a missing shard is a hard error rather than the
  // normal case of those stages not having run.
  sh 'rm -f testsuite/partest-failed-*.txt partest-rust-failed.txt'
  if (shouldWeRunRustTests()) {
    for (p in [1,2]) {
      unstash "partest-failed-${p}"
    }
    sh 'cat testsuite/partest-failed-*.txt | sort -u > partest-rust-failed.txt && wc -l partest-rust-failed.txt'
    archiveArtifacts artifacts: 'partest-rust-failed.txt', allowEmptyArchive: true, fingerprint: true
  }
}

void buildRustGUI() {
  commonLib.standardSetup()
  unstash 'omc-cmake-rust-gui-inputs'
  sh """
    cmake -S . -B build_cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DOM_OMC_ENABLE_RUST=ON \
      -DOM_ENABLE_GUI_CLIENTS=ON \
      -DRUST_OMC_PREBUILT_CDYLIB=${env.WORKSPACE}/build_cmake/OMCompiler/Compiler/rust-target/release/libOpenModelicaCompiler.so \
      -DRUST_OMC_PREBUILT_SCRIPTING_API_QT_DIR=${env.WORKSPACE}/build_cmake/OMCompiler/Compiler/scripting-api-qt \
      -DRUST_OMC_WORK_DIR=${rustWorkDir()} \
      -DOM_OMC_ENABLE_CPP_RUNTIME=OFF \
      -DOM_USE_CCACHE=OFF \
      -DCMAKE_C_COMPILER_LAUNCHER=sccache \
      -DCMAKE_CXX_COMPILER_LAUNCHER=sccache \
      -DCMAKE_C_COMPILER=clang \
      -DCMAKE_CXX_COMPILER=clang++ \
      -DCMAKE_INSTALL_PREFIX=build_gui_install
  """
  withSccache {
    sh "cmake --build build_cmake --parallel ${commonLib.numPhysicalCPU()}"
  }
}

// One partest shard against the Rust-built omc (unstashed). Builds the test
// libraries with that omc (cmake's libs-for-testing == omc index.mos); the repo's
// index.json is copied into place first so omc uses it instead of downloading.
void partestRust(partition) {
  commonLib.standardSetup()
  unstash 'omc-cmake-rust'
  // OMSimulator + libomcruntime aren't produced by the Rust omc build; pull the
  // prebuilt binaries from the clang job (file sets are disjoint from build/**'s
  // rust omc, so this adds to the tree without overwriting it). Needed by the
  // OMSimulator tests and the -lomcruntime bootstrapping tests respectively.
  unstash 'omsimulator'
  unstash 'omcruntime'
  sh """#!/bin/bash -xe
    test ! -z '${env.LIBRARIES}'
    mkdir -p '${env.LIBRARIES}/om-pkg-cache'
    rm -rf libraries/.openmodelica/cache
    mkdir -p libraries/.openmodelica/libraries
    ln -s '${env.LIBRARIES}/om-pkg-cache' libraries/.openmodelica/cache
    cp libraries/index.json libraries/.openmodelica/libraries/
    ( cd libraries && "\$PWD/../build/bin/omc" index.mos )
    build/bin/omc-diff -v1.4
  """
  String simCodeTargetArg = params.RUST_PARTEST_SIMCODETARGET ? " -simCodeTarget=${params.RUST_PARTEST_SIMCODETARGET}" : ''
  // cpp/hpcom: the Rust omc is built without the C++ runtime. metamodelica:
  // MetaModelica code generation only works against the C runtime.
  // cSources/fmuCSources check generated C files or FMU sources - wasm-jit does not use C
  // 63bit/antlr: the port's Integer is i32 and its parser is winnow, not ANTLR
  // stackoverflow: Rust aborts on stack overflow, MMC unwinds out of the SEGV handler
  String suitesArg = ' -suites=-cpp,-hpcom,-metamodelica,-63bit,-antlr,-cSources,-fmuCSources,-stackoverflow'
  // wasmtime reserves ~4 GiB of address space per wasm memory, and shrinking that
  // reservation to fit an RLIMIT_AS costs the bounds-check-free fast path.
  String asLimit = params.RUST_PARTEST_SIMCODETARGET == 'wasm-jit'
                   ? '# wasm-jit: address space is not limited, only the cgroup is'
                   : 'ulimit -v 6291456 # Max 6GB per process'
  try {
    sh """#!/bin/bash
      set -o pipefail
      ulimit -t 1500
      ${asLimit}
      .CI/scripts/cgroup-memory.sh check
      rm -f testsuite/partest-failed-${partition}.txt
      cd testsuite/partest
      set -x
      ./runtests.pl -j${commonLib.numPhysicalCPU()} -partition=${partition}/2 -nocolour -with-xml${suitesArg}${simCodeTargetArg} 2>&1 | tee runtests-${partition}.log
      CODE=\${PIPESTATUS[0]}
      set +x
      ../../.CI/scripts/cgroup-memory.sh report
      # 0/7 == the run completed (7 means some tests failed); only fail the step on
      # anything else, so junit below still publishes the per-test results.
      test \$CODE = 0 -o \$CODE = 7 || exit 1
      # This partition's failures, from the 'Failed tests:' block (the only
      # tab-indented lines). Parsing stdout rather than failed.<branch> avoids the
      # die on branch names with '/'. Stashed and merged in assemble-web.
      grep -E '^[[:space:]]+[^[:space:]].*[.]mo[fs]?\$' runtests-${partition}.log | sed -E 's/^[[:space:]]+//' | sort -u > ../partest-failed-${partition}.txt || true
      wc -l ../partest-failed-${partition}.txt
    """
    stash name: "partest-failed-${partition}", includes: "testsuite/partest-failed-${partition}.txt"
  } finally {
    // Per-partition result.xml; disjoint shards merge into one per-test view in
    // Jenkins. In finally so a hard shard failure still publishes what ran.
    if (params.RUST_PARTEST_JUNIT) {
      junit testResults: 'testsuite/partest/result.xml', allowEmptyResults: true, skipPublishingChecks: true
    }
    sh "cp testsuite/partest/result.xml partest-rust-partest-junit-${partition}.xml"
    archiveArtifacts artifacts: 'partest-rust-partest-junit-${partition}.xml', allowEmptyArchive: true, fingerprint: true
  }
}

// Cargo workspace unit tests as their own stage (parallel with partest), in the
// fast dev/cranelift profile. The generated .rs are unstashed from stage 1, so
// nextest compiles them directly — no codegen rebuild. nextest's `ci` profile
// writes a per-test JUnit report (.config/nextest.toml). The `openmodelica`
// launcher is excluded: its build.rs links the prebuilt cdylib, which this stage
// does not build.
void ctestRust() {
  commonLib.standardSetup()
  unstash 'rust-generated-src'
  // Assembled in rustWorkDir(), not the workspace, so the crates hit sccache (see
  // rustWorkDir()). The whole crate tree, not the rust_src_sync manifest: that one
  // omits test fixtures. Then the stage-1 generated .rs (without them the manifest
  // load fails) and the builtin .mo openmodelica_wasi include_str!s from ../../../.
  def work = "${rustWorkDir()}/rust-src"
  sh """
    rm -rf ${work} && mkdir -p ${work}
    tar -C OMCompiler/Compiler/OpenModelica.rs --exclude=./target -cf - . | tar -C ${work} -xf -
    cp -a rust-generated-src/. ${work}/
    for d in FrontEnd NFFrontEnd; do
      mkdir -p ${rustWorkDir()}/\$d
      cp OMCompiler/Compiler/\$d/*Builtin*.mo ${rustWorkDir()}/\$d/
    done
  """
  // Env vars required by the openmodelica_wasi_libc and openmodelica_wasm_jit
  // build.rs (wasm cross-compile artifacts from CMake build).
  def wasmEnv = [
    "OMC_WASI_PIC_SYSROOT=${env.WORKSPACE}/build_cmake/rust-wasi-pic-sysroot",
    "OMC_SUNDIALS_WASM_DIR=${env.WORKSPACE}/build_cmake/rust-sundials-wasm",
    "OMC_WASI_P1_ADAPTER=${env.WORKSPACE}/build_cmake/downloads/wasi_snapshot_preview1.reactor.wasm",
    "OMC_EXTERNAL_C_SOURCES=${env.WORKSPACE}/OMCompiler/SimulationRuntime/ModelicaExternalC/C-Sources",
  ]
  try {
    withSccache(wasmEnv) {
      sh "cd ${work} && cargo nextest run --workspace --exclude openmodelica --profile ci --no-fail-fast"
    }
  } finally {
    // junit only reads inside the workspace.
    sh "cp ${work}/target/nextest/ci/junit.xml nextest-junit.xml || true"
    junit testResults: 'nextest-junit.xml', allowEmptyResults: true
  }
}

// Whether the Rust test stages run. Evaluated and printed with the other stage
// gates by common.evaluateBuildFlags(), which is handed this script for it.
def shouldWeRunRustTests() {
  if (commonLib.isPR()) {
    if (pullRequest.labels.contains("CI/Enable Rust Tests")) {
      return true
    }
  }
  return params.ENABLE_RUST_PARTEST
}

// wasm-opt -Oz on the web bundle is slow and only shrinks the shipped artifact;
// skip it on PRs, keep it for the release build that publishes to the playground.
def rustWasmOptCMakeFlag() {
  return commonLib.isPR() ? "-DRUST_OMC_WASM_OPT=OFF" : "-DRUST_OMC_WASM_OPT=ON"
}

return this
