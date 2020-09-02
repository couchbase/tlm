# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
set(CMAKE_C_FLAGS_RELEASE        "/MD /O2 /Ob2 /D NDEBUG")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "/MD /O2 /Ob2 /D NDEBUG /Zi")
set(CMAKE_C_FLAGS_DEBUG          "/MDd /Od /Ob0 /Zi")
set(CB_C_FLAGS_NO_OPTIMIZE       "/Od /Ob0")

# Just use an empty value for CB_CXX_FLAGS_OPTIMIZE_FOR_DEBUG - MSVC build
# times for Release / RelWithDebInfo levels haven't thus far been an issue.
set(CB_CXX_FLAGS_OPTIMIZE_FOR_DEBUG)

# we've created wrappers of some of the typical header files
# provided on Linux/Unix to avoid having to deal with #ifdef's
include_directories(AFTER ${CMAKE_SOURCE_DIR}/platform/include/win32)

if (${CMAKE_CXX_COMPILER_VERSION} VERSION_GREATER 19.10)

    foreach (dir ${CB_SYSTEM_HEADER_DIRS})
        list(APPEND _cb_cxx_flags "/external:I ${dir}")
    endforeach (dir ${CB_SYSTEM_HEADER_DIRS})

    # forestdb hash needs this in MSVC 2017 (should be fixed there eventually)
    list(APPEND _cb_cxx_flags "/Zc:offsetof-")
endif()

# Don't include most of Windows.h - speeds up build and also reduces
# symbol / preprocessor clashes with common tokens like ERROR, MIN, ...
list(APPEND _cb_cxx_flags "/D WIN32_LEAN_AND_MEAN")

# Our code emits tons of warnings due to missing declspec dllimport/export
# for standard types (std::vector, unordered_map etc).
# For now let's just mute them.
#
#   4251 - https://msdn.microsoft.com/en-us/library/esew7y1w.aspx
#          'identifier' : class 'type' needs to have dll-interface
#          to be used by clients of class 'type2'
#
list(APPEND _cb_cxx_flags "/wd4251")


#   4275 - https://msdn.microsoft.com/en-us/library/3tdb471s.aspx
#         non – DLL-interface classkey 'identifier' used as base for
#         DLL-interface classkey 'identifier'

list(APPEND _cb_cxx_flags "/wd4275")

#
# Our code has a lot of align-new warnings generated, but we can't really
# make use of these warnings until we have C++17 support, so for now we
# should just mute them.
#
#   4316 - https://msdn.microsoft.com/en-us/library/dn448573.aspx
#          object allocated on the heap may not be aligned 128

list(APPEND _cb_cxx_flags "/wd4316")

#
# We have a couple of C4800: 'type' : forcing value to bool 'true' or
# 'false' (performance warning) warnings
# which actually got removed in VS2017 so go ahead and ignore them
#
#   4800 - https://msdn.microsoft.com/en-us/library/b6801kcy.aspx
#          'type' : forcing value to bool 'true' or 'false'
#	   (performance warning) warnings
list(APPEND _cb_cxx_flags "/wd4800")
# Convert the list to a string
string(REPLACE ";" " " _cb_cxx_options "${_cb_cxx_flags}")

# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
set(CMAKE_CXX_FLAGS_RELEASE        "/MD /O2 /Ob2 /D NDEBUG")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MD /O2 /Ob2 /D NDEBUG /Zi")
set(CMAKE_CXX_FLAGS_DEBUG          "/MDd /Od /Ob0 /Zi")
set(CB_CXX_FLAGS_NO_OPTIMIZE       "/Od /Ob0")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${_cb_cxx_options} -D_ENABLE_EXTENDED_ALIGNED_STORAGE")

