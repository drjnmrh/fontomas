#!/bin/bash

# AutoGen Bash Linux build script.
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
CONFIG="release"
ROOT=${PWD}
TOOLS=${PWD}/tools
JOBS=$(getconf _NPROCESSORS_ONLN)

#######################################################################
# Parses arguments and sets global variables according values of these
# arguments. Exits script in case of failure.
# Globals:
#   CONFIG, DEVELOP, VERBOSE, ROOT, TOOLS, JOBS
# Arguments:
#   config
# Returns:
#   None
#######################################################################
parse_args() {
    local _defaultTools=1

	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
		help
	fi

    CONFIG="$1"
    if [[ ! "${CONFIG}" ]]; then
        echo "config is required (see --help for more information)" >&2
		exit 1
    fi

    shift

	while [[ "$#" > 0 ]]; do case $1 in
	-d|--develop) DEVELOP=1;;
	-v|--verbose) VERBOSE=1;;
	-h|--help) help;;
	-r|--root) ROOT=$2; shift;;
    --tools) TOOLS=$2; _defaultTools=0; shift;;
    -j|--jobs) JOBS=$2; shift;;
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
		echo "DEVELOPMENT mode is ON"
	fi

	if [[ $VERBOSE -eq 1 ]]; then
		echo "VERBOSE mode is ON"
	fi

    if [[ $_defaultTools -eq 1 ]]; then
        TOOLS=${ROOT}/tools
    fi
}


#######################################################################
# Main function of the script. Uses CMake to build generated UNIX Makefiles.
# Globals:
#   PWD, CONFIG, VERBOSE, DEVELOP, ROOT, TOOLS
# Arguments:
#   arguments to the script to parse
# Returns:
#   None
#######################################################################
main() {
    local _cmaketool=cmake
    local _olddir=${PWD}

    parse_args $@
    include_utils linux "${TOOLS}"

    cd ${ROOT}
    if [[ $? -ne 0 ]]; then
        ag::err "expected folder ${ROOT}" >&2
        ag::failed "FAILED\n"
        exit 1
    fi

    local _module=${PWD##*/}

    local _configsToBuild=(release debug)

    case ${CONFIG} in
        Release|release) _configsToBuild=(release);;
        Debug|debug)     _configsToBuild=(debug);;
        All|all)         _configsToBuild=(release debug);;
        *)
			cd $_olddir
			ag::err "unknown config ${CONFIG}"
			ag::fail "FAILED\n"
			exit 1
			;;
    esac

    for _cfg in ${_configsToBuild[@]}; do
        local _builddir=$(ag::get_build_folder_name $_cfg)

        cd $_builddir
        if [[ $? -ne 0 ]]; then
            cd $_olddir
            ag::err "can't cd to $_builddir (generate project first)"
            ag::fail "FAILED\n"
            exit 1
        fi

        ag::info "** building '$_module' ($_cfg) **\n";

        local _buildCfgFlag=$(ag::cmake_build_config_flag $_cfg)
        local _installCfgFlag=$(ag::cmake_install_config_flag $_cfg)

        local _verboseFlag=""
        if [[ ${VERBOSE} -eq 1 ]]; then
            _verboseFlag="VERBOSE=1"
        fi

        $_cmaketool --build . $_buildCfgFlag -- -j $JOBS $_verboseFlag
        if [[ $? -ne 0 ]]; then
            cd $_olddir
            ag::err "failed to build $_module ($_cfg)"
            ag::fail "FAILED\n"
            exit 1
        else
            ag::done "DONE\n"
        fi

        ag::info "** installing '$_module' ($_cfg) **\n";

        $_cmaketool $_installCfgFlag -P cmake_install.cmake
        if [[ $? -ne 0 ]]; then
            cd $_olddir
            ag::err "failed to install $_module ($_cfg)"
            ag::fail "FAILED\n"
            exit 1
        fi

        ag::done "DONE\n"

        cd ..
    done

    cd $_olddir
    exit 0
}


# ----------------------------------------------------------------------------


main $@


# tools/bash/autogen-linux-build.sh
