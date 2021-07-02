# reuse_pch will reuse the precompiled header of the given target for the given target.
# The function can be globally 'disabled' with CB_PCH=OFF

option(CB_PCH "CB_PCH defines if targets will use pre-compiled headers where configured." ON)

function(reuse_pch target pch_target)
    if (CB_PCH)
        target_precompile_headers(${target} REUSE_FROM ${pch_target})

        # Also need to propogate any include directories from the pch_target,
        # so the target picks up include paths for the preprocessed headers.
        # This isn't _strictly_ needed for a straight CMake build; but ccache
        # wants to preprocess each source file by taking CMake-generated
        # compile command and adding '-E' or similar, which requires the actual
        # target source files can locate all "raw" precompiled headers
        # themselves.
        # Note: We don't want to propagate _all_ dependancies (libraries etc),
        # just the include paths - if we propogate libraries say using:
        #
        #     target_link_libraries(${target} PRIVATE ${pch_target})
        #
        # then we can end up lnking the PCH "library" twice - once via
        # target_precompile_headers() above and once via target_link_libraries()
        # which results in linker warnings with MSVC.

        # Propagate INTERFACE_INCLUDE_DIRECTORIES properties set directly on
        # the PCH target to the target.
        get_target_property(include_dirs ${pch_target} INTERFACE_INCLUDE_DIRECTORIES)
        set_property(TARGET ${target} APPEND PROPERTY INCLUDE_DIRECTORIES ${include_dirs})

        # Propagate any INTERFACE_INCLUDE_DIRECTORIES which come via
        # LINK_LIBRARIES on the PCH target to the target.
        get_target_property(target_type "${pch_target}" TYPE)
        if (${target_type} STREQUAL "INTERFACE_LIBRARY")
            get_target_property(libs "${pch_target}" INTERFACE_LINK_LIBRARIES)
        else()
            get_target_property(libs "${pch_target}" LINK_LIBRARIES)
        endif()
        foreach(lib IN LISTS libs)
            if(NOT TARGET "${lib}")
                continue()
            endif()

            get_target_property(include_dirs ${lib} INTERFACE_INCLUDE_DIRECTORIES)
            set_property(TARGET ${target} APPEND PROPERTY INCLUDE_DIRECTORIES ${include_dirs})
        endforeach()
    endif()
endfunction()
