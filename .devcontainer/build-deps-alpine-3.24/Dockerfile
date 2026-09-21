FROM docker.openmodelica.org/build-deps:alpine-3.24

ENV SHELL=/bin/bash

ARG USERNAME=openmodelica-user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user (busybox adduser/addgroup on Alpine)
RUN addgroup -g $USER_GID $USERNAME \
    && adduser -u $USER_UID -G $USERNAME -s /bin/bash -D $USERNAME

# [Optional] Add sudo support. Omit if you don't need to install software after connecting.
RUN apk add --no-cache sudo \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

ENV USER=$USERNAME
