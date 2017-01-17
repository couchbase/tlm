# Locate cURL library
# This module defines
#  CURL_FOUND, if false, do not try to link with cURL
#  CURL_LIBRARIES, Library path and libs
#  CURL_INCLUDE_DIR, where to find the ICU headers
#
# I didn't use the one provided with CMake
# because it didn't work with the curl I downloaded
# for windows..

# Use include files directly from cbdeps exploded download
SET (_curl_exploded "${CMAKE_BINARY_DIR}/tlm/deps/curl.exploded")
FIND_PATH(CURL_INCLUDE_DIR curl/curl.h
          HINTS
               "${_curl_exploded}/include"
               ENV CURL_DIR
          PATH_SUFFIXES include
          PATHS
               ~/Library/Frameworks
               /Library/Frameworks
               /opt/local
               /opt/csw
               /opt/curl
               /opt)

FIND_LIBRARY(CURL_LIBRARIES
             NAMES curl libcurl libcurl_imp
             HINTS
                "${_curl_exploded}/lib"
                 ENV CURL_DIR
             PATHS
                 ~/Library/Frameworks
                 /Library/Frameworks
                 /opt/local
                 /opt/csw
                 /opt/curl
                 /opt)

IF (CURL_LIBRARIES)
  MESSAGE(STATUS "Found cURL in ${CURL_INCLUDE_DIR} : ${CURL_LIBRARIES}")
ELSE (CURL_LIBRARIES)
  MESSAGE(FATAL_ERROR "Can't build Couchbase without cURL")
ENDIF (CURL_LIBRARIES)

MARK_AS_ADVANCED(CURL_INCLUDE_DIR CURL_LIBRARIES)
