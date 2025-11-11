ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ENV SHELL=/bin/bash

ARG USERNAME=openmodelica-user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Additional software (gdb, valgrind) and set locale
RUN apt-get update \
    && apt-get install -qy build-essential gdb valgrind locales \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

# [Optional] Add sudo support. Omit if you don't need to install software after connecting.
RUN apt-get update \
    && apt-get install -y sudo \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV USER=$USERNAME
