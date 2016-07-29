
PROJECT( FSOCKET C Fortran )

SET(VERSION 1.0.0)

CMAKE_MINIMUM_REQUIRED(VERSION 2.8.5)

# set default installation to ./install
#set( CMAKE_INSTALL_PREFIX "${CMAKE_SOURCE_DIR}/install/" CACHE STRING "Choose the installation directory; by default it installs in the ./install directory." FORCE )

# Unique directory for Fortran compiled .mod files -> modules folder
SET(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include)

# set default build to RELEASE
if( NOT CMAKE_BUILD_TYPE )
   set (CMAKE_BUILD_TYPE RELEASE CACHE STRING "Choose the type of build, options are: NONE DEBUG RELEASE." FORCE)
endif( NOT CMAKE_BUILD_TYPE )

# do not build static version by default  
if( NOT DEFINED FSOCKET_BUILD_STATIC )
   set (FSOCKET_BUILD_STATIC OFF CACHE STRING "Build a static version of the FSOCKET library" FORCE)
endif( NOT DEFINED FSOCKET_BUILD_STATIC )

# FSOCKET sources
set( FSOCKET_SRCS fsocket.f90 fsocket_iface.c )

if( FSOCKET_BUILD_STATIC )
   add_library( fsocket STATIC ${FSOCKET_SRCS} ) 
   install( TARGETS fsocket ARCHIVE DESTINATION lib ) 
else( FSOCKET_BUILD_STATIC )
   add_library( fsocket SHARED ${FSOCKET_SRCS} ) 
   install( TARGETS fsocket LIBRARY DESTINATION lib ) 
endif( FSOCKET_BUILD_STATIC )

# copy .mod file when installing
INSTALL( FILES "${CMAKE_Fortran_MODULE_DIRECTORY}/fsocket.mod" DESTINATION include)

# Build the FSOCKET example program
ADD_EXECUTABLE( test_fsocket_server test_fsocket_server.f90 )
ADD_EXECUTABLE( test_fsocket_client test_fsocket_client.f90 )
ADD_EXECUTABLE( test_fsocket_select test_fsocket_select.f90 )

TARGET_LINK_LIBRARIES( test_fsocket_server fsocket )
TARGET_LINK_LIBRARIES( test_fsocket_client fsocket )
TARGET_LINK_LIBRARIES( test_fsocket_select fsocket )

