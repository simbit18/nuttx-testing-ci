# SPDX-License-Identifier: Apache-2.0
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.  The
# ASF licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.

FROM ubuntu:22.04 AS builder-base
# NOTE WE ARE NOT REMOVING APT CACHE.
# This should only be used for temp build images that artifacts will be copied from
RUN apt-get update -qq && apt-get install -y -qq \
  curl \
  patch \
  xz-utils

###############################################################################
# Base image that should be used to prepare tools from nuttx-tools
###############################################################################
FROM builder-base AS nuttx-tools

RUN apt-get update -qq && DEBIAN_FRONTEND="noninteractive" apt-get install -y -qq \
  bison \
  clang \
  cmake \
  flex \
  g++ \
  gawk \
  git \
  gperf \
  libncurses5-dev \
  make \
  ninja-build \
  nodejs \
  npm \
  unzip \
  zip \
  python3

RUN mkdir -p /tools
WORKDIR /tools

RUN mkdir -p /tools/nuttx-tools
RUN curl -s -L https://bitbucket.org/nuttx/tools/get/9ad3e1ee75c7.tar.gz \
  | tar -C nuttx-tools --strip-components=1 -xz

RUN mkdir -p /tools/gn \
  && cd /tools/gn \
  && git clone https://gn.googlesource.com/gn gn \
  && cd gn \
  && python3 build/gen.py \
  && ninja -C out

#########################
# Programming languages
#########################

CMD [ "/bin/bash" ]

###############################################################################
# Base image that should be used to prepare arch build images
###############################################################################
FROM builder-base AS nuttx-toolchain-base

RUN mkdir -p /tools
WORKDIR /tools

###############################################################################
# Build image for tool required by Raspberry Pi pico-sdk builds
###############################################################################
FROM nuttx-toolchain-base AS nuttx-toolchain-raspberrypi-pico-sdk
# Download the latest pico-sdk source archive
RUN mkdir -p pico-sdk && \
  curl -s -L "https://github.com/raspberrypi/pico-sdk/releases/download/2.2.0/pico-sdk-2.2.0.tar.gz" \
  | tar -C pico-sdk --strip-components 1 -xz

###############################################################################
# Build image for tool required by Raspberry Pi picotool builds
###############################################################################
FROM nuttx-toolchain-base AS nuttx-toolchain-raspberrypi-picotool
# Download the prebuilt Raspberry Pi picotool
RUN mkdir -p picotool && \
  curl -s -L "https://github.com/raspberrypi/pico-sdk-tools/releases/download/v2.2.0-0/picotool-2.2.0-x86_64-lin.tar.gz" \
  | tar -C picotool --strip-components 1 -xz

###############################################################################
# Final Docker image used for running CI system.  This includes all toolchains
# supported by the CI system.
###############################################################################
FROM ubuntu:22.04
LABEL maintainer="dev@nuttx.apache.org"

RUN apt-get update -qq && DEBIAN_FRONTEND="noninteractive" apt-get install -y -qq \
  build-essential \
  curl \
  gcc \
  libssl-dev

RUN mkdir -p cmake && \
  curl -s -L https://cmake.org/files/v3.26/cmake-3.26.0.tar.gz \
  | tar -C cmake --strip-components=1 -xz \
  && cd cmake && ./bootstrap && make && make install && rm -rf cmake

