# Locate nlohmann JSON library
# This module defines
#
#  NLOHMANN_JSON_INCLUDE_DIR

SET(_nhlomann_json_exploded ${CMAKE_BINARY_DIR}/tlm/deps/json.exploded)

FIND_PATH(NLOHMANN_JSON_INCLUDE_DIR nlohmann/json.hpp
          HINTS
               ${_nhlomann_json_exploded}
               ENV NLOHMANN_JSON_DIR
          PATH_SUFFIXES include)

IF (NOT NLOHMANN_JSON_INCLUDE_DIR)
  MESSAGE(ERROR "Can't build Couchbase without https://github.com/nlohmann/json")
ENDIF (NOT NLOHMANN_JSON_INCLUDE_DIR)

MARK_AS_ADVANCED(NLOHMANN_JSON_INCLUDE_DIR)
