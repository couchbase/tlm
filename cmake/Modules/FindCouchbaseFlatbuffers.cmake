# Locate Google flatbuffers
# This module defines
#  FLATBUFFERS_INCLUDE_DIR, where to find the flatbuffer headers
#  FLATC, the flatc binary
SET(google_flatbuffers_exploded ${CMAKE_BINARY_DIR}/tlm/deps/flatbuffers.exploded)

FIND_PATH(FLATBUFFERS_INCLUDE_DIR flatbuffers/flatbuffers.h
          HINTS ${google_flatbuffers_exploded}/include)
FIND_PROGRAM(FLATC flatc HINTS ${google_flatbuffers_exploded}/bin)

IF (FLATBUFFERS_INCLUDE_DIR AND FLATC)
  MESSAGE(STATUS "Found Google Flatbuffers in ${FLATBUFFERS_INCLUDE_DIR} : ${FLATC}")
ELSE (FLATBUFFERS_INCLUDE_DIR AND FLATC)
   MESSAGE(FATAL_ERROR "Google flatbuffers is a requirement")
ENDIF (FLATBUFFERS_INCLUDE_DIR AND FLATC)

MARK_AS_ADVANCED(FLATBUFFERS_INCLUDE_DIR FLATC)
