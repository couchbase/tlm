SET(CB_CLANG_WARNINGS "-Qunused-arguments  -Wall -pedantic -Wmissing-declarations -Wredundant-decls -fno-strict-aliasing")
SET(CB_CLANG_VISIBILITY "-fvisibility=hidden")
SET(CB_CLANG_THREAD "-pthread")

IF ("${ENABLE_WERROR}" STREQUAL "YES")
   SET(CB_CLANG_WERROR "-Werror")
ENDIF()

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CB_CLANG_WARNINGS} ${CB_CLANG_VISIBILITY} ${CB_CLANG_THREAD} ${CB_CLANG_WERROR}")
