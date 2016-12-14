
# directory for Fortran compiled .mod files 
SET( FSOCKET_MODULE_DIR ${CMAKE_CURRENT_BINARY_DIR} PARENT_SCOPE )

# do not build static version by default  
if(NOT DEFINED FSOCKET_BUILD_STATIC)
   SET (FSOCKET_BUILD_STATIC OFF CACHE STRING "Build a static version of the FSOCKET library" FORCE)
ENDIF()

# FSOCKET sources
SET( FSOCKET_SRCS fsocket.f90 fsocket_iface.c )

IF( FSOCKET_BUILD_STATIC )
   ADD_LIBRARY( fsocket STATIC ${FSOCKET_SRCS} ) 
   INSTALL( TARGETS fsocket ARCHIVE DESTINATION lib ) 
ELSE()
   ADD_LIBRARY( fsocket SHARED ${FSOCKET_SRCS} ) 
   INSTALL( TARGETS fsocket LIBRARY DESTINATION lib ) 
ENDIF()

# copy .mod file when installing
INSTALL( FILES "${CMAKE_CURRENT_BINARY_DIR}/fsocket.mod" DESTINATION include)

