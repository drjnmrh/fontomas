# AutoGen CMake scripts.
# Copyright (C) 2019  O.Z.
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

macro(AG_Platform_Init)
endmacro()


macro(AG_Platform_GetName outvar)
    set(${outvar} "OSX")
endmacro()


macro(AG_Platform_GetShortName outvar)
    set(${outvar} "macos")
endmacro()


macro(AG_Platform_AddStaticLibrary target)
    add_library(${target} STATIC)
endmacro()


macro(AG_Platform_SetupTargetFlags target)
    target_compile_options(${target} PUBLIC
        $<$<COMPILE_LANGUAGE:CXX>:-std=c++1z>
        $<$<COMPILE_LANGUAGE:C>:-std=c99>
    )

    target_compile_options(${target} PUBLIC
        $<$<CONFIG:Debug>:-rdynamic>
    )
    set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} -rdynamic")

    target_compile_options(${target} PUBLIC
        $<$<CONFIG:Release>:-Ofast $<$<COMPILE_LANGUAGE:CXX>:-fno-rtti> >
    )

    target_compile_definitions(${target} PRIVATE
        OPENGL_HEADER=<GL/glew.h>
    )

    target_compile_definitions(${target} PRIVATE PLATFORM_MACOS)
endmacro()


macro(AG_Platform_AddExecutableTarget target itemsvar)
    add_executable(${target} ${${itemsvar}})
    set_target_properties(${target} PROPERTIES
        XCODE_ATTRIBUTE_LD_RUNPATH_SEARCH_PATHS	"@executable_path"
    )
    target_link_libraries(${target} pthread)
endmacro()


macro(AG_Platform_LinkTargetToExecutable executable target)
    AG_GetCustomTargetProperty(${target} HEADERSDIR _headersdir)

    target_include_directories(${executable} PRIVATE ${_headersdir})
    target_include_directories(${executable} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/sources)

    target_link_libraries(${executable} ${target})

    AG_GetCustomTargetProperty(${target} LINKED_LIBS _libs)

    foreach(item ${_libs})
        target_link_libraries(${executable} ${item})
    endforeach()
endmacro()


macro(AG_Platform_AddTest testname)
    add_test(${testname}_test ${testname})
endmacro()


macro(AG_Platform_AddExecutableResources executable datapath)
    get_filename_component(_foldername ${datapath} NAME)

    add_custom_command(TARGET ${executable} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/${_foldername}
    )

    add_custom_command(TARGET ${executable} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${datapath}/ ${CMAKE_CURRENT_BINARY_DIR}/${_foldername}
    )
endmacro()


macro(AG_Platform_LinkUiLibraries target)
    # as UI framework, the GLFW3 is used; in order to use this
    # library, GLFW3 must be install (this can be done using homebrew)

    find_package(PkgConfig REQUIRED)

    pkg_check_modules(GLFW REQUIRED glfw3)

    if (${VERBOSE})
        message(STATUS "*** GLFW includes      : ${GLFW_INCLUDE_DIRS}")
        message(STATUS "*** GLFW libraries dirs: ${GLFW_LIBRARY_DIRS}")
        message(STATUS "*** GLFW flags         : ${GLFW_CFLAGS_OTHER}")
        message(STATUS "*** GLFW libraries     : ${GLFW_LIBRARIES}")
    endif()

    include_directories(${GLFW_INCLUDE_DIRS})
    link_directories   (${GLFW_LIBRARY_DIRS})
    add_definitions    (${GLFW_CFLAGS_OTHER})

    target_link_libraries(${target} ${GLFW_LIBRARIES})

    foreach(item ${GLFW_LIBRARIES})
        AG_AppendCustomTargetProperty(${target} LINKED_LIBS ${item})
    endforeach()
endmacro()


# platform/AutoGenOsx.cmake
