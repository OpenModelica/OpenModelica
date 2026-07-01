
def isWindows() {
  return !isUnix()
}

void standardSetup() {
  echo "${env.NODE_NAME}"

  if (isWindows()) {
    echo "PATH: ${env.PATH}"
    bat "git clean -ffdx -e OMSetup && git submodule foreach --recursive \"git clean -ffdx\""
    return
  }

  // Jenkins cleans with -fdx; --ffdx is needed to remove git repositories
  sh "git clean -ffdx && git submodule foreach --recursive git clean -ffdx"
}

def numPhysicalCPU() {
  if (env.JENKINS_NUM_PHYSICAL_CPU) {
    return env.JENKINS_NUM_PHYSICAL_CPU
  }

  if (isWindows())
  {
    return env.NUMBER_OF_PROCESSORS.toInteger() / 2 ?: 1
  }


  def uname = sh script: 'uname', returnStdout: true
  if (uname.startsWith("Darwin")) {
    env.JENKINS_NUM_PHYSICAL_CPU = sh (
      script: 'sysctl hw.physicalcpu_max | cut -d" " -f2',
      returnStdout: true
    ).trim().toInteger() ?: 1
  } else {
    env.JENKINS_NUM_PHYSICAL_CPU = sh (
      script: 'lscpu -p | egrep -v "^#" | sort -u -t, -k 2,4 | wc -l',
      returnStdout: true
    ).trim().toInteger() ?: 1
  }
  return env.JENKINS_NUM_PHYSICAL_CPU
}

def numLogicalCPU() {
  if (env.JENKINS_NUM_LOGICAL_CPU) {
    return env.JENKINS_NUM_LOGICAL_CPU
  }

  if (isWindows())
  {
    return env.NUMBER_OF_PROCESSORS.toInteger() ?: 1
  }

  def uname = sh script: 'uname', returnStdout: true
  if (uname.startsWith("Darwin")) {
    env.JENKINS_NUM_LOGICAL_CPU = sh (
      script: 'sysctl hw.logicalcpu_max | cut -d" " -f2',
      returnStdout: true
    ).trim().toInteger() ?: 1
  } else {
    env.JENKINS_NUM_LOGICAL_CPU = sh (
      script: 'lscpu -p | egrep -v "^#" | wc -l',
      returnStdout: true
    ).trim().toInteger() ?: 1
  }
  return env.JENKINS_NUM_LOGICAL_CPU
}

void partest(partition=1,partitionmodulo=1,cache=true,extraArgs='') {
  if (isWindows()) {

  bat ("""
     If Defined LOCALAPPDATA (echo LOCALAPPDATA: %LOCALAPPDATA%) Else (Set "LOCALAPPDATA=C:\\Users\\OpenModelica\\AppData\\Local")
     echo on
     (
     echo export MSYS_WORKSPACE="`cygpath '${WORKSPACE}'`"
     echo echo MSYS_WORKSPACE: \${MSYS_WORKSPACE}
     echo export OPENMODELICAHOME="\${MSYS_WORKSPACE}/build"
     echo export OPENMODELICALIBRARY="${MSYS_WORKSPACE}\\build\\lib\\omlibrary"
     echo cd ${MSYS_WORKSPACE}/testsuite/partest
     echo time perl ./runtests.pl -nocolour -with-xml
     echo CODE=\$?
     echo if test "\$CODE\" = 0 -o "\$CODE" = 7; then
     echo   cp -f ../runtest.db.* "${env.RUNTESTDB}/"
     echo fi
     echo if test "\$CODE" = 0 -o "\$CODE" = 7; then
     echo   exit 0
     echo else
     echo   exit $CODE
     echo fi
     ) > runTestWindows.sh

     set MSYSTEM=UCRT64
     set MSYS2_PATH_TYPE=inherit
     %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "cd `cygpath '${WORKSPACE}'` && chmod +x runTestWindows.sh && ./runTestWindows.sh && rm -f ./runTestWindows.sh"
  """)

  } else {
  sh "rm -f omc-diff.skip && ${makeCommand()} -C testsuite/difftool clean && ${makeCommand()} --output-sync=recurse -C testsuite/difftool"
  sh 'build/bin/omc-diff -v1.4'

  sh ("""#!/bin/bash -x
  ulimit -t 1500
  ulimit -v 6291456 # Max 6GB per process

  cd testsuite/partest
  ./runtests.pl -j${numPhysicalCPU()} -partition=${partition}/${partitionmodulo} -nocolour -with-xml ${extraArgs}
  CODE=\$?
  test \$CODE = 0 -o \$CODE = 7 || exit 1
  """
  + (cache ?
  """
  if test \$CODE = 0; then
    mkdir -p "${env.RUNTESTDB}/${cacheBranchEscape()}/"
    cp ../runtest.db.* "${env.RUNTESTDB}/${cacheBranchEscape()}/"
  fi
  """ : ''))

  }

  junit 'testsuite/partest/result.xml'
}

