#!/bin/bash

DEVELOP=0
VERBOSE=0
ROOT=${PWD}
TOOLS=${PWD}/tools
PREFIX=${PWD}/boutput
CONFIG="debug"
DIR_SUFFIX=osx
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
	echo "  mk <module> <phase> <platform> [options]"
	echo ""
	echo "Specify which module, which phase of the make process"
	echo "should be executed and for which platform the module"
	echo "should be built."
	echo "Phases : depends, build, test, deploy."
	echo "Platforms : android, ios"
	echo ""
	echo "Options:"
	echo "  -d, --develop                   = all modules are installed in the parent folder"
	echo "  -v, --verbose                   = enable verbose mode"
	echo "  -h, --help                      = show this help"
	echo "  -r, --root <path/to/root>       = specify a path to the folder, which contains modules"
	echo "  -s, --serial <device_serial>    = specify a serial number of the device to run tests on (default is emulator)"
	echo "  --strip                         = strip built result artifact"
	echo "  -j, --jobs <number of jobs>     = specify a number of jobs used for the build"
	echo "  --only-debug                    = build only Debug configuration"
	echo "  --only-build					= don't generate project, only run make"
	echo "  --only-generate				    = don't build project, just generate project"
	echo ""
	echo "Examples:"
	echo ""
	echo "  ./mk testing test android --develop --root .. --serial ce12171ca36a2e1601"
	echo "  ./mk commons build android --develop --root .."
	echo "  make_scripts/mk commons build android"
	echo ""

	exit 0
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
	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
		help
	fi
	if [[ "$2" == "--help" ]] || [[ "$2" == "-h" ]]; then
		help
	fi
	if [[ "$3" == "--help" ]] || [[ "$3" == "-h" ]]; then
		help
	fi

	while [[ "$#" > 0 ]]; do case $1 in
	-d|--develop) DEVELOP=1;;
	-v|--verbose) VERBOSE=1;;
	-h|--help) help;;
	-r|--root) ROOT=$2; shift;;
    --config) CONFIG=$2; shift;;
	--tools) TOOLS=$2; shift;;
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

	PREFIX=${ROOT}/boutput
}


################################################################
# Checks Ug CMake & Bash utils and includes sources.
# Sets UTILS global variable.
# Globals:
#   PREFIX, DEVELOP, PWD, MODULE
# Arguments:
#   None
# Returns:
#   0 if succeeded, 1 otherwise
################################################################
include_utils() {
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

	UTILS=$utils
	return 0
}


main() {
    local _cmaketool=cmake
    local _builddir=build.${DIR_SUFFIX}
    local _olddir=${PWD}
    local _module=${ROOT##*/}

    cd ${ROOT}
    if [[ $? -ne 0 ]]; then
        ag::err "expected folder ${ROOT}" >&2
        ag::failed "FAILED\n"
        exit 1
    fi

    cd $_builddir
	if [[ $? -ne 0 ]]; then
		cd $_olddir
		ag::err "can't cd to $_builddir (generate project first)"
		ag::fail "FAILED\n"
		exit 1
	fi

    case $CONFIG in
		Release|release)
			ag::info "** run tests for '$_module' ($DIR_SUFFIX/release) **\n";

			ctest -C Release --verbose
            if [[ $? -ne 0 ]]; then
                cd $_olddir
                ag::err "tests failed"
                ag::fail "FAILED\n"
                exit 1
            fi
			;;
		Debug|debug)
			ag::info "** run tests for '$_module' ($DIR_SUFFIX/debug) **\n";

			ctest -C Debug --verbose
            if [[ $? -ne 0 ]]; then
                cd $_olddir
                ag::err "tests failed"
                ag::fail "FAILED\n"
                exit 1
            fi
			;;
		*)
			cd $_olddir
			ag::err "unknown config $_config"
			ag::fail "FAILED\n"
			exit 1
			;;
	esac

    ag::done "DONE\n"

    cd $_olddir
    exit 0
}


parse_args $@
include_utils

main
