# Helper function for stripping any /opt/gcc* paths from a binary's
# RPATH. This function is intended to be called via an `INSTALL(CODE)`
# directive, not at configuration time.

FUNCTION (StripGccRpathReal binary)

    # Check if the binary exists
    IF (NOT EXISTS "${binary}")
        MESSAGE(FATAL_ERROR "Asked to strip GCC RPATH from ${binary} which does not exist!")
    ENDIF ()

    # Get the current RPATH of the binary
    EXECUTE_PROCESS (
        COMMAND "${chrpath}" -l "${binary}"
        OUTPUT_VARIABLE current_rpath
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_VARIABLE error
        RESULT_VARIABLE result
    )
    IF (NOT result EQUAL 0)
        # chrpath returns 2 if there is no RPATH, and for other errors.
        # Since this whole "strip gcc RPATH" stuff is really just a
        # nice-to-have, we silently ignore any errors.
        RETURN ()
    ENDIF ()

    # Strip chrpath's header output
    STRING (REGEX REPLACE "^.*RPATH=" "" current_rpath "${current_rpath}")

    # Split RPATH into a list
    STRING (REPLACE ":" ";" current_rpath "${current_rpath}")
    LIST (LENGTH current_rpath init_length)

    # Strip /opt/gcc* paths from the RPATH
    LIST (FILTER current_rpath EXCLUDE REGEX "^/opt/gcc")
    LIST (LENGTH current_rpath new_length)

    # If the length of the list has not changed, we have nothing to do
    IF (new_length EQUAL init_length)
        RETURN ()
    ENDIF ()

    # Set the new RPATH for the binary
    EXECUTE_PROCESS (
        COMMAND "${chrpath}" -r "${current_rpath}" "${binary}"
        OUTPUT_QUIET
        RESULT_VARIABLE result
        ERROR_VARIABLE error
    )
    IF (NOT result EQUAL 0)
        MESSAGE(FATAL_ERROR "Failed to set RPATH for ${binary}: ${error}")
    ELSE ()
        STRING (REPLACE ";" ":" current_rpath "${current_rpath}")
        MESSAGE(STATUS "Set runtime path \"${binary}\" to \"${current_rpath}\"")
    ENDIF ()

ENDFUNCTION (StripGccRpathReal)

# Only call the real function on Linux, and only if chrpath is available
# (not an error if it is not)
IF (UNIX AND NOT APPLE)
    # Check if chrpath is available
    FIND_PROGRAM (chrpath NAMES chrpath)

    IF (chrpath)
        MACRO (StripGccRpath binary)
            # Call the function to strip the RPATH
            StripGccRpathReal("${binary}")
        ENDMACRO (StripGccRpath)
    ENDIF ()
ENDIF ()

IF (NOT COMMAND StripGccRpath)
    # Install a stub macro that does nothing
    MACRO (StripGccRpath binary)
    ENDMACRO (StripGccRpath)
ENDIF ()
