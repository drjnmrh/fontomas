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


set(AUTOGEN_VERMAJOR "0")
set(AUTOGEN_VERMINOR "1")
set(AUTOGEN_VERPATCH "0")


macro(autogen_init)
    if (NOT DEFINED AUTOGEN_WAS_INIT)
        set(AUTOGEN_WAS_INIT OFF CACHE BOOL "was AutoGen initialized")
    endif()

    if (NOT AUTOGEN_WAS_INIT)

        if (${VERBOSE})
            message(STATUS "*** Verbose Mode ON")
        endif()

        include(AutoGenProps)
        AG_InitProps()

        include(AutoGenPlatform)
        AG_DetectPlatform()

        AG_InitPlatformImpl()

        include(AutoGenUtils)
        AG_PrintInfo()

        include(AutoGenTesting)
        AG_EnableTargetTesting()

        set(AUTOGEN_WAS_INIT TRUE)

    endif()
endmacro()


macro(autogen_setup_project projectname)
    autogen_init()

    project(${projectname} LANGUAGES CXX C
            VERSION ${VERMAJOR}.${VERMINOR}.${VERPATCH})

    AG_SetProjectFolder(${projectname} ${CMAKE_CURRENT_SOURCE_DIR})

    AG_PrintProjectInfo(${projectname})
endmacro()


macro(autogen_add_static_library target headersdir sourcesdir)
    autogen_init()

    AG_Platform_AddStaticLibrary(${target})

    AG_AddTargetItems(${target} headers ${CMAKE_CURRENT_SOURCE_DIR}/${headersdir} "(h)|(hpp)")
    AG_AddTargetItems(${target} sources ${CMAKE_CURRENT_SOURCE_DIR}/${sourcesdir} "(c)|(cpp)|([m]+)")

    AG_SetCustomTargetProperty(${target} HEADERSDIR ${CMAKE_CURRENT_SOURCE_DIR}/${headersdir})
    AG_SetCustomTargetProperty(${target} SOURCESDIR ${CMAKE_CURRENT_SOURCE_DIR}/${sourcesdir})

    target_include_directories(${target} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/${headersdir})
    target_include_directories(${target} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/${headersdir}/${target})
    target_include_directories(${target} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/sources)
endmacro()


macro(autogen_set_target_parent_scope target scope)
    autogen_init()

    AG_SetCustomTargetProperty(${target} PARENT_SCOPE ${scope})
endmacro()


macro(autogen_setup_target_flags target striptool)
    autogen_init()

    target_compile_definitions(${target} PUBLIC
        $<$<CONFIG:Debug>:DEBUG _DEBUG>
        $<$<CONFIG:Release>:NDEBUG _NDEBUG>
    )

    AG_Platform_SetupTargetFlags(${target})

    get_target_property(_type ${target} TYPE)
    if (_type STREQUAL "SHARED_LIBRARY")
        target_compile_definitions(${target} PRIVATE ${target}_API)
    endif()

    target_compile_definitions(${target} PRIVATE MODULE=${target})

    if (EXISTS ${striptool})
        message(STATUS "Adding striping the result using ${striptool}")
        add_custom_command(TARGET ${target} POST_BUILD
            COMMAND ${striptool} $<TARGET_FILE:${target}>
        )
    endif()
endmacro()


macro(autogen_add_export_macros target)
    autogen_init()

    AG_TryGetProperty(${target} EXPORT_MACROS _export_macros)
    if (NOT _export_macros)
        set(_template_name "exports.h.static.in")

        get_target_property(_type ${target} TYPE)
        if (_type STREQUAL "SHARED_LIBRARY")
            set(_template_name "exports.h.shared.in")
        endif()

        AG_AddGeneratedSource(${target} ${_template_name} exports.h _sourcepath)

        AG_SetCustomTargetProperty(${target} EXPORT_MACROS ${_sourcepath})
    endif()
endmacro()


