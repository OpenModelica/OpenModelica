ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ENV SHELL=/bin/bash

ARG USERNAME=openmodelica-user
ARG USER_UID=1000

# Additional software (gdb, valgrind)
RUN apt-get update                                                             \
    && apt-get install -qy build-essential gdb valgrind                        \
    && apt-get clean                                                           \
    && rm -rf /var/lib/apt/lists/*                                             \
    && usermod -l $USERNAME ubuntu                                             \
    && usermod -u $USER_UID $USERNAME

ENV USER=$USERNAME
