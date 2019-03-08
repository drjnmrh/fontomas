#!/bin/bash

DEVELOP=0
VERBOSE=0
ROOT=${PWD}
TOOLS=${PWD}/tools
PREFIX=${PWD}/boutput
CONFIG="release"
DIR_SUFFIX=linux
MAJOR="0"
MINOR="0"
PATCH="1"

###############################################################
# Displays help information for the script
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
###############################################################
help() {
	echo "Usage"
	echo ""
	echo "  ./autogen-linux-gen.sh <config> [options]"
	echo ""
    echo "Specify which config (debug, release) should be generated."
	echo ""
	echo "Options:"
	echo "  -d, --develop                   = all modules are installed in the parent folder"
	echo "  -v, --verbose                   = enable verbose mode"
	echo "  -h, --help                      = show this help"
	echo "  -r, --root <path/to/root>       = specify a path to the folder, which contains modules"
    echo "  --tools <path/to/tools>         = specify a path to the AutoGen tools folder"
	echo ""
	echo "Examples:"
	echo ""
	echo "  ./autogen-linux-gen.sh debug --develop --root .."
	echo ""

	exit 0
}

################################################################
# Checks Ug CMake & Bash utils and includes sources.
# Globals:
#   TOOLS, PWD
# Arguments:
#   None
# Returns:
#   0 if succeeded, 1 otherwise
################################################################
include_utils() {
    local _platform=$1
	local utils=${TOOLS}/bash

	if [[ ! -d "$utils" ]]; then
		printf "WARNING: no utils in $utils - trying the default path\n"
		utils="${PWD}/../tools/bash"
	fi

	if [[ -d "$utils" ]]; then
		printf "found utils in $utils\n"
	else
		echo "no utils in $utils" >&2
		printf "FAILED\n"
		return 1
	fi

	source $utils/autogen-utils.sh
    source $utils/autogen-utils-$_platform.sh

	return 0
}

################################################################
# Parses Git Tag of the current module in order to get version.
# Uses Ug CMake & Bash Utils.
# Sets MAJOR, MINOR and PATCH global variables.
# Globals:
#   MAJOR, MINOR, PATCH
# Arguments:
#   None
# Returns:
#   0 if succeeded, 1 otherwise
################################################################
parse_version() {
	ag::info "parsing version from Git tag "

	local gittag=$(git describe --tags)
	if [[ $? -ne 0 ]]; then
		ag::err "failed to get current Git tag"
		ag::fail "FAILED\n"
		return 1
	fi

	ag::info "$gittag: "

	local major=$(ag::parse_major_number $gittag)
	if [[ -z "$major" ]]; then
		ag::err "failed to parse major version number from $gittag"
		ag::fail "FAILED\n"
		return 1
	fi

	local minor=$(ag::parse_minor_number $gittag)
	if [[ -z "$minor" ]]; then
		ag::err "failed to parse minor version number from $gittag"
		ag::fail "FAILED\n"
		return 1
	fi

	local patch=$(ag::parse_patch_number $gittag)
	if [[ -z "$patch" ]]; then
		ag::err "failed to parse patch version number from $gittag"
		ag::fail "FAILED\n"
		return 1
	fi
	printf "v$major.$minor.$patch "
	ag::done "DONE\n"

	MAJOR=$major
	MINOR=$minor
	PATCH=$patch
	return 0
}

#######################################################################
# Parses arguments and sets global variables according values of these
# arguments.
# Globals:
#   MODULE, PHASE, PLATFORM, DEVELOP, VERBOSE, PREFIX, SERIAL
# Arguments:
#   phase, platform, options
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

	PREFIX=${ROOT}/boutput
}


main() {
    local _cmaketool=cmake
    local _builddir=build.${DIR_SUFFIX}
    local _olddir=${PWD}

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

    $_cmaketool .. \
            -DCMAKE_INSTALL_PREFIX=$PREFIX/$DIR_SUFFIX \
            -G "Unix Makefiles" \
            -DVERMAJOR=${MAJOR} -DVERMINOR=${MINOR} -DVERPATCH=${PATCH} \
			-DTOOLSDIR=$TOOLS -DVERBOSE=$VERBOSE

    if [[ $? -ne 0 ]]; then
        cd $_olddir
        ag::err "failed to generate Xcode project"
        ag::fail "FAILED\n"
        exit 1
    fi

    cd $_olddir

	ag::done "SUCCESS\n"
}


parse_args $@
include_utils linux

OLDWD=${PWD}
cd ${ROOT}
if [[ $? -ne 0 ]]; then
	echo "expected folder ${ROOT}" >&2
	exit 1
fi

parse_version
if [[ $? -ne 0 ]]; then
    if [[ $DEVELOP -eq 1 ]]; then
        MAJOR="0"
        MINOR="0"
        PATCH="1"
    else
        ag::err "failed to get version of the module"
        ag::fail "EPIC FAIL\n"
        cd ${OLDWD}
        exit 1
    fi
fi

main $@

cd ${OLDWD}