void patchConfigStatus() {
  if (isUnix())
  {
    // Running on nodes with different paths for the workspace
    sh 'sed -i.bak -e "s,--with-ombuilddir=[A-Za-z0-9./_-]*,--with-ombuilddir=`pwd`/build," -e "s,--prefix=[A-Za-z0-9./_-]*,--prefix=`pwd`/install," config.status OMCompiler/config.status'
  }
}

void makeLibsAndCache() {
  if (isWindows())
  {
    // do nothing
  } else {
  sh "test ! -z '${env.LIBRARIES}'"
  // If we don't have any result, copy to the master to get a somewhat decent cache
  sh "cp -f ${env.RUNTESTDB}/${cacheBranchEscape()}/runtest.db.* testsuite/ || " +
     "cp -f ${env.RUNTESTDB}/master/runtest.db.* testsuite/ || true"
  // env.WORKSPACE is null in the docker agent, so link the svn/git cache afterwards
  sh label: 'Create directory for omlibrary cache', script: """
  mkdir -p '${env.LIBRARIES}/om-pkg-cache'
  # Remove the symbolic link, or if it's a directory there... the entire thing
  rm libraries/.openmodelica/cache || rm -rf libraries/.openmodelica/cache
  mkdir -p libraries/.openmodelica/
  test ! -e libraries/.openmodelica/cache
  ln -s '${env.LIBRARIES}/om-pkg-cache' libraries/.openmodelica/cache
  ls -lh libraries/.openmodelica/cache/
  """
  generateTemplates()
  sh "touch omc.skip"
  def cmd = "${makeCommand()} -j${numLogicalCPU()} --output-sync=recurse libs-for-testing ReferenceFiles omc-diff ffi-test-lib"
  if (env.SHARED_LOCK) {
    lock(env.SHARED_LOCK) {
      sh cmd
    }
  } else {
    sh cmd
  }
  }
}

/*
 * Perform sanity check.
 *
 * Run script testsuite/sanity-check/runSanity.sh for C and C++ runtime.
 * On Windows a install directory with spaces and three tests with rtest are run as well.
 *
 * @param installDir  Path to omc installation directory.
 * @param buildCpp    True if omc was build with Cpp runtime.
 */
