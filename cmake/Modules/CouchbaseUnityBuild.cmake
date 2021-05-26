# cb_enable_unity_build will enable unity building for the given TARGET.
# The function can be globally 'disabled' with CB_UNITY_BUILD=OFF

option(CB_UNITY_BUILD "CB_UNITY_BUILD defines if targets that use cb_enable_unity_build will use a unity build." ON)

function(cb_enable_unity_build TARGET)
if (CB_UNITY_BUILD)
    set_target_properties(${TARGET} PROPERTIES UNITY_BUILD ON)
endif()
endfunction()
