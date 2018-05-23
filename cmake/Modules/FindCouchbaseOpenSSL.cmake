# Locate OpenSSL library
#
# For Windows and MacOSX we bundle our own version, but for the
# other platforms we should search for a system-wide installed
# version.
#
# This module defines
#  OPENSSL_LIBRARIES, Library path and libs
#  OPENSSL_INCLUDE_DIR, where to find the ICU headers

SET(_openssl_exploded ${CMAKE_BINARY_DIR}/tlm/deps/openssl.exploded)
set(_openssl_libraries "ssl;libssl32;ssleay32;crypto;libeay32")

if (WIN32 OR APPLE)
    find_path(OPENSSL_INCLUDE_DIR openssl/ssl.h
              HINTS ${_openssl_exploded}
              PATH_SUFFIXES include
              NO_CMAKE_PATH
              NO_CMAKE_ENVIRONMENT_PATH)

    string(STRIP ${OPENSSL_INCLUDE_DIR} OPENSSL_INCLUDE_DIR)
    foreach(_mylib ${_openssl_libraries})
        unset(_the_lib CACHE)
        find_library(_the_lib
                     NAMES ${_mylib}
                     HINTS ${CMAKE_INSTALL_PREFIX}/lib
                     NO_DEFAULT_PATH)
        if (_the_lib)
            list(APPEND OPENSSL_LIBRARIES ${_the_lib})
        endif (_the_lib)
    endforeach(_mylib)
else (WIN32 OR APPLE)
    find_path(OPENSSL_INCLUDE_DIR openssl/ssl.h
              HINTS ENV OPENSSL_DIR
              PATH_SUFFIXES include
              PATHS
                 /usr/local
                 /opt/local
                 /opt/csw
                 /opt/openssl
                 /opt)

    foreach (_mylib ${_openssl_libraries})
        unset(_the_lib CACHE)
        find_library(_the_lib
                     NAMES ${_mylib}
                     HINTS ENV OPENSSL_DIR
                     PATHS
                         /usr/local
                         /opt/local
                         /opt/csw
                         /opt/openssl
                         /opt)
        if (_the_lib)
            list(APPEND OPENSSL_LIBRARIES ${_the_lib})
        endif (_the_lib)
    endforeach (_mylib)

    if (OPENSSL_SSL_LIBRARY AND OPENSSL_CRYPT_LIBRARY)
        set(OPENSSL_LIBRARIES ${OPENSSL_SSL_LIBRARY} ${OPENSSL_CRYPT_LIBRARY})
    endif (OPENSSL_SSL_LIBRARY AND OPENSSL_CRYPT_LIBRARY)
endif (WIN32 OR APPLE)

if (OPENSSL_LIBRARIES AND OPENSSL_INCLUDE_DIR)
    message(STATUS "Found OpenSSL headers in ${OPENSSL_INCLUDE_DIR}")
    message(STATUS "Using OpenSSL libraries: ${OPENSSL_LIBRARIES}")
else (OPENSSL_LIBRARIES AND OPENSSL_INCLUDE_DIR)
  message(FATAL_ERROR "Can't build Couchbase without openssl")
endif (OPENSSL_LIBRARIES AND OPENSSL_INCLUDE_DIR)

set(OPENSSL_FOUND true)
mark_as_advanced(OPENSSL_FOUND OPENSSL_INCLUDE_DIR OPENSSL_LIBRARIES)
