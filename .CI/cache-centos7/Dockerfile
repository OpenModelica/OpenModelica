FROM docker.openmodelica.org/build-deps:el7.amd64

# Install git, zip
RUN yum -y install git zip

# We don't know the uid of the user who will build, so make the /cache directories world writable
RUN mkdir -p /cache/runtest/ /cache/omlibrary/ && chmod ugo+rwx /cache/runtest/ /cache/omlibrary/