macro(autogen_add_version_sources target)
    autogen_init()

    AG_TryGetProperty(${target} VERSION_HEADER _version_header)
    if (NOT _version_header)
        autogen_add_export_macros(${target})

        AG_AddGeneratedSource(${target} "version.h.in" "version.h" _version_hdr)
        AG_AddGeneratedSource(${target} "version.cpp.in" "version.cpp" _version_src)

        AG_SetCustomTargetProperty(${target} VERSION_HEADER ${_version_hdr})
    endif()
endmacro()


macro(autogen_link_ui target)
    autogen_init()

    AG_Platform_LinkUiLibraries(${target})
endmacro()


macro(autogen_add_test target testname sourcespath datapath)
    autogen_init()

    if (${VERBOSE})
        message(STATUS "*** add_test ${target} ${testname} ${sourcespath} ${datapath}")
    endif()

    file(GLOB_RECURSE _allitems "${CMAKE_CURRENT_SOURCE_DIR}/${sourcespath}/*.*")
    set(_items "")
    foreach(item ${_allitems})
        if (${item} MATCHES "^(.+[.]((c)|(cpp)|([m]+)|(h)))$")
            list(APPEND _items ${item})
        endif()
    endforeach()

    AG_FilterPlatformSources(_items "(c)|(cpp)|([m]+)|(h)")

    if (${CMAKE_VERSION} VERSION_LESS "3.8.0")
        source_group("[sources]" FILES ${_items})
    else()
        source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR}/${sourcespath} PREFIX "[sources]" FILES ${_items})
    endif()

    AG_AddTargetTest(${target} ${testname} _items)

    target_include_directories(${testname} PRIVATE ${sourcespath})

    if (EXISTS ${datapath})
        AG_AttachTestData(${testname} ${datapath})
    endif()
endmacro()


macro(autogen_setup_install target)
    autogen_init()

    if (${VERBOSE})
        AG_PrintCustomTargetProperties(${target})
    endif()

    AG_GetCustomTargetProperty(${target} HEADERSDIR _headersdir)
    if (NOT _headersdir)
        message(FATAL_ERROR "Can't setup ${target} install : headers folder wasn't set")
    endif()

    AG_GetCustomTargetProperty(${target} SOURCESDIR _sourcesdir)
    if (NOT _sourcesdir)
        message(FATAL_ERROR "Can't setup ${target} install : sources folder wasn't set")
    endif()

    target_include_directories(${target} PUBLIC
        $<BUILD_INTERFACE:${_headersdir}>
        $<INSTALL_INTERFACE:include>
        PRIVATE ${_sourcesdir}
    )

    install(TARGETS ${target} EXPORT ${target}-targets
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION bin
        RUNTIME DESTINATION bin
        BUNDLE  DESTINATION bin
        FRAMEWORK DESTINATION fwk
    )

    AG_GetTargetItems(${target} headers _headers)

    foreach (item ${_headers})
        if (${item} MATCHES "^(.+(private).+[.]((h)|(hpp)))$")
        else()
            file(RELATIVE_PATH _relpath ${_headersdir} ${item})
            get_filename_component(_relpath ${_relpath} DIRECTORY)

            install(FILES ${item} DESTINATION include/${_relpath})
        endif()
    endforeach()

    AG_TryGetProperty(${target} VERSION_HEADER _version_hdr)
    if (_version_hdr)
        message(STATUS "install: ${_version_hdr} to include/${target}")
        install(FILES ${_version_hdr} DESTINATION include/${target})
    else()
        message(STATUS "install: no version source files generated")
    endif()

    AG_TryGetProperty(${target} EXPORT_MACROS _exports_macros)
    if (_exports_macros)
        message(STATUS "install: ${_exports_macros} to include/${target}")
        install(FILES ${_exports_macros} DESTINATION include/${target})
    else()
        message(STATUS "install: no exports macros files generated")
    endif()

    # This makes the project importable from the install directory
    # Put config file in per-project dir (name MUST match), can also
    # just go into 'cmake'.
    install(EXPORT ${target}-targets FILE ${target}-config.cmake
            DESTINATION share/${target}/cmake)

    # This makes the project importable from the build directory
    export(TARGETS ${target} FILE ${target}-config.cmake)
endmacro()


# AutoGen.cmake
