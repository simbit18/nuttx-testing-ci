# Source licensed under the Apache License
FROM alpine:3.18.3
LABEL maintainer="simbit18"
LABEL org.opencontainers.image.source=https://github.com/simbit18
LABEL org.opencontainers.image.description="My container image"
LABEL org.opencontainers.image.licenses=Apache

RUN apk --no-cache add \
    bash \
    coreutils \
    findutils \
    gawk \
    git

# Install and Upgrade Base Packages
RUN apk --no-cache --update add \
    bison \
    flex \
    gettext \
    texinfo \
    gperf \
    automake \
    libtool \
    binutils-dev \
    picocom \
    u-boot-tools \
    util-linux \
    patch \
    autoconf \
    build-base \
    bash \
    bash-completion \
    shadow \
    git \
    curl \
    rsync \
    nano \
    tar \
    gzip \
    bzip2 \
    xz \
    zip

# Install and Upgrade ARM Compiler Packages
RUN apk --no-cache --update add \
    gcc-arm-none-eabi \
    newlib-arm-none-eabi \
    g++-arm-none-eabi

# Install and Upgrade Packages for Nuttx 
RUN apk --no-cache --update add \
    bsd-compat-headers \
    zlib-dev \
    ncurses-dev

# Install Development Tools Packages
RUN apk --no-cache --update add \
    cmake \
    xxd \
    python3 \
    py3-pip

# WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager.
# It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv
ENV PIP_ROOT_USER_ACTION=ignore

# Install Python 3 option
RUN pip3 install \
    pyelftools \
    cxxfilt

# Install kconfig-frontends
RUN cd /tmp \
    && git clone https://bitbucket.org/nuttx/tools.git \
    && cd tools \
    && cd kconfig-frontends \
    && ./configure --enable-mconf --disable-nconf --disable-gconf --disable-qconf \
    && ln -s /usr/bin/aclocal /usr/local/bin/aclocal-1.15 \
    && ln -s /usr/bin/automake /usr/local/bin/automake-1.15 \
    && make \
    && make install \
    && cd /

# Install genromfs
RUN cd /tmp \
    && git clone https://github.com/chexum/genromfs.git \
    && cd genromfs \
    && make \
    && make install \
    && cd /


RUN cd /tmp \
    && ls -a \
    && cd / \
    && ls -a
