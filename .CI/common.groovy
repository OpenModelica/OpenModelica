
def isWindows() {
  return !isUnix()
}

def isMac() {
  return isUnix() && sh(script: 'uname', returnStdout: true).startsWith("Darwin")
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

// 6 GB per parallel test job, at most 80% of the node's RAM. Override 6 and 80
// with OM_PARTEST_MEM_PER_JOB_GB / OM_PARTEST_MEM_PERCENT when a machine hosts
// more than one Jenkins instance. The arithmetic is awk's because the Groovy
// sandbox rejects most of the numeric conversions this would otherwise need.
String testMemoryLimitMB() {
  String vars = "-v jobs=${numPhysicalCPU()}" +
                " -v per_job=\"\${OM_PARTEST_MEM_PER_JOB_GB:-6}\"" +
                " -v percent=\"\${OM_PARTEST_MEM_PERCENT:-80}\""
  String prog = '/^MemTotal:/ { cap = int($2/1024*percent/100); want = per_job*1024*jobs; print (want < cap ? want : cap) }'
  return sh(script: "awk ${vars} '${prog}' /proc/meminfo", returnStdout: true).trim()
}

// The container's cgroup memory.max: covers every process the run spawns and
// charges memory in use, not address space. --memory-swap must equal --memory to
// forbid swapping; docker reads 0 as "unset" and then allows swap up to --memory.
String memoryLimitArgs() {
  String mb = testMemoryLimitMB()
  echo "Test container memory limit: ${mb} MB, no swap"
  return "--memory=${mb}m --memory-swap=${mb}m"
}

String testCacheMounts(String runtestCache) {
  return "--mount type=volume,source=${runtestCache},target=/cache/runtest " +
         "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
         "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
}

// Not an `agent { docker { args } }`: those args are evaluated before a node is
// allocated, so the limit could not depend on the node's RAM or CPU count.
void insideTestImage(String image, String extraArgs, Closure body) {
  def img = docker.image(image)
  img.pull()
  img.inside("${memoryLimitArgs()} ${extraArgs}") {
    body()
  }
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
  // omc-diff is built and installed into build/bin by the CMake 'install' target
  // (testsuite/difftool/CMakeLists.txt), so it travels with the stashed build
  // tree; just check the stashed one is usable, like partestRust does.
  sh label: 'Check the omc-diff version', script: 'build/bin/omc-diff -v1.4'

  // Susan's generated *.mo live in the CMake build tree.
  withEnv(["OMCOMPILERGENERATEDSOURCES=${generatedMoDir()}"]) {
  sh (label: "Run the testsuite (partition ${partition}/${partitionmodulo}${extraArgs ? ', ' + extraArgs : ''})", script: """#!/bin/bash -x
  ulimit -t 1500
  # On top of the cgroup limit, to catch a single runaway process early
  ulimit -v 6291456 # Max 6GB per process

  .CI/scripts/cgroup-memory.sh check
  cd testsuite/partest
  ./runtests.pl -j${numPhysicalCPU()} -partition=${partition}/${partitionmodulo} -nocolour -with-xml ${extraArgs}
  CODE=\$?
  ../../.CI/scripts/cgroup-memory.sh report
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

  }

  junit 'testsuite/partest/result.xml'
}

// Link the shared package cache into the workspace and install the testsuite
// libraries with the omc in build/. These are the steps of cmake's
// libs-for-testing target (wipe, copy index.json so omc uses the repo's pinned
// versions instead of downloading an index, run index.mos), spelled out because
// the stages calling this unstash an install tree, not a configured build tree,
// so no CMake target is available to them.
void installTestLibraries() {
  // env.WORKSPACE is null in the docker agent, so link the package cache afterwards
  sh label: 'Install the testsuite libraries', script: """#!/bin/bash -xe
  test ! -z '${env.LIBRARIES}'
  mkdir -p '${env.LIBRARIES}/om-pkg-cache'
  # Removes the symbolic link, or if it's a directory there... the entire thing
  rm -rf libraries/.openmodelica/cache libraries/.openmodelica/libraries
  mkdir -p libraries/.openmodelica/libraries
  ln -s '${env.LIBRARIES}/om-pkg-cache' libraries/.openmodelica/cache
  ls -lh libraries/.openmodelica/cache/
  cp libraries/index.json libraries/.openmodelica/libraries/
  ( cd libraries && "\$PWD/../build/bin/omc" index.mos )
  """
}

// The Susan-generated *.mo files live in the CMake build tree, not next to the
// templates they come from. Tests that load the compiler sources by path (the
// bootstrapping tests, MatlabTranslator) read OMCOMPILERGENERATEDSOURCES to find
// them; see testsuite/rtest and Compiler/.cmake/template_compilation.cmake.
// env.WORKSPACE is null in the docker agent, so read the path from pwd.
String generatedMoDir() {
  def ws = sh(script: 'pwd', returnStdout: true).trim()
  return "${ws}/build_cmake/OMCompiler/Compiler/generated-mo"
}

// Build the testsuite dependencies against an installed omc in build/, for the
// stages that unstash an install tree rather than a configured build tree (so
// no CMake target is available to them). ReferenceFiles and the FFI test
// library have standalone Makefiles of their own. omc-diff is not built here:
// the CMake 'install' target already put it in build/bin.
void makeLibsAndCache() {
  // If we don't have any result, copy to the master to get a somewhat decent cache
  sh "cp -f ${env.RUNTESTDB}/${cacheBranchEscape()}/runtest.db.* testsuite/ || " +
     "cp -f ${env.RUNTESTDB}/master/runtest.db.* testsuite/ || true"
  def cmd = """#!/bin/bash -xe
  # ffi-test-lib
  ${makeCommand()} -C testsuite/flattening/modelica/ffi/FFITest/Resources/BuildProjects/gcc
  """
  if (env.SHARED_LOCK) {
    lock(env.SHARED_LOCK) {
      installTestLibraries()
      extractReferenceFiles()
      sh cmd
    }
  } else {
    installTestLibraries()
    extractReferenceFiles()
    sh cmd
  }
}

// Decompress testsuite/ReferenceFiles/*/*.mat.xz next to themselves, where the
// tests read them ($REFERENCEFILES, set by rtest). Every stage that runs
// partest has to call this (or makeLibsAndCache()) first.
void extractReferenceFiles() {
  sh label: 'Extract the reference files',
     script: "${makeCommand()} -j${numLogicalCPU()} --output-sync=recurse -C testsuite/ReferenceFiles"
}

/*
 * Perform sanity check.
 *
 * Run script testsuite/sanity-check/runSanity.sh for C and C++ runtime.
 * On Windows an install directory with spaces is checked as well. Only bin/
 * goes on the PATH; the generated <model>.bat adds the runtime's
 * lib/<triple>/omc, which only omc knows the triple of. The Windows
 * testsuite smoke set runs separately, see runWindowsTestsuite() and the
 * 'testsuite-windows' stage: it is its own stage rather than part of the
 * build/sanity-check step so a test failure is reported distinctly from a
 * build failure, and so the stage can grow (more tests, more Windows
 * compute) without touching the build step at all.
 *
 * @param installDir  Path to omc installation directory.
 * @param buildCpp    True if omc was build with Cpp runtime.
 */
void sanityCheck(String installDir, Boolean buildCpp) {
  if (isWindows()) {
    bat (label: 'Sanity check - C', script: """
      set MSYSTEM=UCRT64
      set MSYS2_PATH_TYPE=inherit
      set PATH=%PATH%;${WORKSPACE}\\${installDir}\\bin
      %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -c "cd `cygpath '${WORKSPACE}'` && bash testsuite/sanity-check/runSanity.sh --omc=${installDir}/bin/omc"
    """)
    bat (label: 'Sanity check - Cpp', script: """
      set MSYSTEM=UCRT64
      set MSYS2_PATH_TYPE=inherit
      set PATH=%PATH%;${WORKSPACE}\\${installDir}\\bin
      %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -c "cd `cygpath '${WORKSPACE}'` && bash testsuite/sanity-check/runSanity.sh --omc=${installDir}/bin/omc --simCodeTarget=Cpp"
    """)
    bat (label: 'Sanity check - Install dir with spaces', script: """
      set MSYSTEM=UCRT64
      set MSYS2_PATH_TYPE=inherit
      set PATH=%PATH%;${WORKSPACE}\\${installDir} but with spaces\\bin
      move "${installDir}" "${installDir} but with spaces"
      %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -c "cd `cygpath '${WORKSPACE}'` && bash testsuite/sanity-check/runSanity.sh --omc='${installDir} but with spaces/bin/omc'" || (move "${installDir} but with spaces" "${installDir}" && exit 1)
      move "${installDir} but with spaces" "${installDir}"
    """)
  } else {
    sh label: 'Sanity check - C', script: "bash testsuite/sanity-check/runSanity.sh --omc=${installDir}/bin/omc"
    if (buildCpp) {
      sh label: 'Sanity check - Cpp', script: "bash testsuite/sanity-check/runSanity.sh --omc=${installDir}/bin/omc --simCodeTarget=Cpp"
    }
  }
}

/*
 * Run the testsuite smoke set (testsuite/runWindowsTests.sh) against an
 * installed omc. Split out of sanityCheck() so it can run as its own
 * 'tests + extras' stage: see testWindowsSmoke().
 *
 * A test opts into this set with '// suite: smoke' in its own header; there is
 * no separate list of Windows tests to maintain here or on disk.
 *
 * @param installDir  Path to omc installation directory.
 */
void runWindowsTestsuite(String installDir) {
  bat (label: "Windows testsuite", script: """
    If Defined LOCALAPPDATA (echo LOCALAPPDATA: %LOCALAPPDATA%) Else (Set "LOCALAPPDATA=C:\\Users\\OpenModelica\\AppData\\Local")
    set MSYSTEM=UCRT64
    set MSYS2_PATH_TYPE=inherit
    set PATH=%PATH%;${WORKSPACE}\\${installDir}\\bin
    %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -c "cd `cygpath '${WORKSPACE}'` && bash testsuite/runWindowsTests.sh"
  """)
}

/*
 * Install the one Modelica Standard Library version the Windows smoke set
 * needs (libraries/install-windows-smoke.mos), via the omc that
 * runWindowsTestsuite() below is about to run against. Only issue10523.mos
 * (an FMI 2.0 CoSimulation export test in the smoke suite) needs this;
 * every other test in the set runs against nothing but omc itself, same as
 * before. There is no shared package cache wired up for Windows agents
 * (installTestLibraries()'s env.LIBRARIES is a Unix path), so this reaches
 * the default remote package index directly.
 *
 * @param installDir  Path to omc installation directory.
 */
void installWindowsSmokeLibrary(String installDir) {
  bat (label: "Install Modelica for the Windows smoke set", script: """
    If Defined LOCALAPPDATA (echo LOCALAPPDATA: %LOCALAPPDATA%) Else (Set "LOCALAPPDATA=C:\\Users\\OpenModelica\\AppData\\Local")
    set MSYSTEM=UCRT64
    set MSYS2_PATH_TYPE=inherit
    set PATH=%PATH%;${WORKSPACE}\\${installDir}\\bin
    %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -c "cd `cygpath '${WORKSPACE}/libraries'` && omc install-windows-smoke.mos"
  """)
}

/**
 * Configure and build OMC via CMake, and run the sanity check.
 *
 * Detects the current platform and applies the platform-specific setup
 * itself, so callers never need to wrap this in their own withEnv/OMDev
 * boilerplate:
 *  - Windows: clones/updates OMDev and extends PATH with its MSYS2 toolchain.
 *  - macOS: prefers Homebrew/MacPorts tools on PATH.
 *  - Linux: no extra setup.
 *
 * @param cmake_args list of individual CMake "-DFOO=BAR"-style arguments
 *                   (not a pre-joined string); they are joined with spaces
 *                   before being passed to the cmake CLI.
 * @param cmake_exe  the cmake executable to invoke.
 * @param testDeps   also build the 'testsuite-depends' target. Pass false on every
 *                   path that goes on to partest(): those all call
 *                   makeLibsAndCache() first, and that one links the shared
 *                   omlibrary cache before building the same dependencies, so
 *                   doing it here just downloads them a second time uncached.
 */
void buildOMC(List cmake_args, cmake_exe='cmake', Boolean testDeps=true) {
  echo "Running on: ${env.NODE_NAME}"
  standardSetup()

  def cmake_args_str = cmake_args.join(' ')

  if (isWindows()) {
    withEnv (["OMDEV=C:\\OMDevUCRT",
              "PATH=${env.OMDEV}\\tools\\msys\\usr\\bin;${env.OMDEV}\\tools\\msys\\ucrt64;c:\\bin\\jdk\\bin;c:\\bin\\nsis\\;${env.PATH};c:\\bin\\git\\bin;"]) {
      bat "echo PATH: %PATH%"
      cloneOMDev()
      bat (label: 'build', script: """
        If Defined LOCALAPPDATA (echo LOCALAPPDATA: %LOCALAPPDATA%) Else (Set "LOCALAPPDATA=C:\\Users\\OpenModelica\\AppData\\Local")
        echo on
        (
        echo export MSYS_WORKSPACE="`cygpath '${WORKSPACE}'`"
        echo echo MSYS_WORKSPACE: \${MSYS_WORKSPACE}
        echo cd \${MSYS_WORKSPACE}
        echo which cmake
        echo set -ex
        echo trap 'echo "buildOMCWindows.sh: command failed, exit code \$?"' ERR
        echo mkdir build_cmake
        echo ${cmake_exe} --version
        echo ${cmake_exe} -S ./ -B ./build_cmake ${cmake_args_str}
        echo time ${cmake_exe} --build ./build_cmake --parallel ${numPhysicalCPU()} --target install
        ) > buildOMCWindows.sh

        set MSYSTEM=UCRT64
        set MSYS2_PATH_TYPE=inherit
        %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "cd `cygpath '${WORKSPACE}'` && chmod +x buildOMCWindows.sh && ./buildOMCWindows.sh && rm -f ./buildOMCWindows.sh"
      """)
      sanityCheck('build', true)
      // For the 'testsuite-windows' stage (testWindowsSmoke()): same 'build/**'
      // shape the other CMake stashes use, so the tests it runs need nothing
      // beyond the install tree.
      stash name: 'omc-windows', includes: 'build/**'
    }
  }
  else if (isMac()) {
    withEnv (["PATH=/opt/homebrew/bin:/opt/homebrew/opt/openjdk/bin:/usr/local/bin:${env.PATH}"]) {
      sh "echo PATH: $PATH"
      sh "mkdir ./build_cmake"
      sh "${cmake_exe} --version"
      sh "${cmake_exe} -S ./ -B ./build_cmake ${cmake_args_str}"
      sh "${cmake_exe} --build ./build_cmake --parallel ${numPhysicalCPU()} --target install"
      if (testDeps) {
        sh "${cmake_exe} --build ./build_cmake --parallel ${numPhysicalCPU()} --target testsuite-depends"
      }
      sh "build/bin/omc --version"
      sanityCheck('build', true)
    }
  }
  else {
    sh "mkdir ./build_cmake"
    sh "${cmake_exe} --version"
    sh "${cmake_exe} -S ./ -B ./build_cmake ${cmake_args_str}"
    sh "${cmake_exe} --build ./build_cmake --parallel ${numPhysicalCPU()} --target install"
    if (testDeps) {
      sh "${cmake_exe} --build ./build_cmake --parallel ${numPhysicalCPU()} --target testsuite-depends"
    }
    sh "build/bin/omc --version"
    sanityCheck('build', true)
  }
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
    // Normalise the per-job workspace prefix out of the cache keys. SCCACHE_BASEDIRS
    // (sccache's CCACHE_BASEDIR) strips it from the C/C++ preprocessor output before
    // hashing, but not from the command line, so a compile that spells the workspace
    // out in its arguments (CMake emits absolute -I and source paths) still only hits
    // at the identical path. It must be absolute and must be in the environment of
    // *every* sccache call, since a client auto-restarts a timed-out server and the
    // restarted server inherits the env. env.WORKSPACE is unreliable in the docker
    // agent (see makeLibsAndCache), so read it from pwd.
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

// The release profile ships LTO at -O3. A lane that builds an omc to test rather
// than to distribute wants none of it: the link is serial and nothing before it
// is reusable.
List cheapReleaseProfile() {
  return ['CARGO_PROFILE_RELEASE_OPT_LEVEL=2',
          'CARGO_PROFILE_RELEASE_LTO=false',
          'CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16']
}

void buildRustOMC() {
  standardSetup()
  // RUST_OMC_THREADS=4 parallelises the rustc front-end on the (near-serial)
  // generated-crate chain. Linking uses mold (RUST_OMC_MOLD defaults ON); the
  // image ships a current mold. OM_ENABLE_RUST_SIM_RUNTIME is what the
  // RUST_PARTEST_SIMCODETARGET=C+Rust partest links against.
  sh """
    cmake -S . -B build_cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DOM_OMC_ENABLE_RUST=ON \
      -DRUST_OMC_CI=ON \
      -DOM_ENABLE_RUST_SIM_RUNTIME=ON \
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
  withSccache(cheapReleaseProfile()) {
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
  stash name: 'omc-rust',
        includes: 'build/**,' +
                  'testsuite/flattening/modelica/ffi/FFITest/Resources/Library/**'
  // The mmtorust/susan-generated .rs, so the unit-tests-rust stage runs cargo test
  // without re-running codegen. stash reaches only inside the workspace, so stage
  // them there first, relative to the working copy root.
  sh """
    rm -rf rust-generated-src && mkdir -p rust-generated-src
    cd ${rustWorkDir()}/rust-src/Compiler/OpenModelica.rs
    find . -path '*/src/*.rs' -print0 |
      tar --null -T - -cf - | tar -C ${env.WORKSPACE}/rust-generated-src -xf -
  """
  stash name: 'rust-generated-src',
        includes: 'rust-generated-src/**,' +
                  'build_cmake/rust-wasi-pic-sysroot/**,' +
                  'build_cmake/rust-sundials-wasm/**,' +
                  'build_cmake/downloads/wasi_snapshot_preview1.reactor.wasm'
  stash name: 'omc-rust-gui-inputs',
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
  sh "mkdir -p ${rustWorkDir()}/rust-src/Compiler/OpenModelica.rs && cp -a rust-generated-src/. ${rustWorkDir()}/rust-src/Compiler/OpenModelica.rs/"
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
  standardSetup()
  unstash 'wasm-jit-runtime'
  unstash 'runtime-sources-mo'
  restoreGeneratedSrc()
  unstash 'omc-rust-gui-inputs'
  unstash 'fmu-loaders'
  configureWeb('-DRUST_OMC_WEB_QT=OFF')
  withEmSccache {
    sh "cmake --build build_cmake --parallel ${numPhysicalCPU()}"
  }
  sh "cmake --install build_cmake --component web"
  // cargo --timings HTML report for the wasm crate build (RUST_OMC_TIMINGS=ON).
  archiveArtifacts artifacts: 'build_cmake/OMCompiler/Compiler/rust-target/cargo-timings/cargo-timing-*.html', allowEmptyArchive: true, fingerprint: true
  stash name: 'web-partial', includes: 'install_web/share/omc/web/**'
}

// OMEdit's cloud-storage OAuth registrations, from the secret-file credential
// `OMEDIT_CLOUD_API_KEYS_WEB` (see OMEdit/OMEditGUI/wasm/CLOUD-STORAGE.md).
// Master only: the registration names playground.openmodelica.org. `body` gets
// the cmake flag, always passed since the variable is cached.
void withOmeditCloudConfig(Closure body) {
  if (isPR() || env.BRANCH_NAME != 'master') {
    echo "${env.BRANCH_NAME} is not master: building OMEdit-qt web without the cloud-storage configuration"
    body('-DOMEDIT_CLOUD_CONFIG=')
    return
  }
  // The bound file exists for the closure only, so configure/build/install are
  // all inside it. Expanded by the shell, not Groovy, to keep it out of the log.
  withCredentials([file(credentialsId: 'OMEDIT_CLOUD_API_KEYS_WEB', variable: 'OMEDIT_CLOUD_CONFIG')]) {
    body('-DOMEDIT_CLOUD_CONFIG=$OMEDIT_CLOUD_CONFIG')
  }
}

// The Qt web pages (OMShell/OMNotebook/OMEdit-qt) alone, off the stage-1 prebuilt
// omc. OMEDIT_WASM_OPTIMIZE=ON always: an -O0 OMEdit link does not run in the
// browser (see rust_omc.cmake).
void buildRustWebQt() {
  standardSetup()
  unstash 'wasm-jit-runtime'
  unstash 'runtime-sources-mo'
  restoreGeneratedSrc()
  unstash 'omc-rust-gui-inputs'
  withOmeditCloudConfig { cloudConfigFlag ->
    configureWeb("-DRUST_OMC_WEB_QT=OFF -DRUST_OMC_WEB_QT_STANDALONE=ON -DOMEDIT_WASM_OPTIMIZE=ON ${cloudConfigFlag}")
    withEmSccache {
      sh "cmake --build build_cmake --parallel ${numPhysicalCPU()} --target rust_omshell_qt_web rust_omnotebook_qt_web rust_omedit_qt_web"
    }
    sh "cmake --install build_cmake --component web"
  }
  stash name: 'web-qt', includes: 'install_web/share/omc/web/OMShell-qt/**, install_web/share/omc/web/OMNotebook-qt/**, install_web/share/omc/web/OMEdit-qt/**'
}

// Merge the Qt pages into the main web tree (both unstash to the same path), zip.
void assembleWeb() {
  unstash 'web-partial'
  unstash 'web-qt'
  def webZip = "OpenModelicaCompiler-web-${tagName()}.zip"
  sh "rm -f ${webZip} && (cd install_web/share/omc/web && zip -r -9 ${env.WORKSPACE}/${webZip} .)"
  archiveArtifacts artifacts: webZip, fingerprint: true
  stash name: 'web', includes: webZip

  // The testsuite-rust shards, merged and archived. Here since the web
  // deliverable is already assembled.
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
  standardSetup()
  unstash 'omc-rust-gui-inputs'
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
    sh "cmake --build build_cmake --parallel ${numPhysicalCPU()}"
  }
}

// ---------------------------------------------------------------------------
// Nightly cross builds. The stages are in .CI/Jenkinsfile.rust-nightly, which
// says what runs where; here is what each stage does.
//
// buildRustNightlyShared() builds everything that does not depend on the target
// platform (the transpile, the Qt scripting-API sources, the wasm half of omc,
// the FMU loaders) and hands it over as one stash, so a target stage runs
// neither the MetaModelica transpiler nor any wasm toolchain -- it compiles Rust
// and C/C++ for its own target and nothing else.
// ---------------------------------------------------------------------------

// Stage 1's output, and where every later stage unstashes it. Relative to the
// workspace: a stash cannot reach outside it.
String nightlySharedDir() { return 'nightly-shared' }

// Install prefix for one target. The omc stage and the GUI stage install into
// the same prefix and stash it under different names, so the packaging stage
// gets one merged tree by unstashing both.
String nightlyInstallDir(String name) { return "install/${name}" }

// The macOS Qt kit in the rust-qt-mac image: the GUI stages configure against it,
// the packaging stage deploys its frameworks into the bundle.
String qtMacPrefix() { return '/opt/Qt/6.11.2/macos' }

// The Linux Qt kit in the ubuntu-22.04 image. Same 6.11.2 the other platforms
// ship, rather than 22.04's packaged 6.2.4, so the three clients are one version.
String qtLinuxPrefix() { return '/opt/Qt/6.11.2/gcc_64' }

// One nightly cross target:
//   triple    the rustc target triple (RUST_OMC_TARGET, and cargo's subdirectory)
//   toolchain the CMake toolchain file for the C/C++ half of the tree
//   configure the flags only this platform needs
//   qt        the Qt kit for the GUI stage; empty = not configured yet, which
//             makes the stage error out rather than build without Qt
//   sccache   whether this target's C/C++ compiler can run under sccache
//   cdylib    the file name cargo gives libOpenModelicaCompiler for it
//   multiarch the Linux targets' <triple> under lib/; absent elsewhere
//   arch      the Linux targets' archive-name architecture
Map nightlyTarget(String name) {
  String rs = 'OMCompiler/Compiler/OpenModelica.rs/.cmake'
  // Fortran is off for both: flang compiles for either target but links for
  // neither (no flang_rt/clang_rt.builtins), and MOO/optimization need it.
  List noFortran = ['-DOM_OMC_ENABLE_FORTRAN=OFF',
                    '-DOM_OMC_ENABLE_MOO=OFF',
                    '-DOM_OMC_ENABLE_OPTIMIZATION=OFF']
  // Qt's one macOS desktop kit is universal, so both targets share it.
  List qtMac = ["-DCMAKE_PREFIX_PATH=${qtMacPrefix()}",
                '-DQT_HOST_PATH=/opt/Qt/6.11.2/gcc_64']
  Map all = [
    'win64': [
      triple: 'x86_64-pc-windows-msvc',
      toolchain: "${rs}/xwin-toolchain.cmake",
      // OpenBLAS, Boost and PThreads4W are fetched/built by windows-deps.cmake,
      // which the top-level CMakeLists includes when cross-compiling to Windows.
      configure: noFortran + ['-DENABLE_CPACK=OFF', '-DZMQ_BUILD_TESTS=OFF'],
      qt: ['-DCMAKE_PREFIX_PATH=/opt/Qt/6.11.2/msvc2022_64',
           '-DQT_HOST_PATH=/opt/Qt/6.11.2/gcc_64'],
      sccache: true,
      cdylib: 'OpenModelicaCompiler.dll',
    ],
    'mac-x86_64': [
      triple: 'x86_64-apple-darwin',
      toolchain: "${rs}/darwin-toolchain.cmake",
      // ColPack's SMPGC includes omp.h unconditionally and zig ships no OpenMP.
      configure: noFortran + ['-DDARWIN_ARCH=x86_64',
                              "-DDARWIN_SDK=${fmuMacosSdk()}",
                              '-DOM_OMC_ENABLE_COLPACK=OFF'],
      qt: qtMac,
      // `zig cc` reaches the compiler through a generated shell wrapper, which
      // sccache does not recognise as a compiler.
      sccache: false,
      cdylib: 'libOpenModelicaCompiler.dylib',
    ],
    'mac-aarch64': [
      triple: 'aarch64-apple-darwin',
      toolchain: "${rs}/darwin-toolchain.cmake",
      configure: noFortran + ['-DDARWIN_ARCH=arm64',
                              "-DDARWIN_SDK=${fmuMacosSdk()}",
                              '-DOM_OMC_ENABLE_COLPACK=OFF'],
      qt: qtMac,
      sccache: false,
      cdylib: 'libOpenModelicaCompiler.dylib',
    ],
    // The only native target. It builds on 22.04 rather than the 26.04 image
    // the other stages use because the distribution's glibc floor is its build
    // host's, and Qt's own binaries stop at 2.34 -- so 22.04 (2.35) is as low as
    // anything linking Qt can go, and cross-compiling would buy nothing.
    'linux64': [
      triple: '',
      toolchain: '',
      configure: [],
      qt: ["-DCMAKE_PREFIX_PATH=${qtLinuxPrefix()}",
           '-DOM_OMEDIT_ANIMATION_QUICK3D=ON'],
      sccache: true,
      cdylib: 'libOpenModelicaCompiler.so',
      arch: 'x86_64',
      multiarch: 'x86_64-linux-gnu',
    ],
    // Cross-compiled on the same 22.04 floor with the distribution's own GNU
    // cross toolchain (the qt-aarch64-linux add-on), which has a real gfortran,
    // so Fortran stays in. Qt publishes no ARM64 Linux kit below GLIBC_2.38 and
    // linux-deploy.sh cannot bundle the distribution's own layout, so this
    // target is CLI-only: qt: [] makes the GUI stage error out.
    'linux-aarch64': [
      triple: 'aarch64-unknown-linux-gnu',
      toolchain: "${rs}/linux-cross-toolchain.cmake",
      configure: [],
      qt: [],
      sccache: true,
      cdylib: 'libOpenModelicaCompiler.so',
      arch: 'aarch64',
      multiarch: 'aarch64-linux-gnu',
    ],
  ]
  Map t = all[name]
  if (!t) {
    error("unknown nightly cross target '${name}'")
  }
  t.name = name
  return t
}

// The flags that hand stage 1's artifacts to a target stage. RUST_OMC_WORK_DIR
// is where restoreNightlyShared() laid the generated Rust down.
List nightlyHandoverFlags() {
  String d = "${env.WORKSPACE}/${nightlySharedDir()}"
  return ['-DRUST_OMC_PREBUILT_GENERATED_SRC=ON',
          "-DRUST_OMC_WORK_DIR=${rustWorkDir()}",
          "-DRUST_OMC_PREBUILT_WASM_DIR=${d}/wasm",
          "-DRUST_OMC_FMU_LOADERS=${d}/fmu-loaders",
          "-DRUST_OMC_FMU_NATIVE_TARGETS=${fmuNativeTargets()}",
          "-DRUST_OMC_MACOS_SDK=${fmuMacosSdk()}"]
}

// Stage 1: the target-independent half of an omc build.
void buildRustNightlyShared() {
  standardSetup()
  String d = "${env.WORKSPACE}/${nightlySharedDir()}"
  sh "rm -rf ${d} && mkdir -p ${d}"
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
      -DRUST_OMC_THREADS=4 \
      -DRUST_OMC_WORK_DIR=${rustWorkDir()} \
      -DRUST_OMC_FMU_NATIVE_TARGETS=${fmuNativeTargets()} \
      -DRUST_OMC_MACOS_SDK=${fmuMacosSdk()} \
      -DOM_DOWNLOADS_DIR=/cache/thirdparty \
      -DRUST_OMC_WASM_ARTIFACTS_OUT=${d}/wasm
  """
  withSccache {
    // rust_codegen is susan + mmtorust + the Qt scripting API sources;
    // rust_wasm_runtime and rust_wasm_artifacts are the wasm blobs and the FMU
    // loaders. The compiler itself is deliberately not built here: every byte of
    // it is target-specific, so each target stage builds its own.
    sh "cmake --build build_cmake --parallel ${numPhysicalCPU()} --target rust_codegen rust_wasm_runtime rust_wasm_artifacts"
  }
  // The generated .rs, staged flat so a target stage can lay them straight back
  // into its own working copy (restoreNightlyShared).
  sh """
    rm -rf ${d}/rust-generated-src && mkdir -p ${d}/rust-generated-src
    cd ${rustWorkDir()}/rust-src/Compiler/OpenModelica.rs
    find . -path '*/src/*.rs' -print0 |
      tar --null -T - -cf - | tar -C ${d}/rust-generated-src -xf -
  """
  sh """
    cp -a build_cmake/OMCompiler/Compiler/fmu-loaders ${d}/fmu-loaders
    cp -a build_cmake/OMCompiler/Compiler/scripting-api-qt ${d}/scripting-api-qt
    du -sh ${d}/*
  """
  stash name: 'nightly-shared', includes: "${nightlySharedDir()}/**"
}

// Lay stage 1's hand-over back down: the stash into the workspace, and the
// generated .rs into the working copy the cmake configure mirrors from. Must run
// after standardSetup(), which cleans the workspace.
void restoreNightlyShared() {
  unstash 'nightly-shared'
  sh """
    mkdir -p ${rustWorkDir()}/rust-src/Compiler/OpenModelica.rs
    cp -a ${nightlySharedDir()}/rust-generated-src/. ${rustWorkDir()}/rust-src/Compiler/OpenModelica.rs/
  """
}

// The configure flags shared by a target's omc stage and its GUI stage.
List nightlyCommonFlags(Map t) {
  List flags = ['-DCMAKE_BUILD_TYPE=Release',
                '-DOM_OMC_ENABLE_RUST=ON',
                '-DRUST_OMC_CI=ON',
                "-DRUST_OMC_TARGET=${t.triple}",
                '-DOM_USE_CCACHE=OFF',
                // The downloads default under the build tree, which
                // standardSetup()'s `git clean -ffdx` deletes first, so they
                // would be re-fetched once per stage per night (Boost alone is
                // a 108 MB tarball).
                '-DOM_DOWNLOADS_DIR=/cache/thirdparty',
                "-DCMAKE_INSTALL_PREFIX=${env.WORKSPACE}/${nightlyInstallDir(t.name)}"]
  // linux64 is native, so it has neither.
  if (t.toolchain) {
    flags += ["-DCMAKE_TOOLCHAIN_FILE=${t.toolchain}", "-DRUST_OMC_TARGET=${t.triple}"]
  }
  if (t.sccache) {
    flags += ['-DCMAKE_C_COMPILER_LAUNCHER=sccache', '-DCMAKE_CXX_COMPILER_LAUNCHER=sccache']
  }
  return flags + t.configure
}

// A cross build cannot run what it produced, so check the file format instead --
// a host binary left in bin/ by a misconfigured stage would otherwise ship. On
// the Linux targets the glibc floor is checked on top, because it is what can
// regress there: the whole point of building on 22.04 is to stay at 2.35.
void nightlyCheckArtifacts(Map t) {
  String exe = t.triple.contains('windows') ? '.exe' : ''
  sh """#!/bin/bash
    set -eu
    bin=${nightlyInstallDir(t.name)}/bin/omc${exe}
    test -f "\$bin"
    magic=\$(od -An -tx1 -N4 "\$bin" | tr -d ' \\n')
    echo "\$bin: \$magic"
    case '${t.triple}' in
      *windows*) test "\${magic:0:4}" = 4d5a ;;  # MZ
      *darwin*)  test "\$magic" = cffaedfe ;;    # 64-bit Mach-O, little endian
      # ELF says nothing here (a host binary is one), so: e_machine, at 18.
      *aarch64-unknown-linux-gnu)
        test "\$magic" = 7f454c46
        test "\$(od -An -tx1 -j18 -N2 "\$bin" | tr -d ' \\n')" = b700 ;;
    esac
  """
  if (t.multiarch) {
    nightlyCheckGlibcFloor(nightlyInstallDir(t.name), nightlyGlibcFloor())
  }
}

// The glibc version the Linux distribution is allowed to demand. 22.04's own,
// one above the 2.34 the Qt binaries need.
String nightlyGlibcFloor() { return '2.35' }

// Every versioned glibc reference in a tree, against that floor. A stage that
// silently moved to a newer image would otherwise ship a distribution that dies
// with "version `GLIBC_2.39' not found" on the machines it is built for.
// Only over real ELF: bin/OMSimulator is a Python wrapper and the wasi sysroot's
// .so are linker scripts, and a reader exiting non-zero on one of those takes
// the pipeline down under `pipefail`. readelf also reads a foreign architecture.
void nightlyCheckGlibcFloor(String tree, String floor) {
  sh """#!/bin/bash
    set -euo pipefail
    elfs=()
    while read -r f; do
      if [ "\$(od -An -tx1 -N4 "\$f" | tr -d ' \\n')" = 7f454c46 ]; then
        elfs+=("\$f")
      fi
    done < <(find ${tree}/bin ${tree}/lib -type f \\( -name '*.so' -o -name '*.so.*' -o -perm -u+x \\))
    if [ \${#elfs[@]} = 0 ]; then
      echo "ERROR: no ELF files under ${tree}" >&2
      exit 1
    fi
    max=\$(readelf -V "\${elfs[@]}" | grep -o 'GLIBC_[0-9][0-9.]*' | sort -uV | tail -1)
    echo "highest glibc reference in \${#elfs[@]} ELF files under ${tree}: \${max:-none}"
    if [ -z "\$max" ]; then
      echo "ERROR: no glibc reference at all; the scan cannot have worked" >&2
      exit 1
    fi
    highest=\$(printf '%s\\n' "\${max#GLIBC_}" ${floor} | sort -V | tail -1)
    if [ "\$highest" != ${floor} ]; then
      echo "ERROR: needs glibc \${max#GLIBC_}, above the ${floor} floor" >&2
      exit 1
    fi
  """
}

// Stage 2: omc and the simulation runtime for one target, GUI clients off.
// RUST_OMC_SCRIPTING_API is forced on so the cdylib carries the OMEdit C ABI the
// GUI stage links against, without that stage running cargo over the compiler.
void buildRustNightlyOMC(String name) {
  Map t = nightlyTarget(name)
  standardSetup()
  restoreNightlyShared()
  List flags = nightlyCommonFlags(t) + nightlyHandoverFlags() +
               ['-DOM_ENABLE_GUI_CLIENTS=OFF', '-DRUST_OMC_SCRIPTING_API=ON',
                '-DOM_OMC_ENABLE_CPP_RUNTIME=ON']
  sh "cmake -S . -B build_cmake ${flags.join(' ')}"
  withSccache {
    sh "cmake --build build_cmake --parallel ${numPhysicalCPU()} --target install"
  }
  nightlyCheckArtifacts(t)
  // The cdylib (and on Windows its import library) for the GUI stage, staged in
  // the workspace: the cargo target directory is in a build tree that stage does
  // not have.
  // A native cargo build has no <triple>/ level under the target directory.
  String sub = t.triple ? "${t.triple}/release" : 'release'
  String cdylib = "build_cmake/OMCompiler/Compiler/rust-target/${sub}/${t.cdylib}"
  sh """
    rm -rf nightly-cdylib && mkdir -p nightly-cdylib
    cp -a ${cdylib} nightly-cdylib/
    cp -a ${cdylib}.lib nightly-cdylib/ 2>/dev/null || true
  """
  stash name: "nightly-cdylib-${name}", includes: 'nightly-cdylib/**'
  stash name: "nightly-omc-${name}", includes: "${nightlyInstallDir(name)}/**"
}

// Stage 3: the Qt GUI clients for one target, linked against the cdylib the omc
// stage built (RUST_OMC_PREBUILT_CDYLIB), so no cargo build of the compiler runs
// here. They install into the omc stage's prefix, which the packaging stage
// merges by unstashing both.
void buildRustNightlyGUI(String name) {
  Map t = nightlyTarget(name)
  if (!t.qt) {
    error("no Qt kit for ${name} on this image, so the GUI stage cannot run (see nightlyTarget in common.groovy)")
  }
  standardSetup()
  restoreNightlyShared()
  unstash "nightly-cdylib-${name}"
  String d = "${env.WORKSPACE}/${nightlySharedDir()}"
  // The hand-over flags again: rust_omc.cmake is included in this mode too, and
  // would otherwise fetch the wasi-libc sources and the preview1 adapter for a
  // stage that builds no wasm at all.
  List flags = nightlyCommonFlags(t) + nightlyHandoverFlags() + t.qt +
               ['-DOM_ENABLE_GUI_CLIENTS=ON',
                "-DRUST_OMC_PREBUILT_CDYLIB=${env.WORKSPACE}/nightly-cdylib/${t.cdylib}",
                "-DRUST_OMC_PREBUILT_SCRIPTING_API_QT_DIR=${d}/scripting-api-qt"]
  sh "cmake -S . -B build_cmake ${flags.join(' ')}"
  withSccache {
    sh "cmake --build build_cmake --parallel ${numPhysicalCPU()} --target install"
  }
  stash name: "nightly-gui-${name}", includes: "${nightlyInstallDir(name)}/**"
}

// Stage 4, Windows. Two distributions off the same install tree: the CLI one is
// the omc stages' tree alone, the full one is that tree with the GUI stages'
// files unstashed on top, so the CLI zip has to be made before they are.
void packageRustNightlyWindows(List omcStashes, List guiStashes) {
  standardSetup()
  for (s in omcStashes) {
    unstash s
  }
  zipRustNightlyWindows("OpenModelica-CLI-${tagName()}-x86_64-windows.zip")
  if (!guiStashes) {
    return
  }
  for (s in guiStashes) {
    unstash s
  }
  zipRustNightlyWindows("OpenModelica-${tagName()}-x86_64-windows.zip")
}

void zipRustNightlyWindows(String zip) {
  sh "rm -f ${zip} && (cd ${nightlyInstallDir('win64')} && zip -q -r -9 -y ${env.WORKSPACE}/${zip} .)"
  sh "ls -l ${zip}"
  uploadRustNightly(zip)
}

// Stage 4, Linux: the same two-distribution split as Windows, for one target.
// An empty guiStashes leaves the CLI distribution as the only one, which is what
// linux-aarch64 ships.
void packageRustNightlyLinux(String name, List omcStashes, List guiStashes) {
  Map t = nightlyTarget(name)
  standardSetup()
  for (s in omcStashes) {
    unstash s
  }
  // No Qt prefix: the CLI tree has no GUI clients, but it still needs its own
  // libraries bundled -- omc pulls in libgfortran and libcurl-gnutls, neither of
  // which a target is required to have.
  tarRustNightlyLinux(t, "OpenModelica-CLI-${tagName()}-${t.arch}-linux.tar.gz", '')
  if (!guiStashes) {
    return
  }
  for (s in guiStashes) {
    unstash s
  }
  tarRustNightlyLinux(t, "OpenModelica-${tagName()}-${t.arch}-linux.tar.gz", qtLinuxPrefix())
}

void tarRustNightlyLinux(Map t, String tgz, String qtPrefix) {
  String tree = nightlyInstallDir(t.name)
  // Self-contain the tree before it is archived: the Qt kit lives in /opt on the
  // agent and nowhere on a user's machine, and several of the libraries omc
  // links are not standard on a target either.
  sh "TRIPLE=${t.multiarch} .CI/scripts/linux-deploy.sh ${tree} ${qtPrefix}"
  nightlyCheckGlibcFloor(tree, nightlyGlibcFloor())
  sh "rm -f ${tgz} && tar -C ${tree} -czf ${tgz} ."
  sh "ls -l ${tgz}"
  uploadRustNightly(tgz)
}

// Stage 4, macOS: lipo the two per-architecture install trees into one universal
// tree (.CI/scripts/mac-universal.sh). That tree ships as the CLI tar.gz; with
// the GUI stages unstashed on top it is lipo'd again, folded into OMEdit.app and
// shipped as a .dmg (the unix tree inside the bundle only runs from there).
void packageRustNightlyMacUniversal(List omcStashes, List guiStashes) {
  standardSetup()
  for (s in omcStashes) {
    unstash s
  }
  String cli = 'install/mac-universal-cli'
  macUniversalTree(cli)
  String tgz = "OpenModelica-CLI-${tagName()}-macos-universal.tar.gz"
  sh "rm -f ${tgz} && tar -C ${cli} -czf ${tgz} ."
  sh "ls -l ${tgz}"
  uploadRustNightly(tgz)
  if (!guiStashes) {
    return
  }
  for (s in guiStashes) {
    unstash s
  }
  String out = 'install/mac-universal'
  macUniversalTree(out)
  sh ".CI/scripts/mac-app-bundle.sh ${out} install/OMEdit.app ${qtMacPrefix()}"
  String dmg = "OpenModelica-${tagName()}-macos-universal.dmg"
  sh ".CI/scripts/mac-dmg.sh install/OMEdit.app ${dmg} OpenModelica"
  uploadRustNightly(dmg)
}

void macUniversalTree(String out) {
  sh ".CI/scripts/mac-universal.sh ${out} ${nightlyInstallDir('mac-x86_64')} ${nightlyInstallDir('mac-aarch64')}"
  // Both architectures really in the shipped launcher, not just in the tree.
  sh """#!/bin/bash
    set -eu
    lipo=\$(command -v llvm-lipo || command -v lipo || ls /usr/bin/llvm-lipo-* | sort -V | tail -1)
    info=\$("\$lipo" -info ${out}/bin/omc)
    echo "\$info"
    case "\$info" in
      *x86_64*arm64* | *arm64*x86_64*) ;;
      *) echo "ERROR: bin/omc is not universal" >&2; exit 1 ;;
    esac
  """
}

// build.openmodelica.org/omc/rust/latest/, under the artifact's own name
// (tagName() is `latest` on master). `rust-builds` is the publisher config
// rooted at omc/rust/.
void uploadRustNightly(String archive) {
  if (env.BRANCH_NAME != 'master') {
    echo "${env.BRANCH_NAME} is not master: not publishing ${archive}"
    return
  }
  sshPublisher(publishers: [sshPublisherDesc(configName: 'rust-builds',
    transfers: [sshTransfer(sourceFiles: archive, remoteDirectory: 'latest')])])
}

// One partest shard against the Rust-built omc (unstashed) for one simCodeTarget.
// The test libraries are installed with that omc. An empty simCodeTarget leaves
// the compiler default. Without registerJUnit the results are archived artifacts
// instead.
void partestRust(String simCodeTarget, partition, partitionmodulo, boolean registerJUnit) {
  standardSetup()
  unstash 'omc-rust'
  // OMSimulator + libomcruntime aren't produced by the Rust omc build; pull the
  // prebuilt binaries from the clang job (file sets are disjoint from build/**'s
  // rust omc, so this adds to the tree without overwriting it). Needed by the
  // OMSimulator tests and the -lomcruntime bootstrapping tests respectively.
  unstash 'omsimulator'
  unstash 'omcruntime'
  installTestLibraries()
  extractReferenceFiles()
  sh 'build/bin/omc-diff -v1.4'
  boolean isWasmTarget = ['wasm-jit', 'wasm'].contains(simCodeTarget)
  String simCodeTargetArg = simCodeTarget ? " -simCodeTarget=${simCodeTarget}" : ''
  // Properties of the Rust omc itself, so excluded for every target.
  // cpp/hpcom: the Rust omc is built without the C++ runtime. metamodelica:
  // MetaModelica code generation only works against the C runtime.
  // 63bit/antlr: the port's Integer is i32 and its parser is winnow, not ANTLR
  // stackoverflow: Rust aborts on stack overflow, MMC unwinds out of the SEGV handler
  // wasm: off everywhere else - these tests select the wasm-jit/wasm target
  // themselves, which only this build has.
  // hdf5: the CMake build this stage uses links the system HDF5, so MAT v7.3
  // works.
  String suites = '-cpp,-hpcom,-metamodelica,-63bit,-antlr,-stackoverflow,+wasm,+hdf5'
  // cSources/fmuCSources inspect generated C, which a wasm target does not write.
  if (isWasmTarget) {
    suites += ',-cSources,-fmuCSources'
  }
  // wasmtime reserves ~4 GiB of address space per wasm memory, and shrinking that
  // reservation to fit an RLIMIT_AS costs the bounds-check-free fast path.
  String asLimit = isWasmTarget
                   ? '# wasm: address space is not limited, only the cgroup is'
                   : 'ulimit -v 6291456 # Max 6GB per process'
  // The 'Failed tests:' block (the only tab-indented lines); stdout rather than
  // failed.<branch>, which dies on branch names with '/'.
  String failureList = registerJUnit ? '' : """
      grep -E '^[[:space:]]+[^[:space:]].*[.]mo[fs]?\$' runtests-${partition}.log | sed -E 's/^[[:space:]]+//' | sort -u > ../partest-failed-${partition}.txt || true
      wc -l ../partest-failed-${partition}.txt"""
  try {
    sh """#!/bin/bash
      set -o pipefail
      ulimit -t 1500
      ${asLimit}
      .CI/scripts/cgroup-memory.sh check
      rm -f testsuite/partest-failed-${partition}.txt
      cd testsuite/partest
      set -x
      ./runtests.pl -j${numPhysicalCPU()} -partition=${partition}/${partitionmodulo} -nocolour -with-xml -suites=${suites}${simCodeTargetArg} 2>&1 | tee runtests-${partition}.log
      CODE=\${PIPESTATUS[0]}
      set +x
      ../../.CI/scripts/cgroup-memory.sh report
      # 0/7 == the run completed (7 means some tests failed); only fail the step on
      # anything else, so the results below are still published.
      test \$CODE = 0 -o \$CODE = 7 || exit 1${failureList}
    """
    if (!registerJUnit) {
      stash name: "partest-failed-${partition}", includes: "testsuite/partest-failed-${partition}.txt"
    }
  } finally {
    // In finally so a hard shard failure still publishes what ran.
    if (registerJUnit) {
      junit testResults: 'testsuite/partest/result.xml', allowEmptyResults: true, skipPublishingChecks: true
    } else {
      sh "cp testsuite/partest/result.xml partest-rust-partest-junit-${partition}.xml || true"
      archiveArtifacts artifacts: "partest-rust-partest-junit-${partition}.xml", allowEmptyArchive: true, fingerprint: true
    }
  }
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
  // Assembled in rustWorkDir(), not the workspace, so the crates hit sccache (see
  // rustWorkDir()). The whole crate tree, not the rust_src_sync manifest: that one
  // omits test fixtures. Then the stage-1 generated .rs (without them the manifest
  // load fails) and the builtin .mo openmodelica_wasi include_str!s from ../../../.
  // The tree reproduces OMCompiler/, since the compiler and simulation-runtime
  // workspaces path-reference each other across it (cf. rust_omc.cmake).
  def tree = "${rustWorkDir()}/rust-src"
  def work = "${tree}/Compiler/OpenModelica.rs"
  def simrt = "${tree}/SimulationRuntime/rust"
  sh """
    rm -rf ${tree} && mkdir -p ${work} ${simrt} ${tree}/Compiler/FrontEnd ${tree}/Compiler/NFFrontEnd
    tar -C OMCompiler/Compiler/OpenModelica.rs --exclude=./target -cf - . | tar -C ${work} -xf -
    tar -C OMCompiler/SimulationRuntime/rust --exclude=./target -cf - . | tar -C ${simrt} -xf -
    cp -a rust-generated-src/. ${work}/
    for d in FrontEnd NFFrontEnd; do
      cp OMCompiler/Compiler/\$d/*Builtin*.mo ${tree}/Compiler/\$d/
    done
  """
  // Env vars required by the openmodelica_wasi_libc and openmodelica_wasm_jit
  // build.rs (wasm cross-compile artifacts from CMake build).
  def wasmEnv = [
    "OMC_WASI_PIC_SYSROOT=${env.WORKSPACE}/build_cmake/rust-wasi-pic-sysroot",
    "OMC_SUNDIALS_WASM_DIR=${env.WORKSPACE}/build_cmake/rust-sundials-wasm",
    "OMC_WASI_P1_ADAPTER=${env.WORKSPACE}/build_cmake/downloads/wasi_snapshot_preview1.reactor.wasm",
    "OMC_EXTERNAL_C_SOURCES=${env.WORKSPACE}/OMCompiler/SimulationRuntime/ModelicaExternalC/C-Sources",
    // The runtime headers openmodelica_simulation_runtime's ABI test compiles;
    // without them it would skip rather than fail (cf. tests/abi_layout.rs).
    "OMC_SIMRT_INCLUDE_DIRS=${env.WORKSPACE}/OMCompiler/SimulationRuntime/c|${env.WORKSPACE}/OMCompiler/3rdParty/gc/include",
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

// Build the whole tree with the GUI clients and run the OMEdit testsuite. The
// OMEdit tests are CTest tests registered with absolute build-tree paths, so
// they run in the stage that builds them.
//
// Instrumented for coverage (OMEdit, and the compiler and runtimes the tests
// drive). The counters land in the build tree right here, so unlike the
// testsuite stages this collects them itself and hands coverageReportStage()
// the finished tracefiles, as stash 'coverage-tracefiles-omedit'.
void buildGUIAndRunOMEditTestsuite() {
  // See buildGccOMC() on caching instrumented objects.
  withSccache {
    buildOMC([
      // RelWithDebInfo, not Release: OMEdit's crash report shells out to gdb
      // (CrashReport/GDBBacktrace.cpp - the in-process backtrace.c is _WIN32-only),
      // and without -g that backtrace has no line numbers.
      "-DCMAKE_BUILD_TYPE=RelWithDebInfo",
      "-DOM_COMPILER_CACHE=sccache",
      "-DCMAKE_INSTALL_PREFIX=build",
      "-DCMAKE_C_COMPILER=clang",
      "-DCMAKE_CXX_COMPILER=clang++",
      "-DOM_OMEDIT_ENABLE_TESTS=ON",
      "-DOM_ENABLE_COVERAGE=ON"], 'cmake', false)
  }

  // The tests browse the MSL, so they need the test libraries and a writable HOME.
  makeLibsAndCache()
  try {
    // These GUI tests are flaky, so each is retried up to 5 times.
    sh label: 'RunOMEditTestsuite', script: """
    # The test binaries live in the build tree, not in build/bin, so they cannot
    # deduce the installation dir from their own path; and omc needs a writable
    # HOME holding the test libraries.
    export OPENMODELICAHOME="\$PWD/build"
    export HOME="\$PWD/libraries"
    xvfb-run ctest --test-dir build_cmake/OMEdit/Testsuite \
                   --repeat until-pass:5 \
                   --output-on-failure \
                   --output-junit "\$PWD/omedit-testsuite.xml"
    """
  } finally {
    junit testResults: 'omedit-testsuite.xml', allowEmptyResults: true
  }

  // The paths in the tracefiles are relative to this checkout, so they merge
  // with the ones coverageReportStage() collects in its own.
  sh label: 'Collect the coverage', script: """#!/bin/bash -xe
  cmake --build build_cmake --target coverage-collect
  mkdir -p coverage-tracefiles
  cp build_cmake/coverage/coverage.json coverage-tracefiles/omedit-coverage.json
  cp build_cmake/coverage/templates.json coverage-tracefiles/omedit-templates.json
  """
  stash name: 'coverage-tracefiles-omedit', includes: 'coverage-tracefiles/*.json'
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
  // installTestLibraries() rather than makeLibsAndCache(): the suite needs only
  // ModelicaCompliance, and a CMake install tree has no Makefile to drive.
  unstash 'omc-rust'
  installTestLibraries()
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

// Send the default failure-notification email, but only for master builds.
void notifyOnFailure() {
  if (cacheBranch() == "master") {
    emailext subject: '$DEFAULT_SUBJECT',
    body: '$DEFAULT_CONTENT',
    replyTo: '$DEFAULT_REPLYTO',
    to: '$DEFAULT_TO'
  }
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

private def shouldWeBuildWindows() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/Build MSYS2-UCRT64")) {
      return true
    }
  }
  return params.BUILD_WINDOWS
}

private def shouldWeBuildAlpine() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/Build Alpine")) {
      return true
    }
  }
  return params.BUILD_ALPINE
}

private def shouldWeBuildEnterpriseLinux() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/Build Enterprise Linux")) {
      return true
    }
  }
  return params.BUILD_ENTERPRISE_LINUX
}

private def shouldWeBuildFedora() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/Build Fedora")) {
      return true
    }
  }
  return params.BUILD_FEDORA
}

private def shouldWeEnableMacOSCMakeBuild() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/CMake/Enable/macOS")) {
      return true
    }
  }
  return params.ENABLE_MACOS_CMAKE_BUILD
}

// The extra Rust-omc partest on RUST_PARTEST_SIMCODETARGET; wasm-jit always runs.
private def shouldWeRunRustTests() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/Enable Rust Tests")) {
      return true
    }
  }
  return params.ENABLE_RUST_PARTEST
}

// wasm-opt -Oz on the web bundle is slow and only shrinks the shipped artifact;
// skip it on PRs, keep it for the release build that publishes to the playground.
def rustWasmOptCMakeFlag() {
  return isPR() ? "-DRUST_OMC_WASM_OPT=OFF" : "-DRUST_OMC_WASM_OPT=ON"
}

private def shouldWeRunTests() {
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

private def isPR() {
  return env.CHANGE_ID ? true : false
}

/**
 * Evaluate all the shouldWe... / isPR build flags used to gate pipeline stages,
 * printing each one, and return them as a map. Centralising this in one
 * function (instead of the Jenkinsfile calling+printing each individually)
 * keeps the CPS-compiled pipeline script itself small.
 */
Map evaluateBuildFlags() {
  def flags = [:]
  flags.isPR = isPR()
  print "isPR: ${flags.isPR}"
  flags.shouldWeBuildAlpine = shouldWeBuildAlpine()
  print "shouldWeBuildAlpine: ${flags.shouldWeBuildAlpine}"
  flags.shouldWeBuildEnterpriseLinux = shouldWeBuildEnterpriseLinux()
  print "shouldWeBuildEnterpriseLinux: ${flags.shouldWeBuildEnterpriseLinux}"
  flags.shouldWeBuildFedora = shouldWeBuildFedora()
  print "shouldWeBuildFedora: ${flags.shouldWeBuildFedora}"
  flags.shouldWeEnableMacOSCMakeBuild = shouldWeEnableMacOSCMakeBuild()
  print "shouldWeEnableMacOSCMakeBuild: ${flags.shouldWeEnableMacOSCMakeBuild}"
  flags.shouldWeBuildWindows = shouldWeBuildWindows()
  print "shouldWeBuildWindows: ${flags.shouldWeBuildWindows}"
  flags.shouldWeRunTests = shouldWeRunTests()
  print "shouldWeRunTests: ${flags.shouldWeRunTests}"
  flags.shouldWeRunRustTests = flags.shouldWeRunTests && shouldWeRunRustTests()
  print "shouldWeRunRustTests: ${flags.shouldWeRunRustTests}"
  return flags
}

// ----------------------------------------------------------------------------
// Whole-stage step bodies. These live here rather than inline in the
// Jenkinsfile so the declarative pipeline's single generated CPS method stays
// under Groovy's 64kB method-size limit.
// ----------------------------------------------------------------------------

// The jammy CMake build of omc. Its install tree is what the testsuite-gcc
// stages run against (ctestStashed), so keep the flags in sync with what
// those tests need. Built with -DOM_ENABLE_COVERAGE=ON so those stages'
// coverage numbers (see coverageReportStage()) come from the same run that
// tests the PR, rather than a separate instrumented build.
void buildGccOMC() {
  // The instrumented objects carry the absolute path gcov writes their .gcda to, so
  // caching them is only safe because a hit needs the identical workspace path (see
  // withSccache); coverageReportStage would not find counters written anywhere else.
  //
  // RelWithDebInfo, like every build the coverage report is made of: builds
  // at different optimization levels record different lines of the same
  // source, and merged, the lines only one of them has add to the total but
  // hardly ever to the hits.
  withSccache {
    buildOMC([
      "-DCMAKE_BUILD_TYPE=RelWithDebInfo",
      "-DOM_COMPILER_CACHE=sccache",
      "-DCMAKE_INSTALL_PREFIX=build",
      "-DOM_ENABLE_COVERAGE=ON"])
  }

  // The compiler translated to C for MSVC, for crossBuildOMCWindows().
  sh label: 'Translate the compiler for MSVC',
     script: "cmake --build build_cmake --parallel ${numPhysicalCPU()} --target generate-msvc-c-sources"
  stash name: 'omc-msvc-c-sources',
        includes: 'build_cmake/OMCompiler/Compiler/msvc-c-sources/*.c,' +
                  'build_cmake/OMCompiler/Compiler/msvc-c-sources/*.h'

  // Susan's *.mo and Autoconf.mo travel along because the bootstrapping tests
  // load the compiler sources by path (see ctestStashed).
  stash name: 'omc-gcc',
        includes: 'build/**,' +
                  'build_cmake/OMCompiler/Compiler/generated-mo/**,' +
                  'OMCompiler/Compiler/Util/Autoconf.mo'
  stashCoverageNotes('gcc')
}

// What coverageReportStage() needs of an instrumented build to turn the
// counters of the stages testing it into a report. See section 9 of
// README.cmake.md for what is instrumented.
void stashCoverageNotes(String compiler) {
  // Coverage counters (*.gcda), written by the instrumented binaries as the
  // testsuite runs, land next to the *.gcno files below, at whatever absolute
  // path this build happened to compile at (baked in by the compiler). The
  // testsuite stages run on other agents/workspaces that don't have that
  // path, so they redirect their counters elsewhere with GCOV_PREFIX (see
  // withCoverageCounters) instead of writing there directly; this string is
  // what lets coverageReportStage() find them again afterwards to merge in
  // the *.gcno tree.
  writeFile file: 'coverage-build-root.txt', text: env.WORKSPACE
  stash name: "coverage-${compiler}-root", includes: 'coverage-build-root.txt'
  stash name: "coverage-${compiler}-gcno", includes: 'build_cmake/**/*.gcno'
  // Sources that only exist because this stage built them: Susan's generated
  // *.mo and the two *.mo generated into the source tree. The report stage
  // starts from a clean checkout and only configures, so nothing regenerates
  // them there - and gcovr needs to read every source it covers to annotate
  // it, failing the whole report otherwise. They are also what lets the
  // template mapping (OpenModelicaCoverageTemplates.py) find the generated
  // functions to attribute back to *.tpl.
  //
  // And the compiler's generated C: without it gcc's gcov loses the
  // MetaModelica coverage of most modules, and clang's coverage is filed
  // under it, to be moved onto the MetaModelica by replaying the C's #line
  // directives (see OpenModelicaCoverageLineDirectives.py).
  stash name: "coverage-${compiler}-sources",
        includes: 'build_cmake/OMCompiler/Compiler/generated-mo/**/*.mo,' +
                  'OMCompiler/Compiler/Script/OpenModelicaScriptingAPI.mo,' +
                  'OMCompiler/Compiler/Util/Autoconf.mo,' +
                  'build_cmake/OMCompiler/Compiler/c_files/*.c'
}

// The jammy clang build of omc, tested by the testsuite-clang and testsuite-misc
// stages. Instrumented for coverage like buildGccOMC(), and for the same
// reason: coverageReportStage() merges what those stages cover into the report.
void buildClangOMC() {
  // See buildGccOMC() on caching instrumented objects.
  withSccache {
    // RelWithDebInfo: see buildGccOMC().
    buildOMC([
      "-DCMAKE_BUILD_TYPE=RelWithDebInfo",
      "-DOM_COMPILER_CACHE=sccache",
      "-DCMAKE_INSTALL_PREFIX=build",
      "-DCMAKE_C_COMPILER=clang",
      "-DCMAKE_CXX_COMPILER=clang++",
      "-DOM_ENABLE_COVERAGE=ON"], 'cmake', false)
  }
  stashCoverageNotes('clang')
  sh 'find build/lib/*/omc/ -name "*.so" -exec strip {} ";"'
  // Find unused imports
  sh label: 'Find unused imports', script: 'cd OMCompiler/Compiler/boot && ./find-unused-import.sh ../*/*.mo'
  getVersion()
  // Resolve symbolic links to make Jenkins happy
  sh 'cp -Lr build build.new && rm -rf build && mv build.new build'
  // Susan's *.mo and Autoconf.mo travel along because the bootstrapping and
  // MatlabTranslator tests load the compiler sources by path (generatedMoDir()).
  stash name: 'omc-clang',
        includes: 'build/**,' +
                  'build_cmake/OMCompiler/Compiler/generated-mo/**,' +
                  'OMCompiler/Compiler/Util/Autoconf.mo'
  // The Rust omc build (GUI off, no full C++ runtime) lacks OMSimulator and
  // libomcruntime, which the rust testsuite shard needs. Hand the prebuilt
  // binaries over so partestRust doesn't have to rebuild them. Kept narrow so
  // unstashing on top of the rust build/** doesn't clobber the rust omc.
  stash name: 'omsimulator',
        includes: 'build/bin/OMSimulator*,' +
                  'build/lib/**/libOMSimulator*,' +
                  'build/lib/**/OMSimulator/**,' +
                  'build/include/omc/OMSimulator/**,' +
                  'build/share/OMSimulator/**'
  stash name: 'omcruntime', includes: 'build/lib/**/libomcruntime*'
}

void checks() {
  standardSetup()
  // It's really bad if we mess up the repo and can no longer build properly
  sh '! git submodule foreach --recursive git diff 2>&1 | grep CRLF'
  // TODO: trailing-whitespace-error tab-error
  // The scripts behind the source-check targets (cmake/omc_source_checks.cmake)
  // need no configured build dir.
  sh 'bash cmake/source_checks.sh bom-error .'
  sh 'bash cmake/source_checks.sh utf8-error .'
  sh 'bash cmake/source_checks.sh thumbsdb-error .'
  sh 'bash cmake/spellcheck.sh . aspell'
  sh '''
  cd doc/bibliography
  mkdir -p openmodelica.org-bibgen
  sh generate.sh "$PWD/openmodelica.org-bibgen"
  '''
  stash name: 'bibliography', includes: 'doc/bibliography/openmodelica.org-bibgen/*.md'
}

// The suites the gcc and clang testsuite shards run. Both are CMake builds,
// which link the system HDF5 (MAT v7.3) and have libomc_result, so they select
// the same tests. Partitioning is computed over these; see -partition-suites in
// testsuite/partest/runtests.pl.
String sharedTestSuites() {
  return '+hdf5'
}

// A partest shard against a stashed CMake install tree (see buildClangOMC).
// The install tree is coverage-instrumented, so this also leaves coverage
// counters behind, as stash 'coverage-counters-<stashName>-<partition>'.
void partestStashed(stashName, partition, partitionmodulo) {
  standardSetup()
  unstash stashName
  makeLibsAndCache()
  withCoverageCounters("${stashName}-${partition}") {
    partest(partition, partitionmodulo, true,
            "-suites=${sharedTestSuites()} -partition-suites=${sharedTestSuites()}")
  }
}

// Runs body with the coverage counters (*.gcda) of the instrumented omc and
// runtimes redirected under the workspace, then stashes them as
// 'coverage-counters-<name>' for coverageReportStage().
//
// The instrumented binaries come from an install tree built elsewhere. They
// can't write their counters to the build tree they were compiled in - this
// stage has none - so GCOV_PREFIX redirects them to gcda-out/, where they
// land at gcda-out/<coverage-build-root>/... (GCOV_PREFIX is prepended
// verbatim to the original build's absolute compile path;
// coverageReportStage() re-derives that same coverage-build-root string from
// the stash stashCoverageNotes() left, to find them again).
//
// FMUs exported along the way are instrumented by their own build, and keep
// their notes and counters in OMC_COVERAGE_FMU_DIR (see Coverage.cmake.in in
// SimulationRuntime/fmi/export/buildproject). GCOV_PREFIX redirects those
// counters too, so they are moved back next to their notes before stashing.
void withCoverageCounters(String name, Closure body) {
  def ws = sh(script: 'pwd', returnStdout: true).trim()
  sh 'rm -rf gcda-out fmu-coverage'
  withEnv(["GCOV_PREFIX=${ws}/gcda-out",
           "OMC_COVERAGE_FMU_DIR=${ws}/fmu-coverage"]) {
    body()
  }
  sh label: 'Gather the coverage counters', script: """#!/bin/bash -e
  if [ -d 'gcda-out${ws}/fmu-coverage' ]; then
    mkdir -p fmu-coverage
    cp -a 'gcda-out${ws}/fmu-coverage/.' fmu-coverage/
    rm -rf 'gcda-out${ws}/fmu-coverage'
  fi
  echo "\$(find gcda-out -name '*.gcda' 2>/dev/null | wc -l) counter files and" \\
       "\$(find fmu-coverage -name '*.gcda' 2>/dev/null | wc -l) of FMUs"
  """
  // Only the counters (and the FMUs' notes), not the rest of gcda-out.
  stash name: "coverage-counters-${name}",
        includes: 'gcda-out/**/*.gcda,fmu-coverage/**/*.gcno,fmu-coverage/**/*.gcda',
        allowEmpty: true
}

// A CTest-driven testsuite shard against a stashed CMake install tree (see
// buildGccOMC). Test dependencies are built the same
// way as before; only how the tests themselves are discovered and run
// changes: CTestTestfile.cmake is (re-)generated fresh here rather than
// configuring the whole project (this stage only unstashes an installed omc,
// not a configured build tree), and the generated file holds just this shard,
// which runtests.pl selects. See testsuite/CTest/Readme.md.
//
// The install tree carries the coverage-instrumented runtime/omc from
// buildGccOMC(), so this shard's share of the testsuite also produces
// coverage counters, stashed as 'coverage-counters-<stashName>-<partition>'
// (see withCoverageCounters()). See section 9 of README.cmake.md.
void ctestStashed(stashName, partition, partitionmodulo) {
  standardSetup()
  unstash stashName
  makeLibsAndCache()
  // omc-diff: installed into build/bin by the CMake build, see makeLibsAndCache().
  sh 'build/bin/omc-diff -v1.4'

  def ws = sh(script: 'pwd', returnStdout: true).trim()
  withCoverageCounters("${stashName}-${partition}") {
    withEnv(["OMCOMPILERGENERATEDSOURCES=${generatedMoDir()}"]) {
      sh """
      cmake -DTESTSUITE_DIR=${ws}/testsuite -DOUTPUT_DIR=${ws}/build-testsuite-ctest \\
            -DTESTSUITE_SUITES=${sharedTestSuites()} \\
            -DTESTSUITE_PARTITION=${partition}/${partitionmodulo} \\
            -DTESTSUITE_PARTITION_SUITES=${sharedTestSuites()} \\
            -P testsuite/CTest/Partest/GenerateCTestFile.cmake
      """
      // hdf5: the CMake build links the system HDF5, which gives it MAT v7.3.
      // (baked into the generated CTestTestfile.cmake above)
      sh ("""#!/bin/bash -x
      ulimit -t 1500
      # On top of the cgroup limit, to catch a single runaway process early
      ulimit -v 6291456 # Max 6GB per process

      .CI/scripts/cgroup-memory.sh check
      ctest --test-dir build-testsuite-ctest \\
            -j${numPhysicalCPU()} --output-on-failure --output-junit ctest-result.xml || true
      .CI/scripts/cgroup-memory.sh report
      test -f build-testsuite-ctest/ctest-result.xml
      """)
    }
  }
  junit 'build-testsuite-ctest/ctest-result.xml'
}

// Turns the coverage counters the testsuite stages left (withCoverageCounters)
// into one report, merged with the tracefiles of the OMEdit stage
// (buildGUIAndRunOMEditTestsuite) and of the C runtime unit tests (testUnitC). countersByCompiler maps each instrumented
// build, by the name it passed to stashCoverageNotes(), to the names of the
// counter stashes of the stages that tested it.
//
// gcc and clang counters can't be merged as such - they are not even read by
// the same gcov - so each set is collected into a gcovr JSON tracefile on its
// own, against the *.gcno tree of the build that produced it, and the report
// is rendered from all tracefiles at the end. gcovr sums up what they say
// about the same source line. Where the compilers disagree on which lines of
// a source are code at all, the report holds the union of both.
//
// This never rebuilds anything - the coverage targets only invoke gcovr - so a
// fresh, otherwise-empty configure (matching -DOM_ENABLE_COVERAGE=ON) is
// enough to get them back without a configured build tree having to be
// stashed/unstashed. See section 9 of README.cmake.md.
void coverageReportStage(Map countersByCompiler) {
  standardSetup()
  sh 'rm -rf coverage-tracefiles && mkdir coverage-tracefiles'
  unstash 'coverage-tracefiles-omedit'
  unstash 'coverage-tracefiles-unit-c'

  // Not iterating the Map itself: its iterator can't be serialized when the
  // pipeline checkpoints at a step inside the loop.
  List compilers = new ArrayList(countersByCompiler.keySet())
  try {
    for (int i = 0; i < compilers.size(); i++) {
      collectCoverage(compilers[i], countersByCompiler[compilers[i]], i == compilers.size() - 1)
    }
  } finally {
    // Every tracefile the report is rendered from, one per stage, so that
    // the merge can be redone (or each stage's part inspected) locally with
    // gcovr --add-tracefile. Compressed: each is tens of MB of JSON. Also
    // when collecting or rendering failed, which is when they are most
    // needed.
    sh label: 'Compress the coverage tracefiles', script: '''#!/bin/bash -e
    rm -rf coverage-tracefiles-archive && mkdir coverage-tracefiles-archive
    for f in coverage-tracefiles/*.json; do
      [ -e "$f" ] || continue
      gzip -c "$f" > "coverage-tracefiles-archive/$(basename "$f").gz"
    done
    '''
    archiveArtifacts artifacts: 'coverage-tracefiles-archive/*.json.gz', allowEmptyArchive: true
  }

  // The browsable HTML, kept per build.
  archiveArtifacts artifacts: 'build_cmake/coverage/**', allowEmptyArchive: false

  // Pick the build recordCoverage below compares against (Git Forensics
  // plugin). For a PR that is the build of the target branch (master) at the
  // commit the PR is based on, so the deltas show what the PR changes and not
  // what master did since. On master itself it is the previous build. Without
  // this, the Coverage plugin falls back to the previous build of the same job,
  // i.e. the PR's own previous run. Commits older than maxCommits have no build
  // left anyway (buildDiscarder keeps 14 days); rather than comparing against
  // an unrelated master build, the delta is then left out.
  discoverGitReferenceBuild(maxCommits: 500)

  // Publish to Jenkins itself (Coverage plugin), which keeps the numbers per
  // build and draws the trend. With the reference build above it also shows
  // the delta of the whole project, the coverage of the modified lines and the
  // indirect coverage changes: lines the PR did not touch whose coverage
  // changed, e.g. because tests were added or removed.
  recordCoverage(tools: [[parser: 'COBERTURA',
                          pattern: 'build_cmake/coverage/coverage.xml']],
                 id: 'omc-coverage',
                 name: 'Compiler, runtimes, FMU export and OMEdit',
                 sourceCodeRetention: 'LAST_BUILD')
}

// Collects the counter stashes counterNames, left by the stages testing the
// build stashCoverageNotes(compiler) describes, into coverage-tracefiles/, one
// gcovr JSON tracefile per stash. With render, also renders the report from
// every tracefile in there, into build_cmake/coverage/.
void collectCoverage(String compiler, List counterNames, boolean render) {
  sh "rm -rf build_cmake coverage-build-root.txt"
  unstash "coverage-${compiler}-root"
  def coverageBuildRoot = readFile('coverage-build-root.txt').trim()
  unstash "coverage-${compiler}-gcno"
  unstash "coverage-${compiler}-sources"
  for (int i = 0; i < counterNames.size(); i++) {
    sh "rm -rf 'counters-${counterNames[i]}'"
    dir("counters-${counterNames[i]}") {
      unstash "coverage-counters-${counterNames[i]}"
    }
  }

  // The compiler bakes the absolute path of the build into the *.gcno files,
  // and that is the only path under which the data is recognised afterwards:
  // gcov looks for the sources there and gcovr's --filter (absolute, built
  // from CMAKE_SOURCE_DIR) has to match it. 'ws/OpenModelica' resolves
  // against each agent's own root, so landing on another agent than the build
  // did - the normal case - leaves gcovr filtering everything out and
  // reporting 0%. Bind-mount the workspace a second time at the path the
  // build used and work through that; it is the same directory, so what is
  // written there is in the workspace as usual, for archiveArtifacts and
  // recordCoverage.
  def extraMounts = coverageBuildRoot == env.WORKSPACE ? ''
                                                       : "-v ${env.WORKSPACE}:${coverageBuildRoot}"
  // The gcov the coverage targets pick (gcov or llvm-cov gcov) follows the
  // compiler CMake finds, so it has to be the one the build used.
  def compilerFlags = compiler == 'clang' ? '-DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++' : ''

  // gcov and llvm-cov have to be the ones that match the compilers the data
  // was produced with, which are this image's; the testsuite caches are of no
  // use here because this stage runs no tests.
  insideTestImage('docker.openmodelica.org/build-deps:ubuntu-22.04', extraMounts) {
    // Configure only: nothing needs (re)building for the coverage targets,
    // and the flags otherwise just have to be enough to reach them (matching
    // the build's keeps this from silently drifting out of sync with what was
    // actually instrumented). OM_COVERAGE_TRACEFILES is a pattern gcovr
    // expands when it renders, so it picks up everything collected by then.
    sh """#!/bin/bash -xe
    # Fails the stage right here if the mount above did not take effect,
    # rather than further down with an empty report.
    test -e "${coverageBuildRoot}/OMCompiler/Compiler/CMakeLists.txt"
    cd "${coverageBuildRoot}"
    cmake -S . -B build_cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DOM_USE_CCACHE=OFF \\
          -DCMAKE_INSTALL_PREFIX=build -DOM_ENABLE_COVERAGE=ON ${compilerFlags} \\
          '-DOM_COVERAGE_TRACEFILES=${coverageBuildRoot}/coverage-tracefiles/*.json' \\
          '-DOM_COVERAGE_TITLE=OpenModelica Code Coverage Report (GCC and Clang)'
    """

    for (int i = 0; i < counterNames.size(); i++) {
      String counters = "counters-${counterNames[i]}"
      sh label: "Collect ${counterNames[i]}", script: """#!/bin/bash -xe
      cd "${coverageBuildRoot}"
      # Only this stash's counters on the *.gcno tree unstashed above.
      find build_cmake -name '*.gcda' -delete
      rm -rf build_cmake/coverage-fmu
      if [ -d '${counters}/gcda-out${coverageBuildRoot}/build_cmake' ]; then
        cp -a '${counters}/gcda-out${coverageBuildRoot}/build_cmake/.' build_cmake/
      fi
      # The FMUs' notes and counters, where coverage-collect looks for them.
      if [ -d '${counters}/fmu-coverage' ]; then
        mkdir -p build_cmake/coverage-fmu
        cp -a '${counters}/fmu-coverage/.' build_cmake/coverage-fmu/
      fi
      cmake --build build_cmake --target coverage-collect
      cp build_cmake/coverage/coverage.json 'coverage-tracefiles/${counterNames[i]}-coverage.json'
      cp build_cmake/coverage/templates.json 'coverage-tracefiles/${counterNames[i]}-templates.json'
      """
    }

    if (render) {
      sh label: 'Render the coverage report', script: """#!/bin/bash -xe
      cd "${coverageBuildRoot}"
      cmake --build build_cmake --target coverage-html
      """
    }
  }
}

// The 'testsuite-windows' stage (see buildOMC()'s Windows branch for
// where 'omc-windows' is stashed). Split out of sanityCheck() so a
// failure here is reported as a distinct testsuite failure rather than a
// build failure, and so this stage can grow -- more tests, more Windows
// compute -- without ever touching the build step.
void testWindowsSmoke() {
  standardSetup()
  unstash 'omc-windows'
  withEnv (["OMDEV=C:\\OMDevUCRT",
            "PATH=${env.OMDEV}\\tools\\msys\\usr\\bin;${env.OMDEV}\\tools\\msys\\ucrt64;C:\\Program Files\\TortoiseSVN\\bin;c:\\bin\\jdk\\bin;c:\\bin\\nsis\\;${env.PATH};c:\\bin\\git\\bin;"]) {
    cloneOMDev()
    installWindowsSmokeLibrary('build')
    runWindowsTestsuite('build')
  }
}

// The C omc cross-compiled to Windows (MSVC) with the Rust nightly's win64
// toolchain. A cross build cannot run bomc, so it compiles the C that
// 'cmake-jammy-gcc' translated for MSVC.
void crossBuildOMCWindows() {
  Map t = nightlyTarget('win64')
  standardSetup()
  unstash 'omc-msvc-c-sources'
  sh 'mv build_cmake/OMCompiler/Compiler/msvc-c-sources omc-c-sources && rm -rf build_cmake'
  List flags = ['-DCMAKE_BUILD_TYPE=Release',
                "-DCMAKE_TOOLCHAIN_FILE=${t.toolchain}",
                "-DRUST_OMC_TARGET=${t.triple}",
                "-DOM_OMC_PREBUILT_C_SOURCES=${env.WORKSPACE}/omc-c-sources",
                '-DOM_ENABLE_GUI_CLIENTS=OFF',
                '-DOM_OMC_ENABLE_CPP_RUNTIME=ON',
                '-DOM_USE_CCACHE=OFF',
                '-DCMAKE_C_COMPILER_LAUNCHER=sccache',
                '-DCMAKE_CXX_COMPILER_LAUNCHER=sccache',
                '-DOM_DOWNLOADS_DIR=/cache/thirdparty',
                "-DCMAKE_INSTALL_PREFIX=${env.WORKSPACE}/${nightlyInstallDir(t.name)}"] + t.configure
  sh "cmake -S . -B build_cmake ${flags.join(' ')}"
  withSccache {
    sh "cmake --build build_cmake --parallel ${numPhysicalCPU()} --target install"
  }
  nightlyCheckArtifacts(t)
  testWindowsSmokeWine(nightlyInstallDir(t.name))
}

// The Windows smoke set against the MSVC omc in installDir, under wine, with
// the compilers of the Linux host (testsuite/wine). The omc and omc-diff for
// the build host are the Rust ones of 'omc-rust', which arrive in build/,
// where rtest then has to find the omc under test.
void testWindowsSmokeWine(String installDir) {
  unstash 'omc-rust'
  sh label: 'Install Modelica for the Windows smoke set',
     script: 'cd libraries && ../build/bin/omc install-windows-smoke.mos'
  sh label: 'Put the MSVC omc where rtest looks',
     script: "mv build/bin/omc-diff ${installDir}/bin/ && rm -rf build && ln -s ${installDir} build"
  sh label: 'Windows testsuite under wine',
     script: "bash testsuite/runWindowsTests.sh --wine -j${numPhysicalCPU()}"
}

void crossBuildFMU() {
  def deps = docker.image('docker.openmodelica.org/build-deps:ubuntu-22.04')
  deps.pull()
  def dockergid = sh (script: 'stat -c %g /var/run/docker.sock', returnStdout: true).trim()
  deps.inside("-v /var/run/docker.sock:/var/run/docker.sock --group-add '${dockergid}' " +
              "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
              "--mount type=volume,source=runtest-gcc-cache,target=/cache/runtest") {
    standardSetup()
    unstash 'omc-gcc'
    makeLibsAndCache()
    writeFile file: 'testsuite/special/FmuExportCrossCompile/VERSION', text: getVersion()
    sh 'make -C testsuite/special/FmuExportCrossCompile/ dockerpull'
    sh 'make -C testsuite/special/FmuExportCrossCompile/ test'
    sh 'make -C testsuite/special/FMPy/ fmpy-fmus'
    stash name: 'cross-fmu', includes: 'testsuite/special/FmuExportCrossCompile/*.fmu, testsuite/special/FMPy/Makefile'
    stash name: 'fmpy-fmu', includes: 'testsuite/special/FMPy/*.fmu'
    archiveArtifacts "testsuite/special/FmuExportCrossCompile/*.fmu"
  }
}

void buildUsersGuide() {
  standardSetup()
  unstash 'omc-gcc'
  makeLibsAndCache()
  sh '''
  # omc invoked while building the docs needs a writable HOME holding the
  # libraries, otherwise it tries to write to //.openmodelica and fails to
  # load Modelica (same as the compliance stage).
  export HOME=$PWD/libraries
  test ! -d $PWD/build/lib/omlibrary
  cp -a libraries/.openmodelica/libraries $PWD/build/lib/omlibrary
  # The guide is generated by running the OpenModelica unstashed above, so it is
  # configured against that install tree instead of being built as part of it.
  # Everything is written below build_usersguide/, never into the checkout.
  cmake -S doc/UsersGuide -B build_usersguide -DOM_USERSGUIDE_OMHOME=$PWD/build
  for target in usersguide usersguide-pdf usersguide-epub; do
    if ! cmake --build build_usersguide --target $target; then
      killall omc || true
      exit 1
    fi
  done
  '''
  sh "tar --transform 's/^html/OpenModelicaUsersGuide/' -cJf OpenModelicaUsersGuide-${tagName()}.html.tar.xz -C build_usersguide/build html"
  sh "mv build_usersguide/build/latex/OpenModelicaUsersGuide.pdf OpenModelicaUsersGuide-${tagName()}.pdf"
  sh "mv build_usersguide/build/epub/OpenModelicaUsersGuide.epub OpenModelicaUsersGuide-${tagName()}.epub"
  archiveArtifacts "OpenModelicaUsersGuide-${tagName()}*.*"
  stash name: 'usersguide', includes: "OpenModelicaUsersGuide-${tagName()}*.*"
}

// The C runtime unit tests, against a C runtime built right here.
//
// Instrumented for coverage. Like buildGUIAndRunOMEditTestsuite(), the counters
// land in the build tree right here, so this collects them itself and hands
// coverageReportStage() the finished tracefiles, as stash
// 'coverage-tracefiles-unit-c'.
void testUnitC() {
  // See buildGccOMC() on caching instrumented objects.
  withSccache {
    sh label: 'cmake version', script: "cmake --version"
    // Only the C runtime is what the unit tests exercise; see
    // OM_COVERAGE_SOURCE_DIRS on why the rest must stay out of the tracefile.
    sh label: 'Configure the C unit tests', script: "cmake -S ./ -B ./build_cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DOM_COMPILER_CACHE=sccache -DOM_ENABLE_COVERAGE=ON -DOM_COVERAGE_SOURCE_DIRS=OMCompiler/SimulationRuntime/c/"
    sh label: 'Build the C unit tests', script: "cmake --build ./build_cmake --parallel ${numPhysicalCPU()} --target ctestsuite-depends"
    sh label: 'Run the C unit tests', script: "cmake --build ./build_cmake --parallel ${numPhysicalCPU()} --target test"
  }
  sh label: 'Check that the C unit tests wrote junit.xml', script: "test -f ./build_cmake/junit.xml"

  // The paths in the tracefiles are relative to this checkout, so they merge
  // with the ones coverageReportStage() collects in its own.
  sh label: 'Collect the coverage of the C unit tests', script: """#!/bin/bash -xe
  cmake --build build_cmake --target coverage-collect
  mkdir -p coverage-tracefiles
  cp build_cmake/coverage/coverage.json coverage-tracefiles/unit-c-coverage.json
  """
  stash name: 'coverage-tracefiles-unit-c', includes: 'coverage-tracefiles/unit-c-*.json'
}

// The short test suites, run back to back in one node. testUnitC() goes first
// so CMake configures a tree that only git clean has touched; it collects its
// own coverage. The omc the others run is the coverage-instrumented one of
// buildClangOMC(), so they leave coverage counters behind, as stash
// 'coverage-counters-omc-clang-misc'.
void testMisc() {
  echo "Running on: ${env.NODE_NAME}"
  standardSetup()
  testUnitC()
  unstash 'omc-clang'
  withCoverageCounters('omc-clang-misc') {
    partest(1, 1, false, '-j1 -parmodexp')
    makeLibsAndCache()
    // The translator loads the compiler sources by path, Susan's *.mo included.
    withEnv(["OMCOMPILERGENERATEDSOURCES=${generatedMoDir()}"]) {
      sh label: 'Matlab translator', script: 'make -C testsuite/special/MatlabTranslator/ test'
    }
    sh label: 'Icon generator', script: 'make -C testsuite/openmodelica/icon-generator test'
  }
}

void fmpyLinux() {
  echo "${env.NODE_NAME}"
  unstash 'cross-fmu'
  unstash 'fmpy-fmu'
  sh '''
  export HOME="$PWD"
  cd testsuite/special/FMPy/
  make test
  '''
}

void uploadCompliance() {
  unstash 'compliance'
  echo "${env.NODE_NAME}"
  sshPublisher(publishers: [sshPublisherDesc(configName: 'ModelicaComplianceReports', transfers: [sshTransfer(sourceFiles: 'compliance-*html')])])
}

void uploadDoc() {
  unstash 'usersguide'
  echo "${env.NODE_NAME}"
  sh "tar xJf OpenModelicaUsersGuide-${tagName()}.html.tar.xz"
  sh "mv OpenModelicaUsersGuide ${tagName()}"
  sshPublisher(publishers: [sshPublisherDesc(configName: 'OpenModelicaUsersGuide', transfers: [sshTransfer(sourceFiles: "OpenModelicaUsersGuide-${tagName()}*,${tagName()}/**")])])
}

void uploadWeb() {
  unstash 'web'
  echo "${env.NODE_NAME}"
  sh "rm -rf ${tagName()} && mkdir -p ${tagName()} && (cd ${tagName()} && unzip -o ../OpenModelicaCompiler-web-${tagName()}.zip)"
  sshPublisher(publishers: [sshPublisherDesc(configName: 'playground', transfers: [sshTransfer(sourceFiles: "OpenModelicaCompiler-web-${tagName()}*,${tagName()}/**")])])
}

void pushToMaster() {
  standardSetup()
  githubNotify status: 'SUCCESS', description: 'The staged library changes are working', context: 'continuous-integration/jenkins/pr-merge'
  githubNotify status: 'SUCCESS', description: 'Skipping CLA checks on omlib-staging', context: 'license/CLA'
  sshagent (credentials: ['Hudson-SSH-Key']) {
    sh 'ssh-keyscan github.com >> ~/.ssh/known_hosts'
    sh 'git push git@github.com:OpenModelica/OpenModelica.git omlib-staging:master || (echo "Trying to update the repository if that is the problem" ; git pull --rebase && git push --force  git@github.com:OpenModelica/OpenModelica.git omlib-staging:omlib-staging && false)'
  }
}

void pushBibliography() {
  git branch: 'main', credentialsId: 'Hudson-SSH-Key', url: 'git@github.com:OpenModelica/www.openmodelica.org.git'
  standardSetup()
  unstash 'bibliography' // 'doc/bibliography/openmodelica.org-bibgen'
  sh "git remote -v | grep www.openmodelica.org"
  sh "mv doc/bibliography/openmodelica.org-bibgen/*.md content/research/"
  sh "git add content/research/*.md"
  sshagent (credentials: ['Hudson-SSH-Key']) {
    sh """
    if ! git diff-index --quiet HEAD; then
      git config user.name "OpenModelica Jenkins"
      git config user.email "openmodelicabuilds@ida.liu.se"
      git commit -m 'Updated bibliography'
      ssh-keyscan github.com >> ~/.ssh/known_hosts
      git push --set-upstream origin main
    fi
    """
  }
}

return this
