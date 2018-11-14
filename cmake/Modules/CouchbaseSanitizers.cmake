include(CouchbaseAddressSanitizer)
include(CouchbaseThreadSanitizer)
include(CouchbaseUndefinedBehaviorSanitizer)

# Enable sanitizers for specific target. No-op if none of the
#  Sanitizers are enabled.
function(add_sanitizers TARGET)
    add_sanitize_memory(${TARGET})
    add_sanitize_undefined(${TARGET})
endfunction()

# Override and always disable sanitizers for specific target. Useful
# when a target is incompatible with sanitizers.
# No-op if one of the sanitizers are enabled.
function(remove_sanitizers TARGET)
    remove_sanitize_memory(${TARGET})
    remove_sanitize_undefined(${TARGET})
endfunction()
