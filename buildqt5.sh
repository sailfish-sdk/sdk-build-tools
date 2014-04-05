#!/bin/bash
#
# This will use the current directory to build Qt5
#
# Qt5 sources must be found from the current user's home directory
# $HOME/invariant/qt5 or in case of Windows in C:\invariant\qt5
#
# Copyright (C) 2014 Jolla Oy
# Contact: Juha Kallioinen <juha.kallioinen@jolla.com>
# All rights reserved.
#
# You may use this file under the terms of BSD license as follows:
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   * Neither the name of the Jolla Ltd nor the
#     names of its contributors may be used to endorse or promote products
#     derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

export LC_ALL=C

UNAME_SYSTEM=$(uname -s)
UNAME_ARCH=$(uname -m)

if [[ $UNAME_SYSTEM == "Linux" ]] || [[ $UNAME_SYSTEM == "Darwin" ]]; then
    BASEDIR=$HOME/invariant
    SRCDIR_QT=$BASEDIR/qt5
    BUILD_DIR=$BASEDIR/qt5-build
else
    BASEDIR="/c/invariant"
    SRCDIR_QT="$BASEDIR/qt5"
    BUILD_DIR="$BASEDIR/build-qt5"
fi

COMMON_CONFIG_OPTIONS="-developer-build -opensource -confirm-license -nomake examples -nomake tests -qt-xcb -prefix $BUILD_DIR"

build_dynamic_qt_windows() {
    echo "Building Qt5 not tested in Windows yet - exiting"
    return

    rm -rf   $BUILD_DIR
    mkdir -p $BUILD_DIR
    pushd    $BUILD_DIR

    cat <<EOF > build-dyn.bat
@echo off
if DEFINED ProgramFiles(x86) set _programs=%ProgramFiles(x86)%
if Not DEFINED ProgramFiles(x86) set _programs=%ProgramFiles%

PATH=%PATH%;c:\invariant\bin

call "%_programs%\Microsoft Visual Studio 10.0\VC\vcvarsall.bat"
call "C:\invariant\qt5\configure.exe" $COMMON_CONFIG_OPTIONS -platform win32-msvc2010 -prefix
 
call jom
EOF

    cmd //c build-dyn.bat
    popd
}

configure_dynamic_qt5() {
    $SRCDIR_QT/configure $COMMON_CONFIG_OPTIONS
}

build_dynamic_qt() {
    rm -rf   $BUILD_DIR
    mkdir -p $BUILD_DIR
    pushd    $BUILD_DIR
    configure_dynamic_qt5
    make -j$(getconf _NPROCESSORS_ONLN)
    make install
    make docs
    popd
}

fail() {
    echo "FAIL: $@"
    exit 1
}

usage() {
    cat <<EOF

Build Qt5 libraries and documentation

Required directories:
 $BASEDIR
 $SRCDIR_QT

Usage:
   $(basename $0) [OPTION]

Options:
   -y  | --non-interactive    answer yes to all questions presented by the script
   -h  | --help               this help

EOF

    # exit if any argument is given
    [[ -n "$1" ]] && exit 1
}


# handle commandline options
while [[ ${1:-} ]]; do
    case "$1" in
	-y | --non-interactive ) shift
	    OPT_YES=1
	    ;;
	-h | --help ) shift
	    usage quit
	    ;;
	* )
	    usage quit
	    ;;
    esac
done

cat <<EOF
Build Qt5 libraries and documentation using sources in
 $SRCDIR_QT
EOF

# confirm
if [[ -z $OPT_YES ]]; then
    while true; do
	read -p "Do you want to continue? (y/n) " answer
	case $answer in
	    [Yy]*)
		break ;;
	    [Nn]*)
		echo "Ok, exiting"
		exit 0
		;;
	    *)
		echo "Please answer yes or no."
		;;
	esac
    done
fi

if [[ ! -d $BASEDIR ]]; then
    fail "directory [$BASEDIR] does not exist"
fi

if [[ ! -d $SRCDIR_QT ]]; then
    fail "directory [$SRCDIR_QT] does not exist"
fi

pushd $BASEDIR || exit 1

# stop in case of errors
set -e

if [[ $UNAME_SYSTEM == "Linux" ]] || [[ $UNAME_SYSTEM == "Darwin" ]]; then
    build_dynamic_qt
else
    build_dynamic_qt_windows
fi

popd