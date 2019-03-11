#!/bin/bash

# AutoGen Bash Xcode project tests running script.
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

DEVELOP=0
VERBOSE=0
ROOT=${PWD}
TOOLS=${PWD}/tools
CONFIG="all"


#######################################################################
# Parses arguments and sets global variables according values of these
# arguments.
# Globals:
#   ROOT, CONFIG, PLATFORM, DEVELOP, VERBOSE, TOOLS
# Arguments:
#   None
# Returns:
#   None
#######################################################################
parse_args() {
	local _defaultTools=1

	while [[ "$#" > 0 ]]; do case $1 in
	-d|--develop) DEVELOP=1;;
	-v|--verbose) VERBOSE=1;;
	-h|--help) help;;
	-r|--root) ROOT=$2; shift;;
    --config) CONFIG=$2; shift;;
	--tools) TOOLS=$2; _defaultTools=0; shift;;
	*) echo "Unknown parameter passed: $1" >&2; exit 1;;
	esac; shift; done

	if [[ "${ROOT:~0}" == "/" ]]; then
		ROOT="${ROOT:0:$((${#ROOT}-1))}"
	fi

    if [[ "${TOOLS:~0}" == "/" ]]; then
		TOOLS="${TOOLS:0:$((${#TOOLS}-1))}"
	fi

	ROOT="$(cd "$(dirname "$ROOT")"; pwd)/$(basename "$ROOT")"

	if [[ $DEVELOP -eq 1 ]]; then
		echo "DEVELOP mode is ON"
	fi

	if [[ $VERBOSE -eq 1 ]]; then
		echo "VERBOSE mode is ON"
	fi

	if [[ $_defaultTools -eq 1 ]]; then
		TOOLS=${ROOT}/tools
	fi
}


#######################################################################
# Main function of the script. Uses CTest tool to test already built
# artifacts.
# Globals:
#   PWD, CONFIG, VERBOSE, DEVELOP, ROOT, TOOLS
# Arguments:
#   arguments to the script to parse
# Returns:
#   None
#######################################################################
main() {
    local _olddir=${PWD}

	parse_args $@
	include_utils osx ${TOOLS}

    local _module=${ROOT##*/}

    cd ${ROOT}
    if [[ $? -ne 0 ]]; then
        ag::err "expected folder ${ROOT}" >&2
        ag::failed "FAILED\n"
        exit 1
    fi

	local _configsToTest=(release debug)

    case ${CONFIG} in
        Release|release) _configsToTest=(release);;
        Debug|debug)     _configsToTest=(debug);;
        All|all)         _configsToTest=(release debug);;
        *)
			cd $_olddir
			ag::err "unknown config ${CONFIG}"
			ag::fail "FAILED\n"
			exit 1
			;;
    esac

	# Xcode allows multi-config projects, thus there's one build folder for all
	# configurations
	local _builddir=$(ag::get_build_folder_name ${CONFIG})

    cd $_builddir
	if [[ $? -ne 0 ]]; then
		cd $_olddir
		ag::err "can't cd to $_builddir (generate project first)"
		ag::fail "FAILED\n"
		exit 1
	fi

	for _cfg in ${_configsToTest[@]}; do
		ag::info "** run tests for '$_module' ($_cfg) **\n";

		local _configFlag=$(ag::cmake_test_config_flag $_cfg)

		ctest $_configFlag --verbose
		if [[ $? -ne 0 ]]; then
			cd $_olddir
			ag::err "tests failed"
			ag::fail "FAILED\n"
			exit 1
		fi
	done

    ag::done "DONE\n"

    cd $_olddir
    exit 0
}


# ----------------------------------------------------------------------------


main $@


# tools/bash/autogen-osx-test.sh
