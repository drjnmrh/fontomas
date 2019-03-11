#!/bin/bash

# AutoGen Bash Linux project make script.
# Copyright (C) 2019 O.Z.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# ----------------------- AutoGen Scripts Commons -----------------------------


MYDIR="$(cd "$(dirname "$0")" && pwd)"
MYNAME=`basename "$0"`

################################################################
# Checks AutoGen CMake & Bash utils and includes sources.
# Exits script in case of failure.
# Globals:
#   MYDIR, PWD
# Arguments:
#   platform, tools path
# Returns:
#   None
################################################################
include_utils() {
    local _platform=$1
    local _utils=$2/bash

	if [[ ! -d "$_utils" ]]; then
		printf "WARNING: no utils in $_utils - trying the default path\n"
		_utils="${MYDIR}"
	fi

	if [[ -d "$_utils" ]]; then
		printf "found utils in $_utils\n"
	else
		echo "no utils in $_utils" >&2
		printf "FAILED\n"
		exit 1
	fi

	source $_utils/autogen-utils.sh
    source $_utils/autogen-utils-$_platform.sh
}

###############################################################
# Displays help information for the script end exits.
# Globals:
#   MYDIR, MYNAME
# Arguments:
#   None
# Returns:
#   None
###############################################################
help() {
    echo ""
	cat ${MYDIR}/../docs/${MYNAME}.txt
    echo ""

	exit 0
}


# ----------------------------------------------------------------------------


ROOT=${PWD}
TOOLS=${PWD}/tools
PREFIX=${PWD}/boutput
VERBOSE=0
DEVELOP=0
BUILDNUMBER="1"
CONFIG="all"
DONTS=()


#######################################################################
# Parses arguments and sets global variables according values of these
# arguments.
# Globals:
#   VERBOSE, ROOT, BUILDNUMBER, DONTS, TOOLS, PREFIX
# Arguments:
#   arguments to the script to parse
# Returns:
#   None
#######################################################################
parse_args() {
    local _dontsCounter=0
    local _toolsDefault=1
    local _defaultPrefix=1

    while [[ "$#" > 0 ]]; do case $1 in
	-v|--verbose) VERBOSE=1;;
    -d|--develop) DEVELOP=1;;
    --dont) DONTS[$_dontsCounter]=$2; _dontsCounter=$(($_dontsCounter+1)); shift;;
	-h|--help) help;;
	-r|--root) ROOT=$2; shift;;
    --config) CONFIG=$2; shift;;
    --buildno) BUILDNUMBER=$2; shift;;
    --tools) TOOLS=$2; _toolsDefault=0; shift;;
    --prefix) PREFIX=$2; _defaultPrefix=0; shift;;
	*) echo "Unknown parameter passed: $1" >&2; exit 1;;
	esac; shift; done

    if [[ "${ROOT}" == "." ]]; then
        ROOT=${PWD}
    fi

	if [[ "${ROOT:~0}" == "/" ]]; then
		ROOT="${ROOT:0:$((${#ROOT}-1))}"
	fi

 	ROOT="$(cd "$(dirname "$ROOT")"; pwd)/$(basename "$ROOT")"

	if [[ $VERBOSE -eq 1 ]]; then
		echo "VERBOSE mode is ON"
	fi

    if [[ $DEVELOP -eq 1 ]]; then
		echo "DEVELOPMENT mode is ON"
	fi

    if [[ $_toolsDefault -eq 1 ]]; then
        TOOLS=${ROOT}/tools
    fi

    if [[ $_defaultPrefix -eq 1 ]]; then
		PREFIX=${ROOT}/boutput
	fi
}

#######################################################################
# The main function of the script. Executes the generation, building and
# testing scripts for the Linux target platform.
# Globals:
#   PLATFORM, VERBOSE, DEVELOP, BUILDNUMBER
# Arguments:
#   arguments to the script to parse
# Returns:
#   None
#######################################################################
main() {
    local _config=${CONFIG}

    parse_args $@
    include_utils linux ${TOOLS}

    local _oldDir=${PWD}
    cd ${ROOT}

    local _verbose=""
    if [[ $VERBOSE -eq 1 ]]; then
        _verbose="--verbose"
    fi

    local _develop=""
    if [[ $DEVELOP -eq 1 ]]; then
        _develop="--develop"
    fi

    local _needGenerate=1
    local _needBuild=1
    local _needTest=1
    for dont in ${DONTS[@]}; do
        if [[ "$dont" == "generate" ]]; then
            _needGenerate=0
        fi

        if [[ "$dont" == "build" ]]; then
            _needBuild=0
        fi

        if [[ "$dont" == "test" ]]; then
            _needTest=0
        fi
    done

    if [[ $_needGenerate -eq 1 ]]; then
        ${TOOLS}/bash/autogen-linux-gen.sh $_config $_verbose --root ${ROOT} --tools ${TOOLS} --prefix ${PREFIX} $_develop
        if [[ $? -ne 0 ]]; then
            ag::fail "EPIC FAIL\n"
            cd $_oldDir
            exit 1
        fi
    fi

    if [[ $_needBuild -eq 1 ]]; then
        ${TOOLS}/bash/autogen-linux-build.sh $_config $_verbose --root ${ROOT} --tools ${TOOLS} $_develop
        if [[ $? -ne 0 ]]; then
            ag::fail "EPIC FAIL\n"
            cd $_oldDir
            exit 1
        fi
    fi

    if [[ $_needTest -eq 1 ]]; then
        ${TOOLS}/bash/autogen-linux-test.sh $_config $_verbose --root ${ROOT} --tools ${TOOLS} $_develop
        if [[ $? -ne 0 ]]; then
            ag::fail "EPIC FAIL\n"
            cd $_oldDir
            exit 1
        fi
    fi

    cd $_oldDir
    exit 0
}


# ---------------------------------------------------------------------------


main $@


# tools/bash/autogen-linux-mk.sh
