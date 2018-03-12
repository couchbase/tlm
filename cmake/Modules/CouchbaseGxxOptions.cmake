SET(CB_GXX_DEBUG "-g")
SET(CB_GXX_WARNINGS "-Wall -Wredundant-decls -Wmissing-braces -fno-strict-aliasing")
SET(CB_GXX_VISIBILITY "-fvisibility=hidden")
SET(CB_GXX_THREAD "-pthread")

IF (${CMAKE_CXX_COMPILER_VERSION} VERSION_GREATER 6.9.9)
    #Disable aligned-new warning
    SET(CB_GXX_WARNINGS "${CB_GXX_WARNINGS} -Wno-aligned-new")
    MESSAGE(STATUS "Disabling aligned-new warning as we don't support C++17 (yet)")

    # Disable stringop-overflow warnings as there seem to be a fair few bugs in that area (GCC 7.2)
    # There are multiple bugs files regarding false positives.
    # See: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=79095 and https://gcc.gnu.org/bugzilla/show_bug.cgi?id=83239
    SET(CB_GXX_WARNINGS "${CB_GXX_WARNINGS} -Wno-stringop-overflow")
    MESSAGE(STATUS "Disabling stringop-overflow warning as it seems to report false positives at the moment")
    MESSAGE(STATUS "Current GXX Warnings state: ${CB_GXX_WARNINGS}")
ENDIF ()

# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
SET(CMAKE_CXX_FLAGS_RELEASE        "-O3 -DNDEBUG")
SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O3 -DNDEBUG -g")
SET(CMAKE_CXX_FLAGS_DEBUG          "-Og -g")

SET(CB_CXX_FLAGS_NO_OPTIMIZE       -O0)

IF ("${ENABLE_WERROR}" STREQUAL "YES")
   SET(CB_GXX_WERROR "-Werror")
ELSE()
   # We've fixed all occurrences for the following warnings and don't want
   # any new ones to appear
   SET(CB_GXX_WERROR "-Werror=switch")
ENDIF()

IF (${CMAKE_CXX_COMPILER_VERSION} VERSION_LESS 5.1.0)
    MESSAGE (FATAL_ERROR "\n\nCouchbase Server requires GCC version 5.1.0 or newer to compile. Aborting build.\n\n")
ENDIF ()

SET(COMPILER_SUPPORTS_CXX11 true)
SET(CB_CXX_LANG_VER "-std=c++11")
SET(CB_GNU_CXX11_OPTION "-std=gnu++11")
SET(CB_CXX_PEDANTIC "-pedantic")

INCLUDE(CouchbaseCXXVersion)

FOREACH(dir ${CB_SYSTEM_HEADER_DIRS})
   SET(CB_GNU_CXX_IGNORE_HEADER "${CB_GNU_CXX_IGNORE_HEADER} -isystem ${dir}")
ENDFOREACH(dir ${CB_SYSTEM_HEADER_DIRS})

IF (CB_CODE_COVERAGE)
  SET(CB_GXX_COVERAGE "--coverage")
ENDIF ()

SET(CMAKE_CXX_FLAGS "${CB_GNU_CXX_IGNORE_HEADER} ${CMAKE_CXX_FLAGS} ${CB_CXX_LANG_VER} ${CB_GXX_DEBUG} ${CB_GXX_WARNINGS} ${CB_CXX_PEDANTIC} ${CB_GXX_VISIBILITY} ${CB_GXX_THREAD} ${CB_GXX_WERROR} ${CB_GXX_COVERAGE}")
