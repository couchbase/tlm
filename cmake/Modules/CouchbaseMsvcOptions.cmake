# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
set(CMAKE_C_FLAGS_RELEASE        "/MD /O2 /Ob2 /D NDEBUG")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "/MD /O2 /Ob2 /D NDEBUG /Zi")
set(CMAKE_C_FLAGS_DEBUG          "/MDd /Od /Ob0 /Zi")
set(CB_C_FLAGS_NO_OPTIMIZE       "/Od /Ob0")

# Flag for DebugOptimized build (see CouchbaseCompilerOptions.cmake):
# - /MD: Use release (non-debug) runtime library. We use the release runtime
#        library given (a) that's what all our third-party dependaecies use
#        (and MSVC doesn't allow mixing and matching) and (b) it's
#        significantly faster than the debug runtime library - but doesn't
#        itself take longer to build with.
# - /Ob1: Inline function calls which are considered inline. This is a cheap
#        optimization to enable in terms of compile-time; but results in
#        a noticable speedup in runtime performance.
set(CB_FLAGS_OPTIMIZE_FOR_DEBUG "/MD /Ob1 /Zi")

# we've created wrappers of some of the typical header files
# provided on Linux/Unix to avoid having to deal with #ifdef's
include_directories(AFTER ${CMAKE_SOURCE_DIR}/platform/include/win32)

# Disable warnings for any external (aka system) headers.
list(APPEND _cb_cxx_flags "/external:W0")
set(CMAKE_INCLUDE_SYSTEM_FLAG_CXX "/external:I ")

# force the compiler to use the UTF-8 codepage
list(APPEND _cb_cxx_flags "/utf-8")

# Don't include most of Windows.h - speeds up build by avoiding preprocessing
# a bunch of unused code.
list(APPEND _cb_cxx_flags "/D WIN32_LEAN_AND_MEAN")

#  folly.exploded\include\folly/container/detail/F14Policy.h(951):
# warning C4996: warning STL4015: The std::iterator class template (used as
# a base class to provide typedefs) is deprecated in C++17. (The <iterator>
# header is NOT deprecated.) The C++ Standard has never required
# user-defined iterators to derive from std::iterator. To fix this warning,
# stop deriving from std::iterator and start providing publicly accessible
# typedefs named iterator_category, value_type, difference_type, pointer,
# and reference. Note that value_type is required to be non-const, even for
# constant iterators. You can define
# _SILENCE_CXX17_ITERATOR_BASE_CLASS_DEPRECATION_WARNING or
# _SILENCE_ALL_CXX17_DEPRECATION_WARNINGS to acknowledge that you have
# received this warning.
list(APPEND _cb_cxx_flags "/D _SILENCE_CXX17_ITERATOR_BASE_CLASS_DEPRECATION_WARNING")

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

# MB-58743 compile with /bigobj due to running out of segments
# when building unit tests in kv-engine
list(APPEND _cb_cxx_flags "/bigobj")

# Set warning level to 4
list(APPEND _cb_cxx_flags "/W4")

# Disable "unreferenced formal parameter" warning
list(APPEND _cb_cxx_flags "/wd4100")

# Microsoft compiler warning C4458, classified as a level 4 warning,
# indicates that a declaration of an identifier in a local scope (within
# a function, for instance) hides the declaration of an identically-named
# identifier at a class scope. This means that within that local scope,
# references to the identifier will resolve to the locally declared version,
# not the class member version.
# We currently have too many of these to fix right now, so just disable
# the warning for now.
list(APPEND _cb_cxx_flags "/wd4458")

# Convert the list to a string
string(REPLACE ";" " " _cb_cxx_options "${_cb_cxx_flags}")

# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
set(CMAKE_CXX_FLAGS_RELEASE        "/MD /O2 /Ob2 /D NDEBUG")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MD /O2 /Ob2 /D NDEBUG /Zi")
set(CMAKE_CXX_FLAGS_DEBUG          "/MDd /Od /Ob0 /Zi")
set(CB_CXX_FLAGS_NO_OPTIMIZE       "/Od /Ob0")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${_cb_cxx_options} -D_ENABLE_EXTENDED_ALIGNED_STORAGE")

message(STATUS "Ignore MSVC linker warning 4099")
# Mute the Link warning 4099 as it floods our output:
# "linking object as if no debug info"
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /IGNORE:4099")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /IGNORE:4099")
set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /IGNORE:4099")
