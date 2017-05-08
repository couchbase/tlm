if (NOT APPLE)
    message(FATAL_ERROR "Transport Security is only to be used on MacOSX")
endif (NOT APPLE)

# In order to use the Transport Security we need to use the
# Security and CoreFoundation frameworks.

FIND_LIBRARY(_security_lib
             NAMES Security)

if (_security_lib)
    list(APPEND TRANSPORT_SECURITY_LIBRARIES ${_security_lib})
else ()
    message(FATAL_ERROR Failed to locate the Security framework)
endif ()

find_library(_core_foundation_lib
             NAMES CoreFoundation)
if (_core_foundation_lib)
    list(APPEND TRANSPORT_SECURITY_LIBRARIES ${_core_foundation_lib})
else ()
    message(FATAL_ERROR Failed to locate the CoreFoundation framework)
endif ()

mark_as_advanced(TRANSPORT_SECURITY_LIBRARIES)
