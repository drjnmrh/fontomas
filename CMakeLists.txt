# Fontomas. A font glyphs loading API.
# Copyright (C) 2019  O.Z.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

cmake_minimum_required(VERSION 3.6)

# setup options

option(VERBOSE "enable verbose option on/off" OFF)
option(PUBLISH "generate a build for publishing" OFF)
option(VERMAJOR "set version major value" 0)
option(VERMINOR "set version minor value" 0)
option(VERPATCH "set version patch value" 0)
option(TOOLSDIR "set folder, where cmake utility scripts are" OFF)
option(STRIPTOOL "set strip tool command" OFF)


if(NOT ${VERMAJOR})
    set(VERMAJOR "0")
endif()
if(NOT ${VERMINOR})
    set(VERMINOR "0")
endif()
if(NOT ${VERPATCH})
    set(VERPATCH "0")
endif()

if (${VERBOSE})
    message(STATUS "[${TOOLSDIR}]")
endif()
if (NOT EXISTS ${TOOLSDIR})
    set(TOOLSDIR ${CMAKE_SOURCE_DIR}/tools)
    message(STATUS "Using default tools : ${TOOLSDIR}")
else()
    message(STATUS "Using custom tools : ${TOOLSDIR}")
endif()

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${TOOLSDIR}/cmake)
include(AutoGen)

# setup project

autogen_setup_project(fontomas)


# setup target

set(CMAKE_DEBUG_POSTFIX d)
autogen_add_static_library(fontomas sources/inc sources/src)

autogen_setup_target_flags(fontomas ${STRIPTOOL})
autogen_add_export_macros(fontomas)
autogen_add_version_sources(fontomas)


# linking dependencies


# setup testing

autogen_add_test(fontomas fontomastst sources/tst ${CMAKE_CURRENT_SOURCE_DIR}/data)


# setup installation

autogen_setup_install(fontomas)


# fontomas/CMakeLists.txt
