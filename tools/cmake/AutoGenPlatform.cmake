# AutoGen CMake scripts.
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

# contains utils for platforms info detection, initialization of
# platform-dependent scripts

macro(AG_DetectPlatform)

    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${TOOLSDIR}/cmake/3rdparty)
    include(TargetArch)

    target_architecture(ARCH)

    if (${CMAKE_SYSTEM_NAME} STREQUAL "Android")
        set(${archvar} ${ANDROID_ABI})
        if (NOT DEFINED ANDROID)
            set(ANDROID TRUE)
        elseif (NOT ANDROID)
            set(ANDROID TRUE)
        endif()
    elseif (IOS)
    elseif (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
        if (NOT DEFINED MACOSX)
            set(MACOSX TRUE)
        elseif (NOT MACOSX)
            set(MACOSX TRUE)
        endif()
    elseif (UNIX)
        set(LINUX TRUE)
    endif()

    if (ANDROID)
        set(MOBILE TRUE)
    elseif (IOS)
        set(MOBILE TRUE)
    endif()

endmacro()


macro(AG_InitPlatformImpl)

    if (NOT DEFINED ARCH)
        message(FATAL_ERROR "AutoGen Logic Error: Can't init platform impl without ARCH")
    endif()

    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${TOOLSDIR}/cmake/platform)

    if (ANDROID)
        include(AutoGenAndroid)
    elseif (IOS)
        include(AutoGenIos)
    elseif (MACOSX)
        include(AutoGenOsx)
    elseif (MSVC)
        include(AutoGenMsvc)
    elseif (LINUX)
        include(AutoGenLinux)
    else ()
        message(FATAL_ERROR "AutoGen Error : platform is not supported!")
    endif ()

    AG_Platform_Init()

endmacro()

# AutoGenPlatform.cmake
