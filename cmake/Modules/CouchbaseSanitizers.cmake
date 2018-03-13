include(CouchbaseAddressSanitizer)
include(CouchbaseThreadSanitizer)
include(CouchbaseUndefinedBehaviorSanitizer)

# Enable sanitizers for specific target. No-op if none of the
#  Sanitizers are enabled.
function(add_sanitizers TARGET)
    add_sanitize_memory(${TARGET})
    add_sanitize_undefined(${TARGET})
endfunction()
