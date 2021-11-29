# Cannot be parametrized in Jenkins...
FROM docker.openmodelica.org/build-deps:v1.16.3

# We don't know the uid of the user who will build, so make the /cache directories world writable
RUN mkdir -p /cache/runtest/ /cache/omlibrary/ && chmod ugo+rwx /cache/runtest/ /cache/omlibrary/ \
    && apt-get remove -qy cmake cmake-data

# Install cmake 3.17.2.
RUN wget cmake.org/files/v3.17/cmake-3.17.2-Linux-x86_64.sh
RUN mkdir -p /opt/cmake-3.17.2
RUN sh cmake-3.17.2-Linux-x86_64.sh --prefix=/opt/cmake-3.17.2 --skip-license
