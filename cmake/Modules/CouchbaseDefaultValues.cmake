#
# Set up default values for couchbase related variables
#

IF ("${INSTALL_HEADER_FILES}" STREQUAL "")
   SET(INSTALL_HEADER_FILES false)
ENDIF ()

# Create a list of all of the directories we would like
# to be treated as system headers (and not report
# compiler warnings from (if the compiler supports it).
#
# Note that as a side-effect this will change the compiler
# search order - non-system paths (-I) are searched before
# system paths.
# Therefore if a header file exists both in a standard
# system location (e.g. /usr/local/include) and in one of
# our paths then adding to CB_SYSTEM_HEADER_DIRS may
# result in the compiler picking up the wrong version.
# As a consequence of this we only add headers which
# (1) have known warning issues and (2) are unlikely
# to exist in a normal system location.

# Explicitly add Google Breakpad as it's headers have
# many warnings :(
IF (IS_DIRECTORY "${CMAKE_INSTALL_PREFIX}/include/breakpad")
   LIST(APPEND CB_SYSTEM_HEADER_DIRS "${CMAKE_INSTALL_PREFIX}/include/breakpad")
ENDIF (IS_DIRECTORY "${CMAKE_INSTALL_PREFIX}/include/breakpad")
