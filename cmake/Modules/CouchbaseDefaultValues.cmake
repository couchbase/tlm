#
# Set up default values for couchbase related variables
#

IF ("${INSTALL_HEADER_FILES}" STREQUAL "")
   SET(INSTALL_HEADER_FILES false)
ENDIF ()

# Create a list of all of the directories we would like
# to be treated as system headers (and not report
# compiler warnings from (if the compiler supports it)
LIST(APPEND CB_SYSTEM_HEADER_DIRS "${CMAKE_INSTALL_PREFIX}/include")

# Unfortunately google breakpad installs it's files in
# a slightly different way, so it needs to be added to the
# list (otherwise it'll be found through the -I statement
# causing all of the warnings to appear.
IF (IS_DIRECTORY "${CMAKE_INSTALL_PREFIX}/include/breakpad")
   LIST(APPEND CB_SYSTEM_HEADER_DIRS "${CMAKE_INSTALL_PREFIX}/include/breakpad")
ENDIF (IS_DIRECTORY "${CMAKE_INSTALL_PREFIX}/include/breakpad")
