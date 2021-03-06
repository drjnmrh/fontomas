#!/bin/bash

# AutoGen Bash Xcode project generation script.
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
PREFIX=${PWD}/boutput
CONFIG="all"
MAJOR="0"
MINOR="0"
PATCH="1"


#######################################################################
# Parses arguments and sets global variables according values of these
# arguments.
# Globals:
#   ROOT, TOOLS, DEVELOP, VERBOSE, PREFIX
# Arguments:
#   None
# Returns:
#   None
#######################################################################
parse_args() {
	local _defaultTools=1
	local _defaultPrefix=1

	while [[ "$#" > 0 ]]; do case $1 in
	-d|--develop) DEVELOP=1;;
	-v|--verbose) VERBOSE=1;;
	-h|--help) help;;
	-r|--root) ROOT=$2; shift;;
	--tools) TOOLS=$2; _defaultTools=0; shift;;
	--prefix) PREFIX=$2; _defaultPrefix=0; shift;;
	--config) CONFIG=$2; shift;;
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
		echo "DEVELOP mode ON"
	fi

	if [[ $VERBOSE -eq 1 ]]; then
		echo "VERBOSE mode ON"
	fi

	if [[ $_defaultTools -eq 1 ]]; then
        TOOLS=${ROOT}/tools
    fi

	if [[ $_defaultPrefix -eq 1 ]]; then
		PREFIX=${ROOT}/boutput
	fi
}


#######################################################################
# Main function of the script. Uses CMake to generate Xcode project.
# Globals:
#   PWD, CONFIG, VERBOSE, DEVELOP, ROOT, PREFIX, TOOLS, MAJOR, MINOR, PATCH
# Arguments:
#   arguments to the script to parse
# Returns:
#   None
#######################################################################
main() {
    local _cmaketool=cmake
    local _olddir=${PWD}

	parse_args $@
	include_utils osx ${TOOLS}

	local _cfg=${CONFIG}

	cd ${ROOT}
	if [[ $? -ne 0 ]]; then
		ag::err "failed to CD to the root folder ${ROOT}!\n"
		ag::fail "FAILED\n"
		exit 1
	fi

	ag::parse_version
	if [[ $? -ne 0 ]]; then
		ag::err "failed to get version of the module"
		ag::fail "FAILED\n"
		cd $_olddir
		exit 1
	fi

	local _builddir=$(ag::get_build_folder_name $_cfg)

    if [[ -d "$_builddir" ]]; then
		printf "  - cleaning by removing $_builddir : ";
		rm -rf $_builddir
		if [[ $? -ne 0 ]]; then
			ag::err "failed to remove $_builddir"
			ag::warn "FAILED\n"
		else
			ag::done "DONE\n"
		fi
	fi

    printf "  - creating $_builddir folder: ";
	mkdir $_builddir
	if [[ $? -ne 0 ]]; then
		cd $_olddir
		ag::err "failed to create $_builddir"
		ag::fail "FAILED\n"
		exit 1
	fi
	cd $_builddir
	if [[ $? -ne 0 ]]; then
		cd $_olddir
		ag::err "can't cd to $_builddir"
		ag::fail "FAILED\n"
		exit 1
	fi
	ag::done "DONE\n"

	local _prefixdir=$(ag::get_prefix_path ${PREFIX} $_cfg)
	local _buildtype=$(ag::cmake_generate_config_flag $_cfg)

    $_cmaketool .. \
            -DCMAKE_INSTALL_PREFIX=$_prefixdir \
			$_buildtype \
            -G "Xcode" \
            -DVERMAJOR=${MAJOR} -DVERMINOR=${MINOR} -DVERPATCH=${PATCH} \
			-DTOOLSDIR=${TOOLS} -DVERBOSE=${VERBOSE}

    if [[ $? -ne 0 ]]; then
        cd $_olddir
        ag::err "failed to generate Xcode project"
        ag::fail "FAILED\n"
        exit 1
    fi

    cd $_olddir

	ag::done "SUCCESS\n"
}


# ----------------------------------------------------------------------------


main $@


# tools/bash/autogen-osx-gen.sh
