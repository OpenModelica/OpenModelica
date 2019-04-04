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
            buildOMC('gcc', 'g++', '')
            stash name: 'omc-gcc', includes: 'build/**, **/config.status'
          }
        }
        stage('clang') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.13'
              label 'linux'
              alwaysPull true
            }
          }
          steps {
            buildOMC('clang', 'clang++', '--without-hwloc')
            stash name: 'omc-clang', includes: 'build/**, **/config.status'
          }
        }
        stage('checks') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.13'
              label 'linux'
              alwaysPull true
            }
          }
          steps {
            standardSetup()
            // It's really bad if we mess up the repo and can no longer build properly
            sh '! git submodule foreach --recursive git diff 2>&1 | grep CRLF'
            // TODO: trailing-whitespace-error tab-error
            sh "make -f Makefile.in -j${numLogicalCPU()} --output-sync bom-error utf8-error thumbsdb-error spellcheck"
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
            standardSetup()
            unstash 'omc-clang'
            makeLibsAndCache()
            partest()
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
            standardSetup()
            unstash 'omc-gcc'
            makeLibsAndCache()
            partest()
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
                    standardSetup()
                    unstash 'omc-clang'
                    makeLibsAndCache()
                    writeFile file: 'testsuite/special/FmuExportCrossCompile/VERSION', text: getVersion()
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
            COMPLIANCEEXTRAREPORTFLAGS = "--expectedFailures=.CI/compliance.failures"
            COMPLIANCEPREFIX = "compliance"
          }
          steps {
            compliance()
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
            compliance()
          }
        }

        stage('build-gui-clang-qt5') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.13'
              label 'linux'
              alwaysPull true
            }
          }
          steps {
            buildGUI('omc-clang')
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
            buildGUI('omc-gcc')
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
            standardSetup()
            unstash 'omc-clang'
            makeLibsAndCache()
            sh '''
            export OPENMODELICAHOME=$PWD/build
            for target in html pdf epub; do
              if ! make -C doc/UsersGuide $target; then
                killall omc || true
                exit 1
              fi
            done
            '''
            sh "tar --transform 's/^html/OpenModelicaUsersGuide/' -cJf OpenModelicaUsersGuide-${tagName()}.html.tar.xz -C doc/UsersGuide/build html"
            sh "mv doc/UsersGuide/build/latex/OpenModelicaUsersGuide.pdf OpenModelicaUsersGuide-${tagName()}.pdf"
            sh "mv doc/UsersGuide/build/epub/OpenModelicaUsersGuide.epub OpenModelicaUsersGuide-${tagName()}.epub"
            archiveArtifacts "OpenModelicaUsersGuide-${tagName()}*.*"
            stash name: 'usersguide', includes: "OpenModelicaUsersGuide-${tagName()}*.*"
          }
        }

        stage('testsuite-clang-parmod') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.13'
              label 'linux'
              alwaysPull true
              // No runtest.db cache necessary; the tests run in serial and do not load libraries!
            }
          }
          steps {
            standardSetup()
            unstash 'omc-clang'
            partest(false, '-j1 -parmodexp')
          }
        }

        stage('testsuite-clang-metamodelica') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.13'
              label 'linux'
            }
          }
          steps {
            standardSetup()
            unstash 'omc-clang'
            sh 'make -C testsuite/metamodelica/MetaModelicaDev test-error'
          }
        }

        stage('testsuite-matlab-translator') {
          agent {
            docker {
              image 'docker.openmodelica.org/build-deps:v1.13'
              label 'linux'
              alwaysPull true
            }
          }
          steps {
            standardSetup()
            unstash 'omc-clang'
            generateTemplates()
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
              image 'docker.openmodelica.org/build-deps:v1.13'
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
              image 'docker.openmodelica.org/build-deps:v1.13'
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
              image 'docker.openmodelica.org/build-deps:v1.13'
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
            sh 'tar xJf OpenModelicaUsersGuide-${tagName()}.tar.xz'
            sh 'mv OpenModelicaUsersGuide ${tagName()}'
            sshPublisher(publishers: [sshPublisherDesc(configName: 'OpenModelicaUsersGuide', transfers: [sshTransfer(sourceFiles: 'OpenModelicaUsersGuide-${tagName()},${tagName()}')])])
          }
        }
      }
    }
  }
  post {
    failure {
      script {
        if (cacheBranch()=="master") {
          emailext subject: '$DEFAULT_SUBJECT',
          body: '$DEFAULT_CONTENT',
          replyTo: '$DEFAULT_REPLYTO',
          to: '$DEFAULT_TO'
        }
      }
    }
  }
}

void standardSetup() {
  echo "${env.NODE_NAME}"
  // Jenkins cleans with -fdx; --ffdx is needed to remove git repositories
  sh "git clean -ffdx && git submodule foreach --recursive git clean -ffdx"
}

def numPhysicalCPU() {
  def uname = sh script: 'uname', returnStdout: true
  if (uname.startsWith("Darwin")) {
    return sh (
      script: 'sysctl hw.physicalcpu_max | cut -d" " -f2',
      returnStdout: true
    ).trim().toInteger() ?: 1
  } else {
    return sh (
      script: 'lscpu -p | egrep -v "^#" | sort -u -t, -k 2,4 | wc -l',
      returnStdout: true
    ).trim().toInteger() ?: 1
  }
}

def numLogicalCPU() {
  def uname = sh script: 'uname', returnStdout: true
  if (uname.startsWith("Darwin")) {
    return sh (
      script: 'sysctl hw.logicalcpu_max | cut -d" " -f2',
      returnStdout: true
    ).trim().toInteger() ?: 1
  } else {
    return sh (
      script: 'lscpu -p | egrep -v "^#" | wc -l',
      returnStdout: true
    ).trim().toInteger() ?: 1
  }
}

