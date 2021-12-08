def common
def shouldWeBuildOSX
def shouldWeBuildMINGW
def shouldWeBuildCENTOS7
def shouldWeSkipCMakeBuild_value
def shouldWeRunTests
def isPR
pipeline {
  agent none
  options {
    newContainerPerStage()
    buildDiscarder(logRotator(daysToKeepStr: "14", artifactNumToKeepStr: "2"))
  }
  environment {
    LC_ALL = 'C.UTF-8'
  }
  parameters {
    booleanParam(name: 'BUILD_OSX', defaultValue: false, description: 'Build with OSX')
    booleanParam(name: 'BUILD_MINGW', defaultValue: false, description: 'Build with Win/MinGW')
    booleanParam(name: 'BUILD_CENTOS7', defaultValue: false, description: 'Build on CentOS7 with CMake 2.8')
    booleanParam(name: 'SKIP_CMAKE_BUILD', defaultValue: false, description: 'Skip building omc with the CMake build system (CMake 3.17.2)')
  }
  // stages are ordered according to execution time; highest time first
  // nodes are selected based on a priority (in Jenkins config)
  stages {
    stage('Environment') {
      agent {
        label '!windows'
      }
      steps {
        script {
          if (changeRequest()) {
            def buildNumber = env.BUILD_NUMBER as int
            if (buildNumber > 1) milestone(buildNumber - 1)
            milestone(buildNumber)
          }
          common = load("${env.workspace}/.CI/common.groovy")
          isPR = common.isPR()
          print "isPR: ${isPR}"
          shouldWeBuildOSX = common.shouldWeBuildOSX()
          print "shouldWeBuildOSX: ${shouldWeBuildOSX}"
          shouldWeBuildMINGW = common.shouldWeBuildMINGW()
          print "shouldWeBuildMINGW: ${shouldWeBuildMINGW}"
          shouldWeBuildCENTOS7 = common.shouldWeBuildCENTOS7()
          print "shouldWeBuildCENTOS7: ${shouldWeBuildCENTOS7}"
          shouldWeSkipCMakeBuild_value = common.shouldWeSkipCMakeBuild()
          print "shouldWeSkipCMakeBuild: ${shouldWeSkipCMakeBuild_value}"
          shouldWeRunTests = common.shouldWeRunTests()
          print "shouldWeRunTests: ${shouldWeRunTests}"
        }
      }
    }
    stage('setup') {
      parallel {
        stage('gcc') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.16-qt4-xenial'
              label 'linux'
              alwaysPull true
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
            }
          }
          environment {
            QTDIR = "/usr/lib/qt4"
          }
          steps {
            // Xenial is GCC 5
            script { common.buildOMC('gcc-5', 'g++-5', '', true, false) }
            stash name: 'omc-gcc', includes: 'build/**, **/config.status'
          }
        }
        stage('clang') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.16.3'
              label 'linux'
              alwaysPull true
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
            }
          }
          steps {
            script {
              common.buildOMC('clang', 'clang++', '--without-hwloc', true, true)
              common.getVersion()
            }
            // Resolve symbolic links to make Jenkins happy
            sh 'cp -Lr build build.new && rm -rf build && mv build.new build'
            stash name: 'omc-clang', includes: 'build/**, **/config.status'
          }
        }
        stage('MacOS') {
          agent {
            node {
              label 'osx'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeBuildOSX }
          }
          environment {
            RUNTESTDB = '/Users/hudson/jenkins-cache/runtest/'
            LIBRARIES = '/Users/hudson/jenkins-cache/omlibrary'
            GMAKE = 'gmake'
            LC_ALL = 'C'
          }
          steps {
            script {
              // Qt5 is MacOS 10.12+...
              withEnv (["PATH=${env.MACPORTS}/bin:${env.PATH}:/usr/local/bin/", "QTDIR=${env.MACPORTS}/libexec/qt4"]) {
                sh "echo PATH: \$PATH QTDIR: \$QTDIR"
                sh "${env.GMAKE} --version"
                common.buildOMC('cc', 'c++', "OMPCC='gcc-mp-5 -fopenmp -mno-avx' GNUCXX=g++-mp-5 FC=gfortran-mp-5 LDFLAGS=-L${env.MACPORTS}/lib CPPFLAGS=-I${env.MACPORTS}/include --without-omlibrary", true, false)
                common.buildGUI('', false)
                sh label: "All dylibs and their deps in build/", script: 'find build/ -name "*.dylib" -exec otool -L {} ";"'
                sh label: "Look for relative paths in dylibs", script: '! ( find build/ -name "*.dylib" -exec otool -L {} ";" | tr -d "\t" | grep -v : | grep -v "^[/@]" )'
                sh label: "All executables and therir deps in build/bin", script: 'find build/bin -type f -exec otool -L {} ";"'
                sh label: "Look for relative paths in bin folder", script: '! ( find build/bin -type f -exec otool -L {} ";" | tr -d "\t" | grep -v : | grep -v "^[/@]" )'
                // TODO: OMCppOSUSimulation throws error for help display
                //sh label: "Sanity check for Cpp runtime", script: "./build/bin/OMCppOSUSimulation --help"
                sh label: "Sanity check for OMEdit", script: "./build/Applications/OMEdit.app/Contents/MacOS/OMEdit --help"
              }
            }
          }
        }
        stage('Win/MinGW') {
          agent {
            node {
              label 'windows'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeBuildMINGW }
          }
          environment {
            RUNTESTDB = '/c/dev/'
            LIBRARIES = '/c/dev/jenkins-cache/omlibrary/'
          }
          steps {
            script {
              withEnv (["PATH=C:\\OMDev\\tools\\msys\\usr\\bin;C:\\Program Files\\TortoiseSVN\\bin;c:\\bin\\jdk\\bin;c:\\bin\\nsis\\;${env.PATH};c:\\bin\\git\\bin;"]) {
                bat "echo PATH: %PATH%"
                common.buildOMC('cc', 'c++', '', true, false)
                common.makeLibsAndCache()
                common.buildOMSens()
                common.buildGUI('', true)
                common.buildAndRunOMEditTestsuite('')
              }
            }
          }
        }
        stage('CentOS7') {
          agent {
            dockerfile {
              additionalBuildArgs '--pull'
              dir '.CI/cache-centos7'
              label 'linux'
              args "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
            }
          }
          when {
            beforeAgent true
            expression { shouldWeBuildCENTOS7 }
          }
          environment {
            QTDIR = "/usr/lib64/qt5/"
          }
          steps {
            sh "source /opt/rh/devtoolset-8/enable"
            script {
              common.buildOMC(
                '/opt/rh/devtoolset-8/root/usr/bin/gcc',
                '/opt/rh/devtoolset-8/root/usr/bin/g++',
                'FC=/opt/rh/devtoolset-8/root/usr/bin/gfortran CMAKE=cmake3',
                false, // Building C++ runtime doesn't work at the moment
                false)
            }
            //stash name: 'omc-centos7', includes: 'build/**, **/config.status'
          }
        }
        stage('cmake-gcc') {
          agent {
            dockerfile {
              additionalBuildArgs '--pull'
              dir '.CI/cache-bionic-cmake-3.17.2'
              label 'linux'
              args "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
            }
          }
          when {
            beforeAgent true
            expression { !shouldWeSkipCMakeBuild_value }
          }
          steps {
            script {
              common.buildOMC_CMake('-DCMAKE_BUILD_TYPE=Release -DOMC_USE_CCACHE=OFF -DCMAKE_INSTALL_PREFIX=build', '/opt/cmake-3.17.2/bin/cmake')
              sh "build/bin/omc --version"
            }
            // stash name: 'omc-cmake-gcc', includes: 'OMCompiler/build_cmake/install_cmake/bin/**'
          }
        }
        stage('checks') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.16.3'
              label 'linux'
              alwaysPull true
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
            }
          }
          steps {
            script { common.standardSetup() }
            // It's really bad if we mess up the repo and can no longer build properly
            sh '! git submodule foreach --recursive git diff 2>&1 | grep CRLF'
            // TODO: trailing-whitespace-error tab-error
            sh "make -f Makefile.in -j${common.numLogicalCPU()} --output-sync=recurse bom-error utf8-error thumbsdb-error spellcheck"
            sh '''
            cd doc/bibliography
            mkdir -p /tmp/openmodelica.org-bibgen
            sh generate.sh /tmp/openmodelica.org-bibgen
            '''
          }
        }
      }
    }
    stage('tests') {
      parallel {
        stage('cross-build-fmu') {
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
          steps {
            script {
              def deps = docker.build('testsuite-fmu-crosscompile', '--pull .CI/cache')
              // deps.pull() // Already built...
              def dockergid = sh (script: 'stat -c %g /var/run/docker.sock', returnStdout: true).trim()
              deps.inside("-v /var/run/docker.sock:/var/run/docker.sock --group-add '${dockergid}'") {
                common.standardSetup()
                unstash 'omc-clang'
                common.makeLibsAndCache()
                writeFile file: 'testsuite/special/FmuExportCrossCompile/VERSION', text: common.getVersion()
                sh 'make -C testsuite/special/FmuExportCrossCompile/ dockerpull'
                sh 'make -C testsuite/special/FmuExportCrossCompile/ test'
                stash name: 'cross-fmu', includes: 'testsuite/special/FmuExportCrossCompile/*.fmu'
                stash name: 'cross-fmu-extras', includes: 'testsuite/special/FmuExportCrossCompile/*.mos, testsuite/special/FmuExportCrossCompile/*.csv, testsuite/special/FmuExportCrossCompile/*.sh, testsuite/special/FmuExportCrossCompile/*.opt, testsuite/special/FmuExportCrossCompile/*.txt, testsuite/special/FmuExportCrossCompile/VERSION'
                archiveArtifacts "testsuite/special/FmuExportCrossCompile/*.fmu"
              }
            }
          }
        }
        stage('testsuite-clang 1/3') {
          agent {
            dockerfile {
              additionalBuildArgs '--pull'
              dir '.CI/cache'
              /* The cache Dockerfile makes /cache/runtest, etc world writable
               * This is necessary because we run the docker image as a user and need to
               * be able to have a global caching of the omlibrary parts and the runtest database.
               * Note that the database is stored in a volume on a per-node basis, so the first time
               * the tests run on a particular node, they might execute slightly slower
               */
              label 'linux'
              args "--mount type=volume,source=runtest-clang-cache,target=/cache/runtest " +
                   "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
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
          steps {
            script {
              common.standardSetup()
              unstash 'omc-clang'
              common.makeLibsAndCache()
              common.partest(1,3)
            }
          }
        }
        stage('testsuite-clang 2/3') {
          agent {
            dockerfile {
              additionalBuildArgs '--pull'
              dir '.CI/cache'
              /* The cache Dockerfile makes /cache/runtest, etc world writable
               * This is necessary because we run the docker image as a user and need to
               * be able to have a global caching of the omlibrary parts and the runtest database.
               * Note that the database is stored in a volume on a per-node basis, so the first time
               * the tests run on a particular node, they might execute slightly slower
               */
              label 'linux'
              args "--mount type=volume,source=runtest-clang-cache,target=/cache/runtest " +
                   "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
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
          steps {
            script {
              common.standardSetup()
              unstash 'omc-clang'
              common.makeLibsAndCache()
              common.partest(2,3)
            }
          }
        }
        stage('testsuite-clang 3/3') {
          agent {
            dockerfile {
              additionalBuildArgs '--pull'
              dir '.CI/cache'
              /* The cache Dockerfile makes /cache/runtest, etc world writable
               * This is necessary because we run the docker image as a user and need to
               * be able to have a global caching of the omlibrary parts and the runtest database.
               * Note that the database is stored in a volume on a per-node basis, so the first time
               * the tests run on a particular node, they might execute slightly slower
               */
              label 'linux'
              args "--mount type=volume,source=runtest-clang-cache,target=/cache/runtest " +
                   "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
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
          steps {
            script {
              common.standardSetup()
              unstash 'omc-clang'
              common.makeLibsAndCache()
              common.partest(3,3)
            }
          }
        }

        stage('testsuite-gcc 1/3') {
          agent {
            dockerfile {
              additionalBuildArgs '--pull'
              dir '.CI/cache-xenial'
              label 'linux'
              args "--mount type=volume,source=runtest-gcc-cache,target=/cache/runtest " +
                   "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
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
          steps {
            script {
              common.standardSetup()
              unstash 'omc-gcc'
              common.makeLibsAndCache()
              common.partest(1,3)
            }
          }
        }
        stage('testsuite-gcc 2/3') {
          agent {
            dockerfile {
              additionalBuildArgs '--pull'
              dir '.CI/cache-xenial'
              label 'linux'
              args "--mount type=volume,source=runtest-gcc-cache,target=/cache/runtest " +
                   "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
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
          steps {
            script {
              common.standardSetup()
              unstash 'omc-gcc'
              common.makeLibsAndCache()
              common.partest(2,3)
            }
          }
        }
        stage('testsuite-gcc 3/3') {
          agent {
            dockerfile {
              additionalBuildArgs '--pull'
              dir '.CI/cache-xenial'
              label 'linux'
              args "--mount type=volume,source=runtest-gcc-cache,target=/cache/runtest " +
                   "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
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
          steps {
            script {
              common.standardSetup()
              unstash 'omc-gcc'
              common.makeLibsAndCache()
              common.partest(3,3)
            }
          }
        }

        stage('testsuite-compliance') {
          agent {
            dockerfile {
              additionalBuildArgs '--pull'
              dir '.CI/cache'
              /* The cache Dockerfile makes /cache/runtest, etc world writable
               * This is necessary because we run the docker image as a user and need to
               * be able to have a global caching of the omlibrary parts and the runtest database.
               * Note that the database is stored in a volume on a per-node basis, so the first time
               * the tests run on a particular node, they might execute slightly slower
               */
              label 'linux'
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
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
          steps {
            script { common.compliance() }
          }
        }

        stage('testsuite-compliance-newinst') {
          agent {
            dockerfile {
              additionalBuildArgs '--pull'
              dir '.CI/cache'
              /* The cache Dockerfile makes /cache/runtest, etc world writable
               * This is necessary because we run the docker image as a user and need to
               * be able to have a global caching of the omlibrary parts and the runtest database.
               * Note that the database is stored in a volume on a per-node basis, so the first time
               * the tests run on a particular node, they might execute slightly slower
               */
              label 'linux'
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
            }
          }
          environment {
            LIBRARIES = "/cache/omlibrary"
            COMPLIANCEEXTRAFLAGS = "-d=newInst"
            COMPLIANCEEXTRAREPORTFLAGS = "--expectedFailures=.CI/compliance-newinst.failures"
            COMPLIANCEPREFIX = "compliance-newinst"
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          steps {
            script { common.compliance() }
          }
        }

        stage('build-gui-clang-qt5') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.16.3'
              label 'linux'
              alwaysPull true
            }
          }
          steps {
            script {
              common.buildGUI('omc-clang', true)
            }
            stash name: 'omedit-testsuite-clang', includes: 'build/**, **/config.status, OMEdit/**'
          }
        }

        stage('build-usersguide') {
          agent {
            dockerfile {
              additionalBuildArgs '--pull'
              dir '.CI/cache'
              label 'linux'
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
            }
          }
          environment {
            RUNTESTDB = "/cache/runtest/" // Dummy directory
            LIBRARIES = "/cache/omlibrary"
          }
          steps {
            script {
              common.standardSetup()
              unstash 'omc-clang'
              common.makeLibsAndCache()
            }
            sh '''
            export OPENMODELICAHOME=$PWD/build
            test ! -d $PWD/build/lib/omlibrary
            cp -a testsuite/libraries-for-testing/.openmodelica/libraries $PWD/build/lib/omlibrary
            for target in html pdf epub; do
              if ! make -C doc/UsersGuide $target; then
                killall omc || true
                exit 1
              fi
            done
            '''
            sh "tar --transform 's/^html/OpenModelicaUsersGuide/' -cJf OpenModelicaUsersGuide-${common.tagName()}.html.tar.xz -C doc/UsersGuide/build html"
            sh "mv doc/UsersGuide/build/latex/OpenModelicaUsersGuide.pdf OpenModelicaUsersGuide-${common.tagName()}.pdf"
            sh "mv doc/UsersGuide/build/epub/OpenModelicaUsersGuide.epub OpenModelicaUsersGuide-${common.tagName()}.epub"
            archiveArtifacts "OpenModelicaUsersGuide-${common.tagName()}*.*"
            stash name: 'usersguide', includes: "OpenModelicaUsersGuide-${common.tagName()}*.*"
          }
        }

        stage('testsuite-clang-parmod') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.16.3'
              label 'linux'
              alwaysPull true
              // No runtest.db cache necessary; the tests run in serial and do not load libraries!
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          steps {
            script {
              common.standardSetup()
              unstash 'omc-clang'
              common.partest(1, 1, false, '-j1 -parmodexp')
            }
          }
        }

        stage('testsuite-clang-metamodelica') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.16.3'
              label 'linux'
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          steps {
            script { common.standardSetup() }
            unstash 'omc-clang'
            sh 'make -C testsuite/metamodelica/MetaModelicaDev test-error'
          }
        }

        stage('testsuite-matlab-translator') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.16.3'
              label 'linux'
              alwaysPull true
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          steps {
            script {
              common.standardSetup()
              unstash 'omc-clang'
              common.generateTemplates()
            }
            sh 'make -C testsuite/special/MatlabTranslator/ test'
          }
        }

        stage('test-clang-icon-generator') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.16.3'
              label 'linux'
              args "--mount type=volume,source=runtest-clang-icon-generator,target=/cache/runtest " +
                   "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary " +
                   "-v /var/lib/jenkins/gitcache:/var/lib/jenkins/gitcache"
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
          steps {
            script {
              common.standardSetup()
              unstash 'omc-clang'
              common.makeLibsAndCache()
            }
            sh 'make -C testsuite/openmodelica/icon-generator test'
          }
        }

      }
    }
    stage('fmuchecker + OMEdit testsuite') {
      parallel {
        stage('linux-wine-fmuchecker') {
          agent {
            docker {
              label 'linux'
              image 'docker.openmodelica.org/fmuchecker:v2.0.4'
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
            echo "${env.NODE_NAME}"
            sh 'rm -rf testsuite/'
            unstash 'cross-fmu'
            unstash 'cross-fmu-extras'
            sh '''
            export HOME="$PWD"
            cd testsuite/special/FmuExportCrossCompile/
            ./single-fmu-run.sh linux64 `cat VERSION`
            ./single-fmu-run.sh linux32 `cat VERSION`
            ./single-fmu-run.sh win64 `cat VERSION`
            ./single-fmu-run.sh win32 `cat VERSION`
            '''
            stash name: 'cross-fmu-results-linux-wine', includes: 'testsuite/special/FmuExportCrossCompile/*.csv, testsuite/special/FmuExportCrossCompile/Test_FMUs/**'
          }
        }
        stage('osx-fmuchecker') {
          agent {
            label 'osx'
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          options {
            skipDefaultCheckout true
          }
          steps {
            echo "${env.NODE_NAME}"
            sh 'rm -rf testsuite/'
            unstash 'cross-fmu'
            unstash 'cross-fmu-extras'
            sh '''
            cd testsuite/special/FmuExportCrossCompile/
            ./single-fmu-run.sh darwin64 `cat VERSION` /usr/local/bin/fmuCheck.darwin64
            '''
            stash name: 'cross-fmu-results-osx', includes: 'testsuite/special/FmuExportCrossCompile/*.csv, testsuite/special/FmuExportCrossCompile/Test_FMUs/**'
          }
        }
        stage('arm-fmuchecker') {
          agent {
            docker {
              label 'linux-arm32'
              image 'docker.openmodelica.org/fmuchecker:v2.0.4-arm'
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
            echo "${env.NODE_NAME}"
            sh 'rm -rf testsuite/'
            unstash 'cross-fmu'
            unstash 'cross-fmu-extras'
            sh '''
            cd testsuite/special/FmuExportCrossCompile/
            ./single-fmu-run.sh arm-linux-gnueabihf `cat VERSION` /usr/local/bin/fmuCheck.arm-linux-gnueabihf
            '''
            stash name: 'cross-fmu-results-armhf', includes: 'testsuite/special/FmuExportCrossCompile/*.csv, testsuite/special/FmuExportCrossCompile/Test_FMUs/**'
          }
        }
        stage('clang-qt5') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.16.3'
              label 'linux'
              alwaysPull true
            }
          }
          steps {
            script { common.buildAndRunOMEditTestsuite('omedit-testsuite-clang') }
          }
        }
      }
    }
    stage('check-and-upload') {
      parallel {
        stage('fmuchecker-results') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.16.3'
              label 'linux'
              alwaysPull true
            }
          }
          when {
            beforeAgent true
            expression { shouldWeRunTests }
          }
          options {
            skipDefaultCheckout true // This seems to cause problems for symbolic links
          }
          steps {
            echo "${env.NODE_NAME}"
            sh 'rm -rf build/ testsuite/'
            unstash 'omc-clang'
            unstash 'cross-fmu-extras'
            unstash 'cross-fmu-results-linux-wine'
            unstash 'cross-fmu-results-osx'
            unstash 'cross-fmu-results-armhf'
            sh 'cd testsuite/special/FmuExportCrossCompile && ../../../build/bin/omc check-files.mos'
            sh 'cd testsuite/special/FmuExportCrossCompile && tar -czf ../../../Test_FMUs.tar.gz Test_FMUs'
            archiveArtifacts 'Test_FMUs.tar.gz'
          }
        }
        stage('upload-compliance') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.16.3'
              label 'linux'
              alwaysPull true
            }
          }
          when {
            beforeAgent true
            expression { !isPR }
          }
          steps {
            unstash 'compliance'
            unstash 'compliance-newinst'
            echo "${env.NODE_NAME}"
            sshPublisher(publishers: [sshPublisherDesc(configName: 'ModelicaComplianceReports', transfers: [sshTransfer(sourceFiles: 'compliance-*html')])])
          }
        }
        stage('upload-doc') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.16.3'
              label 'linux'
              alwaysPull true
            }
          }
          when {
            beforeAgent true
            expression { !isPR }
          }
          steps {
            unstash 'usersguide'
            echo "${env.NODE_NAME}"
            sh "tar xJf OpenModelicaUsersGuide-${common.tagName()}.html.tar.xz"
            sh "mv OpenModelicaUsersGuide ${common.tagName()}"
            sshPublisher(publishers: [sshPublisherDesc(configName: 'OpenModelicaUsersGuide', transfers: [sshTransfer(sourceFiles: "OpenModelicaUsersGuide-${common.tagName()}*,${common.tagName()}/**")])])
          }
        }
      }
    }
    stage('push-to-master') {
      agent {
        label 'linux'
      }
      when {
        beforeAgent true
        branch 'omlib-staging'
        expression { return currentBuild.currentResult == 'SUCCESS' }
      }
      steps {
        githubNotify status: 'SUCCESS', description: 'The staged library changes are working', context: 'continuous-integration/jenkins/pr-merge'
        githubNotify status: 'SUCCESS', description: 'Skipping CLA checks on omlib-staging', context: 'license/CLA'
        sshagent (credentials: ['Hudson-SSH-Key']) {
          sh 'ssh-keyscan github.com >> ~/.ssh/known_hosts'
          sh 'git push git@github.com:OpenModelica/OpenModelica.git omlib-staging:master || (echo "Trying to update the repository if that is the problem" ; git pull --rebase && git push --force  git@github.com:OpenModelica/OpenModelica.git omlib-staging:omlib-staging & false)'
        }
      }
    }
  }
  post {
    failure {
      script {
        if (common.cacheBranch()=="master") {
          emailext subject: '$DEFAULT_SUBJECT',
          body: '$DEFAULT_CONTENT',
          replyTo: '$DEFAULT_REPLYTO',
          to: '$DEFAULT_TO'
        }
      }
    }
  }
}

/* Note: If getting "Unexpected end of /proc/mounts line" , flatten the docker image:
 * https://stackoverflow.com/questions/46138549/docker-openmpi-and-unexpected-end-of-proc-mounts-line
 * Or use a newer OS image with fixed hwloc, or disable hwloc in the configure script
 */
