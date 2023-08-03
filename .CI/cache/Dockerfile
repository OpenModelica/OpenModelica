# Cannot be parametrized in Jenkins...
FROM anheuermann/openmodelica-build-deps:v1.22.0

# We don't know the uid of the user who will build, so make the /cache directories world writable

USER root
RUN mkdir -p /cache/runtest/ /cache/omlibrary/ && chmod ugo+rwx /cache/runtest/ /cache/omlibrary/
USER openmodelica-user
