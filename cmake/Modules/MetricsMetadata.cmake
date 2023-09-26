# Provides functions for testing and installing metrics_metadata.json files.

IF (NOT MetricsMetadata_INCLUDED)

  # Have to remember cwd when this file is INCLUDE()d
  SET (TLM_MODULES_DIR "${CMAKE_CURRENT_LIST_DIR}")

  # We'll use this if it's available
  FIND_PROGRAM(JQ_EXE jq)

  # Adds a target to verify and install a metrics_metadata.json file.
  #
  # Required arguments:
  #   JSON - path to .json file
  #   COMPONENT - name of the component these metrics are for.
  #
  # This will install the JSON file as
  #   ${CMAKE_INSTALL_PREFIX}/etc/couchbase/COMPONENT/metrics_metadata.json.
  #
  # If the 'jq' utility was found, it will sort the top-level keys of this
  # file (this is required for production builds). Otherwise it will simply
  # parse the file to ensure it is valid JSON.
  MACRO (AddMetricsMetadata)
    PARSE_ARGUMENTS(mm "JSON;COMPONENT" "" "" ${ARGN})

    IF (NOT mm_JSON)
      MESSAGE (FATAL_ERROR "JSON is required!")
    ENDIF ()
    IF (NOT mm_COMPONENT)
      MESSAGE (FATAL_ERROR "COMPONENT is required!")
    ENDIF ()

    IF (CB_PRODUCTION_BUILD AND NOT JQ_EXE AND UNIX AND NOT APPLE)
      MESSAGE (FATAL_ERROR "'jq' not found - required for Linux production builds!")
    ENDIF ()

    SET (_outdir "${CMAKE_CURRENT_BINARY_DIR}/etc/couchbase/${mm_COMPONENT}")
    FILE (MAKE_DIRECTORY "${_outdir}")
    SET (_outputfile "${_outdir}/metrics_metadata.json")

    ADD_CUSTOM_COMMAND(
      OUTPUT "${_outputfile}"
      DEPENDS "${mm_JSON}"
      COMMAND "${CMAKE_COMMAND}"
      -D "JQ_EXE=${JQ_EXE}"
      -D "JSON_IN=${mm_JSON}"
      -D "JSON_OUT=${_outputfile}"
      -P "${TLM_MODULES_DIR}/add_metrics_metadata.cmake"
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
      VERBATIM
    )
    ADD_CUSTOM_TARGET(
      "${mm_COMPONENT}_metrics_metadata" ALL
      DEPENDS "${_outputfile}"
    )
    INSTALL(
      FILES "${_outputfile}"
      DESTINATION "etc/couchbase/${mm_COMPONENT}"
    )

  ENDMACRO (AddMetricsMetadata)

  SET (MetricsMetadata_INCLUDED 1)
ENDIF (NOT MetricsMetadata_INCLUDED)
