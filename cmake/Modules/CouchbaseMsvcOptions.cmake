# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
set(CMAKE_C_FLAGS_RELEASE        "/MD /O2 /Ob2 /D NDEBUG")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "/MD /O2 /Ob2 /D NDEBUG /Zi")
set(CMAKE_C_FLAGS_DEBUG          "/MDd /Od /Ob0 /Zi")
set(CB_C_FLAGS_NO_OPTIMIZE       "/Od /Ob0")

# we've created wrappers of some of the typical header files
# provided on Linux/Unix to avoid having to deal with #ifdef's
include_directories(AFTER ${CMAKE_SOURCE_DIR}/platform/include/win32)

# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
set(CMAKE_CXX_FLAGS_RELEASE        "/MD /O2 /Ob2 /D NDEBUG")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MD /O2 /Ob2 /D NDEBUG /Zi")
set(CMAKE_CXX_FLAGS_DEBUG          "/MDd /Od /Ob0 /Zi")
set(CB_CXX_FLAGS_NO_OPTIMIZE       "/Od /Ob0")

# Our code emits tons of warnings due to missing declspec dllimport/export
# for standard types (std::vector, unordered_map etc).
# For now let's just mute them.
#
#   4251 - https://msdn.microsoft.com/en-us/library/esew7y1w.aspx
#          'identifier' : class 'type' needs to have dll-interface
#          to be used by clients of class 'type2'
#
#   4275 - https://msdn.microsoft.com/en-us/library/3tdb471s.aspx
#         non – DLL-interface classkey 'identifier' used as base for
#         DLL-interface classkey 'identifier'
#
# Our code has a lot of align-new warnings generated, but we can't really
# make use of these warnings until we have C++17 support, so for now we
# should just mute them.
#
#   4316 - https://msdn.microsoft.com/en-us/library/dn448573.aspx
#          object allocated on the heap may not be aligned 128
#
# We have a couple of C4800: 'type' : forcing value to bool 'true' or
# 'false' (performance warning) warnings
# which actually got removed in VS2017 so go ahead and ignore them
#
#   4800 - https://msdn.microsoft.com/en-us/library/b6801kcy.aspx
#          'type' : forcing value to bool 'true' or 'false'
#	   (performance warning) warnings
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4251 /wd4275 /wd4316 /wd4800")
