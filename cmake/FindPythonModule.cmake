# Find if a Python module is installed
# Found at http://www.cmake.org/pipermail/cmake/2011-January/041666.html
# To use do: find_python_module(PyQt4 REQUIRED)
# Sets modulename_FOUND if found

FUNCTION(FIND_PYTHON_MODULE module)
   FIND_PACKAGE(PythonInterp)
   STRING(TOUPPER ${module} module_upper)
   IF(NOT PY_${module_upper})
      IF(ARGC GREATER 1 AND ARGV1 STREQUAL "REQUIRED")
         SET(${module}_FIND_REQUIRED TRUE)
      ENDIF()
      # A module's location is usually a directory, but for binary modules
      # it's a .so file.
      EXECUTE_PROCESS(COMMAND "${PYTHON_EXECUTABLE}" "-c" 
         "import re, ${module}; print(re.compile('/__init__.py.*').sub('',${module}.__file__))"
         RESULT_VARIABLE _${module}_status 
         OUTPUT_VARIABLE _${module}_location
         ERROR_QUIET 
         OUTPUT_STRIP_TRAILING_WHITESPACE)
      IF(NOT _${module}_status)
         SET(PY_${module_upper} ${_${module}_location} CACHE STRING 
            "Location of Python module ${module}")
      ENDIF()
   ENDIF()
   INCLUDE(FindPackageHandleStandardArgs)
   FIND_PACKAGE_HANDLE_STANDARD_ARGS(${module} DEFAULT_MSG PY_${module_upper})
   SET( ${module}_FOUND ${module}_FOUND PARENT_SCOPE )
ENDFUNCTION(FIND_PYTHON_MODULE)

