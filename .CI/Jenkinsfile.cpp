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
         dockerfile {
          additionalBuildArgs '--pull'
          dir '.CI/cache'
          label 'linux'
          args "--mount type=volume,source=runtest-cpp-test-cache,target=/cache/runtest " +
               "--mount type=volume,source=omlibrary-cache,target=/cache/omlibrary"
        }
      }
      environment {
        RUNTESTDB = "/cache/runtest/"
        LIBRARIES = "/cache/omlibrary"
      }
      steps {
        script {
          common.buildOMC('clang', 'clang++', '--without-hwloc')
          common.makeLibsAndCache()
          common.partest(true, '-cppruntime')
        }
      }
    }
  }
}
