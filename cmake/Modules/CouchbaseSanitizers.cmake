# Helper function used by CouchbaseAddressSanitizer / UndefinedSanitizer.
# Searches for a sanitizer_lib_name, returning the path in the variable named <path_var>
function(find_sanitizer_library path_var sanitizer_lib_name)
  execute_process(COMMAND ${CMAKE_C_COMPILER} -print-search-dirs
    OUTPUT_VARIABLE cc_search_dirs)
  # Extract the line listing the library paths
  string(REGEX MATCH "libraries: =(.*)\n" _ ${cc_search_dirs})
  # CMAKE expects lists to be semicolon-separated instead of colon.
  string(REPLACE ":" ";" cc_library_dirs ${CMAKE_MATCH_1})
  find_file(${path_var} ${sanitizer_lib_name}
    PATHS ${cc_library_dirs})
endfunction()

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
