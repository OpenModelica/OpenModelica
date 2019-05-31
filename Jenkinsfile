def common
pipeline {
  agent none
  options {
    newContainerPerStage()
  }
  environment {
    LC_ALL = 'C.UTF-8'
  }
  // stages are ordered according to execution time; highest time first
  // nodes are selected based on a priority (in Jenkins config)
  stages {
    stage('Environment') {
      agent {
        label 'linux'
      }
      steps {
        script {
          if (changeRequest()) {
            def buildNumber = env.BUILD_NUMBER as int
            if (buildNumber > 1) milestone(buildNumber - 1)
            milestone(buildNumber)
          }
          common = load("${env.workspace}/.CI/common.groovy")
        }
      }
    }
    stage('setup') {
      parallel {
        stage('gcc') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.13-qt4-xenial'
              label 'linux'
              alwaysPull true
            }
          }
          environment {
            QTDIR = "/usr/lib/qt4"
          }
          steps {
            // Xenial is GCC 5
            script { common.buildOMC('gcc-5', 'g++-5', '') }
            stash name: 'omc-gcc', includes: 'build/**, **/config.status'
          }
        }
        stage('clang') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.14'
              label 'linux'
              alwaysPull true
            }
          }
          steps {
            script { common.buildOMC('clang', 'clang++', '--without-hwloc') }
            stash name: 'omc-clang', includes: 'build/**, **/config.status'
          }
        }
        stage('checks') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.14'
              label 'linux'
              alwaysPull true
            }
          }
          steps {
            script { common.standardSetup() }
            // It's really bad if we mess up the repo and can no longer build properly
            sh '! git submodule foreach --recursive git diff 2>&1 | grep CRLF'
            // TODO: trailing-whitespace-error tab-error
            sh "make -f Makefile.in -j${common.numLogicalCPU()} --output-sync bom-error utf8-error thumbsdb-error spellcheck"
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
        stage('testsuite-clang') {
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
                   "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary"
            }
          }
          environment {
            RUNTESTDB = "/cache/runtest/"
            LIBRARIES = "/cache/omlibrary"
          }
          steps {
            script {
              common.standardSetup()
              unstash 'omc-clang'
              common.makeLibsAndCache()
              common.partest()
            }
          }
        }

        stage('testsuite-gcc') {
          agent {
            dockerfile {
              additionalBuildArgs '--pull'
              dir '.CI/cache-xenial'
              label 'linux'
              args "--mount type=volume,source=runtest-gcc-cache,target=/cache/runtest " +
                   "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary"
            }
          }
          environment {
            RUNTESTDB = "/cache/runtest/"
            LIBRARIES = "/cache/omlibrary"
          }
          steps {
            script {
              common.standardSetup()
              unstash 'omc-gcc'
              common.makeLibsAndCache()
              common.partest()
            }
          }
        }

        stage('testsuite-fmu-crosscompile') {
          stages {
            stage('cross-build-fmu') {
              agent {
                label 'linux'
              }
              environment {
                RUNTESTDB = "/cache/runtest/"
                LIBRARIES = "/cache/omlibrary"
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
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary"
            }
          }
          environment {
            LIBRARIES = "/cache/omlibrary"
            COMPLIANCEEXTRAREPORTFLAGS = "--expectedFailures=.CI/compliance.failures --flakyTests=.CI/compliance.flaky"
            COMPLIANCEPREFIX = "compliance"
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
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary"
            }
          }
          environment {
            LIBRARIES = "/cache/omlibrary"
            COMPLIANCEEXTRAFLAGS = "-d=newInst"
            COMPLIANCEEXTRAREPORTFLAGS = "--expectedFailures=.CI/compliance-newinst.failures"
            COMPLIANCEPREFIX = "compliance-newinst"
          }
          steps {
            script { common.compliance() }
          }
        }

        stage('build-gui-clang-qt5') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.14'
              label 'linux'
              alwaysPull true
            }
          }
          steps {
            script { common.buildGUI('omc-clang') }
          }
        }

        stage('build-gui-gcc-qt4') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.13-qt4-xenial'
              label 'linux'
              alwaysPull true
            }
          }
          environment {
            QTDIR = "/usr/lib/qt4"
          }
          steps {
            script { common.buildGUI('omc-gcc') }
          }
        }

        stage('build-usersguide') {
          agent {
            dockerfile {
              additionalBuildArgs '--pull'
              dir '.CI/cache'
              label 'linux'
              args "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary"
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
              image 'docker.openmodelica.org/build-deps:v1.14'
              label 'linux'
              alwaysPull true
              // No runtest.db cache necessary; the tests run in serial and do not load libraries!
            }
          }
          steps {
            script {
              common.standardSetup()
              unstash 'omc-clang'
              common.partest(false, '-j1 -parmodexp')
            }
          }
        }

        stage('testsuite-clang-metamodelica') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.14'
              label 'linux'
            }
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
              image 'docker.openmodelica.org/build-deps:v1.14'
              label 'linux'
              alwaysPull true
            }
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

      }
    }
    stage('fmuchecker') {
      parallel {
        stage('linux-wine-fmuchecker') {
          agent {
            docker {
              label 'linux'
              image 'docker.openmodelica.org/fmuchecker:v2.0.4'
            }
          }
          options {
            skipDefaultCheckout true
          }
          steps {
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
          options {
            skipDefaultCheckout true
          }
          steps {
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
          options {
            skipDefaultCheckout true
          }
          steps {
            unstash 'cross-fmu'
            unstash 'cross-fmu-extras'
            sh '''
            cd testsuite/special/FmuExportCrossCompile/
            ./single-fmu-run.sh arm-linux-gnueabihf `cat VERSION` /usr/local/bin/fmuCheck.arm-linux-gnueabihf
            '''
            stash name: 'cross-fmu-results-armhf', includes: 'testsuite/special/FmuExportCrossCompile/*.csv, testsuite/special/FmuExportCrossCompile/Test_FMUs/**'
          }
        }
      }
    }
    stage('check-and-upload') {
      parallel {
        stage('fmuchecker-results') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.14'
              label 'linux'
              alwaysPull true
            }
          }
          options {
            skipDefaultCheckout true
          }
          steps {
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
              image 'docker.openmodelica.org/build-deps:v1.14'
              label 'linux'
              alwaysPull true
            }
          }
          when {
            not {
              changeRequest()
            }
          }
          steps {
            unstash 'compliance'
            unstash 'compliance-newinst'
            sshPublisher(publishers: [sshPublisherDesc(configName: 'ModelicaComplianceReports', transfers: [sshTransfer(sourceFiles: 'compliance-*html')])])
          }
        }
        stage('upload-doc') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.14'
              label 'linux'
              alwaysPull true
            }
          }
          when {
            not {
              changeRequest()
            }
          }
          steps {
            unstash 'usersguide'
            sh "tar xJf OpenModelicaUsersGuide-${common.tagName()}.html.tar.xz"
            sh "mv OpenModelicaUsersGuide ${common.tagName()}"
            sshPublisher(publishers: [sshPublisherDesc(configName: 'OpenModelicaUsersGuide', transfers: [sshTransfer(sourceFiles: "OpenModelicaUsersGuide-${common.tagName()}*,${common.tagName()}/**")])])
          }
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