void sanityCheck(String installDir, Boolean buildCpp) {
  if (isWindows()) {
    bat (label: 'Sanity check - C', script: """
      set MSYSTEM=UCRT64
      set MSYS2_PATH_TYPE=inherit
      set PATH=%PATH%;${WORKSPACE}\\${installDir}\\bin;${WORKSPACE}\\${installDir}\\lib\\omc\\omsicpp;${WORKSPACE}\\${installDir}\\lib\\omc\\cpp
      %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -c "cd `cygpath '${WORKSPACE}'` && bash testsuite/sanity-check/runSanity.sh --omc=${installDir}/bin/omc"
    """)
    bat (label: 'Sanity check - Cpp', script: """
      set MSYSTEM=UCRT64
      set MSYS2_PATH_TYPE=inherit
      set PATH=%PATH%;${WORKSPACE}\\${installDir}\\bin;${WORKSPACE}\\${installDir}\\lib\\omc\\omsicpp;${WORKSPACE}\\${installDir}\\lib\\omc\\cpp
      %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -c "cd `cygpath '${WORKSPACE}'` && bash testsuite/sanity-check/runSanity.sh --omc=${installDir}/bin/omc --simCodeTarget=Cpp"
    """)
    bat (label: 'Sanity check - Install dir with spaces', script: """
      set MSYSTEM=UCRT64
      set MSYS2_PATH_TYPE=inherit
      set PATH=%PATH%;${WORKSPACE}\\${installDir} but with spaces\\bin;${WORKSPACE}\\${installDir} but with spaces\\lib\\omc\\omsicpp;${WORKSPACE}\\${installDir} but with spaces\\lib\\omc\\cpp
      move "${installDir}" "${installDir} but with spaces"
      %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -c "cd `cygpath '${WORKSPACE}'` && bash testsuite/sanity-check/runSanity.sh --omc='${installDir} but with spaces/bin/omc'" || (move "${installDir} but with spaces" "${installDir}" && exit 1)
      move "${installDir} but with spaces" "${installDir}"
    """)
    bat (label: "Sanity check - testsuite", script: """
      If Defined LOCALAPPDATA (echo LOCALAPPDATA: %LOCALAPPDATA%) Else (Set "LOCALAPPDATA=C:\\Users\\OpenModelica\\AppData\\Local")
      echo on
      (
      echo export MSYS_WORKSPACE="`cygpath '${WORKSPACE}'`"
      echo echo MSYS_WORKSPACE: \${MSYS_WORKSPACE}
      echo cd \${MSYS_WORKSPACE}
      echo echo Unset OPENMODELICALIBRARY to make sure the default is used
      echo unset OPENMODELICALIBRARY
      echo echo Testing some models from testsuite, ffi, meta, fmi
      echo cd testsuite/flattening/libraries/biochem
      echo ../../../rtest --return-with-error-code EnzMM.mos
      echo cd \${MSYS_WORKSPACE}
      echo cd testsuite/flattening/modelica/ffi
      echo ../../../rtest --return-with-error-code ModelicaInternal_countLines.mos
      echo ../../../rtest --return-with-error-code Integer1.mos
      echo cd \${MSYS_WORKSPACE}
      echo cd testsuite/metamodelica/meta
      echo ../../rtest --return-with-error-code AlgPatternm.mos
      echo echo FMI export+import roundtrip, guards Windows -lfmilib linking against libfmilib.dll
      echo cd \${MSYS_WORKSPACE}
      echo cd testsuite/openmodelica/fmi/ModelExchange/2.0
      echo ../../../../rtest --return-with-error-code HelloFMIWorld.mos
      ) > miniTestsuite.sh

      set MSYSTEM=UCRT64
      set MSYS2_PATH_TYPE=inherit
      set PATH=%PATH%;${WORKSPACE}\\${installDir}\\bin;${WORKSPACE}\\${installDir}\\lib\\omc\\omsicpp;${WORKSPACE}\\${installDir}\\lib\\omc\\cpp
      %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -c "cd `cygpath '${WORKSPACE}'` && chmod +x miniTestsuite.sh && ./miniTestsuite.sh && rm -f ./miniTestsuite.sh"
    """)
  } else {
    sh label: 'Sanity check - C', script: "bash testsuite/sanity-check/runSanity.sh --omc=${installDir}/bin/omc"
    if (buildCpp) {
      sh label: 'Sanity check - Cpp', script: "bash testsuite/sanity-check/runSanity.sh --omc=${installDir}/bin/omc --simCodeTarget=Cpp"
    }
  }
}

void buildOMC(CC, CXX, extraFlags, Boolean buildCpp, Boolean clean) {
  standardSetup()

  if (isWindows()) {
    bat (label: 'build', script: """
      If Defined LOCALAPPDATA (echo LOCALAPPDATA: %LOCALAPPDATA%) Else (Set "LOCALAPPDATA=C:\\Users\\OpenModelica\\AppData\\Local")
      echo on
      (
      echo export MSYS_WORKSPACE="`cygpath '${WORKSPACE}'`"
      echo echo MSYS_WORKSPACE: \${MSYS_WORKSPACE}
      echo cd \${MSYS_WORKSPACE}
      echo export MAKETHREADS=-j16
      echo set -ex
      echo export OPENMODELICAHOME="\${MSYS_WORKSPACE}/build"
      echo export OPENMODELICALIBRARY="\${MSYS_WORKSPACE}/build/lib/omlibrary"
      echo set
      echo which cmake
      echo time make -f Makefile.omdev.mingw \${MAKETHREADS} omc testsuite-depends
      echo cd \${MSYS_WORKSPACE}
      echo make -f Makefile.omdev.mingw \${MAKETHREADS} BUILDTYPE=Release all-runtimes
      ) > buildOMCWindows.sh

      set MSYSTEM=UCRT64
      set MSYS2_PATH_TYPE=inherit
      %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "cd `cygpath '${WORKSPACE}'` && chmod +x buildOMCWindows.sh && ./buildOMCWindows.sh && rm -f ./buildOMCWindows.sh"
    """)
  } else {
    sh 'autoreconf --install'
    // Note: Do not use -march=native since we might use an incompatible machine in later stages
    def withCppRuntime = buildCpp ? "--with-cppruntime":"--without-cppruntime"
    sh "./configure CC='${CC}' CXX='${CXX}' FC=gfortran CFLAGS=-Os ${withCppRuntime} --without-omc --without-omlibrary --with-omniORB --enable-modelica3d --prefix=`pwd`/install ${extraFlags}"
    // OMSimulator requires HOME to be set and writeable
    if (clean) {
      sh label: 'clean', script: "HOME='${env.WORKSPACE}' ${makeCommand()} -j${numPhysicalCPU()} ${outputSync()} clean"
    }
    sh label: 'build', script: "HOME='${env.WORKSPACE}' ${makeCommand()} -j${numPhysicalCPU()} ${outputSync()} omc omc-diff omsimulator"
    sh 'find build/lib/*/omc/ -name "*.so" -exec strip {} ";"'

    // Find unused imports
    sh label: 'Find unused imports', script: 'cd OMCompiler/Compiler/boot && ./find-unused-import.sh ../*/*.mo'
  }

  sanityCheck('build', buildCpp)
}

