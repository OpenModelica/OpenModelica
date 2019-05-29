# Cannot be parametrized in Jenkins...
FROM docker.openmodelica.org/build-deps:v1.13

RUN apt-get update && apt-get install -qyy clang-tools && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
