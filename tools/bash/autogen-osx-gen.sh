#!/bin/bash

DEVELOP=0
VERBOSE=0
ROOT=${PWD}
TOOLS=${PWD}/tools
PREFIX=${PWD}/boutput
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
            -G "Xcode" \
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
include_utils

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

