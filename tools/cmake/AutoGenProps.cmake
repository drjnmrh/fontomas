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
#
# contains utils for custom target properties processing


# prepares custom properties global info
macro(AG_InitProps)
    set(AUTOGEN_GLOBAL_PROPERTIES_LIST "" CACHE STRING "AutoGen custom properties list")
endmacro()



# prints values of all custom properties values of the specified target
# @params target - name of the target
macro(AG_PrintCustomTargetProperties target)
    message(STATUS "Custom properties of ${target}:")
    foreach(item ${UG_GLOBAL_PROPERTIES_LIST})
        AG_GetCustomTargetProperty(${target} ${item} _value)
        message(STATUS " - ${target}::${item} == ${_value}")
    endforeach()
endmacro()



# checks if custom property has been defined
# @params propertyname - name of the property
#         outvar       - result output variable (ON if defined)
macro(AG_IsPropertyDefined propertyname outvar)
    if (NOT DEFINED PROJECT_${propertyname}_DEF)
        set(${outvar} OFF)
    elseif (NOT PROJECT_${propertyname}_DEF)
        set(${outvar} OFF)
    else ()
        set(${outvar} ON)
    endif()
endmacro()



# defines custom target property
# @params propertyname - name of the property
macro(AG_DefineTargetProperty propertyname)
    AG_IsPropertyDefined(${propertyname} _is_def)
    if (NOT _is_def)
        define_property(TARGET PROPERTY ${propertyname}
            BRIEF_DOCS "project ${propertyname} custom prop"
            FULL_DOCS  "project ${propertyname} custom prop"
        )
        set(PROJECT_${propertyname}_DEF ON CACHE BOOL "${propertyname} PROP defined")
        list(APPEND UG_GLOBAL_PROPERTIES_LIST "${propertyname}")
    endif()
endmacro()



# tries to get value of the custom target property
# @params target       - target name
#         propertyname - name of the property
#         outvar       - variable to output result to (OFF if no such property)
macro(AG_TryGetProperty target propertyname outvar)
    AG_IsPropertyDefined(${propertyname} _is_def)
    if (_is_def)
        get_property(_is_set TARGET ${target} PROPERTY ${propertyname} DEFINED)
        if (_is_set)
            get_property(${outvar} TARGET ${target} PROPERTY ${propertyname})
        else()
            set(${outvar} OFF)
        endif()
    else()
        set(${outvar} OFF)
    endif()
endmacro()


# tries to get value of the custom target property
# @params target       - target name
#         propertyname - name of the property
#         outvar       - variable to output result to (empty if no such property)
macro(AG_GetCustomTargetProperty target propertyname outvar)
    AG_IsPropertyDefined(${propertyname} _is_def)
    if (_is_def)
        get_property(_is_set TARGET ${target} PROPERTY ${propertyname} DEFINED)
        if (_is_set)
            get_property(${outvar} TARGET ${target} PROPERTY ${propertyname})
        else()
            set(${outvar} "")
        endif()
    else()
        set(${outvar} "")
    endif()
endmacro()



# sets value of the custom target property for the specified target;
# if property doesn't exist, defines it.
# @param target       - target name
#        propertyname - name of the custom property
#        value        - value for the property
macro(AG_SetCustomTargetProperty target propertyname value)
    AG_DefineTargetProperty(${propertyname})
    set_property(TARGET ${target} PROPERTY ${propertyname} "${value}")
endmacro()



# appends value to the custom target property for the specified target;
# if property doesn't exist, defines it.
# @param target       - target name
#        propertyname - name of the custom property
#        value        - value to append for the property
macro(AG_AppendCustomTargetProperty target propertyname value)
    AG_GetCustomTargetProperty(${target} ${propertyname} _old_value)
    list(APPEND _old_value ${value})
    AG_SetCustomTargetProperty(${target} ${propertyname} "${_old_value}")
endmacro()


# AutoGenProps.cmake
