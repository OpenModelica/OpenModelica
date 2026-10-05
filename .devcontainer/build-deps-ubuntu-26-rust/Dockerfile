FROM docker.openmodelica.org/build-deps:ubuntu-26.04-rust

ENV SHELL=/bin/bash

ARG USERNAME=openmodelica-user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user. Unlike the older build-deps images, Ubuntu >= 24.04 bases
# already ship a user on UID 1000 ('ubuntu'), which collides with the usual host
# UID, so drop that one first.
RUN set -eux; \
    if getent passwd "$USER_UID" >/dev/null; then \
      userdel -r "$(getent passwd "$USER_UID" | cut -d: -f1)" 2>/dev/null || true; \
    fi; \
    getent group "$USER_GID" >/dev/null || groupadd --gid "$USER_GID" "$USERNAME"; \
    useradd --uid "$USER_UID" --gid "$USER_GID" -m "$USERNAME"

# [Optional] Add sudo support. Omit if you don't need to install software after connecting.
RUN apt-get update \
    && apt-get install -y sudo \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# The image ships CARGO_HOME=/opt/rust/cargo, which is root-owned; cargo needs
# to write it. Move CARGO_HOME into the user's home rather than chown -R'ing
# /opt/rust, which would copy the whole toolchain into another image layer.
# RUSTUP_HOME is left alone: running rustc/cargo only reads it.
ENV CARGO_HOME=/home/$USERNAME/.cargo

# These are also the mount points of the cache volumes in devcontainer.json. A
# fresh named volume inherits the ownership of the image directory it is mounted
# over, so they have to exist and be owned by the user here.
RUN mkdir -p /home/$USERNAME/.cargo/registry \
             /home/$USERNAME/.cache/sccache \
             /cache/omlibrary \
    && chown -R $USER_UID:$USER_GID /home/$USERNAME /cache

ENV USER=$USERNAME
