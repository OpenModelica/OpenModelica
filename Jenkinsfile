def common
def isPR
def shouldWeBuildAlpine
def shouldWeBuildEnterpriseLinux
def shouldWeBuildFedora
def shouldWeEnableMacOSCMakeBuild
def shouldWeBuildWindows
def shouldWeRunTests
def shouldWeRunRustTests

pipeline {
  agent none
  options {
    newContainerPerStage()
    // Abort the sibling branches as soon as one of them fails: the build is
    // going to be red anyway and the stages that are still running would keep
    // the nodes busy for hours.
    parallelsAlwaysFailFast()
    buildDiscarder(logRotator(daysToKeepStr: "14", artifactNumToKeepStr: "2"))
    // This group's Jenkins config takes the priority from BUILD_PRIORITY.
    jobGroup jobGroupName: 'OpenModelica', useJobGroup: true
  }
  environment {
    LC_ALL = 'C.UTF-8'
  }
  parameters {
    booleanParam(name: 'BUILD_WINDOWS', defaultValue: false, description: 'Build with Windows using CMake')
    booleanParam(name: 'BUILD_ALPINE', defaultValue: false, description: 'Build with Alpine (musl libc) using CMake')
    booleanParam(name: 'BUILD_ENTERPRISE_LINUX', defaultValue: false, description: 'Build with Enterprise Linux')
    booleanParam(name: 'BUILD_FEDORA', defaultValue: false, description: 'Build with Fedora 44')
    booleanParam(name: 'ENABLE_MACOS_CMAKE_BUILD', defaultValue: false, description: 'Enable building omc with CMake on MacOS')
    booleanParam(name: 'ENABLE_RUST_PARTEST', defaultValue: false, description: 'Enable the extra partest run on the Rust omc with RUST_PARTEST_SIMCODETARGET (the wasm-jit partest always runs)')
    string(name: 'RUST_PARTEST_SIMCODETARGET', defaultValue: 'C+Rust', description: 'simCodeTarget for the ENABLE_RUST_PARTEST run (empty = compiler default)')
    // Read at queue time, before common.groovy is loaded.
    string(name: 'BUILD_PRIORITY',
           defaultValue: env.CHANGE_ID ? '3' : '5',
           description: 'Queue priority, 1 (scheduled first) to 5 (last). Defaults to 3 for pull requests and 5 for branch builds.')
  }
  // stages are ordered according to execution time; highest time first
  // nodes are selected based on a priority (in Jenkins config)
  stages {
    stage('Environment') {
      agent {
        node {
          label 'linux'
          customWorkspace 'ws/OpenModelica'
        }
      }
      options {
        retry(count: 2, conditions: [nonresumable()])
      }
      steps {
        script {
          if (changeRequest()) {
            def buildNumber = env.BUILD_NUMBER as int
            if (buildNumber > 1) milestone(buildNumber - 1)
            milestone(buildNumber)
          }
          common = load("${env.workspace}/.CI/common.groovy")
          def buildFlags = common.evaluateBuildFlags()
          isPR = buildFlags.isPR
          shouldWeBuildAlpine = buildFlags.shouldWeBuildAlpine
          shouldWeBuildEnterpriseLinux = buildFlags.shouldWeBuildEnterpriseLinux
          shouldWeBuildFedora = buildFlags.shouldWeBuildFedora
          shouldWeEnableMacOSCMakeBuild = buildFlags.shouldWeEnableMacOSCMakeBuild
          shouldWeBuildWindows = buildFlags.shouldWeBuildWindows
          shouldWeRunTests = buildFlags.shouldWeRunTests
          shouldWeRunRustTests = buildFlags.shouldWeRunRustTests
        }
      }
    }
    stage('setup') {
      parallel {
        // Linux build stages
        stage('jammy-clang') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
              customWorkspace 'ws/OpenModelica'
            }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.buildClangOMC() }
          }
        }
        stage('jammy-gcc') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
              customWorkspace 'ws/OpenModelica'
            }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.buildGccOMC() }
          }
        }
        stage('alpine-clang') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:alpine-3.24'
              label 'linux'
              alwaysPull true
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeBuildAlpine }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script {
              common.buildOMC([
                "-DCMAKE_BUILD_TYPE=Release",
                "-DOM_USE_CCACHE=OFF",
                "-DCMAKE_INSTALL_PREFIX=build",
                "-DCMAKE_C_COMPILER=clang",
                "-DCMAKE_CXX_COMPILER=clang++"])
            }
          }
        }
        stage('enterprise-linux-gcc') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:almalinux-10'
              label 'linux'
              alwaysPull true
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeBuildEnterpriseLinux }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script {
              common.withSccache {
                common.buildOMC([
                  "-DCMAKE_BUILD_TYPE=Release",
                  "-DOM_COMPILER_CACHE=sccache",
                  "-DCMAKE_INSTALL_PREFIX=build",
                  "-DCMAKE_C_COMPILER=gcc",
                  "-DCMAKE_CXX_COMPILER=g++"
                ])
              }
            }
          }
        }
        stage('fedora-gcc') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:fedora-44'
              label 'linux'
              alwaysPull true
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeBuildFedora }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script {
              common.withSccache {
                common.buildOMC([
                  "-DCMAKE_BUILD_TYPE=Release",
                  "-DOM_COMPILER_CACHE=sccache",
                  "-DCMAKE_INSTALL_PREFIX=build",
                  "-DCMAKE_C_COMPILER=gcc",
                  "-DCMAKE_CXX_COMPILER=g++"])
              }
            }
          }
        }

        // macOS build stages
        stage('macos-arm64-gcc') {
          agent {
            node {
              label 'M1'
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeEnableMacOSCMakeBuild}
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script {
              common.buildOMC([
                "-DCMAKE_BUILD_TYPE=Release",
                "-DOM_USE_CCACHE=OFF",
                "-DCMAKE_INSTALL_PREFIX=build",
                "-DCMAKE_PREFIX_PATH=/opt/local",   // Look in /opt/local first to prefer the macports libraries over others in the system.
                "-DCMAKE_C_COMPILER=gcc",           // Always specify the compilers explicitly for macOS
                "-DCMAKE_CXX_COMPILER=g++",
                "-DCMAKE_Fortran_COMPILER=gfortran",
                "-DOM_OMC_ENABLE_COLPACK=OFF"])     // Disable ColPack (missing OpenMP)
            }
          }
        }

        // Windows build stages
        stage('OMDev-gcc') {
          agent {
            node {
              label 'windows-no-release'
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeBuildWindows}
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script {
              common.buildOMC([
                '-DCMAKE_BUILD_TYPE=Release',
                '-DCMAKE_INSTALL_PREFIX=build',
                '-G "MSYS Makefiles"'])
            }
          }
        }

        // The Rust (mmtorust) omc port, GUI off; the GUI is built in parallel
        // with the tests by the 'build-gui-rust' stage. See common.buildRustOMC().
        stage('rust-clang') {
          agent {
            docker {
              alwaysPull true
              image 'docker.openmodelica.org/build-deps:ubuntu-26.04-rust'
              label 'linux'
              args "--mount type=volume,source=rust-cargo-registry,target=/opt/rust/cargo/registry " +
                   "--mount type=volume,source=rust-sccache,target=/cache/sccache " +
                   "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/MacOSX.sdk:/mnt/MacOSX.sdk:ro " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
              customWorkspace 'ws/OpenModelica'
            }
          }
          steps {
            script {
              common.buildRustOMC()
            }
          }
        }

        // Checks
        stage('checks') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
              customWorkspace 'ws/OpenModelica'
            }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.checks() }
          }
        }
      }
    }
    stage('tests + extras') {
      parallel {
        // partest against the Rust-built omc; dedicated runtest cache. See
        // common.partestRust(). Opt-in, on RUST_PARTEST_SIMCODETARGET; the
        // wasm-jit run is stages 23/24.
        stage('01 testsuite-rust 1/2') {
          agent {
            node {
              label 'linux'
              customWorkspace 'ws/OpenModelica'
            }
          }
          environment {
            RUNTESTDB = "/cache/runtest/"
            LIBRARIES = "/cache/omlibrary"
          }
          when {
            beforeAgent true
            expression { shouldWeRunRustTests }
          }
          steps {
            script {
              common.insideTestImage('docker.openmodelica.org/build-deps:ubuntu-26.04-rust',
                                     common.testCacheMounts('runtest-rust-cache')) {
                common.partestRust(params.RUST_PARTEST_SIMCODETARGET, 1, 2, false)
              }
            }
          }
        }
        stage('02 testsuite-rust 2/2') {
          agent {
            node {
              label 'linux'
              customWorkspace 'ws/OpenModelica'
            }
          }
          environment {
            RUNTESTDB = "/cache/runtest/"
            LIBRARIES = "/cache/omlibrary"
          }
          when {
            beforeAgent true
            expression { shouldWeRunRustTests }
          }
          steps {
            script {
              common.insideTestImage('docker.openmodelica.org/build-deps:ubuntu-26.04-rust',
                                     common.testCacheMounts('runtest-rust-cache')) {
                common.partestRust(params.RUST_PARTEST_SIMCODETARGET, 2, 2, false)
              }
            }
          }
        }

        // Both shards run coverage-instrumented builds, one gcc and one clang:
        // their counters become the coverage report in 'check-and-upload'.
        stage('04 testsuite-gcc 1/2') {
          agent {
            node {
              label 'linux'
              customWorkspace 'ws/OpenModelica'
            }
          }
          environment {
            RUNTESTDB = "/cache/runtest/"
            LIBRARIES = "/cache/omlibrary"
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script {
              common.insideTestImage('docker.openmodelica.org/build-deps:ubuntu-22.04',
                                     common.testCacheMounts('runtest-gcc-cache')) {
                common.ctestStashed('omc-gcc', 1, 2)
              }
            }
          }
        }

        stage('05 testsuite-clang 2/2') {
          agent {
            node {
              label 'linux'
              customWorkspace 'ws/OpenModelica'
            }
          }
          environment {
            RUNTESTDB = "/cache/runtest/"
            LIBRARIES = "/cache/omlibrary"
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script {
              common.insideTestImage('docker.openmodelica.org/build-deps:ubuntu-22.04',
                                     common.testCacheMounts('runtest-clang-cache')) {
                common.partestStashed('omc-clang', 2, 2)
              }
            }
          }
        }

        // The WebAssembly/web bundle, embedding the wasm-jit runtime built by
        // the rust-clang stage (OM_OMC_WASM forces the Rust port and a
        // wasm32 build of just the browser/Node deliverable).
        stage('10 web target') {
          agent {
            docker {
              alwaysPull true
              image 'docker.openmodelica.org/build-deps:ubuntu-26.04-rust-qt-wasm'
              label 'linux'
              // EM_CACHE on a persistent volume so the Qt-wasm sysroot (libc/libc++
              // and the ASYNCIFY/memory-growth variants) is built once, not per run.
              args "--mount type=volume,source=rust-cargo-registry,target=/opt/rust/cargo/registry " +
                   "--mount type=volume,source=rust-sccache,target=/cache/sccache " +
                   "--mount type=volume,source=emscripten-cache,target=/cache/emscripten " +
                   "-e EM_CACHE=/cache/emscripten " +
                   "-v /var/lib/jenkins/MacOSX.sdk:/mnt/MacOSX.sdk:ro " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          steps {
            script {
              common.buildRustWeb()
            }
          }
        }

        // The slow Qt web pages (OMShell/OMNotebook/OMEdit-qt), in parallel;
        // merged by assemble-web.
        stage('10b qt-web target') {
          agent {
            docker {
              alwaysPull true
              image 'docker.openmodelica.org/build-deps:ubuntu-26.04-rust-qt-wasm'
              label 'linux'
              args "--mount type=volume,source=rust-cargo-registry,target=/opt/rust/cargo/registry " +
                   "--mount type=volume,source=rust-sccache,target=/cache/sccache " +
                   "--mount type=volume,source=emscripten-cache,target=/cache/emscripten " +
                   "-e EM_CACHE=/cache/emscripten " +
                   "-v /var/lib/jenkins/MacOSX.sdk:/mnt/MacOSX.sdk:ro " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          steps {
            script {
              common.buildRustWebQt()
            }
          }
        }

        // Qt GUI clients linked against the stage-1 cdylib (no cargo/codegen
        // rerun), in parallel with the tests. See common.buildRustGUI().
        stage('11 build-gui-rust') {
          agent {
            docker {
              alwaysPull true
              image 'docker.openmodelica.org/build-deps:ubuntu-26.04-rust'
              label 'linux'
              args "--mount type=volume,source=rust-cargo-registry,target=/opt/rust/cargo/registry " +
                   "--mount type=volume,source=rust-sccache,target=/cache/sccache " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          steps {
            script {
              common.buildRustGUI()
            }
          }
        }

        // Cargo workspace unit tests (dev/cranelift) off the build critical path,
        // on the stage-1 generated .rs. See common.ctestRust().
        stage('12 unit-tests-rust') {
          agent {
            docker {
              alwaysPull true
              image 'docker.openmodelica.org/build-deps:ubuntu-26.04-rust'
              label 'linux'
              args "--mount type=volume,source=rust-cargo-registry,target=/opt/rust/cargo/registry " +
                   "--mount type=volume,source=rust-sccache,target=/cache/sccache " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          steps {
            script {
              common.ctestRust()
            }
          }
        }

        stage('13 cross-build-fmu') {
          agent {
            node {
              label 'linux'
              customWorkspace 'ws/OpenModelica'
            }
          }
          environment {
            RUNTESTDB = "/cache/runtest/"
            LIBRARIES = "/cache/omlibrary"
            HOME = "${env.WORKSPACE}/libraries"
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.crossBuildFMU() }
          }
        }

        // The Rust omc with the wasm-jit target: no C compiler or linker per
        // model, which is where the ~1000 runs went. The rust image because that
        // is the glibc the unstashed omc was built against.
        stage('14 testsuite-compliance') {
          agent {
            docker {
              alwaysPull true
              image 'docker.openmodelica.org/build-deps:ubuntu-26.04-rust'
              label 'linux'
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
              customWorkspace 'ws/OpenModelica'
            }
          }
          environment {
            LIBRARIES = "/cache/omlibrary"
            COMPLIANCEEXTRAFLAGS = "--simCodeTarget=wasm-jit"
            COMPLIANCEEXTRAREPORTFLAGS = "--expectedFailures=.CI/compliance.failures --flakyTests=.CI/compliance.flaky"
            COMPLIANCEPREFIX = "compliance"
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.compliance() }
          }
        }

        stage('15 build-usersguide') {
          agent {
            docker {
              alwaysPull true
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
              customWorkspace 'ws/OpenModelica'
            }
          }
          environment {
            RUNTESTDB = "/cache/runtest/" // Dummy directory
            LIBRARIES = "/cache/omlibrary"
            GITHUB_AUTH = credentials('OpenModelica-Hudson')
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.buildUsersGuide() }
          }
        }

        stage('17 build-gui-clang + omedit-testsuite') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary"
              customWorkspace 'ws/OpenModelica'
            }
          }
          environment {
            // makeLibsAndCache() only reads runtest.db from RUNTESTDB (and
            // tolerates it being absent); the omlibrary cache is the one that
            // matters here, so no runtest volume is mounted.
            RUNTESTDB = "/cache/runtest/"
            LIBRARIES = "/cache/omlibrary"
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.buildGUIAndRunOMEditTestsuite() }
          }
        }

        // parmod, the Matlab translator, the icon generator and the C unit tests.
        // Short runs sharing one image, so one node: split up, the
        // image pull and the git checkout cost more than the tests.
        stage('18 testsuite-misc') {
          agent {
            node {
              // Intel only: ParModelica compiles its OpenCL kernels through the node's ICD,
              // which on AMD is PoCL. Jammy's PoCL 1.8 (LLVM 14) cannot name a Zen CPU it
              // does not know and falls back to the target CPU 'generic', which LLVM
              // rejects; the POCL_LLVM_CPU_NAME override only exists in later PoCL. Lifting
              // this needs both the build and the tests on a newer image (Ubunut 26.04 or newer).
              label 'linux-intel-x64'
              customWorkspace 'ws/OpenModelica'
            }
          }
          environment {
            RUNTESTDB = "/cache/runtest/"
            LIBRARIES = "/cache/omlibrary"
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script {
              common.insideTestImage('docker.openmodelica.org/build-deps:ubuntu-22.04',
                                     common.testCacheMounts('runtest-clang-icon-generator')) {
                common.testMisc()
              }
            }
          }
          post {
            always {
              junit testResults: 'build_cmake/junit.xml', skipPublishingChecks: true
            }
          }
        }

        // The wasm-jit partest, same setup as stages 01/02. Last in the block
        // (against the ordering rule above): the fastest of the testsuite runs,
        // so it loses the least by starting after the others. Unpartitioned - it
        // is fast enough not to need the split the C targets use.
        stage('19 testsuite-wasm-jit') {
          agent {
            node {
              label 'linux'
              customWorkspace 'ws/OpenModelica'
            }
          }
          environment {
            RUNTESTDB = "/cache/runtest/"
            LIBRARIES = "/cache/omlibrary"
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script {
              common.insideTestImage('docker.openmodelica.org/build-deps:ubuntu-26.04-rust',
                                     common.testCacheMounts('runtest-rust-cache')) {
                common.partestRust('wasm-jit', 1, 1, true)
              }
            }
          }
        }

        // The smoke set (every test in '// suite: smoke', see
        // testsuite/runWindowsTests.sh), against the install tree
        // 'OMDev-gcc' stashed as 'omc-windows'. Its own stage, not
        // part of that build, so a test failure here reads as a testsuite
        // failure rather than a build failure.
        stage('20 testsuite-windows') {
          agent {
            node {
              label 'windows-no-release'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeBuildWindows }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script {
              common.testWindowsSmoke()
            }
          }
        }

        // The C omc cross-compiled to Windows (MSVC) from the C sources
        // 'cmake-jammy-gcc' translated, and the Windows smoke set run against
        // it under wine. See common.crossBuildOMCWindows().
        stage('21 cross-build-omc-msvc') {
          agent {
            docker {
              alwaysPull true
              image 'docker.openmodelica.org/build-deps:ubuntu-26.04-rust-qt-win-x86_64'
              label 'linux'
              args "--mount type=volume,source=rust-cargo-registry,target=/opt/rust/cargo/registry " +
                   "--mount type=volume,source=om-thirdparty-downloads,target=/cache/thirdparty " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          steps {
            script {
              common.crossBuildOMCWindows()
            }
          }
        }
      }
    }
    stage('FMPy') {
      parallel {
        // Merge stages 10 + 10b into the published web zip.
        stage('assemble-web') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          steps {
            script { common.assembleWeb() }
          }
        }
        stage('linux-FMPy') {
          agent {
            docker {
              label 'linux'
              image 'docker.openmodelica.org/fmpy:v0.3.18'
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          options {
            skipDefaultCheckout true
          }
          steps {
            script { common.fmpyLinux() }
          }
        }
      }
    }
    stage('check-and-upload') {
      parallel {
        // Turns the coverage counters of the testsuite-gcc and -clang shards,
        // the testsuite-misc stage (clang), the C runtime unit tests (gcc) and
        // the OMEdit testsuite into one report. Unlike its neighbours it is not
        // gated on !isPR: the point is to get the number on every PR.
        stage('coverage-report') {
          agent {
            node {
              label 'linux'
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          steps {
            script {
              // Enters the build image itself: which mounts it needs depends
              // on where the instrumented build ran, which it only learns
              // from the stash.
              common.coverageReportStage([
                'gcc'  : ['omc-gcc-1'],
                'clang': ['omc-clang-2', 'omc-clang-misc']])
            }
          }
        }
        stage('upload-compliance') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { !isPR }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.uploadCompliance() }
          }
        }
        stage('upload-doc') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { !isPR }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.uploadDoc() }
          }
        }
        stage('upload-web') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            expression { !isPR }
          }
          steps {
            script { common.uploadWeb() }
          }
        }
      }
    }
    stage('publish') {
      parallel {
        stage('push-to-master') {
          agent {
            node {
              label 'linux'
              customWorkspace 'ws/OpenModelica'
            }
          }
          when {
            beforeAgent true
            branch 'omlib-staging'
            expression { return currentBuild.currentResult == 'SUCCESS' }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.pushToMaster() }
          }
        }
        stage('push-bibliography') {
          agent {
            node {
              label 'linux'
              customWorkspace 'ws/OpenModelica-Bibliography'
            }
          }
          when {
            beforeAgent true
            branch 'master'
            expression { return currentBuild.currentResult == 'SUCCESS' }
          }
          options {
            skipDefaultCheckout true
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.pushBibliography() }
          }
        }
      }
    }
  }
  post {
    failure {
      script {
        common.notifyOnFailure()
      }
    }
  }
}

/* Note: If getting "Unexpected end of /proc/mounts line" , flatten the docker image:
 * https://stackoverflow.com/questions/46138549/docker-openmpi-and-unexpected-end-of-proc-mounts-line
 * Or use a newer OS image with fixed hwloc.
 */
