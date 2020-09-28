
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

void partest(cache=true, extraArgs='') {
  if (isWindows()) {

  bat ("""
     set OMDEV=C:\\OMDev
     echo on
     (
     echo export MSYS_WORKSPACE="`cygpath '${WORKSPACE}'`"
     echo echo MSYS_WORKSPACE: \${MSYS_WORKSPACE}
     echo export OPENMODELICAHOME="\${MSYS_WORKSPACE}/build"
     echo export OPENMODELICALIBRARY="${MSYS_WORKSPACE}\\build\\lib\\omlibrary"
     echo cd ${MSYS_WORKSPACE}/testsuite/partest
     echo time perl ./runtests.pl -j8 -nocolour -with-xml
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

     set MSYSTEM=MINGW64
     set MSYS2_PATH_TYPE=inherit
     %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "cd `cygpath '${WORKSPACE}'` && chmod +x runTestWindows.sh && ./runTestWindows.sh && rm -f ./runTestWindows.sh"
  """)

  } else {
  sh "rm -f omc-diff.skip && ${makeCommand()} -C testsuite/difftool clean && ${makeCommand()} --output-sync -C testsuite/difftool"
  sh 'build/bin/omc-diff -v1.4'

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

  }

  junit 'testsuite/partest/result.xml'
}

void patchConfigStatus() {
  if (isUnix())
  {
    // Running on nodes with different paths for the workspace
    sh 'sed -i.bak "s,--with-ombuilddir=[A-Za-z0-9./_-]*,--with-ombuilddir=`pwd`/build," config.status OMCompiler/config.status'
  }
}

void makeLibsAndCache(libs='core') {
  if (isWindows())
  {
    // do nothing
  } else {
  // If we don't have any result, copy to the master to get a somewhat decent cache
  sh "cp -f ${env.RUNTESTDB}/${cacheBranchEscape()}/runtest.db.* testsuite/ || " +
     "cp -f ${env.RUNTESTDB}/master/runtest.db.* testsuite/ || true"
  // env.WORKSPACE is null in the docker agent, so link the svn/git cache afterwards
  sh "mkdir -p '${env.LIBRARIES}/om-pkg-cache'"
  sh "mkdir -p testsuite/libraries-for-testing/.openmodelica/"
  sh "ln -s '${env.LIBRARIES}/om-pkg-cache' testsuite/libraries-for-testing/.openmodelica/"
  generateTemplates()
  sh "touch omc.skip"
  def cmd = "${makeCommand()} -j${numLogicalCPU()} --output-sync libs-for-testing ReferenceFiles omc-diff"
  if (env.SHARED_LOCK) {
    lock(env.SHARED_LOCK) {
      sh cmd
    }
  } else {
    sh cmd
  }
  }
}

void buildOMC(CC, CXX, extraFlags) {
  standardSetup()

  if (isWindows()) {
  bat ("""
     set OMDEV=C:\\OMDev
     echo on
     (
     echo export MSYS_WORKSPACE="`cygpath '${WORKSPACE}'`"
     echo echo MSYS_WORKSPACE: \${MSYS_WORKSPACE}
     echo cd \${MSYS_WORKSPACE}
     echo export MAKETHREADS=-j16
     echo set -e
     echo export OPENMODELICAHOME="\${MSYS_WORKSPACE}/build"
     echo export OPENMODELICALIBRARY="\${MSYS_WORKSPACE}/build/lib/omlibrary"
     echo time make -f Makefile.omdev.mingw \${MAKETHREADS} omc testsuite-depends
     echo cd \${MSYS_WORKSPACE}
     echo make -f Makefile.omdev.mingw \${MAKETHREADS} BUILDTYPE=Release all-runtimes
     echo echo Check that omc can be started and a model can be build for NF OF with runtimes C Cpp FMU
     echo ./build/bin/omc --version
     echo mkdir .sanity-check
     echo cd .sanity-check
     echo cp ../testsuite/sanity-check/testSanity.mos .
     echo ../build/bin/omc --linearizationDumpLanguage=matlab testSanity.mos
     echo export PATH=\$PATH:../build/bin/:../build/lib/omc/omsicpp:../build/lib/omc/cpp
     echo ./M
     echo ./M -l=1.0
     echo ls linear_M.m
     echo ls M.fmu
     echo rm -rf M* OMCppM* linear_M*
     echo ../build/bin/omc --simCodeTarget=Cpp testSanity.mos
     echo ./M
     echo ls M.fmu
     echo rm -rf M* OMCppM*
     echo cd ..
     echo rm -rf .sanity-check
     ) > buildOMCWindows.sh

     set MSYSTEM=MINGW64
     set MSYS2_PATH_TYPE=inherit
     %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "cd `cygpath '${WORKSPACE}'` && chmod +x buildOMCWindows.sh && ./buildOMCWindows.sh && rm -f ./buildOMCWindows.sh"
  """)
  } else {
  sh 'autoconf'
  // Note: Do not use -march=native since we might use an incompatible machine in later stages
  sh "./configure CC='${CC}' CXX='${CXX}' FC=gfortran CFLAGS=-Os --with-cppruntime --without-omc --without-omlibrary --with-omniORB --enable-modelica3d ${extraFlags}"
  // OMSimulator requires HOME to be set and writeable
  sh "HOME='${env.WORKSPACE}' ${makeCommand()} -j${numPhysicalCPU()} --output-sync omc omc-diff omsimulator"
  sh 'find build/lib/*/omc/ -name "*.so" -exec strip {} ";"'
  sh '''
  mv build build.sanity-check
  mkdir .sanity-check
  cd .sanity-check
  echo 'loadString("model M end M;");getErrorString();buildModel(M);getErrorString();' > test.mos
  cat test.mos
  ../build.sanity-check/bin/omc test.mos
  ./M
  cd ..
  mv build.sanity-check build
  rm -rf .sanity-check
  '''
  sh "cd OMCompiler/Compiler/boot && ./find-unused-import.sh ../*/*.mo"
  }
}