RUN dpkg --add-architecture i386
# This is used for the final images so make sure to not store apt cache
# Note: xtensa-esp32-elf-gdb is linked to libpython2.7
RUN apt-get update -qq && DEBIAN_FRONTEND="noninteractive" TZ=Etc/UTC apt-get install -y -qq --no-install-recommends \
  -o APT::Immediate-Configure=0 \
  avr-libc \
  ccache \
  clang \
  clang-tidy \
  g++-12-multilib \
  gcc-avr \
  gcc-12-multilib \
  genromfs \
  gettext \
  git \
  lib32z1-dev \
  libasound2-dev libasound2-dev:i386 \
  libc6-dev-i386 \
  libcurl4-openssl-dev \
  libmp3lame-dev:i386 \
  libmad0-dev:i386 \
  libncurses5-dev \
  libpulse-dev libpulse-dev:i386 \
  libpython2.7 \
  libtinfo5 \
  libusb-1.0-0-dev libusb-1.0-0-dev:i386 \
  libv4l-dev libv4l-dev:i386 \
  libx11-dev libx11-dev:i386 \
  libxext-dev libxext-dev:i386 \
  linux-headers-generic \
  linux-libc-dev:i386 \
  ninja-build \
  npm \
  qemu-system-arm \
  qemu-system-misc \
  python3 \
  python3-pip \
  python-is-python3 \
  u-boot-tools \
  unzip \
  wget \
  xxd \
  file \
  subversion \
  tclsh \
  zip \
  && rm -rf /var/lib/apt/lists/*

# Set GCC-12 as Default compiler
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 20 && \
  update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 20 && \
  update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 30 && \
  update-alternatives --set cc /usr/bin/gcc && \
  update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 30 && \
  update-alternatives --set c++ /usr/bin/g++

# Configure out base setup for adding python packages
ENV PIP_DISABLE_PIP_VERSION_CHECK=true
# This disables the cache with value 0. We do not want caching as it
# increases the images size.
ENV PIP_NO_CACHE_DIR=0
# We are using the minimal python installation from the system so include
# setuptools and also wheel so we can use the binary releases of packages
# instead of requiring them to be compiled.
RUN pip3 install setuptools
RUN pip3 install wheel
RUN pip3 install cmake-format
# Install CodeChecker and use it to statically analyze the code.
# RUN pip3 install CodeChecker
# Install cvt2utf to check for non-UTF characters.
RUN pip3 install cvt2utf
# Install pytest
RUN pip3 install cxxfilt
RUN pip3 install construct
RUN pip3 install esptool==4.8.dev4
RUN pip3 install imgtool
RUN pip3 install kconfiglib
RUN pip3 install pexpect==4.8.0
RUN pip3 install pyelftools
RUN pip3 install pyserial==3.5
RUN pip3 install pytest==6.2.5
RUN pip3 install pytest-json==0.4.0
RUN pip3 install pytest-ordering==0.6
RUN pip3 install pytest-repeat==0.9.1
# Install lark stringcase jinja2 and coloredlogs for matter build
RUN pip3 install lark
RUN pip3 install stringcase
RUN pip3 install jinja2
RUN pip3 install coloredlogs

# Upgrade nodejs to the stable version we need
RUN npm install -g n && n 20.10.0 node && hash -r

# Used to generate symbol table files

RUN mkdir -p /tools
WORKDIR /tools

# Raspberry Pi pico-sdk source
COPY --from=nuttx-toolchain-raspberrypi-pico-sdk /tools/pico-sdk/ pico-sdk/
ENV PICO_SDK_PATH="/tools/pico-sdk"

# Raspberry Pi picotool
COPY --from=nuttx-toolchain-raspberrypi-picotool /tools/picotool/ picotool/
ENV PATH="/tools/picotool:$PATH"

# gn tool
RUN mkdir -p /tools/gn
COPY --from=nuttx-tools /tools/gn/gn/out/gn /tools/gn
ENV PATH="/tools/gn:$PATH"

# Configure ccache
# use `/ccache` as cachedir for all users
# RUN mkdir -p /ccache && \
#  chmod 666 /ccache && \
#  mkdir -p /tools/ccache/bin && \
#  ln -sf `which ccache` /tools/ccache/bin/aarch64-none-elf-gcc && \
#  ln -sf `which ccache` /tools/ccache/bin/aarch64-none-elf-g++ && \
#  ln -sf `which ccache` /tools/ccache/bin/arm-none-eabi-gcc && \
#  ln -sf `which ccache` /tools/ccache/bin/arm-none-eabi-g++ && \
#  ln -sf `which ccache` /tools/ccache/bin/avr-gcc && \
#  ln -sf `which ccache` /tools/ccache/bin/avr-g++ && \

# ENV PATH="/tools/ccache/bin:$PATH"
# ENV CCACHE_DIR="/ccache"

CMD [ "/bin/bash" ]