void buildOMC_CMake(cmake_args, cmake_exe='cmake') {
  standardSetup()

  if (isWindows()) {
    bat (label: 'build', script: """
      If Defined LOCALAPPDATA (echo LOCALAPPDATA: %LOCALAPPDATA%) Else (Set "LOCALAPPDATA=C:\\Users\\OpenModelica\\AppData\\Local")
      echo on
      (
      echo export MSYS_WORKSPACE="`cygpath '${WORKSPACE}'`"
      echo echo MSYS_WORKSPACE: \${MSYS_WORKSPACE}
      echo cd \${MSYS_WORKSPACE}
      echo which cmake
      echo set -ex
      echo mkdir build_cmake
      echo ${cmake_exe} --version
      echo ${cmake_exe} -S ./ -B ./build_cmake ${cmake_args}
      echo time ${cmake_exe} --build ./build_cmake --parallel ${numPhysicalCPU()} --target install
      ) > buildOMCWindows.sh

      set MSYSTEM=UCRT64
      set MSYS2_PATH_TYPE=inherit
      %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "cd `cygpath '${WORKSPACE}'` && chmod +x buildOMCWindows.sh && ./buildOMCWindows.sh && rm -f ./buildOMCWindows.sh"
    """)
  }
  else {
    sh "mkdir ./build_cmake"
    sh "${cmake_exe} --version"
    sh "${cmake_exe} -S ./ -B ./build_cmake ${cmake_args}"
    sh "${cmake_exe} --build ./build_cmake --parallel ${numPhysicalCPU()} --target install"
    sh "${cmake_exe} --build ./build_cmake --parallel ${numPhysicalCPU()} --target testsuite-depends"
  }

  sanityCheck('build', true)
}

