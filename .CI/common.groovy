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
  def cmd = "make -j${numLogicalCPU()} --output-sync omlibrary-${libs} ReferenceFiles omc-diff"
  if (env.SHARED_LOCK) {
    lock(env.SHARED_LOCK) {
      sh cmd
    }
  } else {
    sh cmd
  }
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
  if (stash) {
    unstash stash
  }
  sh 'autoconf'
  patchConfigStatus()
  sh 'CONFIG=`./config.status --config` && ./configure `eval $CONFIG`'
  sh 'touch omc.skip omc-diff.skip ReferenceFiles.skip omsimulator.skip && make -q omc omc-diff ReferenceFiles omsimulator' // Pretend we already built omc since we already did so
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

return this
