SET(CB_CLANGXX_DEBUG "-g")
SET(CB_CLANGXX_WARNINGS "-Qunused-arguments -Wall -pedantic -Wredundant-decls -fno-strict-aliasing")
SET(CB_CLANGXX_VISIBILITY "-fvisibility=hidden")
SET(CB_CLANGXX_THREAD "-pthread")

# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
SET(CMAKE_CXX_FLAGS_RELEASE        "-O3 -DNDEBUG")
SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O3 -DNDEBUG -g")
SET(CMAKE_CXX_FLAGS_DEBUG          "-O0 -g")

SET(CB_CXX_FLAGS_NO_OPTIMIZE       -O0)

IF ("${ENABLE_WERROR}" STREQUAL "YES")
   SET(CB_CLANGXX_WERROR "-Werror")
ELSE()
   # We've fixed all occurrences for the following warnings and don't want
   # any new ones to appear
   SET(CB_CLANGXX_WERROR "-Werror=switch")
ENDIF()

if (${CMAKE_CXX_COMPILER_VERSION} VERSION_LESS 3.1)
  SET(CB_CXX_LANG_VER "")
  MESSAGE(WARNING "The C++ compiler is too old and don't support C++11")
ELSE ()
  SET(COMPILER_SUPPORTS_CXX11 true)
  SET(CB_CXX_LANG_VER "-std=c++11")
  SET(CB_GNU_CXX11_OPTION "-std=gnu++11")
ENDIF()

INCLUDE(CouchbaseCXXVersion)

FOREACH(dir ${CB_SYSTEM_HEADER_DIRS})
   SET(CB_CLANGXX_IGNORE_HEADER "${CB_CLANGXX_IGNORE_HEADER} -isystem ${dir}")
ENDFOREACH(dir ${CB_SYSTEM_HEADER_DIRS})

SET(CMAKE_CXX_FLAGS "${CB_CLANGXX_IGNORE_HEADER} ${CMAKE_CXX_FLAGS} ${CB_CXX_LANG_VER} ${CB_CLANGXX_DEBUG} ${CB_CLANGXX_WARNINGS} ${CB_CLANGXX_VISIBILITY} ${CB_CLANGXX_THREAD} ${CB_CLANGXX_WERROR}")
