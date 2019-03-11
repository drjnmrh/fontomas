#!/bin/bash

# AutoGen Bash Linux utils script.
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

ag::get_build_folder_name() {
	local _config=$1

	local _builddir="build.linux"

	case $_config in
		Release|release)
			_builddir="$_builddir.release";;
		Debug|debug)
			_builddir="$_builddir.debug";;
		All|all)
			_builddir="$_builddir";;
		*)
			return;;
	esac

	echo $_builddir
}


ag::get_prefix_path() {
    local _prefix=$1
    local _config=$2

    echo $_prefix/linux
}

# tools/bash/autogen-utils-linux.sh
