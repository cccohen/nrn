# =================================================================================================
# Organise which Python versions are to be built against, and find their versions, include
# directories and library paths. This is used both for dynamic Python (>= 1 libnrnpythonX.Y) and
# standard Python (libnrniv linked against one Python version) builds. To avoid the restrictions
# inherent in Python's limited API / stable ABI (see
# https://docs.python.org/3/c-api/stable.html#stable-application-binary-interface), we build
# Python-related NEURON code separately for each version of Python: libnrnpythonX.Y. Historically
# macOS and Linux were built ignoring the minor version, but this is unsafe without the limited API
# =================================================================================================

# Parse commandline options so that:
#
# * PYTHON_EXECUTABLE is the default Python, which is used for running tests and so on.
# * NRN_PYTHON_EXECUTABLES is a list of all the Pythons that we are building against. This will only
#   have a length > 1 if NRN_ENABLE_PYTHON_DYNAMIC is defined.
if(NOT PYTHON_EXECUTABLE AND (NOT NRN_ENABLE_PYTHON_DYNAMIC OR NOT NRN_PYTHON_DYNAMIC))
  # Haven't been explicitly told about any Python versions, set PYTHON_EXECUTABLE by searching PATH
  message(STATUS "No python executable specified. Looking for `python3` in the PATH...")
  # Since PythonInterp module prefers system-wide python, if PYTHON_EXECUTABLE is not set, look it
  # up in the PATH exclusively. Need to set PYTHON_EXECUTABLE before calling SanitizerHelper.cmake
  find_program(
    PYTHON_EXECUTABLE python3
    PATHS ENV PATH
    NO_DEFAULT_PATH)
  if(PYTHON_EXECUTABLE STREQUAL "PYTHON_EXECUTABLE-NOTFOUND")
    message(FATAL_ERROR "Could not find Python, please set PYTHON_EXECUTABLE or NRN_PYTHON_DYNAMIC")
  endif()
endif()
if(NRN_ENABLE_PYTHON_DYNAMIC AND NRN_PYTHON_DYNAMIC)
  list(GET NRN_PYTHON_DYNAMIC 0 NRN_PYTHON_DYNAMIC_0)
  if(PYTHON_EXECUTABLE AND NOT PYTHON_EXECUTABLE STREQUAL NRN_PYTHON_DYNAMIC_0)
    # When NRN_ENABLE_PYTHON_DYNAMIC and NRN_PYTHON_DYNAMIC are set, the first entry of
    # NRN_PYTHON_DYNAMIC is taken to be the default python version
    message(
      WARNING
        "NRN_ENABLE_PYTHON_DYNAMIC and NRN_PYTHON_DYNAMIC overriding PYTHON_EXECUTABLE=${PYTHON_EXECUTABLE} to ${NRN_PYTHON_DYNAMIC_0}"
    )
  endif()
  set(PYTHON_EXECUTABLE "${NRN_PYTHON_DYNAMIC_0}")
  set(NRN_PYTHON_EXECUTABLES ${NRN_PYTHON_DYNAMIC})
else()
  # In other cases, there is just one Python and it's PYTHON_EXECUTABLE.
  set(NRN_PYTHON_EXECUTABLES "${PYTHON_EXECUTABLE}")
endif()

# For each Python in NRN_PYTHON_EXECUTABLES, find its version number, it's include directory, and
# its library path. Store those in the new lists NRN_PYTHON_VERSIONS, NRN_PYTHON_INCLUDES and
# NRN_PYTHON_LIBRARIES. Set NRN_PYTHON_COUNT to be the length of those lists, and
# NRN_PYTHON_ITERATION_LIMIT to be NRN_PYTHON_COUNT - 1.
set(NRN_PYTHON_VERSIONS
    ""
    CACHE INTERNAL "" FORCE)
set(NRN_PYTHON_INCLUDES
    ""
    CACHE INTERNAL "" FORCE)
set(NRN_PYTHON_LIBRARIES
    ""
    CACHE INTERNAL "" FORCE)
if(NRN_ENABLE_PYTHON)
  foreach(pyexe ${NRN_PYTHON_EXECUTABLES})
    message(STATUS "Checking if ${pyexe} is a working python")
    set(pyinc_code "import sysconfig; print(sysconfig.get_path('include'))")
    set(pyver_code "import sys; print('{}.{}'.format(*sys.version_info[:2]))")
    execute_process(
      COMMAND "${pyexe}" -c "${pyinc_code}; ${pyver_code}"
      RESULT_VARIABLE result
      OUTPUT_VARIABLE std_output
      ERROR_VARIABLE err_output
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT result EQUAL 0)
      message(FATAL_ERROR "Error checking ${pyexe} : ${result}\n${std_output}\n${err_output}")
    endif()
    # cmake-format: off
    string(REGEX MATCH [0-9.]*$ PYVER ${std_output})
    string(REGEX MATCH ^[^\n]* incval ${std_output})
    # cmake-format: on
    # Unset the variables set by PythonLibsNew so we can start afresh.
    set(PYTHON_EXECUTABLE ${pyexe})
    unset(PYTHON_INCLUDE_DIR CACHE)
    unset(PYTHON_LIBRARY CACHE)
    set(PYTHON_PREFIX "")
    set(PYTHON_LIBRARIES "")
    set(PYTHON_INCLUDE_DIRS "")
    set(PYTHON_MODULE_EXTENSION "")
    set(PYTHON_MODULE_PREFIX "")
    find_package(PythonLibsNew ${PYVER} REQUIRED)
    # convert major.minor to majorminor
    string(REGEX REPLACE [.] "" PYVER ${PYVER})
    list(APPEND NRN_PYTHON_VERSIONS "${PYVER}")
    list(APPEND NRN_PYTHON_INCLUDES "${incval}")
    list(APPEND NRN_PYTHON_LIBRARIES "${PYTHON_LIBRARIES}")
  endforeach()
endif()
list(LENGTH NRN_PYTHON_EXECUTABLES NRN_PYTHON_COUNT)
math(EXPR NRN_PYTHON_ITERATION_LIMIT "${NRN_PYTHON_COUNT} - 1")
