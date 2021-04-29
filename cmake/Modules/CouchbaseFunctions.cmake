# 'everything' custom target - build "everything".
#
# Builds targets part of 'ALL' (i.e. everything which isn't marked as
# EXCLUDE_FROM_ALL), plus all targets built via cb_add_test_executable().
#
# This doesn't build absolutely everything; it will not build targets which
# are expliclty marked as EXCLUDE_FROM_ALL (or are under a directory marked
# EXCLUDE_FROM_ALL) - for example third-party libraries' test programs etc.
add_custom_target(everything DEPENDS all)

# Add an executable for a test program / benchmark.
#
# This target is not added to the "all" target, so will not be built by
# default. It is instead added as a dependency of the "everything" target.
# Is it also added to a project-specific "<project>_everything" target, allowing
# an easy way to build everything in a given project - e.g kv_engine_everything.
function(cb_add_test_executable name)
    # TODO: Add 'EXCLUDE_FROM_ALL' to add_executable(); removing tests from the
    # 'all' target.
    add_executable(${name} ${ARGN})
    add_dependencies(everything ${name})

    # Also add to <project>_everything:

    # Get the relative project source dir for the target
    # e.g. /Users/dave/repos/couchbase/server/source/kv_engine -> kv_engine
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" relative_project_dir ${PROJECT_SOURCE_DIR})

    # Get the base directory if this is a sub-project
    # e.g.  kv_engine/engines/ep -> kv_engine
    string(REGEX REPLACE "/.*$" "" base_project_dir ${relative_project_dir})

    # Define the <base_project_dir>_everything target if it doesn't already
    # exist.
    if(NOT TARGET "${base_project_dir}_everything")
        add_custom_target("${base_project_dir}_everything")
    endif()
    add_dependencies("${base_project_dir}_everything" ${name})
endfunction()
