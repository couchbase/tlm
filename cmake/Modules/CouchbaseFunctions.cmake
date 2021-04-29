# Add an executable for a test program / benchmark.
#
# This target is not added to the "all" target, so will not be built by
# default. It is instead added as a dependency of the "everything" target.
# Is it also added to a project-specific "<project>_everything" target, allowing
# an easy way to build everything in a given project - e.g kv_engine_everything.
function(cb_add_test_executable name)
    add_executable(${name} EXCLUDE_FROM_ALL ${ARGN})
    set_property(TARGET ${name} PROPERTY CB_TEST_EXECUTABLE ON)
endfunction()

macro(get_all_targets_recursive targets dir)
    get_property(subdirectories DIRECTORY ${dir} PROPERTY SUBDIRECTORIES)
    foreach(subdir ${subdirectories})
        get_property(exclude_from_all DIRECTORY ${subdir} PROPERTY EXCLUDE_FROM_ALL)
        if(NOT exclude_from_all)
            get_all_targets_recursive(${targets} ${subdir})
        endif()
    endforeach()

    get_property(current_targets DIRECTORY ${dir} PROPERTY BUILDSYSTEM_TARGETS)
    list(APPEND ${targets} ${current_targets})
endmacro()

# Define 'everything' custom target - build "everything".
#
# Define a target named "everything" which builds:
# a) Targets which are part of 'ALL' (i.e. everything which isn't marked as
#    EXCLUDE_FROM_ALL), plus
# b) all targets built via cb_add_test_executable().
#
# This doesn't build absolutely everything; it will not build targets which
# are explictly marked as EXCLUDE_FROM_ALL and not otherwise marked as
# CB_TEST_EXECUTABLE - for example third-party libraries' test programs will
# still be skipped.
#
# Note this function must be called after all targets have been defined - as
# it must recursively scan all directories to locate all defined targets.
function(define_everything_targets)
    add_custom_target(everything)
    set(targets)
    get_all_targets_recursive(targets ${CMAKE_CURRENT_SOURCE_DIR})

    # Add to project-specific everything target (<project>_everything):
    foreach(target ${targets})
        # Skip INTERFACE targets - they aren't part of all or test executables,
        # and additionally it's an error for us to try to read custom
        # properties on them.
        get_property(target_type TARGET ${target} PROPERTY TYPE)
        if(NOT (target_type STREQUAL "INTERFACE" OR target_type STREQUAL "INTERFACE_LIBRARY"))
            # Read EXCLUDE_FROM_ALL and CB_TEST_EXECUTABLE properties of
            # the target.
            get_property(exclude_from_all TARGET ${target} PROPERTY EXCLUDE_FROM_ALL)
            get_property(cb_test_executable TARGET ${target} PROPERTY CB_TEST_EXECUTABLE)

            # Add to the *everything targets if target doesn't have
            # EXCLUDE_FROM_ALL set or does have CB_TEST_EXECUTABLE set.
            if ((NOT exclude_from_all) OR cb_test_executable)
                # Get the relative project source dir for the target
                # e.g. /Users/dave/repos/couchbase/server/source/kv_engine -> kv_engine
                get_property(target_source_dir TARGET ${target} PROPERTY SOURCE_DIR)
                string(REPLACE "${CMAKE_SOURCE_DIR}/" "" relative_project_dir ${target_source_dir})

                # Get the base directory if this is a sub-project
                # e.g.  kv_engine/engines/ep -> kv_engine
                string(REGEX REPLACE "/.*$" "" base_project_dir ${relative_project_dir})

                # Define the <base_project_dir>_everything target if it doesn't already
                # exist.
                if(NOT TARGET "${base_project_dir}_everything")
                    add_custom_target("${base_project_dir}_everything")
                    add_dependencies("everything" "${base_project_dir}_everything")
                endif()
                add_dependencies("${base_project_dir}_everything" ${target})
            endif ((NOT exclude_from_all) OR cb_test_executable)
        endif(NOT (target_type STREQUAL "INTERFACE" OR target_type STREQUAL "INTERFACE_LIBRARY"))
    endforeach()
endfunction()
