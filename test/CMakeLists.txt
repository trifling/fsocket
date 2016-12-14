
# Build the FSOCKET example program

INCLUDE_DIRECTORIES( ${FSOCKET_MODULE_DIR} )

ADD_EXECUTABLE( test_fsocket_server test_fsocket_server.f90 )
ADD_EXECUTABLE( test_fsocket_client test_fsocket_client.f90 )
ADD_EXECUTABLE( test_fsocket_select test_fsocket_select.f90 )

TARGET_LINK_LIBRARIES( test_fsocket_server fsocket )
TARGET_LINK_LIBRARIES( test_fsocket_client fsocket )
TARGET_LINK_LIBRARIES( test_fsocket_select fsocket )

