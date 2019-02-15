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

macro(AG_PrintInfo)
    message(STATUS "AutoGen v${AUTOGEN_VERMAJOR}.${AUTOGEN_VERMINOR}.${AUTOGEN_VERPATCH}")

    set(_platform "Unknown")
    AG_Platform_GetName(_platform)
    message(STATUS "Platform ${_platform} : ${ARCH}")
endmacro()


macro(AG_SetProjectFolder projectname folderpath)
    set(AUTOGEN_${projectname}_FOLDER ${folderpath})
endmacro()


macro(AG_GetProjectFolder projectname outvar)
    set(${outvar} ${AUTOGEN_${projectname}_FOLDER})
endmacro()


macro(AG_PrintProjectInfo projectname)
    message(STATUS "Project : ${projectname} v.${${projectname}_VERSION_MAJOR}.${${projectname}_VERSION_MINOR}.${${projectname}_VERSION_PATCH}")
    message(STATUS "Prefix  : ${CMAKE_INSTALL_PREFIX}")

    set(_root "")
    AG_GetProjectFolder(${projectname} _root)
    message(STATUS "Folder  : ${_root}")
endmacro()


macro(AG_FilterPlatformSources itemsvar filter)
    set(_platform "unknown")
    AG_Platform_GetShortName(_platform)
    message(STATUS "Selecting ${_platform} sources using filter ${filter}")

    set(_platform_sources "")
    set(_sources "")

    foreach (item ${${itemsvar}})
        if (${VERBOSE})
            message(STATUS "*** regarding ${item}")
        endif()
        if (${item} MATCHES "^(.+(platform).+[.](${filter}))$")
            if (${VERBOSE})
                message(STATUS "*** checking ${item}")
            endif()
            if (${item} MATCHES "^(.+(platform)[/](${_platform}).+[.](${filter}))$")
                if (${VERBOSE})
                    message(STATUS "*** selected ${item}")
                endif()
                list(APPEND _platform_sources ${item})
            endif()
        else()
            list(APPEND _sources ${item})
        endif()
    endforeach()

    set(${itemsvar} ${_sources} ${_platform_sources})
endmacro()


macro(AG_AddTargetItems target type folder filter)
    string(TOUPPER ${type} _type_u)
    string(TOLOWER ${type} _type_l)

    file(GLOB_RECURSE _allitems "${folder}/*.*")
    set(_items "")
    foreach(item ${_allitems})
        if (${item} MATCHES "^(.+[.](${filter}))$")
            list(APPEND _items ${item})
        endif()
    endforeach()

    AG_FilterPlatformSources(_items ${filter})

    list(LENGTH _items _items_nb)
    message(STATUS "Added ${_items_nb} files of type ${type} from ${folder} to ${target}")
    if (${VERBOSE})
        message(STATUS "*** ${type} : ${_items}")
    endif()

    if (${CMAKE_VERSION} VERSION_LESS "3.8.0")
        source_group("[${_type_l}]" FILES ${_items})
    else()
        source_group(TREE ${folder} PREFIX "[${_type_l}]" FILES ${_items})
    endif()

    target_sources(${target} PRIVATE ${_items})

    AG_DefineTargetProperty(${_type_u}_ITEMS)
    foreach(item ${_items})
        AG_AppendCustomTargetProperty(${target} ${_type_u}_ITEMS ${item})
    endforeach()
endmacro()


macro(AG_GetTargetItems target type outvar)
    string(TOUPPER ${type} _type_u)
    AG_GetCustomTargetProperty(${target} ${_type_u}_ITEMS ${outvar})
endmacro()


macro(AG_AddGeneratedSource target template dest outvar)
    set(_templatepath "${TOOLSDIR}/templates/cpp")
    AG_TryGetProperty(${target} PARENT_SCOPE _parent_scope)
    if (NOT _parent_scope)
        set(TARGET_PARENT ${target})
        string(TOUPPER ${TARGET_PARENT} TARGET_PARENT_U)
        string(TOLOWER ${TARGET_PARENT} TARGET_PARENT_L)

        set(_templatepath "${TOOLSDIR}/templates/cpp/nparent")
    else()
        set(TARGET_PARENT ${_parent_scope})
        string(TOUPPER ${TARGET_PARENT} TARGET_PARENT_U)
        string(TOLOWER ${TARGET_PARENT} TARGET_PARENT_L)

        set(_templatepath "${TOOLSDIR}/templates/cpp/wparent")
    endif()

    set(TARGET_NAME ${target})
    string(TOUPPER ${TARGET_NAME} TARGET_NAME_U)
    string(TOLOWER ${TARGET_NAME} TARGET_NAME_L)

    set(${outvar} "${CMAKE_CURRENT_BINARY_DIR}/sources/${target}/${dest}")
    if (${VERBOSE})
        message(STATUS "*** conf ${_templatepath}/${template} to ${${outvar}}")
    endif()
    configure_file("${_templatepath}/${template}" "${${outvar}}")

    target_sources(${target} PRIVATE "${${outvar}}")
    source_group("[generated]" FILES "${${outvar}}")
endmacro()
