#!/bin/bash

runner_os=$1
inputs_compiler=$2
use_sudo=$3

if [[ -z ${GITHUB_ACTION+z} ]]; then
    ECHO=echo
else
    unset ECHO
fi

if [[ ${use_sudo} == true ]]; then
    SUDO=sudo
else
    unset SUDO
fi

# $1 - runner os
# $2 - compiler
# $3 - version; optional
function install_compilers {
    if [[ -n $3 ]]; then
        _VER=$3
        P_VER='-'$_VER
    fi

    case $2 in
        gcc | g++)
            _CC=gcc
            _CXX=g++
            PKGS="$_CC$P_VER $_CXX$P_VER"
            WINPKGS="mingw --version=$_VER"
            [[ ! -n "$_VER" ]] && MACPKGS="gcc" || MACPKGS="gcc@$_VER"
        ;;
        clang | clang++)
            _CC=clang
            _CXX=clang++
            PKGS="$_CC$P_VER"
            WINPKGS="llvm --version=$_VER"
            [[ ! -n "$_VER" ]] && MACPKGS="llvm" || MACPKGS="llvm@$_VER"
        ;;
        *)
            echo "::error ::Unknown compiler '$2'"
            exit 1
        ;;
    esac

    case $1 in
        Linux)
            echo "::group::apt install"

            echo $SUDO apt update -q
            $SUDO apt update -q
            EXITCODE=$?
            [[ $EXITCODE != 0 ]] && exit $EXITCODE

            echo DEBIAN_FRONTEND=noninteractive $SUDO apt install $PKGS -q -y
            DEBIAN_FRONTEND=noninteractive $SUDO apt install $PKGS -q -y
            EXITCODE=$?
            [[ $EXITCODE != 0 ]] && exit $EXITCODE

            echo "::endgroup::"
            echo "cc=$(which ${_CC}${P_VER})" >> $GITHUB_OUTPUT
            echo "cxx=$(which ${_CXX}${P_VER})" >> $GITHUB_OUTPUT
        ;;
        Windows)
            echo "::group::choco install"

            echo choco upgrade $WINPKGS -y --no-progress --allow-downgrade
            $ECHO choco upgrade $WINPKGS -y --no-progress --allow-downgrade

            echo "::endgroup::"
            echo "cc=${_CC}" >> $GITHUB_OUTPUT
            echo "cxx=${_CXX}" >> $GITHUB_OUTPUT
        ;;
        macOS)
            case ${_CC}${P_VER} in
                gcc*)
                    echo "::group::Brew install"

                    echo brew update
                    $ECHO brew update
                    EXITCODE=$?
                    [[ $EXITCODE != 0 ]] && exit $EXITCODE

                    echo brew install $MACPKGS
                    $ECHO brew install $MACPKGS
                    EXITCODE=$?
                    [[ $EXITCODE != 0 ]] && exit $EXITCODE

                    echo brew link $MACPKGS
                    $ECHO brew link $MACPKGS
                    EXITCODE=$?
                    [[ $EXITCODE != 0 ]] && exit $EXITCODE

                    echo "::endgroup::"
                    echo "cc=$(which ${_CC}${P_VER})" >> $GITHUB_OUTPUT
                    echo "cxx=$(which ${_CC}${P_VER})" >> $GITHUB_OUTPUT
                ;;
                clang*)
                    echo "::group::Brew install"

                    echo brew update
                    $ECHO brew update
                    EXITCODE=$?
                    [[ $EXITCODE != 0 ]] && exit $EXITCODE

                    echo brew install $MACPKGS
                    $ECHO brew install $MACPKGS
                    EXITCODE=$?
                    [[ $EXITCODE != 0 ]] && exit $EXITCODE

                    echo brew link $MACPKGS
                    $ECHO brew link $MACPKGS
                    EXITCODE=$?
                    [[ $EXITCODE != 0 ]] && exit $EXITCODE

                    echo "::endgroup::"
                    echo "cc=$(which ${_CC}${P_VER})" >> $GITHUB_OUTPUT
                    echo "cxx=$(which ${_CC}${P_VER})" >> $GITHUB_OUTPUT
                ;;
            esac
        ;;
        *)
            echo "::error ::Unsupported runner '$1'"
            exit 1
        ;;
    esac
}

ARR=($(echo $inputs_compiler | tr '-' '\n'))

#echo "::notice::Input: ${inputs_compiler} Parsed: ${ARR[@]} Size: ${#ARR[@]}"

if [[ ${#ARR[@]} == 2 ]]; then
  case ${ARR[0]} in
    gcc | g++)
        COMPILER=gcc
    ;;
    clang | clang++)
        COMPILER=clang
    ;;
    *)
    ;;
  esac

  case ${ARR[1]} in
    latest)
        VERSION=
    ;;
    *)
        VERSION=${ARR[1]}
    ;;
  esac

else
  case ${ARR[0]} in
    latest | gcc | g++)
        COMPILER=gcc
    ;;
    clang | clang++)
        COMPILER=clang
    ;;
    *)
    ;;
  esac
  VERSION=

fi

#echo "::notice::Runner: ${runner_os} Compiler: ${COMPILER} Version: ${VERSION}"

install_compilers $runner_os $COMPILER $VERSION