void partest(cache=true, extraArgs='') {
  sh ("""#!/bin/bash -x
  ulimit -t 1500
  ulimit -v 6291456 # Max 6GB per process

  cd testsuite/partest
  ./runtests.pl -j${numPhysicalCPU()} -nocolour -with-xml ${extraArgs}
  CODE=\$?
  test \$CODE = 0 -o \$CODE = 7 || exit 1
  """
  + (cache ?
  """
  if test \$CODE = 0; then
    mkdir -p "${env.RUNTESTDB}/"
    cp ../runtest.db.* "${env.RUNTESTDB}/"
  fi
  """ : ''))
  junit 'testsuite/partest/result.xml'
}

void patchConfigStatus() {
  // Running on nodes with different paths for the workspace
  sh 'sed -i "s,--with-ombuilddir=[A-Za-z0-9/_-]*,--with-ombuilddir=`pwd`/build," config.status OMCompiler/config.status'
}

void makeLibsAndCache(libs='core') {
  // If we don't have any result, copy to the master to get a somewhat decent cache
  sh "cp -f ${env.RUNTESTDB}/${cacheBranch()}/runtest.db.* testsuite/ || " +
     "cp -f ${env.RUNTESTDB}/master/runtest.db.* testsuite/ || true"
  // env.WORKSPACE is null in the docker agent, so link the svn/git cache afterwards
  sh "mkdir -p '${env.LIBRARIES}/svn' '${env.LIBRARIES}/git'"
  sh "find libraries"
  sh "ln -s '${env.LIBRARIES}/svn' '${env.LIBRARIES}/git' libraries/"
  generateTemplates()
  sh "make -j${numLogicalCPU()} --output-sync omlibrary-${libs} ReferenceFiles"
}

void buildOMC(CC, CXX, extraFlags) {
  standardSetup()
  sh 'autoconf'
  // Note: Do not use -march=native since we might use an incompatible machine in later stages
  sh "./configure CC='${CC}' CXX='${CXX}' FC=gfortran CFLAGS=-Os --with-cppruntime --without-omc --without-omlibrary --with-omniORB --enable-modelica3d ${extraFlags}"
  // OMSimulator requires HOME to be set and writeable
  sh "HOME='${env.WORKSPACE}' make -j${numPhysicalCPU()} --output-sync omc omc-diff omsimulator"
  sh 'find build/lib/*/omc/ -name "*.so" -exec strip {} ";"'
}

void buildGUI(stash) {
  standardSetup()
  unstash stash
  sh 'autoconf'
  patchConfigStatus()
  sh 'CONFIG=`./config.status --config` && ./configure `eval $CONFIG`'
  sh 'touch omc omc-diff ReferenceFiles omsimulator && make -q omc omc-diff ReferenceFiles omsimulator' // Pretend we already built omc since we already did so
  sh "make -j${numPhysicalCPU()} --output-sync" // Builds the GUI files
}

void generateTemplates() {
  patchConfigStatus()
  // Runs Susan again, for bootstrapping tests, etc
  sh 'make -C OMCompiler/Compiler/Template/ -f Makefile.in OMC=$PWD/build/bin/omc'
  sh 'cd OMCompiler && ./config.status'
  sh './config.status'
}

def getVersion() {
  return (sh (script: 'build/bin/omc --version | grep -o "v[0-9]\\+[.][0-9]\\+[.][0-9]\\+[^ ]*"', returnStdout: true)).replaceAll("\\s","")
}

void compliance() {
  standardSetup()
  unstash 'omc-clang'
  makeLibsAndCache('all')
  sh 'build/bin/omc -g=MetaModelica build/share/doc/omc/testmodels/ComplianceSuite.mos'
  sh "mv ${env.COMPLIANCEPREFIX}.html ${env.COMPLIANCEPREFIX}-current.html"
  sh "test -f ${env.COMPLIANCEPREFIX}.xml"
  // Only publish openmodelica-current.html if we are running master
  sh "cp -p ${env.COMPLIANCEPREFIX}-current.html ${env.COMPLIANCEPREFIX}${cacheBranch()=='master' ? '' : ('-' + cacheBranch()).replace('/','-')}-${getVersion()}.html"
  sh "test ! '${cacheBranch()}' = 'master' || rm -f ${env.COMPLIANCEPREFIX}-current.html"
  stash name: "${env.COMPLIANCEPREFIX}", includes: "${env.COMPLIANCEPREFIX}-*.html"
  archiveArtifacts "${env.COMPLIANCEPREFIX}*${getVersion()}.html, ${env.COMPLIANCEPREFIX}.failures"
  // get rid of freaking %
  sh "sed -i.bak 's/%/\\&#37;/g' ${env.COMPLIANCEPREFIX}.ignore.xml && sed -i.bak 's/[^[:print:]]/ /g' ${env.COMPLIANCEPREFIX}.ignore.xml"
  junit "${env.COMPLIANCEPREFIX}.ignore.xml"
}

def cacheBranch() {
  return "${env.CHANGE_TARGET ?: env.GIT_BRANCH}"
}

def tagName() {
  def name = env.TAG_NAME ?: cacheBranch()
  return name == "master" ? "latest" : name
}

/* Note: If getting "Unexpected end of /proc/mounts line" , flatten the docker image:
 * https://stackoverflow.com/questions/46138549/docker-openmpi-and-unexpected-end-of-proc-mounts-line
 */
