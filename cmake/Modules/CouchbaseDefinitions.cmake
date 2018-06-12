
if (WIN32)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS=1)
    add_definitions(-D_CRT_NONSTDC_NO_DEPRECATE)
    # Valgrind's macros doesn't support MSVC - disable any attempt to use them.
    add_definitions(-DNVALGRIND)
    add_definitions(-DNOMINMAX=1)
else ()
    add_definitions(-D_POSIX_PTHREAD_SEMANTICS)
    add_definitions(-D_GNU_SOURCE=1)
    add_definitions(-D__EXTENSIONS__=1)
endif ()

add_definitions(-D__STDC_FORMAT_MACROS)
add_definitions(-Dgsl_CONFIG_CONTRACT_VIOLATION_THROWS)
