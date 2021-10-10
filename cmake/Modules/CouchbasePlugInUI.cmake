CMAKE_MINIMUM_REQUIRED (VERSION 3.19)

# Prevent double-definition if two projects use this script
IF (NOT PLUG_IN_UI_INCLUDED)
  SET (PLUG_IN_UI_INCLUDED 1)
  SET (NS_UI_BUILD_DIR "${CMAKE_BINARY_DIR}/ui-build")
  SET (NS_UI_INSTALL_DIR "lib/ns_server/erlang/lib/ns_server/priv/public")
  SET (NS_UI_PUB_DIR "${NS_UI_BUILD_DIR}/public")
  FILE (REMOVE "${NS_UI_BUILD_DIR}/public/pluggable-uis.js")

  MACRO(WATCH_AND_COPY_SOURCES src_dir bin_dir stamp_path service_name)
    FILE (GLOB_RECURSE UI_SRC_JS_FILES CONFIGURE_DEPENDS "${src_dir}/*.js")
    ADD_CUSTOM_COMMAND (OUTPUT "${bin_dir}"
      COMMAND ${CMAKE_COMMAND} -E create_symlink "${src_dir}" "${bin_dir}")
    ADD_CUSTOM_COMMAND (OUTPUT "${stamp_path}.js.stamp"
      COMMAND "${CMAKE_COMMAND}" -E touch "${stamp_path}.js.stamp"
      DEPENDS ${UI_SRC_JS_FILES}
      VERBATIM)
    ADD_CUSTOM_TARGET ("${service_name}_ui_build_prepare"
      DEPENDS "${bin_dir}"
      DEPENDS "${stamp_path}.js.stamp")
    ADD_DEPENDENCIES (ui_build "${service_name}_ui_build_prepare")
  ENDMACRO(WATCH_AND_COPY_SOURCES)

  MACRO(PLUG_IN_UI pluggable_ui_json_name)
    SET (PLUGGABLE_UI_BUILD_DIR "${NS_UI_BUILD_DIR}/public/_p/ui")
    SET (PLUGGABLE_UI_JSON_NAME "${pluggable_ui_json_name}.json")

    # rewrite the config file for installation
    SET (BIN_PREFIX "")
    CONFIGURE_FILE ("${pluggable_ui_json_name}.json.in" "${pluggable_ui_json_name}.json")

    # read interesting json fields
    FILE (READ "${CMAKE_CURRENT_BINARY_DIR}/${pluggable_ui_json_name}.json" PLUGGABLE_UI_JSON)
    STRING (JSON SERVICE_NAME GET ${PLUGGABLE_UI_JSON} service)
    STRING (JSON RES_API_PREFIX MEMBER ${PLUGGABLE_UI_JSON} rest-api-prefixes 0)
    STRING (JSON DOC_ROOT GET ${PLUGGABLE_UI_JSON} doc-root)
    STRING (JSON VERSION_DIR GET ${PLUGGABLE_UI_JSON} version-dirs 0 dir)
    STRING (JSON MODULE_JS GET ${PLUGGABLE_UI_JSON} module)
    FILE (APPEND "${NS_UI_BUILD_DIR}/public/pluggable-uis.js"
      "import pluggableUI_${SERVICE_NAME} from \"./_p/ui/${RES_API_PREFIX}/${VERSION_DIR}/${MODULE_JS}\";\nexport {pluggableUI_${SERVICE_NAME}}\n")


    SET (PLUGGABLE_UI_SRC "${CMAKE_CURRENT_SOURCE_DIR}/${DOC_ROOT}")
    SET (PLUGGABLE_UI_BIN "${PLUGGABLE_UI_BUILD_DIR}/${RES_API_PREFIX}")
    SET (PLUGGABLE_UI_STAMP "${NS_UI_BUILD_DIR}/${RES_API_PREFIX}")

    FILE (MAKE_DIRECTORY "${PLUGGABLE_UI_BUILD_DIR}")
    WATCH_AND_COPY_SOURCES(
      ${PLUGGABLE_UI_SRC}
      ${PLUGGABLE_UI_BIN}
      ${PLUGGABLE_UI_STAMP}
      ${RES_API_PREFIX})

    # copy rewritten config file and code to install directory
    INSTALL (
      FILES "${PROJECT_BINARY_DIR}/${pluggable_ui_json_name}.json"
      DESTINATION "etc/couchbase")

    # rewrite the config file for running locally (using cluster-run)
    SET (BIN_PREFIX "${PROJECT_SOURCE_DIR}/")
    CONFIGURE_FILE (
      "${pluggable_ui_json_name}.json.in"
      "${CMAKE_BINARY_DIR}/cluster_run_ui_plugins/${pluggable_ui_json_name}.cluster_run.json")

    INSTALL (DIRECTORY "${PLUGGABLE_UI_SRC}/"
      DESTINATION "${NS_UI_INSTALL_DIR}/_p/ui/${RES_API_PREFIX}"
      REGEX libs-standalone EXCLUDE
      PATTERN "*standalone.*" EXCLUDE
      PATTERN "*.js" EXCLUDE)

  ENDMACRO(PLUG_IN_UI)

ENDIF(NOT PLUG_IN_UI_INCLUDED)
