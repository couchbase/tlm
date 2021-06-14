# reuse_pch will reuse the precompiled header of the given target for the given target.
# The function can be globally 'disabled' with CB_PCH=OFF

option(CB_PCH "CB_PCH defines if targets will use pre-compiled headers where configured." ON)

function(reuse_pch target pch_target)
    if (CB_PCH)
        target_precompile_headers(${target} REUSE_FROM ${pch_target})
    endif()
endfunction()
