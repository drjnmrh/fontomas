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

