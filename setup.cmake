###| CMAKE Kiibohd Controller Source Configurator |###
#
# Written by Jacob Alexander in 2011-2013 for the Kiibohd Controller
#
# Released into the Public Domain
#
###



###
# Project Modules
#

#| Note: This is the only section you probably want to modify
#| Each module is defined by it's own folder (e.g. Scan/Matrix represents the "Matrix" module)
#| All of the modules must be specified, as they generate the sources list of files to compile
#| Any modifications to this file will cause a complete rebuild of the project

#| Please the {Scan,Macro,USB,Debug}/module.txt for information on the modules and how to create new ones

##| Deals with acquiring the keypress information and turning it into a key index
set(  ScanModule  "MBC-55X" )

##| Uses the key index and potentially applies special conditions to it, mapping it to a usb key code
set( MacroModule  "buffer"  )

##| Sends the current list of usb key codes through USB HID
set(   USBModule  "pjrc"   )

##| Debugging source to use, each module has it's own set of defines that it sets
set( DebugModule  "full"   )




###
# Module Overrides (Used in the buildall.bash script)
#
if ( ( DEFINED ${ScanModuleOverride} ) AND ( EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/Scan/${ScanModuleOverride} ) )
	set( ScanModule ${ScanModuleOverride} )
endif ( ( DEFINED ${ScanModuleOverride} ) AND ( EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/Scan/${ScanModuleOverride} ) )



###
# Path Setup
# 
set(  ScanModulePath  "Scan/${ScanModule}"  )
set( MacroModulePath "Macro/${MacroModule}" )
set(   USBModulePath   "USB/${USBModule}"   )
set( DebugModulePath "Debug/${DebugModule}" )

#| Top-level directory adjustment
set( HEAD_DIR "${CMAKE_CURRENT_SOURCE_DIR}" )



###
# Module Check Function
#

#| Usage:
#|  PathPrepend( ModulePath <ListOfFamiliesSupported> )
#| Uses the ${COMPILER_FAMILY} variable
function( ModuleCompatibility ModulePath )
	foreach( mod_var ${ARGN} )
		if ( ${mod_var} STREQUAL ${COMPILER_FAMILY} )
			# Module found, no need to scan further
			return()
		endif ( ${mod_var} STREQUAL ${COMPILER_FAMILY} )
	endforeach( mod_var ${ARGN} )

	message( FATAL_ERROR "${ModulePath} does not support the ${COMPILER_FAMILY} family..." )
endfunction( ModuleCompatibility ModulePath )



###
# Module Configuration
#

#| Additional options, usually define settings
add_definitions()

#| Include path for each of the modules
add_definitions(
	-I${HEAD_DIR}/${ScanModulePath}
	-I${HEAD_DIR}/${MacroModulePath}
	-I${HEAD_DIR}/${USBModulePath}
	-I${HEAD_DIR}/${DebugModulePath}
)




###
# Module Processing
#

#| Go through lists of sources and append paths
#| Usage:
#|  PathPrepend( OutputListOfSources <Prepend Path> <InputListOfSources> )
macro( PathPrepend Output SourcesPath )
	unset( tmpSource )

	# Loop through items
	foreach( item ${ARGN} )
		# Set the path
		set( tmpSource ${tmpSource} "${SourcesPath}/${item}" )
	endforeach( item )

	# Finalize by writing the new list back over the old one
	set( ${Output} ${tmpSource} )
endmacro( PathPrepend )


#| Scan Module
include    (            "${ScanModulePath}/setup.cmake"  )
PathPrepend(  SCAN_SRCS  ${ScanModulePath} ${SCAN_SRCS}  )

#| Macro Module
include    (           "${MacroModulePath}/setup.cmake"  )
PathPrepend( MACRO_SRCS ${MacroModulePath} ${MACRO_SRCS} )

#| USB Module
include    (             "${USBModulePath}/setup.cmake"  )
PathPrepend(   USB_SRCS   ${USBModulePath} ${USB_SRCS}   )

#| Debugging Module
include    (           "${DebugModulePath}/setup.cmake"  )
PathPrepend( DEBUG_SRCS ${DebugModulePath} ${DEBUG_SRCS} )


#| Print list of all module sources
message( STATUS "Detected Scan Module Source Files:" )
message( "${SCAN_SRCS}" )
message( STATUS "Detected Macro Module Source Files:" )
message( "${MACRO_SRCS}" )
message( STATUS "Detected USB Module Source Files:" )
message( "${USB_SRCS}" )
message( STATUS "Detected Debug Module Source Files:" )
message( "${DEBUG_SRCS}" )



###
# Generate USB Defines
#

#| Manufacturer name
set( MANUFACTURER "Kiibohd" )


#| Serial Number
#| Attempt to call Git to get the branch, last commit date, and whether code modified since last commit

#| Modified
#| Takes a bit of work to extract the "M " using CMake, and not using it if there are not modifications
execute_process( COMMAND git status -s -uno --porcelain
	WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
	OUTPUT_VARIABLE Git_Modified_INFO
	ERROR_QUIET
	OUTPUT_STRIP_TRAILING_WHITESPACE
)
string( LENGTH "${Git_Modified_INFO}" Git_Modified_LENGTH )
if ( ${Git_Modified_LENGTH} GREATER 2 )
	string( SUBSTRING "${Git_Modified_INFO}" 1 2 Git_Modified_Flag_INFO )
endif ( ${Git_Modified_LENGTH} GREATER 2 )

#| Branch
execute_process( COMMAND git rev-parse --abbrev-ref HEAD
	WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
	OUTPUT_VARIABLE Git_Branch_INFO
	ERROR_QUIET
	OUTPUT_STRIP_TRAILING_WHITESPACE
)

#| Date
execute_process( COMMAND git show -s --format=%ci
	WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
	OUTPUT_VARIABLE Git_Date_INFO
	RESULT_VARIABLE Git_RETURN
	ERROR_QUIET
	OUTPUT_STRIP_TRAILING_WHITESPACE
)


#| Only use Git variables if we were successful in calling the commands
if ( ${Git_RETURN} EQUAL 0 )
	set( GitLastCommitDate "${Git_Modified_Flag_INFO}${Git_Branch_INFO} - ${Git_Date_INFO}" )
else ( ${Git_RETURN} EQUAL 0 )
	# TODO Figure out a good way of finding the current branch + commit date + modified
	set( GitLastCommitDate "Pft...Windows Build" )
endif ( ${Git_RETURN} EQUAL 0 )


#| Uses CMake variables to include as defines
#| Primarily for USB configuration
configure_file( ${CMAKE_CURRENT_SOURCE_DIR}/Lib/_buildvars.h buildvars.h )

