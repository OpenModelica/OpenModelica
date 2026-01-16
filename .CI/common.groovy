
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
      set PATH=%PATH%;${installDir}\\build\\bin;${installDir}\\build\\lib\\omc\\omsicpp;${installDir}\\build\\lib\\omc\\cpp
      %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -c "cd `cygpath '${WORKSPACE}'` && bash testsuite/sanity-check/runSanity.sh --omc=${installDir}/bin/omc"
    """)
    bat (label: 'Sanity check - Cpp', script: """
      set MSYSTEM=UCRT64
      set MSYS2_PATH_TYPE=inherit
      set PATH=%PATH%;${installDir}\\build\\bin;${installDir}\\build\\lib\\omc\\omsicpp;${installDir}\\build\\lib\\omc\\cpp
      %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -c "cd `cygpath '${WORKSPACE}'` && bash testsuite/sanity-check/runSanity.sh --omc=${installDir}/bin/omc --simCodeTarget=Cpp"
    """)
    bat (label: 'Sanity check - Install dir with spaces', script: """
      set MSYSTEM=UCRT64
      set MSYS2_PATH_TYPE=inherit
      set PATH=%PATH%;${installDir}\\build\\bin;${installDir}\\build\\lib\\omc\\omsicpp;${installDir}\\build\\lib\\omc\\cpp
      move "${installDir}" "${installDir} but with spaces"
      %OMDEV%\\tools\\msys\\usr\\bin\\sh --login -c "cd `cygpath '${WORKSPACE}'` && bash testsuite/sanity-check/runSanity.sh --omc='${installDir} but with spaces/bin/omc'" || (move "${installDir} but with spaces" "${installDir}" && exit 1)
      move "${installDir} but with spaces/" "${installDir}"
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
      ) > miniTestsuite.sh

      set MSYSTEM=UCRT64
      set MSYS2_PATH_TYPE=inherit
      set PATH=%PATH%;${installDir}\\build\\bin;${installDir}\\build\\lib\\omc\\omsicpp;${installDir}\\build\\lib\\omc\\cpp
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
    bat (label: 'build', script """
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

def getQtMajorVersion(qtVersion) {
  def OM_QT_MAJOR_VERSION = 'OM_QT_MAJOR_VERSION=5'
  if (qtVersion.equals('qt6')) {
    OM_QT_MAJOR_VERSION = 'OM_QT_MAJOR_VERSION=6'
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
