def common
pipeline {
  agent none
  options {
    newContainerPerStage()
    buildDiscarder(logRotator(numToKeepStr: "100", artifactNumToKeepStr: "2"))
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
        }
      }
    }
    stage('cpp-test') {
      agent {
        label 'linux'
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
          common.insideTestImage('docker.openmodelica.org/build-deps:ubuntu-22.04',
                                 "--mount type=volume,source=runtest-cpp-test-cache,target=/cache/runtest " +
                                 "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary") {
            common.buildOMC_CMake([
              "-DCMAKE_BUILD_TYPE=Release",
              "-DOM_USE_CCACHE=OFF",
              "-DCMAKE_INSTALL_PREFIX=build",
              "-DCMAKE_C_COMPILER=clang",
              "-DCMAKE_CXX_COMPILER=clang++",
              "-DOM_ENABLE_GUI_CLIENTS=OFF",
              "-DOM_OMC_ENABLE_CPP_RUNTIME=ON"])
            common.makeLibsAndCache()
            common.partest(1, 1, true, '-cppruntime')
          }
        }
      }
    }
  }
}
