# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
set(CMAKE_C_FLAGS_RELEASE        "/MD /O2 /Ob2 /D NDEBUG")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "/MD /O2 /Ob2 /D NDEBUG /Zi")
set(CMAKE_C_FLAGS_DEBUG          "/MDd /Od /Ob0 /Zi")
set(CB_C_FLAGS_NO_OPTIMIZE       "/Od /Ob0")

add_definitions(-D_CRT_SECURE_NO_WARNINGS=1)
add_definitions(-D_CRT_NONSTDC_NO_DEPRECATE)
# Valgrind's macros doesn't support MSVC - disable any attempt to use them.
add_definitions(-DNVALGRIND)
add_definitions(-DNOMINMAX=1)

include_directories(AFTER ${CMAKE_SOURCE_DIR}/platform/include/win32)

if (MSVC_VERSION LESS 1800)
    message(FATAL_ERROR "You need MSVC 2013 or newer")
endif (MSVC_VERSION LESS 1800)
