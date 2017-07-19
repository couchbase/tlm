# Locate RocksDB library
# This module defines
#  ROCKSDB_FOUND, if false, do not try to link with rocksdb
#  ROCKSDB_LIBRARIES, Library path and libs
#  ROCKSDB_INCLUDE_DIR, where to find the rocksdb headers

SET(_rocksdb_exploded ${CMAKE_BINARY_DIR}/tlm/deps/rocksdb.exploded)

FIND_PATH(ROCKSDB_INCLUDE_DIR rocksdb/db.h
          PATH_SUFFIXES include
          PATHS ${_rocksdb_exploded}
          NO_DEFAULT_PATH)

FIND_LIBRARY(ROCKSDB_LIBRARIES
             NAMES rocksdb)

IF (ROCKSDB_INCLUDE_DIR AND ROCKSDB_LIBRARIES)
  MESSAGE(STATUS "Found RocksDB in ${ROCKSDB_INCLUDE_DIR} : ${ROCKSDB_LIBRARIES}")
ELSE ()
  MESSAGE(STATUS "RocksDB not found")
ENDIF ()

MARK_AS_ADVANCED(ROCKSDB_INCLUDE_DIR ROCKSDB_LIBRARIES)
