
def isWindows
{
  return !isUnix()
}

void standardSetup() {
  echo "${env.NODE_NAME}"
  // Jenkins cleans with -fdx; --ffdx is needed to remove git repositories
  sh "git clean -ffdx -e OMSetup && git submodule foreach --recursive git clean -ffdx"
}

def numPhysicalCPU() {
  return 8
}

def numLogicalCPU() {
  return 8
}

void partest(cache=true, extraArgs='') {
  sh ("""
     set OMDEV=C:\OMDev
	 echo on
	 (
     echo cd ${WORKSPACE}/OM/testsuite/partest
     echo time perl ./runtests.pl -j8 -nocolour -with-xml
     echo CODE=$?
     echo if test "$CODE" = 0 -o "$CODE" = 7; then
     echo   cp -f ../runtest.db.* "${env.RUNTESTDB}/"
     echo fi
     echo if test "$CODE" = 0 -o "$CODE" = 7; then
     echo   exit 0
     echo else
     echo   exit $CODE
     echo fi
     ) > runTestWindows.sh

     set MSYSTEM=MINGW64
     %OMDEV%\tools\msys\usr\bin\sh --login -i -c "cd ${WORKSPACE} && chmod +x runTestWindows.sh && ./runTestWindows.sh && rm -f ./runTestWindows.sh"
  """)
  junit 'testsuite/partest/result.xml'
}

void patchConfigStatus() {
  // does nothing on Windows
}

void makeLibsAndCache(libs='core') {
  // does nothing on Windows
}

void buildOMC(CC, CXX, extraFlags) {
  standardSetup()
  sh ("""
     set OMDEV=C:\OMDev
     echo on
	 (
     echo cd ${WORKSPACE}/OM
     echo export MAKETHREADS=-j16
     echo set -e
     echo time make -f Makefile.omdev.mingw ${MAKETHREADS} omc omc-diff omlibrary-core
     echo set +e
     echo cd ${WORKSPACE}/OM
     echo sed -i.bak 's/mingw32-make/..\\..\\usr\\bin\\make/g' build/share/omc/scripts/Compile.bat
     echo cd ${WORKSPACE}/OM
     echo make -f Makefile.omdev.mingw ${MAKETHREADS} BUILDTYPE=Release simulationruntimecmsvc BuildType=Release
     echo cd ${WORKSPACE}/OM
     echo make -f 'Makefile.omdev.mingw' ${MAKETHREADS} BUILDTYPE=Release runtimeCPPmsvcinstall
     echo cd ${WORKSPACE}/OM
     echo make -f 'Makefile.omdev.mingw' ${MAKETHREADS} BUILDTYPE=Release runtimeCPPinstall
     ) > buildOMCWindows.sh

     set MSYSTEM=MINGW64
     %OMDEV%\tools\msys\usr\bin\sh --login -i -c "cd ${WORKSPACE} && chmod +x buildOMCWindows.sh && ./buildOMCWindows.sh && rm -f ./buildOMCWindows.sh"
  """)
}

void buildGUI(stash) {
  standardSetup()
  if (stash) {
    unstash stash
  }

  sh ("""
     set OMDEV=C:\OMDev
     echo on
	 (
     echo cd ${WORKSPACE}/OM
     echo export MAKETHREADS=-j16
     echo set -e
     echo time make -f Makefile.omdev.mingw ${MAKETHREADS} qtclients
     ) > buildGUIWindows.sh

     set MSYSTEM=MINGW64
     %OMDEV%\tools\msys\usr\bin\sh --login -i -c "cd ${WORKSPACE} && chmod +x buildGUIWindows.sh && ./buildGUIWindows.sh && rm -f ./buildGUIWindows.sh"
  """)
}

void generateTemplates() {
  // nothing to do on Windows
}

def getVersion() {
  return (sh (script: 'build/bin/omc --version | grep -o "v[0-9]\\+[.][0-9]\\+[.][0-9]\\+[^ ]*"', returnStdout: true)).replaceAll("\\s","")
}

void compliance() {
  // does nothing on windows
}

def cacheBranch() {
  return "${env.CHANGE_TARGET ?: env.GIT_BRANCH}"
}

def tagName() {
  def name = env.TAG_NAME ?: cacheBranch()
  return name == "master" ? "latest" : name
}

return this
