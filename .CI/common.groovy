
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
  sh "rm -f omc-diff.skip && ${makeCommand()} -C testsuite/difftool clean && ${makeCommand()} --output-sync=recurse -C testsuite/difftool"
  sh 'build/bin/omc-diff -v1.4'

  sh ("""#!/bin/bash -x
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

// Link the shared package cache into the workspace and install the testsuite
// libraries with the omc in build/. These are the steps of cmake's
// libs-for-testing target (wipe, copy index.json so omc uses the repo's pinned
// versions instead of downloading an index, run index.mos), spelled out because
// the stages calling this unstash an install tree, not a configured build tree,
// so no CMake target is available to them.
void installTestLibraries() {
  // env.WORKSPACE is null in the docker agent, so link the svn/git cache afterwards
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

// makeLibsAndCache()'s counterpart for a CMake-built omc (see
// partestCMakeStashed). Produces the same testsuite dependencies, but without
// the Autoconf machinery: a CMake build has no config.status, so the top-level
// Makefile the other variant drives does not exist. ReferenceFiles and the FFI
// test library have standalone Makefiles of their own. omc-diff is not built
// here: partest() rebuilds it from testsuite/difftool anyway.
void makeLibsAndCacheCMake() {
  // If we don't have any result, copy to the master to get a somewhat decent cache
  sh "cp -f ${env.RUNTESTDB}/${cacheBranchEscape()}/runtest.db.* testsuite/ || " +
     "cp -f ${env.RUNTESTDB}/master/runtest.db.* testsuite/ || true"
  def cmd = """#!/bin/bash -xe
  # reference-files: xz decompression only
  ${makeCommand()} -j${numLogicalCPU()} --output-sync=recurse -C testsuite/ReferenceFiles
  # ffi-test-lib
  ${makeCommand()} -C testsuite/flattening/modelica/ffi/FFITest/Resources/BuildProjects/gcc
  """
  if (env.SHARED_LOCK) {
    lock(env.SHARED_LOCK) {
      installTestLibraries()
      sh cmd
    }
  } else {
    installTestLibraries()
    sh cmd
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

  sh 'autoreconf --install'
  // Note: Do not use -march=native since we might use an incompatible machine in later stages
  def withCppRuntime = buildCpp ? "--with-cppruntime":"--without-cppruntime"
  sh "./configure CC='${CC}' CXX='${CXX}' FC=gfortran CFLAGS=-Os ${withCppRuntime} --without-omc --without-omlibrary --enable-modelica3d --prefix=`pwd`/install ${extraFlags}"
  // OMSimulator requires HOME to be set and writeable
  if (clean) {
    sh label: 'clean', script: "HOME='${env.WORKSPACE}' ${makeCommand()} -j${numPhysicalCPU()} ${outputSync()} clean"
  }
  sh label: 'build', script: "HOME='${env.WORKSPACE}' ${makeCommand()} -j${numPhysicalCPU()} ${outputSync()} omc omc-diff omsimulator"
  sh 'find build/lib/*/omc/ -name "*.so" -exec strip {} ";"'

  // Find unused imports
  sh label: 'Find unused imports', script: 'cd OMCompiler/Compiler/boot && ./find-unused-import.sh ../*/*.mo'

  sanityCheck('build', buildCpp)
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
 */
void buildOMC_CMake(List cmake_args, cmake_exe='cmake') {
  echo "Running on: ${env.NODE_NAME}"
  standardSetup()

  def cmake_args_str = cmake_args.join(' ')

  if (isWindows()) {
    withEnv (["OMDEV=C:\\OMDevUCRT",
              "PATH=${env.OMDEV}\\tools\\msys\\usr\\bin;${env.OMDEV}\\tools\\msys\\ucrt64;C:\\Program Files\\TortoiseSVN\\bin;c:\\bin\\jdk\\bin;c:\\bin\\nsis\\;${env.PATH};c:\\bin\\git\\bin;"]) {
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
    }
  }
  else if (isMac()) {
    withEnv (["PATH=/opt/homebrew/bin:/opt/homebrew/opt/openjdk/bin:/usr/local/bin:${env.PATH}"]) {
      sh "echo PATH: $PATH"
      sh "mkdir ./build_cmake"
      sh "${cmake_exe} --version"
      sh "${cmake_exe} -S ./ -B ./build_cmake ${cmake_args_str}"
      sh "${cmake_exe} --build ./build_cmake --parallel ${numPhysicalCPU()} --target install"
      sh "${cmake_exe} --build ./build_cmake --parallel ${numPhysicalCPU()} --target testsuite-depends"
      sh "build/bin/omc --version"
      sanityCheck('build', true)
    }
  }
  else {
    sh "mkdir ./build_cmake"
    sh "${cmake_exe} --version"
    sh "${cmake_exe} -S ./ -B ./build_cmake ${cmake_args_str}"
    sh "${cmake_exe} --build ./build_cmake --parallel ${numPhysicalCPU()} --target install"
    sh "${cmake_exe} --build ./build_cmake --parallel ${numPhysicalCPU()} --target testsuite-depends"
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
  stash name: 'omc-cmake-rust',
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
  unstash 'omc-cmake-rust-gui-inputs'
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
  unstash 'omc-cmake-rust-gui-inputs'
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

// One nightly cross target:
//   triple    the rustc target triple (RUST_OMC_TARGET, and cargo's subdirectory)
//   toolchain the CMake toolchain file for the C/C++ half of the tree
//   configure the flags only this platform needs
//   qt        the Qt kit for the GUI stage; empty = not configured yet, which
//             makes the stage error out rather than build without Qt
//   sccache   whether this target's C/C++ compiler can run under sccache
//   cdylib    the file name cargo gives libOpenModelicaCompiler for it
Map nightlyTarget(String name) {
  String rs = 'OMCompiler/Compiler/OpenModelica.rs/.cmake'
  // Fortran is off for both: flang compiles for either target but links for
  // neither (no flang_rt/clang_rt.builtins), and MOO/optimization need it.
  List noFortran = ['-DOM_OMC_ENABLE_FORTRAN=OFF',
                    '-DOM_OMC_ENABLE_MOO=OFF',
                    '-DOM_OMC_ENABLE_OPTIMIZATION=OFF']
  // Qt's one macOS desktop kit is universal, so both targets share it.
  List qtMac = ['-DCMAKE_PREFIX_PATH=/opt/Qt/6.11.2/macos',
                '-DQT_HOST_PATH=/opt/Qt/6.11.2/gcc_64',
                '-DOM_OMEDIT_ANIMATION_QUICK3D=ON']
  Map all = [
    'win64': [
      triple: 'x86_64-pc-windows-msvc',
      toolchain: "${rs}/xwin-toolchain.cmake",
      // OpenBLAS, Boost and PThreads4W are fetched/built by windows-deps.cmake,
      // which the top-level CMakeLists includes when cross-compiling to Windows.
      configure: noFortran + ['-DENABLE_CPACK=OFF', '-DZMQ_BUILD_TESTS=OFF'],
      qt: ['-DCMAKE_PREFIX_PATH=/opt/Qt/6.11.2/msvc2022_64',
           '-DQT_HOST_PATH=/opt/Qt/6.11.2/gcc_64',
           // OpenSceneGraph's vcpkg port pulls in openimageio; Quick3D is the
           // animation backend that cross-builds (as in the wasm build).
           '-DOM_OMEDIT_ANIMATION_QUICK3D=ON'],
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
  List flags = ["-DCMAKE_TOOLCHAIN_FILE=${t.toolchain}",
                '-DCMAKE_BUILD_TYPE=Release',
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
  if (t.sccache) {
    flags += ['-DCMAKE_C_COMPILER_LAUNCHER=sccache', '-DCMAKE_CXX_COMPILER_LAUNCHER=sccache']
  }
  return flags + t.configure
}

// A cross build cannot run what it produced, so check the file format instead --
// a host binary left in bin/ by a misconfigured stage would otherwise ship.
void nightlyCheckArtifacts(Map t) {
  String exe = t.triple.contains('windows') ? '.exe' : ''
  sh """#!/bin/bash
    set -eu
    bin=${nightlyInstallDir(t.name)}/bin/omc${exe}
    test -f "\$bin"
    magic=\$(od -An -tx1 -N4 "\$bin" | tr -d ' \\n')
    echo "\$bin: \$magic"
    case ${t.triple} in
      *windows*) test "\${magic:0:4}" = 4d5a ;;  # MZ
      *darwin*)  test "\$magic" = cffaedfe ;;    # 64-bit Mach-O, little endian
    esac
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
               ['-DOM_ENABLE_GUI_CLIENTS=OFF', '-DRUST_OMC_SCRIPTING_API=ON']
  sh "cmake -S . -B build_cmake ${flags.join(' ')}"
  withSccache {
    sh "cmake --build build_cmake --parallel ${numPhysicalCPU()} --target install"
  }
  nightlyCheckArtifacts(t)
  // The cdylib (and on Windows its import library) for the GUI stage, staged in
  // the workspace: the cargo target directory is in a build tree that stage does
  // not have.
  String cdylib = "build_cmake/OMCompiler/Compiler/rust-target/${t.triple}/release/${t.cdylib}"
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

