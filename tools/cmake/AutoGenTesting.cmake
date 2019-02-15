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

macro(AG_EnableTargetTesting)
    AG_DefineTargetProperty(TESTS_LIST)

    enable_testing()
endmacro()


macro(AG_AddTargetTest target testname itemsvar)
    AG_Platform_AddExecutableTarget(${testname} ${itemsvar})
    AG_Platform_LinkTargetToExecutable(${testname} ${target})

    AG_Platform_AddTest(${testname})

    AG_AppendCustomTargetProperty(${target} TESTS_LIST ${testname})
endmacro()


macro(AG_AttachTestData testname datapath)
    AG_Platform_AddExecutableResources(${testname} ${datapath})
endmacro()


# AutoGenTesting.cmake
