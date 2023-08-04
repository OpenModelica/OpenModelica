ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG USERNAME

USER root
# Additional software (gdb, valgrind)
RUN apt-get update \
    && apt-get install -qy build-essential gdb valgrind

# [Optional] Add sudo support. Omit if you don't need to install software after connecting.
RUN apt-get install -y sudo gdb  \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
USER openmodelica-user
