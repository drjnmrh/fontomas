#!/bin/bash

ROOT=${PWD}
VERBOSE=0
DEVELOP=0
BUILDNUMBER="1"
DONTS=()

################################################################
# Checks bash utils and includes sources.
# Globals:
#   PWD, ROOT
# Arguments:
#   platform
# Returns:
#   0 if succeeded, 1 otherwise
################################################################
include_utils() {
	local _platform=$1
    local _utils=${ROOT}/tools/bash

	if [[ ! -d "$_utils" ]]; then
		printf "FAILED: no utils in $_utils!\n"
		return 1
	fi

	source $_utils/autogen-utils-$_platform.sh
	source $_utils/autogen-utils.sh

	return 0
}

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
	echo "  ./autogen-osx-mk.sh [options]"
	echo ""
	echo ""
	echo "Options:"
	echo "  -v, --verbose                   = enable verbose mode"
    echo "  --develop                       = enable development mode"
    echo "  --dont <name of the phasse>     = exclude phase from the process (generate, build, test)"
	echo "  -r, --root <path/to/root>       = specify a path to the folder, which contains sources parent"
	echo "  -h, --help                      = show this help"
    echo "  --buildno <build number>        = specify a build number"
	echo ""
	echo "Examples:"
	echo ""
	echo "  ./autogen-osx-mk.sh --buildno 256"
	echo ""

	exit 0
}

#######################################################################
# Parses arguments and sets global variables according values of these
# arguments.
# Globals:
#   VERBOSE, ROOT, BUILDNUMBER
# Arguments:
#   arguments to the script to parse
# Returns:
#   None
#######################################################################
parse_args() {
    local _dontsCounter=0

    while [[ "$#" > 0 ]]; do case $1 in
	-v|--verbose) VERBOSE=1;;
    --develop) DEVELOP=1;;
    --dont) DONTS[$_dontsCounter]=$2; _dontsCounter=$(($_dontsCounter+1)); shift;;
	-h|--help) help;;
	-r|--root) ROOT=$2; shift;;
    --buildno) BUILDNUMBER=$2; shift;;
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
}

#######################################################################
# The main function of the script. Executes the generation, building and
# testing scripts for the OSX target platform.
# Globals:
#   PLATFORM, VERBOSE, DEVELOP, BUILDNUMBER
# Arguments:
#   arguments to the script to parse
# Returns:
#   None
#######################################################################
main() {
    parse_args $@
    include_utils osx

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
        ./tools/bash/autogen-osx-gen.sh $_verbose --root ${ROOT} $_develop
        if [[ $? -ne 0 ]]; then
            ag::fail "EPIC FAIL\n"
            cd $_oldDir
            exit 1
        fi
    fi

    if [[ $_needBuild -eq 1 ]]; then
        ./tools/bash/autogen-osx-build.sh $_verbose --root ${ROOT} $_develop
        if [[ $? -ne 0 ]]; then
            ag::fail "EPIC FAIL\n"
            cd $_oldDir
            exit 1
        fi
    fi

    if [[ $_needTest -eq 1 ]]; then
        ./tools/bash/autogen-osx-test.sh $_verbose --root ${ROOT} $_develop
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


# tools/bash/autogen-osx-mk.sh
