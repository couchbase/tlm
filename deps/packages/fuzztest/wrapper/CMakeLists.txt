cmake_minimum_required(VERSION 3.19)
project(fuzztest)
include(FetchContent)
include(../../../../cmake/Modules/PopulateFuzzTestDependencies.cmake)

# Now we can fetch and make available the fuzztest sources.
FetchContent_Declare(fuzztest_subbuild
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG ${_git_rev})
FetchContent_MakeAvailable(fuzztest_subbuild)

# Install all targets from the fuzztest and common directories
get_property(main_targets DIRECTORY "${fuzztest_subbuild_SOURCE_DIR}/fuzztest" PROPERTY BUILDSYSTEM_TARGETS)
get_property(common_targets DIRECTORY "${fuzztest_subbuild_SOURCE_DIR}/common" PROPERTY BUILDSYSTEM_TARGETS)
set(install_targets ${main_targets} ${common_targets})

foreach(target IN LISTS install_targets)
    # Check if target name starts with "fuzztest_" and skip it.
    # Once on CMake 4.1, we can use REGEX REPLACE with "^fuzztest_" to remove
    # the prefix. We need to use CMP0186, to avoid replacing
    # "fuzztest_fuzztest_abc" to "abc".
    string(FIND ${target} "fuzztest_" prefix_pos)
    if(prefix_pos EQUAL 0)
        string(LENGTH "fuzztest_" prefix_length)
        string(SUBSTRING ${target} ${prefix_length} -1 exported_name)
        set_target_properties(${target} PROPERTIES EXPORT_NAME ${exported_name})
    endif()
endforeach()

install(TARGETS ${install_targets}
    EXPORT ${CMAKE_PROJECT_NAME}Targets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${CMAKE_PROJECT_NAME}
)
install(EXPORT ${CMAKE_PROJECT_NAME}Targets
    FILE ${CMAKE_PROJECT_NAME}Targets.cmake
    NAMESPACE ${CMAKE_PROJECT_NAME}::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${CMAKE_PROJECT_NAME}
)

# Create a Config file
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}ConfigVersion.cmake"
    VERSION ${_git_rev}
    COMPATIBILITY SameMajorVersion
)
configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}Config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}Config.cmake"
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${CMAKE_PROJECT_NAME}
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}Config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}ConfigVersion.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${CMAKE_PROJECT_NAME}
)

# Glob recursively all header files
file(GLOB_RECURSE header_files RELATIVE ${fuzztest_subbuild_SOURCE_DIR}
    ${fuzztest_subbuild_SOURCE_DIR}/fuzztest/*.h
    ${fuzztest_subbuild_SOURCE_DIR}/common/*.h
)

# Install each header file in the source tree
foreach(header_file IN LISTS header_files)
    # Get the directory of the header file
    get_filename_component(header_file_dir ${header_file} PATH)
    install(FILES ${fuzztest_subbuild_SOURCE_DIR}/${header_file} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${header_file_dir})
endforeach()

install(FILES
    "${fuzztest_subbuild_SOURCE_DIR}/cmake/AddFuzzTest.cmake"
    "${fuzztest_subbuild_SOURCE_DIR}/cmake/FuzzTestFlagSetup.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${CMAKE_PROJECT_NAME}
)
