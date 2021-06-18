# reuse_pch will reuse the precompiled header of the given target for the given target.
# The function can be globally 'disabled' with CB_PCH=OFF

option(CB_PCH "CB_PCH defines if targets will use pre-compiled headers where configured." ON)

function(reuse_pch target pch_target)
    if (CB_PCH)
        target_precompile_headers(${target} REUSE_FROM ${pch_target})

        # Also need to link to pch_target so the target picks up include paths
        # for the preprocessed headers. This isn't _strictly_ needed for a
        # straight CMake build; but ccache wants to preprocess each source
        # file by taking CMake-generated compile command and adding '-E' or
        # similar, which requires the actual target source files can locate
        # all "raw" precompiled headers themselves.
        target_link_libraries(${target} PRIVATE ${pch_target})
    endif()
endfunction()
