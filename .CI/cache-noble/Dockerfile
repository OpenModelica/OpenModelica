FROM openmodelica/build-deps:v1.23.0-wip

# We don't know the uid of the user who will build, so make the /cache directories world writable

RUN mkdir -p /cache/runtest/ /cache/omlibrary/ && chmod ugo+rwx /cache/runtest/ /cache/omlibrary/
