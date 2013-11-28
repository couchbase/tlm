SET(CB_GNU_DEBUG "-g")
SET(CB_GNU_WARNINGS "-Wall -pedantic -Wmissing-prototypes -Wmissing-declarations -Wredundant-decls -fno-strict-aliasing -Wno-overlength-strings")
SET(CB_GNU_VISIBILITY "-fvisibility=hidden")
SET(CB_GNU_THREAD "-pthread")

IF ("${ENABLE_WERROR}" STREQUAL "YES")
   SET(CB_GNU_WERROR "-Werror")
ENDIF()

SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CB_GNU_DEBUG} ${CB_GNU_WARNINGS} ${CB_GNU_VISIBILITY} ${CB_GNU_THREAD} ${CB_GNU_WERROR}")
SET(CMAKE_LINK_FLAGS "${CMAKE_LINK_FLAGS} ${CB_GNU_LDFLAGS}")
