# reuse_pch will reuse the precompiled header of the given target for the given target.
# The function can be globally 'disabled' with CB_PCH=OFF

option(CB_PCH "CB_PCH defines if targets will use pre-compiled headers where configured." ON)

# Clang-11 (and at least AppleClang 12.0.5) upwards support instantiating
# templates as part of precompiled headers; this can significantly speed up
# (1.3x) building as we only need to instantiate templates from precompiled
# headers once, instead of every time the templates are needed.
# While CMake 3.19 enables this automatically for Clang when supported, it does
# not for AppleClang - see
# https://gitlab.kitware.com/cmake/cmake/-/issues/21133
# Given the boost this gives, manually enable it for AppleClang here if
# compiler supports it.
if (CB_PCH AND APPLE)
    check_cxx_compiler_flag(-fpch-instantiate-templates
            HAVE_PCH_INSTANTIATE_TEMPLATES)
    if (HAVE_PCH_INSTANTIATE_TEMPLATES)
        # Note: Technically we only need this to be added to the compilation
        # of the precompiled header itself, not all targets, however CMake
        # doesn't expose an easy way to set compile arguments for PCH building,
        # and (Apple)Clang ignores it if not compiling a header, so just
        # add to the global CXX flags variable.
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fpch-instantiate-templates")
    endif()
endif()

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
