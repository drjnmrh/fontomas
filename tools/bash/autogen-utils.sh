#!/bin/bash

ag::fail() {
	printf "\033[31m$1\033[0m" ${@:2};
}


ag::info() {
	printf "\033[34m$1\033[0m" ${@:2};
}


ag::warn() {
	printf "\033[33m$1\033[0m" ${@:2};
}


ag::done() {
	printf "\033[32m$1\033[0m" ${@:2};
}


ag::err() {
	echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}


ag::cmake_generate_config_flag() {
    local _config=$1

    case $_config in
		Release|release) echo "-DCMAKE_BUILD_TYPE=Release";;
		Debug|debug)     echo "-DCMAKE_BUILD_TYPE=Debug";;
		*) 			     echo "";;
	esac
}


ag::cmake_build_config_flag() {
    local _config=$1

    case $_config in
		Release|release) echo "--config Release";;
		Debug|debug)     echo "--config Debug";;
		*) 			     echo "";;
	esac
}


ag::cmake_install_config_flag() {
    local _config=$1

    case $_config in
		Release|release) echo "-DBUILD_TYPE=\"Release\"";;
		Debug|debug)     echo "-DBUILD_TYPE=\"Debug\"";;
		*) 			     echo "";;
	esac
}


ag::cmake_test_config_flag() {
    local _config=$1

    case $_config in
		Release|release) echo "-C Release";;
		Debug|debug)     echo "-C Debug";;
		*) 			     echo "";;
	esac
}


################################################################
# Gets major version number from the given Git tag
# Globals:
#   None
# Arguments:
#   Version from the Git tag.
# Returns:
#   major version number if succeeded, nothing otherwise.
################################################################
ag::parse_major_number() {
    local gittag=$1
    local major=$(echo ${gittag} \
        | sed -E s/v//g \
        | sed -E s/\([.][0-9]*[.][0-9]*\)\([-a-z0-9]*\)$//g)
    if [[ $? -ne 0 ]]; then
        echo ""
    else
        echo ${major}
    fi
}


################################################################
# Gets minor version number from the given Git tag
# Globals:
#   None
# Arguments:
#   Version from the Git tag.
# Returns:
#   minor version number if succeeded, empty string otherwise.
################################################################
ag::parse_minor_number() {
    local gittag=$1
    local minor=$(echo ${gittag} \
        | sed -E s/\(v.[0-9]*.\)//g \
        | sed -E s/\([.][0-9]*\)\([-a-z0-9]*\)$//g)
    if [[ $? -ne 0 ]]; then
        echo ""
    else
        echo ${minor}
    fi
}


################################################################
# Gets patch version number from the given Git tag
# Globals:
#   None
# Arguments:
#   Version from the Git tag.
# Returns:
#   patch version number if succeeded, empty string otherwise.
################################################################
ag::parse_patch_number() {
    local gittag=$1
    local patch=$(echo ${gittag} \
        | sed -E s/\(v.[0-9]*.[0-9]*.\)//g \
        | sed -E s/\([-a-z]\)\([-a-z0-9]*\)$//g)
    if [[ $? -ne 0 ]]; then
        echo ""
    else
        echo ${patch}
    fi
}


################################################################
# Parses Git Tag of the current module in order to get version.
# If DEVELOP variable is 1, than in case of failure, the version
# is set to the 0.0.1.
# Uses AutoGen CMake & Bash Utils.
# Sets MAJOR, MINOR and PATCH global variables.
# Globals:
#   MAJOR, MINOR, PATCH, DEVELOP
# Arguments:
#   None
# Returns:
#   0 if succeeded, 1 otherwise
################################################################
ag::parse_version() {
	ag::info "parsing version from Git tag "

	local gittag=$(git describe --tags)
	if [[ $? -ne 0 ]]; then
		if [[ ${DEVELOP} -eq 1 ]]; then
			ag::warn "FAILED\n"
			ag::info "Using the development version v0.0.1\n"
			MAJOR="0"
			MINOR="0"
			PATCH="1"
			return 0
		fi

		ag::err "failed to get current Git tag"
		ag::fail "FAILED\n"
		return 1
	fi

	ag::info "$gittag: "

	local major=$(ag::parse_major_number $gittag)
	if [[ -z "$major" ]]; then
		if [[ ${DEVELOP} -eq 1 ]]; then
			ag::warn "failed to parse the major version number\n"
			ag::info "Using the development version v0.0.1\n"
			MAJOR="0"
			MINOR="0"
			PATCH="1"
			return 0
		fi

		ag::err "failed to parse major version number from $gittag"
		ag::fail "FAILED\n"
		return 1
	fi

	local minor=$(ag::parse_minor_number $gittag)
	if [[ -z "$minor" ]]; then
		if [[ ${DEVELOP} -eq 1 ]]; then
			ag::warn "failed to parse the minor version number\n"
			ag::info "Using the development version v0.0.1\n"
			MAJOR="0"
			MINOR="0"
			PATCH="1"
			return 0
		fi

		ag::err "failed to parse minor version number from $gittag"
		ag::fail "FAILED\n"
		return 1
	fi

	local patch=$(ag::parse_patch_number $gittag)
	if [[ -z "$patch" ]]; then
		if [[ ${DEVELOP} -eq 1 ]]; then
			ag::warn "failed to parse the patch version number\n"
			ag::info "Using the development version v0.0.1\n"
			MAJOR="0"
			MINOR="0"
			PATCH="1"
			return 0
		fi

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

