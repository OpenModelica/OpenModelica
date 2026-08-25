def common
def isPR
def shouldWeBuildAlpine
def shouldWeBuildEnterpriseLinux
def shouldWeBuildFedora
def shouldWeEnableMacOSCMakeBuild
def shouldWeBuildWindows
def shouldWeDisableAllCMakeBuilds
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
    booleanParam(name: 'ENABLE_RUST_PARTEST', defaultValue: false, description: 'Enable running partest on the Rust target')
    string(name: 'RUST_PARTEST_SIMCODETARGET', defaultValue: 'wasm-jit', description: 'Override simCodeTarget for the Rust partest, e.g. wasm-jit (empty = compiler default)')
    booleanParam(name: 'RUST_PARTEST_JUNIT', defaultValue: false, description: 'Register the Rust partest result.xml as JUnit results (per-test view; makes the build unstable on failures)')
  }
  // stages are ordered according to execution time; highest time first
  // nodes are selected based on a priority (in Jenkins config)
  stages {
    stage('Environment') {
      agent {
        label 'linux'
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
        stage('gcc') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
            }
          }
          environment {
            QTDIR = "/usr/lib/qt4"
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.buildGccOMC() }
          }
        }
        stage('clang') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
            }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.buildClangOMC() }
          }
        }
        stage('cmake-jammy-gcc') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
            }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.buildCMakeGccOMC() }
          }
        }
        stage('cmake-alpine-clang') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:alpine-3.24'
              label 'linux'
              alwaysPull true
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
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
              common.buildOMC_CMake([
                "-DCMAKE_BUILD_TYPE=Release",
                "-DOM_USE_CCACHE=OFF",
                "-DCMAKE_INSTALL_PREFIX=build",
                "-DCMAKE_C_COMPILER=clang",
                "-DCMAKE_CXX_COMPILER=clang++"])
            }
          }
        }
        stage('cmake-enterprise-linux-gcc') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:almalinux-10'
              label 'linux'
              alwaysPull true
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
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
              common.buildOMC_CMake([
                "-DCMAKE_BUILD_TYPE=Release",
                "-DOM_USE_CCACHE=OFF",
                "-DCMAKE_INSTALL_PREFIX=build",
                "-DCMAKE_C_COMPILER=gcc",
                "-DCMAKE_CXX_COMPILER=g++",
                "-DOM_OMEDIT_ANIMATION_QUICK3D=ON" // Almalinux-10 has no OpenSceneGraph, switch to Quick3D
              ])
            }
          }
        }
        stage('cmake-fedora-gcc') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:fedora-44'
              label 'linux'
              alwaysPull true
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
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
              common.buildOMC_CMake([
                "-DCMAKE_BUILD_TYPE=Release",
                "-DOM_USE_CCACHE=OFF",
                "-DCMAKE_INSTALL_PREFIX=build",
                "-DCMAKE_C_COMPILER=gcc",
                "-DCMAKE_CXX_COMPILER=g++"])
            }
          }
        }

        // macOS build stages
        stage('cmake-macos-arm64-gcc') {
          agent {
            node {
              label 'M1'
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
              common.buildOMC_CMake([
                "-DCMAKE_BUILD_TYPE=Release",
                "-DOM_USE_CCACHE=OFF",
                "-DCMAKE_INSTALL_PREFIX=build",
                "-DCMAKE_PREFIX_PATH=/opt/local",   // Look in /opt/local first to prefer the macports libraries over others in the system.
                "-DCMAKE_C_COMPILER=gcc",           // Always specify the compilers explicitly for macOS
                "-DCMAKE_CXX_COMPILER=g++",
                "-DCMAKE_Fortran_COMPILER=gfortran",
                "-DOM_QT_MAJOR_VERSION=5",          // Use Qt5 on old macOS machines
                "-DOM_OMC_ENABLE_COLPACK=OFF"])     // Disable ColPack (missing OpenMP)
            }
          }
        }

        // Windows build stages
        stage('cmake-OMDev-gcc') {
          agent {
            node {
              label 'windows-no-release'
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
              common.buildOMC_CMake([
                '-DCMAKE_BUILD_TYPE=Release',
                '-DCMAKE_INSTALL_PREFIX=build',
                '-G "MSYS Makefiles"'])
            }
          }
        }

        // The Rust (mmtorust) omc port, GUI off; the GUI is built in parallel
        // with the tests by the 'build-gui-rust' stage. See common.buildRustOMC().
        stage('cmake-rust-clang') {
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
        // common.partestRust().
        stage('01 testsuite-rust 1/2') {
          agent {
            label 'linux'
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
                common.partestRust(1)
              }
            }
          }
        }
        stage('02 testsuite-rust 2/2') {
          agent {
            label 'linux'
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
                common.partestRust(2)
              }
            }
          }
        }

        stage('04 testsuite-cmake-gcc 1/3') {
          agent {
            label 'linux'
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
                common.partestCMakeStashed('omc-cmake-gcc', 1, 3)
              }
            }
          }
        }

        stage('05 testsuite-cmake-gcc 2/3') {
          agent {
            label 'linux'
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
                common.partestCMakeStashed('omc-cmake-gcc', 2, 3)
              }
            }
          }
        }

        stage('06 testsuite-cmake-gcc 3/3') {
          agent {
            label 'linux'
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
                common.partestCMakeStashed('omc-cmake-gcc', 3, 3)
              }
            }
          }
        }

        stage('07 testsuite-clang 1/3') {
          agent {
            label 'linux'
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
                common.partestStashed('omc-clang', 1, 3)
              }
            }
          }
        }

        stage('08 testsuite-clang 2/3') {
          agent {
            label 'linux'
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
                common.partestStashed('omc-clang', 2, 3)
              }
            }
          }
        }

        stage('09 testsuite-clang 3/3') {
          agent {
            label 'linux'
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
                common.partestStashed('omc-clang', 3, 3)
              }
            }
          }
        }

        // The WebAssembly/web bundle, embedding the wasm-jit runtime built by
        // the cmake-rust-clang stage (OM_OMC_WASM forces the Rust port and a
        // wasm32 build of just the browser/Node deliverable).
        stage('10 web target') {
          agent {
            docker {
              alwaysPull true
              image 'docker.openmodelica.org/build-deps:ubuntu-26.04-rust'
              label 'linux'
              // EM_CACHE on a persistent volume so the Qt-wasm sysroot (libc/libc++
              // and the ASYNCIFY/memory-growth variants) is built once, not per run.
              args "--mount type=volume,source=rust-cargo-registry,target=/opt/rust/cargo/registry " +
                   "--mount type=volume,source=rust-sccache,target=/cache/sccache " +
                   "--mount type=volume,source=emscripten-cache,target=/cache/emscripten " +
                   "-e EM_CACHE=/cache/emscripten " +
                   "-v /var/lib/jenkins/MacOSX.sdk:/mnt/MacOSX.sdk:ro " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
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
              image 'docker.openmodelica.org/build-deps:ubuntu-26.04-rust'
              label 'linux'
              args "--mount type=volume,source=rust-cargo-registry,target=/opt/rust/cargo/registry " +
                   "--mount type=volume,source=rust-sccache,target=/cache/sccache " +
                   "--mount type=volume,source=emscripten-cache,target=/cache/emscripten " +
                   "-e EM_CACHE=/cache/emscripten " +
                   "-v /var/lib/jenkins/MacOSX.sdk:/mnt/MacOSX.sdk:ro " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
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
            label 'linux'
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

        stage('14 testsuite-compliance') {
          agent {
            docker {
              alwaysPull true
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
            }
          }
          environment {
            LIBRARIES = "/cache/omlibrary"
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

        stage('16 build-gui-clang-qt5') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary"
            }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.buildGUIAndStash('omc-clang', 'qt5', 'omedit-testsuite-clang-qt5') }
          }
        }

        stage('17 build-gui-clang-qt6') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary"
            }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.buildGUIAndStash('omc-clang', 'qt6', 'omedit-testsuite-clang-qt6') }
          }
        }

        stage('18 testsuite-clang-parmod') {
          agent {
            label 'linux'
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
              // No runtest.db cache necessary; the tests run in serial and do not load libraries!
              common.insideTestImage('docker.openmodelica.org/build-deps:ubuntu-22.04', '') {
                common.partestParmod()
              }
            }
          }
        }

        stage('19 testsuite-clang-metamodelica') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.testMetaModelica() }
          }
        }

        stage('20 testsuite-matlab-translator') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.testMatlabTranslator() }
          }
        }

        stage('21 test-clang-icon-generator') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              args '''
                --mount type=volume,source=runtest-clang-icon-generator,target=/cache/runtest \
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
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
            script { common.testIconGenerator() }
          }
        }

        stage('22 testsuite-unit-test-C') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              args '''
                --mount type=volume,source=omlibrary-cache,target=/cache/omlibrary \
                -v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache
              '''
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script { common.testUnitC() }
          }
          post {
            always {
              junit testResults: 'build_cmake/junit.xml', skipPublishingChecks: true
            }
          }
        }
      }
    }
    stage('FMPy + OMEdit testsuite') {
      parallel {
        // Merge stages 10 + 10b into the published web zip.
        stage('assemble-web') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
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
        stage('clang-qt5-omedit-testsuite') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary"
            }
          }
          environment {
            RUNTESTDB = "/cache/runtest/"
            LIBRARIES = "/cache/omlibrary"
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script {
              common.buildAndRunOMEditTestsuite('omedit-testsuite-clang-qt5', 'qt5')
            }
          }
        }
        stage('clang-qt6-omedit-testsuite') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary"
            }
          }
          environment {
            RUNTESTDB = "/cache/runtest/"
            LIBRARIES = "/cache/omlibrary"
          }
          options {
            retry(count: 2, conditions: [nonresumable()])
          }
          steps {
            script {
              common.buildAndRunOMEditTestsuite('omedit-testsuite-clang-qt6', 'qt6')
            }
          }
        }
      }
    }
    stage('check-and-upload') {
      parallel {
        stage('upload-compliance') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:ubuntu-22.04'
              label 'linux'
              alwaysPull true
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
            label 'linux'
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
 * Or use a newer OS image with fixed hwloc, or disable hwloc in the configure script
 */
