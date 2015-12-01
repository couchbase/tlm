SET(CB_MSVCXX_DEBUG "")
SET(CB_MSVCXX_WARNINGS "")
SET(CB_MSVCXX_VISIBILITY "")
SET(CB_MSVCXX_THREAD "")

IF ("${ENABLE_WERROR}" STREQUAL "YES")
   SET(CB_MSVCXX_WERROR "")
ENDIF()

# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
SET(CMAKE_CXX_FLAGS_RELEASE        "/MD /O2 /Ob2 /D NDEBUG")
SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MD /O2 /Ob2 /D NDEBUG /Zi")
SET(CMAKE_CXX_FLAGS_DEBUG          "/MDd /Od /Ob0 /Zi")

SET(CB_CXX_FLAGS_NO_OPTIMIZE       /Od /Ob0)

# C++11 support has gradually increased in MSVC starting with 2010 (v16), but
# we declare that at least VS 2013 (v18) is needed for std::atomic / C99.
IF (${CMAKE_CXX_COMPILER_VERSION} VERSION_GREATER 17)
  SET(COMPILER_SUPPORTS_CXX11 true)
  SET(CB_CXX_LANG_VER "C++11")
ENDIF()

INCLUDE(CouchbaseCXXVersion)

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CB_MSVCXX_DEBUG} ${CB_MSVCXX_WARNINGS} ${CB_MSVCXX_VISIBILITY} ${CB_MSVCXX_THREAD} ${CB_MSVCXX_WERROR}")
