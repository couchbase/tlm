# Locate Boost headers
# This module defines
#  BOOST_INCLUDE_DIR, where to find the boost headers
SET(boost_exploded ${CMAKE_BINARY_DIR}/tlm/deps/boost.exploded)

FIND_PATH(BOOST_INCLUDE_DIR boost/intrusive/list.hpp
          PATHS ${boost_exploded}/include
          [NO_DEFAULT_PATH])

IF (BOOST_INCLUDE_DIR)
  MESSAGE(STATUS "Found boost in ${BOOST_INCLUDE_DIR}")
ELSE (BOOST_INCLUDE_DIR)
   MESSAGE(FATAL_ERROR "Boost headers not found")
ENDIF (BOOST_INCLUDE_DIR)

MARK_AS_ADVANCED(BOOST_INCLUDE_DIR)
