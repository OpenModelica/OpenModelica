
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

     set MSYSTEM=MINGW64
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
  ./runtests.pl -j${numPhysicalCPU()} -nocolour -with-xml ${extraArgs}
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

void makeLibsAndCache(libs='core') {
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
  rm testsuite/libraries-for-testing/.openmodelica/cache || rm -rf testsuite/libraries-for-testing/.openmodelica/cache
  mkdir -p testsuite/libraries-for-testing/.openmodelica/
  test ! -e testsuite/libraries-for-testing/.openmodelica/cache
  ln -s '${env.LIBRARIES}/om-pkg-cache' testsuite/libraries-for-testing/.openmodelica/cache
  ls -lh testsuite/libraries-for-testing/.openmodelica/cache/
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

void buildOMC(CC, CXX, extraFlags, Boolean buildCpp, Boolean clean) {
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
     echo set -ex
     echo export OPENMODELICAHOME="\${MSYS_WORKSPACE}/build"
     echo export OPENMODELICALIBRARY="\${MSYS_WORKSPACE}/build/lib/omlibrary"
     echo time make -f Makefile.omdev.mingw \${MAKETHREADS} omc testsuite-depends
     echo cd \${MSYS_WORKSPACE}
     echo make -f Makefile.omdev.mingw \${MAKETHREADS} BUILDTYPE=Release all-runtimes
     echo echo Check that omc can be started and a model can be build for NF OF with runtimes C Cpp FMU
     echo echo Unset OPENMODELICALIBRARY to make sure the default is used
     echo unset OPENMODELICALIBRARY
     echo echo Attempt to build things using \$OPENMODELICAHOME
     echo ./build/bin/omc --version
     echo mkdir .sanity-check
     echo cd .sanity-check
     echo cp ../testsuite/sanity-check/testSanity.mos .
     echo ../build/bin/omc --linearizationDumpLanguage=matlab testSanity.mos
     echo export PATH=\$PATH:../build/bin/:../build/lib/omc/omsicpp:../build/lib/omc/cpp
     echo ./M
     echo ./M -l=1.0
     echo ls linearized_model.m
     echo ls M.fmu
     echo rm -rf ./M* ./OMCppM* ./linear_M* ./linearized_model.m
     echo ../build/bin/omc --simCodeTarget=Cpp testSanity.mos
     echo ./M
     echo ls M.fmu
     echo rm -rf ./M* ./OMCppM*
     echo cd ..
     echo rm -rf .sanity-check
     echo echo Testing some models from testsuite, ffi, meta
     echo cd testsuite/flattening/libraries/biochem
     echo ../../../rtest --return-with-error-code EnzMM.mos
     echo cd \${MSYS_WORKSPACE}
     echo cd testsuite/flattening/modelica/ffi
     echo ../../../rtest --return-with-error-code ModelicaInternal_countLines.mos
     echo ../../../rtest --return-with-error-code Integer1.mos
     echo cd \${MSYS_WORKSPACE}
     echo cd testsuite/metamodelica/meta
     echo ../../rtest --return-with-error-code AlgPatternm.mos
     echo echo Testing if we can compile in a path with spaces
     echo cd \${MSYS_WORKSPACE}
     echo mkdir -p ./path\\ with\\ space/
     echo mv build ./path\\ with\\ space/
     echo export OPENMODELICAHOME="\${MSYS_WORKSPACE}/path with space/build"
     echo echo Attempt to build things using \$OPENMODELICAHOME
     echo ./path\\ with\\ space/build/bin/omc --version
     echo cd ./path\\ with\\ space/
     echo mkdir .sanity-check
     echo cd .sanity-check
     echo cp ../../testsuite/sanity-check/testSanity.mos .
     echo ../build/bin/omc --linearizationDumpLanguage=matlab testSanity.mos
     echo export PATH=\$PATH:../build/bin/:../build/lib/omc/omsicpp:../build/lib/omc/cpp
     echo ./M
     echo ./M -l=1.0
     echo ls linearized_model.m
     echo ls M.fmu
     echo rm -rf ./M* ./OMCppM* ./linear_M* ./linearized_model.m
     echo ../build/bin/omc --simCodeTarget=Cpp testSanity.mos
     echo ./M
     echo ls M.fmu
     echo rm -rf ./M* ./OMCppM*
     echo cd ..
     echo rm -rf .sanity-check
     echo mv build/ ../.
     echo cd ../../
     echo rm -rf ./path\\ with\\ space/
     ) > buildOMCWindows.sh

     set MSYSTEM=MINGW64
     set MSYS2_PATH_TYPE=inherit
     %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "cd `cygpath '${WORKSPACE}'` && chmod +x buildOMCWindows.sh && ./buildOMCWindows.sh && rm -f ./buildOMCWindows.sh"
  """)
  } else {
  sh 'autoconf'
  // Note: Do not use -march=native since we might use an incompatible machine in later stages
  def withCppRuntime = buildCpp ? "--with-cppruntime":"--without-cppruntime"
  sh "./configure CC='${CC}' CXX='${CXX}' FC=gfortran CFLAGS=-Os ${withCppRuntime} --without-omc --without-omlibrary --with-omniORB --enable-modelica3d --prefix=`pwd`/install ${extraFlags}"
  // OMSimulator requires HOME to be set and writeable
  if (clean) {
    sh label: 'clean', script: "HOME='${env.WORKSPACE}' ${makeCommand()} -j${numPhysicalCPU()} ${outputSync()} clean"
  }
  sh label: 'build', script: "HOME='${env.WORKSPACE}' ${makeCommand()} -j${numPhysicalCPU()} ${outputSync()} omc omc-diff omsimulator"
  sh 'find build/lib/*/omc/ -name "*.so" -exec strip {} ";"'
  // Run sanity tests
  sh '''
  mv build build.sanity-check
  mkdir .sanity-check
  cd .sanity-check
  cp ../testsuite/sanity-check/testSanity.mos .
  cat testSanity.mos
  ../build.sanity-check/bin/omc --linearizationDumpLanguage=matlab testSanity.mos
  ./M
  ./M -l=1.0
  ls linearized_model.m
  ls M.fmu
  rm -rf ./M* ./OMCppM* ./linear_M* ./linearized_model.m
  '''
  if (buildCpp) {
    sh '''
    cd .sanity-check
    # do not do this on Mac as it doesn't work yet
    # test `uname` = Darwin || ../build.sanity-check/bin/omc --simCodeTarget=Cpp testSanity.mos
    # test `uname` = Darwin || ./M
    # test `uname` = Darwin || ls M.fmu
    # test `uname` = Darwin || rm -rf ./M* ./OMCppM*
    cd ..
    mv build.sanity-check build
    rm -rf .sanity-check
    '''
  }
  sh "cd OMCompiler/Compiler/boot && ./find-unused-import.sh ../*/*.mo"
  }
}

void buildOMSens() {
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
     echo time make -f Makefile.omdev.mingw \${MAKETHREADS} omsens
     ) > buildOMSensWindows.sh

     set MSYSTEM=MINGW64
     set MSYS2_PATH_TYPE=inherit
     %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "cd `cygpath '${WORKSPACE}'` && chmod +x buildOMSensWindows.sh && ./buildOMSensWindows.sh && rm -f ./buildOMSensWindows.sh"
  """)
  }
}

