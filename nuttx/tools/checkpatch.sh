#!/usr/bin/env bash
# tools/checkpatch.sh
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e
set -o xtrace

TOOLDIR=$(dirname $0)
#CID=$(cd "$(dirname "$0")" && pwd)
# CID=$(cd "$(dirname "$0")" && cd .. && pwd)
#CIWORKSPACE=$(cd "${CID}"/../../ && pwd -P)
echo "USAGE: ${0} $TOOLDIR $CIWORKSPACE"
case "$OSTYPE" in
  *bsd*) MAKECMD=gmake;;
  *) MAKECMD=make;;
esac

check=check_patch
fail=0
range=0
spell=0
encoding=0
message=0

# CMake
cmake_warning_once=0

# Python
black_warning_once=0
flake8_warning_once=0
isort_warning_once=0

cvt2utf_warning_once=0

usage() {
  echo "USAGE: ${0} [options] [list|-]"
  echo ""
  echo "Options:"
  echo "-h"
  echo "-c spell check with codespell (install with: pip install codespell)"
  echo "-u encoding check with cvt2utf (install with: pip install cvt2utf)"
  echo "-r range check only (coupled with -p or -g)"
  echo "-p <patch file names> (default)"
  echo "-m Change-Id check in commit message (coupled with -g)"
  echo "-g <commit list>"
  echo "-f <file list>"
  echo "-  read standard input mainly used by git pre-commit hook as below:"
  echo "   git diff --cached | ./tools/checkpatch.sh -"
  echo "Where a <commit list> is any syntax supported by git for specifying git revision, see GITREVISIONS(7)"
  echo "Where a <patch file names> is a space separated list of patch file names or wildcard. or *.patch"

  exit $@
}

is_rust_file() {
  file_ext=${@##*.}
  file_ext_r=${file_ext/R/r}
  file_ext_rs=${file_ext_r/S/s}

  if [[ "$file_ext_rs" == "rs" ]]; then
    echo 1
  else
    echo 0
  fi
}

is_python_file() {
  if [[ "${@##*.}" == "py" ]]; then
    echo 1
  else
    echo 0
  fi
}

is_cmake_file() {
  file_name = "$(basename $@)"
  if [[ "$file_name" == "CMakeLists.txt" ]] || [[ "$file_name" =~ \.cmake$ ]]; then
    echo 1
  else
    echo 0
  fi
}

is_c_file() {
  if [[ "${@##*.}" == "c" ]] || [[ "${@##*.}" == "h" ]]; then
    echo 1
  else
    echo 0
  fi
}

check_file() {
  if [ -x $@ ]; then
    case $@ in
    *.bat | *.sh | *.py)
      ;;
    *)
      echo "$@: error: execute permissions detected!"
      fail=1
      ;;
    esac
  fi

  # if [ ${@##*.} == 'py' ]; then
    # setupcfg="${TOOLDIR}/../.github/linters/setup.cfg"
    # black --check "$@" || fail=1
    # flake8 --config "${setupcfg}" "$@" || fail=1
    # isort --diff --check-only --settings-path "${setupcfg}" "$@"
    # if [ $? -ne 0 ]; then
      # # Format in place
      # isort --settings-path "${setupcfg}" "$@"
      # fail=1
    # fi

  if [ "$(is_python_file $@)" == "1" ]; then
  echo -e "Check Python file ..."
    setupcfg="${TOOLDIR}/../.github/linters/setup.cfg" # ok
    # setupcfg="setup.cfg"
    if ! command -v black &> /dev/null; then
      if [ $black_warning_once == 0 ]; then
        echo -e "\nblack not found, run following command to install:"
        echo "  $ pip install black"
        black_warning_once=1
      fi
      fail=1
    elif ! black --check $@ 2>&1; then
      if [ $black_warning_once == 0 ]; then
        echo -e "\nblack check failed, run following command to update the style:"
        echo -e "  $ black <src>\n"
        black_warning_once=1
      fi
      fail=1
    fi
    if ! command -v flake8 &> /dev/null; then
      if [ $flake8_warning_once == 0 ]; then
        echo -e "\nflake8 not found, run following command to install:"
        echo "  $ pip install flake8"
        flake8_warning_once=1
      fi
      fail=1
    elif ! flake8 --config "${setupcfg}" "$@" 2>&1; then
      if [ $flake8_warning_once == 0 ]; then
        echo -e "\nflake8 check failed !!!"
        flake8_warning_once=1
      fi
      fail=1
    fi
    if ! command -v isort &> /dev/null; then
      if [ $isort_warning_once == 0 ]; then
        echo -e "\nisort not found, run following command to install:"
        echo "  $ pip install isort"
        isort_warning_once=1
      fi
      fail=1
    elif ! isort --diff --check-only --settings-path "${setupcfg}" "$@" 2>&1; then
      if [ $isort_warning_once == 0 ]; then
        echo -e "\nisort ..."
        isort --settings-path "${setupcfg}" "$@"
        isort_warning_once=1
      fi
      fail=1
    fi
  elif [ "$(is_rust_file $@)" == "1" ]; then
    if ! command -v rustfmt &> /dev/null; then
      echo -e "\nrustfmt not found, run following command to install:"
      echo "  $ rustup component add rustfmt"
      fail=1
    elif ! rustfmt --edition 2021 --check $@ 2>&1; then
      fail=1
    fi
  elif [ "$(is_cmake_file $@)" == "1" ]; then
    echo -e "Check CMake file ..."
    if ! command -v cmake-format &> /dev/null; then
      if [ $cmake_warning_once == 0 ]; then
        echo -e "\ncmake-format not found, run following command to install:"
        echo "  $ pip install cmake-format"
        cmake_warning_once=1
      fi
      fail=1
    elif ! cmake-format --check $@ 2>&1; then
      if [ $cmake_warning_once == 0 ]; then
        echo -e "\ncmake-format check failed, run following command to update the style:"
        echo -e "  $ cmake-format <src> -o <dst>\n"
        cmake-format --check $@ 2>&1
        cmake_warning_once=1
      fi
      fail=1
    fi
  elif [ "$(is_c_file $@)" == "1" ]; then
    if ! $TOOLDIR/nxstyle $@ 2>&1; then
      fail=1
    fi
  else
    echo "There is no manual page for that command."
  fi

  if [ $spell != 0 ]; then
    if ! command -v codespell &> /dev/null; then
      echo -e "\ncodespell not found, run following command to install:"
      echo "  $ pip install codespell"
      fail=1
    else
      if ! codespell -q 7 ${@: -1}; then
        fail=1
      fi
    fi
  fi

  if [ $encoding != 0 ]; then
    echo -e "\ncvt2utf ..."
    if ! command -v cvt2utf &> /dev/null; then
      echo -e "\ncvt2utf not found, run following command to install:"
      echo "  $ pip install cvt2utf"
      fail=1
    else
      md5="$(md5sum $@)"
      cvt2utf convert --nobak "$@" &> /dev/null
      if [ "$md5" != "$(md5sum $@)" ]; then
          echo "$@: error: Non-UTF8 characters detected!"
          fail=1
      fi
    fi
    # cvt2utf convert --nobak "$@" &> /dev/null
    # if [ "$md5" != "$(md5sum $@)" ]; then
      # echo "$@: error: Non-UTF8 characters detected!"
      # fail=1
    # fi
  fi
}

