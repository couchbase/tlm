# https://stackoverflow.com/a/68881024/1425601

IF (NOT ListTargetProperties_INCLUDED)

# Sets the CMAKE_PROPERTY_LIST and CMAKE_WHITELISTED_PROPERTY_LIST variables to
# the list of properties
function(get_cmake_property_list)
    # See https://stackoverflow.com/a/44477728/240845
    set(LANGS ASM-ATT ASM ASM_MASM ASM_NASM C CSHARP CUDA CXX FORTRAN HIP ISPC JAVA OBJC OBJCXX RC SWIFT)

    # Get all propreties that cmake supports
    execute_process(COMMAND cmake --help-property-list OUTPUT_VARIABLE CMAKE_PROPERTY_LIST)

    # Convert command output into a CMake list
    string(REGEX REPLACE ";" "\\\\;" CMAKE_PROPERTY_LIST "${CMAKE_PROPERTY_LIST}")
    string(REGEX REPLACE "\n" ";" CMAKE_PROPERTY_LIST "${CMAKE_PROPERTY_LIST}")

    # If CMAKE_CONFIGURATION_TYPES is empty (which it is for many generators),
    # just create a list with CMAKE_BUILD_TYPE.
    if(CMAKE_CONFIGURATION_TYPES)
      set (AVAILABLE_CONFIGURATION_TYPES ${CMAKE_CONFIGURATION_TYPES})
    else()
      set (AVAILABLE_CONFIGURATION_TYPES ${CMAKE_BUILD_TYPE})
    endif()

    # Populate "<CONFIG>" with AVAILBLE_CONFIG_TYPES
    set(CONFIG_LINES ${CMAKE_PROPERTY_LIST})
    list(FILTER CONFIG_LINES INCLUDE REGEX "<CONFIG>")
    list(FILTER CMAKE_PROPERTY_LIST EXCLUDE REGEX "<CONFIG>")
    foreach(CONFIG_LINE IN LISTS CONFIG_LINES)
        foreach(CONFIG_VALUE IN LISTS AVAILABLE_CONFIGURATION_TYPES)
            string(REPLACE "<CONFIG>" "${CONFIG_VALUE}" FIXED "${CONFIG_LINE}")
            list(APPEND CMAKE_PROPERTY_LIST ${FIXED})
        endforeach()
    endforeach()

    # Populate "<LANG>" with LANGS
    set(LANG_LINES ${CMAKE_PROPERTY_LIST})
    list(FILTER LANG_LINES INCLUDE REGEX "<LANG>")
    list(FILTER CMAKE_PROPERTY_LIST EXCLUDE REGEX "<LANG>")
    foreach(LANG_LINE IN LISTS LANG_LINES)
        foreach(LANG IN LISTS LANGS)
            string(REPLACE "<LANG>" "${LANG}" FIXED "${LANG_LINE}")
            list(APPEND CMAKE_PROPERTY_LIST ${FIXED})
        endforeach()
    endforeach()

    # no repeats
    list(REMOVE_DUPLICATES CMAKE_PROPERTY_LIST)

    # Fix https://stackoverflow.com/questions/32197663/how-can-i-remove-the-the-location-property-may-not-be-read-from-target-error-i
    list(FILTER CMAKE_PROPERTY_LIST EXCLUDE REGEX "^LOCATION$|^LOCATION_|_LOCATION$")

    list(SORT CMAKE_PROPERTY_LIST)

    # Whitelisted property list for use with interface libraries to reduce warnings
    set(CMAKE_WHITELISTED_PROPERTY_LIST ${CMAKE_PROPERTY_LIST})

    # regex from https://stackoverflow.com/a/51987470/240845
    list(FILTER CMAKE_WHITELISTED_PROPERTY_LIST INCLUDE REGEX "^(INTERFACE|[_a-z]|IMPORTED_LIBNAME_|MAP_IMPORTED_CONFIG_)|^(COMPATIBLE_INTERFACE_(BOOL|NUMBER_MAX|NUMBER_MIN|STRING)|EXPORT_NAME|IMPORTED(_GLOBAL|_CONFIGURATIONS|_LIBNAME)?|NAME|TYPE|NO_SYSTEM_FROM_IMPORTED)$")

    # make the lists available
    set(CMAKE_PROPERTY_LIST ${CMAKE_PROPERTY_LIST} PARENT_SCOPE)
    set(CMAKE_WHITELISTED_PROPERTY_LIST ${CMAKE_WHITELISTED_PROPERTY_LIST} PARENT_SCOPE)
endfunction()

get_cmake_property_list()

function(print_target_properties tgt)
    if(NOT TARGET ${tgt})
      message("There is no target named '${tgt}'")
      return()
    endif()

    get_target_property(target_type ${tgt} TYPE)
    if(target_type STREQUAL "INTERFACE_LIBRARY")
        set(PROPERTIES ${CMAKE_WHITELISTED_PROPERTY_LIST})    # Fix https://stackoverflow.com/questions/32197663/how-can-i-remove-the-the-location-property-may-not-be-read-from-target-error-i
        list(FILTER CMAKE_PROPERTY_LIST EXCLUDE REGEX "^LOCATION$|^LOCATION_|_LOCATION$")

    else()
        set(PROPERTIES ${CMAKE_PROPERTY_LIST})
    endif()

    foreach (prop ${PROPERTIES})
        # message ("Checking ${prop}")
        get_property(propval TARGET ${tgt} PROPERTY ${prop} SET)
        if (propval)
            get_target_property(propval ${tgt} ${prop})
            message ("Target '${tgt}': ${prop} = ${propval}")
        endif()
    endforeach(prop)
endfunction(print_target_properties)

SET (ListTargetProperties_INCLUDED 1)

ENDIF (NOT ListTargetProperties_INCLUDED)