void buildGUI(stash, isQt5) {
  if (isWindows()) {
  bat ("""
     set OMDEV=C:\\OMDev
     echo on
     (
     echo export MSYS_WORKSPACE="`cygpath '${WORKSPACE}'`"
     echo echo MSYS_WORKSPACE: \${MSYS_WORKSPACE}
     echo cd \${MSYS_WORKSPACE}
     echo export MAKETHREADS=-j16
     echo set -e
     echo export OPENMODELICAHOME="\${MSYS_WORKSPACE}/build"
     echo export OPENMODELICALIBRARY="\${MSYS_WORKSPACE}/build/lib/omlibrary"
     echo time make -f Makefile.omdev.mingw \${MAKETHREADS} qtclients
     echo echo Check that at least OMEdit can be started
     echo ./build/bin/OMEdit --help
     ) > buildGUIWindows.sh

     set MSYSTEM=MINGW64
     set MSYS2_PATH_TYPE=inherit
     %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "cd `cygpath '${WORKSPACE}'` && chmod +x buildGUIWindows.sh && ./buildGUIWindows.sh && rm -f ./buildGUIWindows.sh"
  """)
  } else {

  if (stash) {
    standardSetup()
    unstash stash
  }
  sh 'autoconf'
  if (stash) {
    patchConfigStatus()
  }
  sh 'CONFIG=`./config.status --config` && ./configure `eval $CONFIG`'
  // compile OMSens_Qt for Qt5
  if (isQt5) {
    sh "touch omc.skip omc-diff.skip ReferenceFiles.skip omsimulator.skip && ${makeCommand()} -q omc omc-diff ReferenceFiles omsimulator" // Pretend we already built omc since we already did so
  } else {
    sh "touch omc.skip omc-diff.skip ReferenceFiles.skip omsimulator.skip omsens_qt.skip && ${makeCommand()} -q omc omc-diff ReferenceFiles omsimulator omsens_qt" // Pretend we already built omc since we already did so
  }
  sh "${makeCommand()} -j${numPhysicalCPU()} --output-sync" // Builds the GUI files

  }
}

void buildAndRunOMEditTestsuite(stash) {
  if (isWindows()) {
  bat ("""
     set OMDEV=C:\\OMDev
     echo on
     (
     echo export MSYS_WORKSPACE="`cygpath '${WORKSPACE}'`"
     echo echo MSYS_WORKSPACE: \${MSYS_WORKSPACE}
     echo cd \${MSYS_WORKSPACE}
     echo export MAKETHREADS=-j16
     echo set -e
     echo export OPENMODELICAHOME="\${MSYS_WORKSPACE}/build"
     echo export OPENMODELICALIBRARY="\${MSYS_WORKSPACE}/build/lib/omlibrary"
     echo time make -f Makefile.omdev.mingw \${MAKETHREADS} omedit-testsuite
     echo export "APPDATA=\${PWD}/testsuite/libraries-for-testing"
     echo cd build/bin
     echo ./RunOMEditTestsuite.sh
     ) > buildOMEditTestsuiteWindows.sh

     set MSYSTEM=MINGW64
     set MSYS2_PATH_TYPE=inherit
     %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "cd `cygpath '${WORKSPACE}'` && chmod +x buildOMEditTestsuiteWindows.sh && ./buildOMEditTestsuiteWindows.sh && rm -f ./buildOMEditTestsuiteWindows.sh"
  """)
  } else {

  if (stash) {
    standardSetup()
    unstash stash
  }
  sh 'autoconf'
  if (stash) {
    patchConfigStatus()
  }
  sh 'CONFIG=`./config.status --config` && ./configure `eval $CONFIG`'
  sh "touch omc.skip omc-diff.skip ReferenceFiles.skip omsimulator.skip omedit.skip omplot.skip && ${makeCommand()} -q omc omc-diff ReferenceFiles omsimulator omedit omplot" // Pretend we already built omc since we already did so
  sh "${makeCommand()} -j${numPhysicalCPU()} --output-sync omedit-testsuite" // Builds the OMEdit testsuite
  sh label: 'RunOMEditTestsuite', script: '''
  HOME="\$PWD/testsuite/libraries-for-testing"
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

def getVersion() {
  if (isWindows()) {
  return (bat (script: 'set OMDEV=C:\\OMDev && set MSYSTEM=MINGW64 && set MSYS2_PATH_TYPE=inherit && %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "build/bin/omc --version | grep -o \"v[0-9]\\+[.][0-9]\\+[.][0-9]\\+[^ ]*\""', returnStdout: true)).replaceAll("\\s","")
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
  makeLibsAndCache('all')
  sh 'HOME=$PWD/testsuite/libraries-for-testing/ build/bin/omc -g=MetaModelica build/share/doc/omc/testmodels/ComplianceSuite.mos'
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

def shouldWeBuildOSX() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/Build OSX")) {
      return true
    }
  }
  return params.BUILD_OSX
}

def shouldWeBuildMINGW() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/Build MINGW")) {
      return true
    }
  }
  return params.BUILD_MINGW
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

return this
