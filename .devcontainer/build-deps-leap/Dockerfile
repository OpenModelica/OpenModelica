FROM opensuse/leap:16.0

ARG USERNAME=openmodelica-user
ARG USER_UID=1000
ARG USER_GID=1000

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Refresh repositories and upgrade base system
RUN zypper --non-interactive refresh \
 && zypper --non-interactive update

# Core development pattern (compiler toolchain, make, etc.)
RUN zypper --non-interactive install \
    -t pattern devel_basis

# Core build utilities and infrastructure
RUN zypper --non-interactive install \
    aspell \
    bison \
    blas \
    ca-certificates \
    ccache \
    clang \
    clang-tools \
    cmake \
    curl \
    devscripts \
    flex \
    gcc-c++ \
    gcc-fortran \
    git \
    gnupg \
    java-25-openjdk-devel \
    lapack \
    libcurl-devel \
    libOpenSceneGraph-devel \
    libuuid-devel \
    make \
    patch \
    pkgconf-pkg-config\
    sudo \
    unzip \
    wget \
    xsltproc \
    zip

# Boost tooling
RUN zypper --non-interactive install \
    boost-devel \
    libboost_program_options-devel \
    libboost_filesystem-devel \
    libboost_graph-devel \
    libboost_chrono-devel

# Python tooling
RUN zypper --non-interactive install \
    python3 \
    python3-pip \
    python3-virtualenv

# Qt5 development
RUN zypper --non-interactive install -t pattern devel_qt5 \
  && zypper --non-interactive install \
    libqt5-qtbase-devel \
    libqt5-qtdeclarative-devel \
    libqt5-qtsvg-devel \
    libqt5-qttools-devel \
    libqt5-qtwebengine-devel

# Qt6 development
RUN zypper --non-interactive install -t pattern devel_qt6 \
  && zypper --non-interactive install \
    libQt6WebEngineCore6 \
    libQt6WebEngineWidgets6 \
    qt6-qt5compat-devel \
    qt6-tools-devel \
    qt6-tools-linguist \
    qt6-webenginecore-devel \
    qt6-webenginewidgets-devel

# Clean up
RUN zypper clean --all

# Create group and user with specified UID/GID
RUN groupadd --gid ${USER_GID} ${USERNAME} \
  && useradd  --uid ${USER_UID} \
              --gid ${USER_GID} \
              --create-home \
              --shell /bin/bash \
              ${USERNAME} \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
  && chmod 0440 /etc/sudoers.d/${USERNAME}

# Set environment
ENV USER=${USERNAME}
WORKDIR /home/${USERNAME}

# Switch to non-root user
USER ${USERNAME}
