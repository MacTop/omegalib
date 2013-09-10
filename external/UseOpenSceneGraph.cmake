###############################################################################
# THE OMEGA LIB PROJECT
#-----------------------------------------------------------------------------
# Copyright 2010-2013		Electronic Visualization Laboratory, 
#							University of Illinois at Chicago
# Authors:										
#  Alessandro Febretti		febret@gmail.com
#-----------------------------------------------------------------------------
# Copyright (c) 2010-2013, Electronic Visualization Laboratory,  
# University of Illinois at Chicago
# All rights reserved.
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
# 
# Redistributions of source code must retain the above copyright notice, this 
# list of conditions and the following disclaimer. Redistributions in binary 
# form must reproduce the above copyright notice, this list of conditions and 
# the following disclaimer in the documentation and/or other materials provided 
# with the distribution. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE  GOODS OR 
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###############################################################################
include(ExternalProject)

set(OMEGA_USE_EXTERNAL_OSG false CACHE BOOL "Enable to use an external osg build instead of the built-in one.")
if(OMEGA_USE_EXTERNAL_OSG)
	# When using external osg builds, for now you need to make sure manually the OSG binary
	# include dir is in the compiler include search, paths otherwise osgWorks won't compile.
	# I may find a better solution for this in the future but it's not really high priority.
	set(OMEGA_EXTERNAL_OSG_BINARY_PATH CACHE PATH "The external osg build path")
	set(OMEGA_EXTERNAL_OSG_SOURCE_PATH CACHE PATH "The external osg source path")
    set(EXTLIB_DIR ${OMEGA_EXTERNAL_OSG_BINARY_PATH})
    set(OSG_BINARY_DIR ${OMEGA_EXTERNAL_OSG_BINARY_PATH})
else()
    set(OSG_BASE_DIR ${CMAKE_BINARY_DIR}/src/osg-prefix/src)
    set(OSG_BINARY_DIR ${OSG_BASE_DIR}/osg-build)
    set(OSG_SOURCE_DIR ${OSG_BASE_DIR}/osg)
endif()