// sccache config for the cargo builds: a shared S3 (MinIO) compile cache at
// sccache.openmodelica.org, replacing the per-node /cache/sccache volume so the
// cache is shared across agents (see .CI/sccache/). Incremental must be off for
// sccache to hit. The cache size is bounded server-side (bucket TTL + quota);
// SCCACHE_CACHE_SIZE does not apply to the S3 backend.
//
// RUSTC_WRAPPER is a selective shim (rustc-sccache-wrapper.sh), not sccache
// directly: it only sends the crates.io/git dependencies through sccache and
// runs our own (always-regenerated, never-cached) workspace crates under bare
// rustc, so cargo pipelining survives on the generated-crate chain that
// dominates the build. Absolute path: cargo's CWD is the OpenModelica.rs
// workspace, not the repo root.
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
  standardSetup()
  // RUST_OMC_THREADS=4 parallelises the rustc front-end on the (near-serial)
  // generated-crate chain. Linking uses mold (RUST_OMC_MOLD defaults ON); the
  // image ships a current mold (see .CI/cache/rust/Dockerfile).
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
      -DRUST_OMC_WASM_RUNTIME_OUT=${env.WORKSPACE}/runtime.wasm
  """
  // O3 is the default release opt-level; CI uses O2 to cut build time.
  withSccache(['CARGO_PROFILE_RELEASE_OPT_LEVEL=2']) {
    // install builds the whole tree (incl. rust_omc + the cdylib) and installs in
    // one pass. Don't also pass rust_omc as a goal: recursive sub-makes would re-run
    // the always-run cdylib custom target a second time (a redundant cargo pass).
    sh "cmake --build build_cmake --parallel ${numPhysicalCPU()} --target install"
    sh "build/bin/omc --version"
    sh "cmake --build build_cmake --parallel ${numPhysicalCPU()} --target rust_wasm_runtime"
    sh "cmake --build build_cmake --parallel ${numPhysicalCPU()} --target testsuite-depends"
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
  // without re-running codegen.
  stash name: 'rust-generated-src',
        includes: 'build_cmake/OMCompiler/Compiler/rust-src/**/src/*.rs'
  stash name: 'omc-cmake-rust-gui-inputs',
        includes: 'build_cmake/OMCompiler/Compiler/rust-target/release/libOpenModelicaCompiler.so,' +
                  'build_cmake/OMCompiler/Compiler/scripting-api-qt/**'
}

void buildRustWeb() {
  standardSetup()
  unstash 'wasm-jit-runtime'
  unstash 'runtime-sources-mo'
  // The mmtorust transpile is identical to stage 1's; reuse its generated .rs
  // (RUST_OMC_PREBUILT_GENERATED_SRC below) instead of re-running the codegen.
  unstash 'rust-generated-src'
  sh """
    cmake -S . -B build_web \
      -DCMAKE_BUILD_TYPE=Release \
      -DOM_OMC_WASM=ON \
      -DRUST_OMC_WASM_MODE=web-release \
      -DRUST_OMC_WASM_RUNTIME=${env.WORKSPACE}/runtime.wasm \
      -DRUST_OMC_PREBUILT_GENERATED_SRC=ON \
      -DRUST_OMC_TIMINGS=ON \
      -DOM_USE_CCACHE=OFF \
      -DCMAKE_C_COMPILER_LAUNCHER=sccache \
      -DCMAKE_CXX_COMPILER_LAUNCHER=sccache \
      -DCMAKE_INSTALL_PREFIX=install_web
  """
  withSccache {
    sh "cmake --build build_web --parallel ${numPhysicalCPU()}"
  }
  sh "cmake --install build_web --component web"
  // cargo --timings HTML report for the wasm crate build (RUST_OMC_TIMINGS=ON).
  archiveArtifacts artifacts: 'build_web/OMCompiler/Compiler/rust-target/cargo-timings/cargo-timing-*.html', allowEmptyArchive: true, fingerprint: true
  // Ship the web bundle as a single zip rather than the loose html+js+wasm tree.
  def webZip = "OpenModelicaCompiler-web-${tagName()}.zip"
  sh "rm -f ${webZip} && (cd install_web/share/omc/web && zip -r -9 ${env.WORKSPACE}/${webZip} .)"
  archiveArtifacts artifacts: webZip, fingerprint: true
  stash name: 'web', includes: webZip
}

void buildRustGUI() {
  standardSetup()
  unstash 'omc-cmake-rust-gui-inputs'
  sh """
    cmake -S . -B build_gui \
      -DCMAKE_BUILD_TYPE=Release \
      -DOM_OMC_ENABLE_RUST=ON \
      -DOM_ENABLE_GUI_CLIENTS=ON \
      -DRUST_OMC_PREBUILT_CDYLIB=${env.WORKSPACE}/build_cmake/OMCompiler/Compiler/rust-target/release/libOpenModelicaCompiler.so \
      -DRUST_OMC_PREBUILT_SCRIPTING_API_QT_DIR=${env.WORKSPACE}/build_cmake/OMCompiler/Compiler/scripting-api-qt \
      -DOM_OMC_ENABLE_CPP_RUNTIME=OFF \
      -DOM_USE_CCACHE=OFF \
      -DCMAKE_C_COMPILER_LAUNCHER=sccache \
      -DCMAKE_CXX_COMPILER_LAUNCHER=sccache \
      -DCMAKE_C_COMPILER=clang \
      -DCMAKE_CXX_COMPILER=clang++ \
      -DCMAKE_INSTALL_PREFIX=build_gui_install
  """
  withSccache {
    sh "cmake --build build_gui --parallel ${numPhysicalCPU()}"
  }
}

// One partest shard against the Rust-built omc (unstashed). Builds the test
// libraries with that omc (cmake's libs-for-testing == omc index.mos); the repo's
// index.json is copied into place first so omc uses it instead of downloading.
void partestRust(partition) {
  standardSetup()
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
  sh """#!/bin/bash -x
    ulimit -t 1500
    ulimit -v 6291456
    cd testsuite/partest
    ./runtests.pl -j${numPhysicalCPU()} -partition=${partition}/3 -nocolour -with-xml
    CODE=\$?
    # 0/7 == the run completed (7 means some tests failed); only fail the step on
    # anything else, so junit below still publishes the per-test results.
    test \$CODE = 0 -o \$CODE = 7 || exit 1
  """
  junit 'testsuite/partest/result.xml'
}

// Cargo workspace unit tests as their own stage (parallel with partest), in the
// fast dev/cranelift profile. The generated .rs are unstashed from stage 1, so
// nextest compiles them directly — no codegen rebuild. nextest's `ci` profile
// writes a per-test JUnit report (.config/nextest.toml). The `openmodelica`
// launcher is excluded: its build.rs links the prebuilt cdylib, which this stage
// does not build.
void ctestRust() {
  standardSetup()
  unstash 'rust-generated-src'
  try {
    withSccache {
      sh "cd OMCompiler/Compiler/OpenModelica.rs && cargo nextest run --workspace --exclude openmodelica --profile ci"
    }
  } finally {
    junit testResults: 'OMCompiler/Compiler/OpenModelica.rs/target/nextest/ci/junit.xml', allowEmptyResults: true
  }
}

def getQtMajorVersion(qtVersion) {
  def OM_QT_MAJOR_VERSION = 'OM_QT_MAJOR_VERSION=6'
  if (qtVersion.equals('qt5')) {
    OM_QT_MAJOR_VERSION = 'OM_QT_MAJOR_VERSION=5'
  }
  return OM_QT_MAJOR_VERSION
}

void buildGUI(stash, qtVersion) {
  if (isWindows()) {
  bat ("""
     If Defined LOCALAPPDATA (echo LOCALAPPDATA: %LOCALAPPDATA%) Else (Set "LOCALAPPDATA=C:\\Users\\OpenModelica\\AppData\\Local")
     echo on
     (
     echo export MSYS_WORKSPACE="`cygpath '${WORKSPACE}'`"
     echo echo MSYS_WORKSPACE: \${MSYS_WORKSPACE}
     echo cd \${MSYS_WORKSPACE}
     echo export MAKETHREADS=-j16
     echo set -e
     echo export OPENMODELICAHOME="\${MSYS_WORKSPACE}/build"
     echo export OPENMODELICALIBRARY="\${MSYS_WORKSPACE}/build/lib/omlibrary"
     echo set
     echo which cmake
     echo time make -f Makefile.omdev.mingw \${MAKETHREADS} qtclients ${getQtMajorVersion(qtVersion)}
     echo echo Check that at least OMEdit can be started
     echo ./build/bin/OMEdit --help
     ) > buildGUIWindows.sh

     set MSYSTEM=UCRT64
     set MSYS2_PATH_TYPE=inherit
     %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "cd `cygpath '${WORKSPACE}'` && chmod +x buildGUIWindows.sh && ./buildGUIWindows.sh && rm -f ./buildGUIWindows.sh"
  """)
  } else {

  if (stash) {
    standardSetup()
    unstash stash
  }
  sh 'autoreconf --install'
  if (stash) {
    patchConfigStatus()
  }
  if (qtVersion.equals('qt6')) {
    sh 'echo ./configure --with-qt6 `./config.status --config` > config.status.2 && bash ./config.status.2'
  } else {
    sh 'echo ./configure `./config.status --config` > config.status.2 && bash ./config.status.2'
  }
  // compile OMSens_Qt for Qt5 and Qt6
  if (qtVersion.equals('qt6') || qtVersion.equals('qt5')) {
    sh "touch omc.skip omc-diff.skip ReferenceFiles.skip omsimulator.skip && ${makeCommand()} -j${numPhysicalCPU()} omc omc-diff ReferenceFiles omsimulator omparser omsens_qt" // Pretend we already built omc since we already did so
  } else {
    sh "touch omc.skip omc-diff.skip ReferenceFiles.skip omsimulator.skip omsens_qt.skip && ${makeCommand()} -j${numPhysicalCPU()} omc omc-diff ReferenceFiles omsimulator omparser omsens_qt" // Pretend we already built omc since we already did so
  }
  sh "${makeCommand()} -j${numPhysicalCPU()} ${outputSync()}" // Builds the GUI files

  // test make install after qt builds
  sh label: 'install', script: "HOME='${env.WORKSPACE}' ${makeCommand()} -j${numPhysicalCPU()} ${outputSync()} install ${ignoreOnMac()}"
  }
}

void buildAndRunOMEditTestsuite(stash, qtVersion) {
  if (isWindows()) {
  bat ("""
     If Defined LOCALAPPDATA (echo LOCALAPPDATA: %LOCALAPPDATA%) Else (Set "LOCALAPPDATA=C:\\Users\\OpenModelica\\AppData\\Local")
     echo on
     (
     echo export MSYS_WORKSPACE="`cygpath '${WORKSPACE}'`"
     echo echo MSYS_WORKSPACE: \${MSYS_WORKSPACE}
     echo cd \${MSYS_WORKSPACE}
     echo export MAKETHREADS=-j16
     echo set -e
     echo time make -f Makefile.omdev.mingw \${MAKETHREADS} omedit-testsuite ${getQtMajorVersion(qtVersion)}
     echo export "APPDATA=\${PWD}/libraries"
     echo cd build/bin
     echo ./RunOMEditTestsuite.sh
     ) > buildOMEditTestsuiteWindows.sh

     set MSYSTEM=UCRT64
     set MSYS2_PATH_TYPE=inherit
     %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "cd `cygpath '${WORKSPACE}'` && chmod +x buildOMEditTestsuiteWindows.sh && ./buildOMEditTestsuiteWindows.sh && rm -f ./buildOMEditTestsuiteWindows.sh"
  """)
  } else {

  if (stash) {
    standardSetup()
    sh 'rm -rf OMEdit/common'
    unstash stash
  }
  sh 'autoreconf --install'
  if (stash) {
    patchConfigStatus()
  }
  if (qtVersion.equals('qt6')) {
    sh 'echo ./configure --with-qt6 `./config.status --config` > config.status.2 && bash ./config.status.2'
  } else {
    sh 'echo ./configure `./config.status --config` > config.status.2 && bash ./config.status.2'
  }
  if (stash) {
    makeLibsAndCache()
  }
  sh "touch omc.skip omc-diff.skip ReferenceFiles.skip omsimulator.skip omedit.skip omplot.skip && ${makeCommand()} -j${numPhysicalCPU()} omc omc-diff ReferenceFiles omsimulator omedit omplot omparser" // Pretend we already built omc since we already did so
  sh "${makeCommand()} -j${numPhysicalCPU()} --output-sync=recurse omedit-testsuite" // Builds the OMEdit testsuite
  if (qtVersion.equals('qt6')) {
    // OMEdit compiled with Qt6 crashes in webengine libs on ubuntu
  } else {
    sh label: 'RunOMEditTestsuite', script: '''
    HOME="\$PWD/libraries"
    cd build/bin
    xvfb-run ./RunOMEditTestsuite.sh
    '''
    }
  }
}

void generateTemplates() {
  if (isWindows()) {
  // do nothing
  } else {
  patchConfigStatus()
  // Runs Susan again, for bootstrapping tests, etc
  sh "${makeCommand()} -C OMCompiler/Compiler/Template/ -f Makefile.in OMC=\$PWD/build/bin/omc"
  sh 'cd OMCompiler && ./config.status'
  sh './config.status'
  }
}

void cloneOMDev() {
bat ("""
set HOME=C:\\dev\\
REM taskkill /F /IM omc.exe /T || ECHO.>NUL
REM taskkill /F /IM perl.exe /T || ECHO.>NUL
echo Current directory: %CD%
echo OMDEV: %OMDEV%
If Defined LOCALAPPDATA (echo LOCALAPPDATA: %LOCALAPPDATA%) Else (Set "LOCALAPPDATA=C:\\Users\\OpenModelica\\AppData\\Local")
if not exist "%OMDEV%" (
  echo Checkout %OMDEV%
  cd c:\\
  git clone https://gitlab.liu.se/OpenModelica/OMDevUCRT.git OMDevUCRT
  cd %OMDEV%
  git checkout master
  call SETUP_OMDEV.bat
) else (
  cd %OMDEV%
  git fetch origin
  git reset --hard origin/master
  git pull
  call SETUP_OMDEV.bat
)
""")
}

def getVersion() {
  if (isWindows()) {
  return (bat (script: 'set OMDEV=C:\\OMDevUCRT && set MSYSTEM=UCRT64 && set MSYS2_PATH_TYPE=inherit && %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "build/bin/omc --version | grep -o \"v[0-9]\\+[.][0-9]\\+[.][0-9]\\+[^ ]*\""', returnStdout: true)).replaceAll("\\s","")
  } else {
  return (sh (script: 'build/bin/omc --version | grep -o "v[0-9]\\+[.][0-9]\\+[.][0-9]\\+[^ ]*"', returnStdout: true)).replaceAll("\\s","")
  }
}

void compliance() {
  if (isWindows()) {
    // do nothing for now
  } else {
  standardSetup()
  unstash 'omc-clang'
  makeLibsAndCache()
  sh 'HOME=$PWD/libraries/ build/bin/omc -g=MetaModelica build/share/doc/omc/testmodels/ComplianceSuite.mos'
  sh "mv ${env.COMPLIANCEPREFIX}.html ${env.COMPLIANCEPREFIX}-current.html"
  sh "test -f ${env.COMPLIANCEPREFIX}.xml"
  // Only publish openmodelica-current.html if we are running master
  sh "cp -p ${env.COMPLIANCEPREFIX}-current.html ${env.COMPLIANCEPREFIX}${cacheBranch()=='master' ? '' : ('-' + cacheBranchEscape())}-${getVersion()}.html"
  sh "test ! '${cacheBranch()}' = 'master' || rm -f ${env.COMPLIANCEPREFIX}-current.html"
  stash name: "${env.COMPLIANCEPREFIX}", includes: "${env.COMPLIANCEPREFIX}-*.html"
  archiveArtifacts "${env.COMPLIANCEPREFIX}*${getVersion()}.html, ${env.COMPLIANCEPREFIX}.failures"
  // get rid of freaking %
  sh "sed -i.bak 's/%/\\&#37;/g' ${env.COMPLIANCEPREFIX}.ignore.xml && sed -i.bak 's/[^[:print:]]/ /g' ${env.COMPLIANCEPREFIX}.ignore.xml"
  junit "${env.COMPLIANCEPREFIX}.ignore.xml"
  }
}

def cacheBranch() {
  return "${env.CHANGE_TARGET ?: env.GIT_BRANCH}"
}

def cacheBranchEscape() {
  def name = (cacheBranch()).replace('maintenance/v','')
  name = name.replace('/','-')
  return name
}

def tagName() {
  def name = env.TAG_NAME ?: cacheBranchEscape()
  return name == "master" ? "latest" : name
}

def makeCommand() {
  // OSX uses gmake as the GNU make program
  return env.GMAKE ?: "make"
}

def shouldWeBuildUCRT() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/Build MSYS2-UCRT64")) {
      return true
    }
  }
  return params.BUILD_MSYS2_UCRT64
}

def shouldWeDisableAllCMakeBuilds() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/CMake/Disable/All")) {
      return true
    }
  }
  return params.DISABLE_ALL_CMAKE_BUILDS
}

def shouldWeEnableUCRTCMakeBuild() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/CMake/Enable/MSYS2-UCRT64")) {
      return true
    }
  }
  return params.ENABLE_MSYS2_UCRT64_CMAKE_BUILD
}

def shouldWeEnableMacOSCMakeBuild() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/CMake/Enable/macOS")) {
      return true
    }
  }
  return params.ENABLE_MACOS_CMAKE_BUILD
}

def shouldWeRunTests() {
  if (isPR()) {
    def skipTestsFilesList = [".*[.]md",
                              "OMEdit/.*",
                              "OMNotebook/.*",
                              "OMPlot/.*",
                              "OMShell/.*"]
    def runTest = false
    for (commitFile in pullRequest.files) {
      def results = skipTestsFilesList.findAll {element -> commitFile.filename.matches(element)}
      if (results.size() > 0) {
        continue
      } else {
        runTest = true
        break;
      }
    }
    return runTest
  }
  return true
}

def isPR() {
  return env.CHANGE_ID ? true : false
}

def outputSync()
{
 def osync = sh(script: "${makeCommand()} --version | grep -o -E '[0-9]+' | head -1 | sed -e 's/^0\\+//'", returnStdout: true).toInteger() >= 4 ? "--output-sync=recurse" : ""
 return osync;
}


def ignoreOnMac() {
  def uname = sh script: 'uname', returnStdout: true
  def ignore = ""
  if (uname.startsWith("Darwin")) {
    ignore = "|| true"
  }
  return ignore;
}

return this
