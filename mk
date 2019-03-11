#!/bin/bash

MYDIR="$(cd "$(dirname "$0")" && pwd)"
TOOLS=${MYDIR}/tools
ROOT=${MYDIR}
CONFIG="all"
PLATFORM="osx"
VERBOSE=0
DEVELOP=0
BUILDNUMBER="1"
DONTS=""

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
	echo "  ./mk <platform> [options]"
	echo ""
    echo "Specify the target platform (osx, linux, android, ios)."
	echo ""
	echo "Options:"
	echo "  -v, --verbose                   = enable verbose mode"
    echo "  --develop                       = enable development mode"
	echo "  -h, --help                      = show this help"
    echo "  --buildno <build number>        = specify a build number"
    echo "  --dont <phase name>             = exclude phase (generate, build, test)"
	echo "  --tools <path/to/tools>         = specify a path to the AutoGen tools folder"
	echo "  --config <configuration>        = specify a build configuration ('release', 'debug', 'all' - default)"
	echo ""
	echo "Examples:"
	echo ""
	echo "  ./mk osx --buildno 256"
	echo ""

	exit 0
}

#######################################################################
# Parses arguments and sets global variables according values of these
# arguments.
# Globals:
#   PLATFORM, VERBOSE, BUILDNUMBER
# Arguments:
#   arguments to the script to parse
# Returns:
#   None
#######################################################################
parse_args() {
	local _defaultTools=1

	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
		help
	fi

	PLATFORM="$1"
    if [[ ! "${PLATFORM}" ]]; then
        echo "platform is required (see --help for more information)" >&2
		exit 1
    fi

    shift

	while [[ "$#" > 0 ]]; do case $1 in
	-v|--verbose) VERBOSE=1;;
    --develop) DEVELOP=1;;
    --dont) DONTS="$DONTS --dont $2"; shift;;
	-h|--help) help;;
    --buildno) BUILDNUMBER=$2; shift;;
	--tools) TOOLS=$2; _defaultTools=0; shift;;
	--config) CONFIG=$2; shift;;
	*) echo "Unknown parameter passed: $1" >&2; exit 1;;
	esac; shift; done

	if [[ $VERBOSE -eq 1 ]]; then
		echo "VERBOSE mode is ON"
	fi

    if [[ $DEVELOP -eq 1 ]]; then
		echo "DEVELOPMENT mode is ON"
	fi

	if [[ $_defaultTools -eq 1 ]]; then
        TOOLS=${ROOT}/tools
    fi
}


#######################################################################
# The main function of the script. Executes the corresponding AutoGen
# mk script for the specified platform.
# Globals:
#   PLATFORM, VERBOSE, BUILDNUMBER
# Arguments:
#   arguments to the script to parse
# Returns:
#   None
#######################################################################
main() {
    local _oldDir=${PWD}

	parse_args $@

    cd ${MYDIR}

	local _verboseflag=""
	if [[ $VERBOSE -eq 1 ]]; then
		_verboseflag="--verbose"
	fi

    local _developflag=""
	if [[ $DEVELOP -eq 1 ]]; then
		_developflag="--develop"
	fi

	${TOOLS}/bash/autogen-${PLATFORM}-mk.sh --config ${CONFIG} --tools ${TOOLS} --root ${MYDIR} --buildno ${BUILDNUMBER} $_verboseflag $_developflag ${DONTS}

    cd $_oldDir
    exit 0
}


# ---------------------------------------------------------------------------


main $@


# mk
