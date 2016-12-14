# 
# Try to find Sphinx, if successful:
#  - sets Sphinx_FOUND 
#  - add a target ${PROJECT_NAME}_doc with the HTML docs
#  - if there is a conf.py.in it will configure and use it
#  - otherwise it will use conf.py
#
# The following can be customized, use ccmake for the descriptions
#     SPHINX_THEME
#     SPHINX_THEME_DIR
#     SPHINX_BUILD_DIR 
#     SPHINX_CACHE_DIR 
#     SPHINX_HTML_DIR   
#

FIND_PROGRAM( SPHINX_EXECUTABLE NAMES sphinx-build
              HINTS $ENV{SPHINX_DIR}
              PATH_SUFFIXES bin
              DOC "Sphinx documentation generator" )
 
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Sphinx DEFAULT_MSG SPHINX_EXECUTABLE )
MARK_AS_ADVANCED(SPHINX_EXECUTABLE)

IF( SPHINX_EXECUTABLE )
   
   # Sphinx theme
   SET( SPHINX_THEME "bizstyle" CACHE STRING "Sphinx HTML theme" )
   SET( SPHINX_THEME_DIR "" CACHE STRING "Sphinx HTML theme dir" )
   SET( SPHINX_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "DIR for Sphinx tools and intermediate build results" )
   SET( SPHINX_CACHE_DIR "${SPHINX_BUILD_DIR}/.doctrees" CACHE PATH "DIR for Sphinx cache with pickled ReST documents" )
   SET( SPHINX_HTML_DIR  "${SPHINX_BUILD_DIR}" CACHE PATH "Sphinx HTML output DIR" )
    
   IF(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/conf.py.in")
      CONFIGURE_FILE( "${CMAKE_CURRENT_SOURCE_DIR}/conf.py.in" "${SPHINX_BUILD_DIR}/conf.py" @ONLY)
   ELSE()
      FILE(COPY "${CMAKE_CURRENT_SOURCE_DIR}/conf.py" "${SPHINX_BUILD_DIR}/conf.py" )
   ENDIF()
    
   ADD_CUSTOM_TARGET( ${PROJECT_NAME}_doc  ALL
       ${SPHINX_EXECUTABLE}
           -q -b html
           -c "${SPHINX_BUILD_DIR}"
           -d "${SPHINX_CACHE_DIR}"
           "${CMAKE_CURRENT_SOURCE_DIR}"
           "${SPHINX_HTML_DIR}"
      COMMENT "Building HTML documentation with Sphinx")

ENDIF()