if(NOT OSMEGA_USE_EXTERNAL_OSG)
	if(MSVC OR CMAKE_GENERATOR STREQUAL "Xcode")
		ExternalProject_Add(
			osg
			URL ${CMAKE_SOURCE_DIR}/external/osg.tar.gz
			CMAKE_ARGS 
				-DCMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG}
				-DCMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE}
				-DCMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG}
				-DCMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE}
				-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE:PATH=${CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE}
				-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG:PATH=${CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG}
			INSTALL_COMMAND ""
			)
	elseif(OMEGA_OS_LINUX)
		ExternalProject_Add(
			osg
			URL ${CMAKE_SOURCE_DIR}/external/osg.tar.gz
			CMAKE_ARGS 
				-DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/osg
				-DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/osg
				-DCMAKE_LIBRARY_OUTPUT_DIRECTORY:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/osg
				-DCMAKE_LIBRARY_OUTPUT_DIRECTORY:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/osg
				-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH=${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/osg
				-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH=${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/osg
			INSTALL_COMMAND ""
			)
	else()
		ExternalProject_Add(
			osg
			URL ${CMAKE_SOURCE_DIR}/external/osg.tar.gz
			CMAKE_ARGS 
				-DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
				-DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
				-DCMAKE_LIBRARY_OUTPUT_DIRECTORY:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
				-DCMAKE_LIBRARY_OUTPUT_DIRECTORY:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
				-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH=${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}
				-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH=${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}
			INSTALL_COMMAND ""
			)
	endif()
	set_target_properties(osg PROPERTIES FOLDER "3rdparty")
endif()

if(OMEGA_USE_EXTERNAL_OSG)
	set(OSG_INCLUDES ${OMEGA_EXTERNAL_OSG_SOURCE_PATH}/include ${OMEGA_EXTERNAL_OSG_BINARY_PATH}/include)
else()
	set(OSG_INCLUDES ${OSG_SOURCE_DIR}/include ${OSG_BINARY_DIR}/include)
endif()

# reduced component set.
#set(OSG_COMPONENTS osg osgAnimation osgDB osgFX osgManipulator osgShadow osgUtil OpenThreads)
set(OSG_COMPONENTS osg osgAnimation osgDB osgFX osgShadow osgTerrain osgText osgUtil osgVolume OpenThreads osgGA osgViewer osgSim)

if(OMEGA_OS_WIN)
	if(OMEGA_USE_EXTERNAL_OSG)
		foreach( C ${OSG_COMPONENTS} )
			set(${C}_LIBRARY ${OMEGA_EXTERNAL_OSG_BINARY_PATH}/lib/${C}.lib)
			set(${C}_LIBRARY_DEBUG ${OMEGA_EXTERNAL_OSG_BINARY_PATH}/lib/${C}d.lib)
			#set(${C}_INCLUDE_DIR ${OMEGA_EXTERNAL_OSG_SOURCE_PATH}/include)
			set(OSG_LIBS ${OSG_LIBS} optimized ${${C}_LIBRARY} debug ${${C}_LIBRARY_DEBUG})
		endforeach()

		# Copy the dlls into the target directories
		file(COPY ${OMEGA_EXTERNAL_OSG_BINARY_PATH}/bin/ DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG} PATTERN "*.dll")
		file(COPY ${OMEGA_EXTERNAL_OSG_BINARY_PATH}/bin/ DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE} PATTERN "*.dll")
	else()
		foreach( C ${OSG_COMPONENTS} )
			#set(${C}_LIBRARY ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE}/${C}.lib)
			#set(${C}_LIBRARY_DEBUG ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG}/${C}d.lib)
			set(${C}_LIBRARY ${OSG_BINARY_DIR}/lib/${C}.lib)
			set(${C}_LIBRARY_DEBUG ${OSG_BINARY_DIR}/lib/${C}d.lib)
			set(OSG_LIBS ${OSG_LIBS} optimized ${${C}_LIBRARY} debug ${${C}_LIBRARY_DEBUG})
		endforeach()

		# Copy the dlls into the target directories
		#file(COPY ${OSG_BUILD_DIR}/bin/ DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG} PATTERN "*.dll")
		#file(COPY ${EXTLIB_DIR}/bin/release/ DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE} PATTERN "*.dll")
	endif()

elseif(OMEGA_OS_LINUX)
    foreach( C ${OSG_COMPONENTS} )
			set(${C}_LIBRARY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/osg/lib${C}.so)
			set(${C}_LIBRARY_DEBUG ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/osg/lib${C}d.so)
		#set(${C}_INCLUDE_DIR ${OSG_INCLUDES})
		set(OSG_LIBS ${OSG_LIBS} optimized ${${C}_LIBRARY} debug ${${C}_LIBRARY_DEBUG})
	endforeach()

	# if(CMAKE_BUILD_TYPE STREQUAL "Debug")
		# file(COPY ${EXTLIB_DIR}/lib/debug/ DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
		# file(COPY ${EXTLIB_DIR}/lib/debug/ DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
	# else()
		# file(COPY ${EXTLIB_DIR}/lib/release/ DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
		# file(COPY ${EXTLIB_DIR}/lib/release/ DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
	# endif()
else()
	foreach( C ${OSG_COMPONENTS} )
		set(${C}_LIBRARY ${OSG_BINARY_DIR}/lib${C}.dylib)
		set(${C}_LIBRARY_DEBUG ${OSG_BINARY_DIR}/lib${C}d.dylib)
		#set(${C}_INCLUDE_DIR ${OSG_INCLUDES})
		set(OSG_LIBS ${OSG_LIBS} optimized ${${C}_LIBRARY} debug ${${C}_LIBRARY_DEBUG})
	endforeach()
	# file(COPY ${EXTLIB_DIR}/lib/ DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
	# file(COPY ${EXTLIB_DIR}/lib/ DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
endif()

include(${CMAKE_CURRENT_LIST_DIR}/UseOsgWorks.cmake)
# Add osgWorks to openscenegraph includes and libraries (this simplified inclusion in other projects.
# we consider osg and osgWorks as a single package.
set(OSG_INCLUDES ${OSG_INCLUDES} ${OSGWORKS_INCLUDES})
set(OSG_LIBS ${OSG_LIBS} ${OSGWORKS_LIBS})
