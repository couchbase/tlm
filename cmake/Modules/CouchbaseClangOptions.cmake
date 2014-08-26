SET(CB_CLANG_DEBUG "-g")
SET(CB_CLANG_WARNINGS "-Qunused-arguments -Wall -pedantic -Wmissing-prototypes -Wmissing-declarations -Wredundant-decls -fno-strict-aliasing -Wno-overlength-strings")
SET(CB_CLANG_VISIBILITY "-fvisibility=hidden")
SET(CB_CLANG_THREAD "-pthread")
SET(CB_CLANG_LANG_VER "-std=gnu99")

IF ("${ENABLE_WERROR}" STREQUAL "YES")
   SET(CB_CLANG_WERROR "-Werror")
ENDIF()

SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CB_CLANG_DEBUG} ${CB_CLANG_LANG_VER} ${CB_CLANG_WARNINGS} ${CB_CLANG_VISIBILITY} ${CB_CLANG_THREAD} ${CB_CLANG_WERROR}")
SET(CMAKE_LINK_FLAGS "${CMAKE_LINK_FLAGS} ${CB_CLANG_LDFLAGS}")
