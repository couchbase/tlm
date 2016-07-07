# Locate LDAP library (We've only tested this on systems
# using OpenLDAP)
#
# This module defines
#  LDAP_FOUND, if false, do not try to link with LDAP support
#  LDAP_LIBRARIES
#  LDAP_INCLUDE_DIR
#
# If found -DHAVE_LDAP=1 is added to the compile environment

FIND_PATH(LDAP_INCLUDE_DIR ldap.h
          HINTS
               ENV LDAP_DIR
          PATH_SUFFIXES include
          PATHS
               /opt/local
               /opt/csw)

FIND_LIBRARY(LDAP_LIBRARIES
             NAMES ldap
             HINTS
                 ENV LDAP_DIR
             PATH_SUFFIXES lib
             PATHS
                 /opt/local
                 /opt/csw)

IF (LDAP_INCLUDE_DIR AND LDAP_LIBRARIES)
    MESSAGE(STATUS "Found ldap in ${LDAP_INCLUDE_DIR} : ${LDAP_LIBRARIES}")
    ADD_DEFINITIONS(-DHAVE_LDAP=1)
    SET(LDAP_FOUND True)
ELSE (LDAP_INCLUDE_DIR AND LDAP_LIBRARIES)
    SET(LDAP_FOUND False)
#    IF (CB_ENTERPRISE_EDITION AND NOT WIN32)
#        MESSAGE(FATAL_ERROR "Can't build Couchbase EE without LDAP")
#    ENDIF (CB_ENTERPRISE_EDITION AND NOT WIN32)
ENDIF (LDAP_INCLUDE_DIR AND LDAP_LIBRARIES)

MARK_AS_ADVANCED(LDAP_FOUND LDAP_INCLUDE_DIR LDAP_LIBRARIES)