check_ranges() {
  while read; do
    if [[ $REPLY =~ ^(\+\+\+\ (b/)?([^[:blank:]]+).*)$ ]]; then
      if [ "$ranges" != "" ]; then
        if [ $range != 0 ]; then
          check_file $ranges $path
        else
          check_file $path
        fi
      fi
      path=$(realpath "${BASH_REMATCH[3]}")
      # path= $(realpath "$CIWORKSPACE/${BASH_REMATCH[3]}")
      ranges=""
    elif [[ $REPLY =~ @@\ -[0-9]+(,[0-9]+)?\ \+([0-9]+,[0-9]+)?\ @@.* ]]; then
      ranges+="-r ${BASH_REMATCH[2]} "
    fi
  done
  if [ "$ranges" != "" ]; then
    if [ $range != 0 ]; then
      check_file $ranges $path
    else
      check_file $path
    fi
  fi
}

check_patch() {
  if ! git apply --check $1; then
    fail=1
  else
    git apply $1
    diffs=`cat $1`
    check_ranges <<< "$diffs"
    git apply -R $1
  fi
}

check_msg() {
  while read; do
    if [[ $REPLY =~  ^Change-Id ]]; then
      echo "Remove Gerrit Change-ID's before submitting upstream"
      fail=1
    fi
  done
}

check_commit() {
  if [ $message != 0 ]; then
    msg=`git show -s --format=%B $1`
    check_msg <<< "$msg"
  fi
  diffs=`git diff $1`
  check_ranges <<< "$diffs"
}

 $MAKECMD -C $TOOLDIR -f Makefile.host nxstyle 1>/dev/null

if [ -z "$1" ]; then
  usage
  exit 0
fi

while [ ! -z "$1" ]; do
  case "$1" in
  - )
    check_ranges
    ;;
  -c )
    spell=1
    ;;
  -u )
    encoding=1
    ;;
  -f )
    check=check_file
    ;;
  -m )
    message=1
    ;;
  -g )
    check=check_commit
    ;;
  -h )
    usage 0
    ;;
  -p )
    check=check_patch
    ;;
  -r )
    range=1
    ;;
  -* )
    usage 1
    ;;
  * )
    break
    ;;
  esac
  shift
done

for arg in $@; do
  $check $arg
done

exit $fail