void buildOMC_CMake(cmake_args, cmake_exe='cmake') {
  standardSetup()

  if (isWindows()) {
  bat ("""
     set OMDEV=C:\\OMDev
     echo on
     (
     echo export MSYS_WORKSPACE="`cygpath '${WORKSPACE}'`"
     echo echo MSYS_WORKSPACE: \${MSYS_WORKSPACE}
     echo cd \${MSYS_WORKSPACE}
     echo export MAKETHREADS=16
     echo set -ex
     echo mkdir OMCompiler/build_cmake
     echo cmake -S OMCompiler -B OMCompiler/build_cmake ${cmake_args}
     echo time cmake --build OMCompiler/build_cmake --parallel \${MAKETHREADS} --target install
     echo OMCompiler/build_cmake/install_cmake/bin/omc --help
     echo OMCompiler/build_cmake/install_cmake/bin/omc --version
     ) > buildOMCWindows.sh

     set MSYSTEM=MINGW64
     set MSYS2_PATH_TYPE=inherit
     %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -i -c "cd `cygpath '${WORKSPACE}'` && chmod +x buildOMCWindows.sh && ./buildOMCWindows.sh && rm -f ./buildOMCWindows.sh"
  """)
  }
  else {
    sh "mkdir OMCompiler/build_cmake"
    sh "${cmake_exe} -S OMCompiler -B OMCompiler/build_cmake ${cmake_args}"
    sh "${cmake_exe} --build OMCompiler/build_cmake --parallel ${numPhysicalCPU()} --target install"
    sh "OMCompiler/build_cmake/install_cmake/bin/omc --help"
    sh "OMCompiler/build_cmake/install_cmake/bin/omc --version"
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
  sh 'echo ./configure `./config.status --config` > config.status.2 && bash ./config.status.2'
  // compile OMSens_Qt for Qt5
  if (isQt5) {
    sh "touch omc.skip omc-diff.skip ReferenceFiles.skip omsimulator.skip && ${makeCommand()} -q -j${numPhysicalCPU()} omc omc-diff ReferenceFiles omsimulator" // Pretend we already built omc since we already did so
  } else {
    sh "touch omc.skip omc-diff.skip ReferenceFiles.skip omsimulator.skip omsens_qt.skip && ${makeCommand()} -j${numPhysicalCPU()} -q omc omc-diff ReferenceFiles omsimulator omsens_qt" // Pretend we already built omc since we already did so
  }
  sh "${makeCommand()} -j${numPhysicalCPU()} ${outputSync()}" // Builds the GUI files

  // test make install after qt builds
  sh label: 'install', script: "HOME='${env.WORKSPACE}' ${makeCommand()} -j${numPhysicalCPU()} ${outputSync()} install ${ignoreOnMac()}"
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
  sh 'echo ./configure `./config.status --config` > config.status.2 && bash ./config.status.2'
  sh "touch omc.skip omc-diff.skip ReferenceFiles.skip omsimulator.skip omedit.skip omplot.skip omparser.skip && ${makeCommand()} -q omc omc-diff ReferenceFiles omsimulator omedit omplot omparser" // Pretend we already built omc since we already did so
  sh "${makeCommand()} -j${numPhysicalCPU()} --output-sync=recurse omedit-testsuite" // Builds the OMEdit testsuite
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

def shouldWeBuildCENTOS7() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/Build CentOS")) {
      return true
    }
  }
  return params.BUILD_CENTOS7
}

def shouldWeSkipCMakeBuild() {
  if (isPR()) {
    if (pullRequest.labels.contains("CI/Skip CMake Build")) {
      return true
    }
  }
  return params.SKIP_CMAKE_BUILD
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
