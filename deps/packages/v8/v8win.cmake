SET (ENV{DEPOT_TOOLS_WIN_TOOLCHAIN} 0)
SET (ENV{GYP_GENERATORS} "ninja")
SET (GYP_FLAGS "-Dcomponent=shared_library" "-Dv8_enable_backtrace=1"
               "-Dv8_use_snapshot=true" "-Dv8_use_external_startup_data=0"
               "-Dv8_enable_i18n_support=1" "-Dtest_isolation_mode=noop"
               "-Dv8_target_arch=${V8_TARGET_ARCH}")
EXECUTE_PROCESS(COMMAND "python" "gypfiles\\gyp_v8" ${GYP_FLAGS})
