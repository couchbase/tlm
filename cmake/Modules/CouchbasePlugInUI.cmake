CMAKE_MINIMUM_REQUIRED (VERSION 3.19)

# Prevent double-definition if two projects use this script
IF (NOT PLUG_IN_UI_INCLUDED)
  SET (PLUG_IN_UI_INCLUDED 1)
  SET (NS_UI_BUILD_DIR "${CMAKE_BINARY_DIR}/ui-build")
  SET (NS_UI_INSTALL_DIR "lib/ns_server/erlang/lib/ns_server/priv/public")
  SET (NS_UI_PUB_DIR "${NS_UI_BUILD_DIR}/public")

  MACRO(PLUG_IN_UI pluggable_ui_json_name)
    SET (PLUGGABLE_UI_BUILD_DIR "${NS_UI_BUILD_DIR}/public/_p/ui")
    SET (PLUGGABLE_UI_JSON_NAME "${pluggable_ui_json_name}.json")

    # rewrite the config file for installation
    SET (BIN_PREFIX "")
    CONFIGURE_FILE ("${PLUGGABLE_UI_JSON_NAME}.in" "${PLUGGABLE_UI_JSON_NAME}")

    # copy rewritten config file and code to install directory
    INSTALL (
      FILES "${PROJECT_BINARY_DIR}/${PLUGGABLE_UI_JSON_NAME}"
      DESTINATION "etc/couchbase")
  ENDMACRO(PLUG_IN_UI)

ENDIF(NOT PLUG_IN_UI_INCLUDED)