// Stage 4, Windows: the install tree of every stage that contributed to it, as
// one zip.
void packageRustNightlyWindows(List stashes) {
  standardSetup()
  for (s in stashes) {
    unstash s
  }
  String zip = "OpenModelica-${tagName()}-x86_64-windows.zip"
  sh "rm -f ${zip} && (cd ${nightlyInstallDir('win64')} && zip -q -r -9 -y ${env.WORKSPACE}/${zip} .)"
  sh "ls -l ${zip}"
  uploadRustNightly(zip)
}

// Stage 4, macOS: lipo the two per-architecture install trees into one universal
// tree and ship that. Every Mach-O both trees have becomes a fat binary; see
// .CI/scripts/mac-universal.sh.
void packageRustNightlyMacUniversal(List stashes) {
  standardSetup()
  for (s in stashes) {
    unstash s
  }
  String out = 'install/mac-universal'
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
  String tgz = "OpenModelica-${tagName()}-macos-universal.tar.gz"
  sh "rm -f ${tgz} && tar -C ${out} -czf ${tgz} ."
  uploadRustNightly(tgz)
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
  unstash 'omc-cmake-rust'
  // OMSimulator + libomcruntime aren't produced by the Rust omc build; pull the
  // prebuilt binaries from the clang job (file sets are disjoint from build/**'s
  // rust omc, so this adds to the tree without overwriting it). Needed by the
  // OMSimulator tests and the -lomcruntime bootstrapping tests respectively.
  unstash 'omsimulator'
  unstash 'omcruntime'
  installTestLibraries()
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

def getQtMajorVersion(qtVersion) {
  def OM_QT_MAJOR_VERSION = 'OM_QT_MAJOR_VERSION=6'
  if (qtVersion.equals('qt5')) {
    OM_QT_MAJOR_VERSION = 'OM_QT_MAJOR_VERSION=5'
  }
  return OM_QT_MAJOR_VERSION
}

void buildGUI(stash, qtVersion) {
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

void buildAndRunOMEditTestsuite(stashName, qtVersion) {
  if (stashName) {
    standardSetup()
    sh 'rm -rf OMEdit/common'
    unstash stashName
  }
  sh 'autoreconf --install'
  if (stashName) {
    patchConfigStatus()
  }
  if (qtVersion.equals('qt6')) {
    sh 'echo ./configure --with-qt6 `./config.status --config` > config.status.2 && bash ./config.status.2'
  } else {
    sh 'echo ./configure `./config.status --config` > config.status.2 && bash ./config.status.2'
  }
  if (stashName) {
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
  // installTestLibraries() rather than makeLibsAndCache(): the suite needs only
  // ModelicaCompliance, and a CMake install tree has no Makefile to drive.
  unstash 'omc-cmake-rust'
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

// ----------------------------------------------------------------------------
// Whole-stage step bodies. These live here rather than inline in the
// Jenkinsfile so the declarative pipeline's single generated CPS method stays
// under Groovy's 64kB method-size limit.
// ----------------------------------------------------------------------------

void buildGccOMC() {
  buildOMC('gcc', 'g++', '', true, false)
  stash name: 'omc-gcc', includes: 'build/**, **/config.status'
}

// The jammy CMake build of omc. Its install tree is what the testsuite-gcc
// stages run against (partestCMakeStashed), so keep the flags in sync with what
// those tests need.
void buildCMakeGccOMC() {
  buildOMC_CMake([
    "-DCMAKE_BUILD_TYPE=Release",
    "-DOM_USE_CCACHE=OFF",
    "-DCMAKE_INSTALL_PREFIX=build"])

  // Susan's *.mo and Autoconf.mo travel along because the bootstrapping tests
  // load the compiler sources by path (see partestCMakeStashed).
  stash name: 'omc-cmake-gcc',
        includes: 'build/**,' +
                  'build_cmake/OMCompiler/Compiler/generated-mo/**,' +
                  'OMCompiler/Compiler/Util/Autoconf.mo'
}

void buildClangOMC() {
  buildOMC('clang', 'clang++', '--without-hwloc', true, true)
  getVersion()
  // Resolve symbolic links to make Jenkins happy
  sh 'cp -Lr build build.new && rm -rf build && mv build.new build'
  stash name: 'omc-clang', includes: 'build/**, **/config.status'
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
  sh "make -f Makefile.in -j${numLogicalCPU()} --output-sync=recurse bom-error utf8-error thumbsdb-error spellcheck"
  sh '''
  cd doc/bibliography
  mkdir -p openmodelica.org-bibgen
  sh generate.sh "$PWD/openmodelica.org-bibgen"
  '''
  stash name: 'bibliography', includes: 'doc/bibliography/openmodelica.org-bibgen/*.md'
}

// A partest shard against a stashed omc build (gcc/clang).
void partestStashed(stashName, partition, partitionmodulo) {
  standardSetup()
  unstash stashName
  makeLibsAndCache()
  // arrow: this is the autotools build, the one without libomc_result.
  partest(partition, partitionmodulo, true, '-suites=-arrow')
}

// The same, for a stashed CMake install tree (see buildCMakeGccOMC). Only the
// way the test dependencies are built differs; the run itself is the same
// partest.
void partestCMakeStashed(stashName, partition, partitionmodulo) {
  standardSetup()
  unstash stashName
  makeLibsAndCacheCMake()
  // Susan's generated *.mo files are in the build tree
  def ws = sh(script: 'pwd', returnStdout: true).trim()
  withEnv(["OMCOMPILERGENERATEDSOURCES=${ws}/build_cmake/OMCompiler/Compiler/generated-mo"]) {
    // hdf5: unlike the autotools build, this one links the system HDF5, which
    // gives it MAT v7.3.
    partest(partition, partitionmodulo, true, '-suites=+hdf5')
  }
}

void crossBuildFMU() {
  def deps = docker.image('docker.openmodelica.org/build-deps:ubuntu-22.04')
  deps.pull()
  def dockergid = sh (script: 'stat -c %g /var/run/docker.sock', returnStdout: true).trim()
  deps.inside("-v /var/run/docker.sock:/var/run/docker.sock --group-add '${dockergid}' " +
              "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
              "--mount type=volume,source=runtest-gcc-cache,target=/cache/runtest") {
    standardSetup()
    unstash 'omc-cmake-gcc'
    makeLibsAndCacheCMake()
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
  unstash 'omc-cmake-gcc'
  makeLibsAndCacheCMake()
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

void buildGUIAndStash(stashInput, qtVersion, outStash) {
  buildGUI(stashInput, qtVersion)
  stash name: outStash, includes: 'build/**, **/config.status, OMEdit/**', excludes: 'OMEdit/common'
}

void partestParmod() {
  standardSetup()
  unstash 'omc-clang'
  partest(1, 1, false, '-j1 -parmodexp')
}

void testMetaModelica() {
  standardSetup()
  unstash 'omc-clang'
  sh 'make -C testsuite/metamodelica/MetaModelicaDev test-error'
}

void testMatlabTranslator() {
  standardSetup()
  unstash 'omc-clang'
  generateTemplates()
  sh 'make -C testsuite/special/MatlabTranslator/ test'
}

void testIconGenerator() {
  standardSetup()
  unstash 'omc-clang'
  makeLibsAndCache()
  sh 'make -C testsuite/openmodelica/icon-generator test'
}

void testUnitC() {
  echo "Running on: ${env.NODE_NAME}"
  sh "cmake --version"
  sh "cmake -S ./ -B ./build_cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DOM_USE_CCACHE=OFF"
  sh "cmake --build ./build_cmake --parallel ${numPhysicalCPU()} --target ctestsuite-depends"
  sh "cmake --build ./build_cmake --parallel ${numPhysicalCPU()} --target test"
  sh "test -f ./build_cmake/junit.xml"
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
