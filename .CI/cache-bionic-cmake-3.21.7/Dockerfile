# Cannot be parametrized in Jenkins...
FROM docker.openmodelica.org/build-deps:v1.16.3

# We don't know the uid of the user who will build, so make the /cache directories world writable
RUN mkdir -p /cache/runtest/ /cache/omlibrary/ && chmod ugo+rwx /cache/runtest/ /cache/omlibrary/ \
    && apt-get remove -qy cmake cmake-data

# Install cmake 3.21.7
RUN wget https://cmake.org/files/v3.21/cmake-3.21.7-linux-x86_64.sh
RUN mkdir -p /opt/cmake-3.21.7
RUN sh cmake-3.21.7-linux-x86_64.sh --prefix=/opt/cmake-3.21.7 --skip-license
RUN ln -s /opt/cmake-3.21.7/bin/cmake /usr/bin/cmake
