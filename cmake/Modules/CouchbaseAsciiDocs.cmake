FIND_PROGRAM(XMLTO_EXE NAMES xmlto)
FIND_PROGRAM(ASCIIDOC_EXE NAMES asciidoc)

IF (ASCIIDOC_EXE AND XMLTO_EXE)
  MESSAGE(STATUS "Found asciidoc : ${ASCIIDOC_EXE}")
  MESSAGE(STATUS "Found xmlto : ${XMLTO_EXE}")

  MACRO (ASCIIDOC _manpage _section _asciidoc_opts _xmlto_opts)
    set(_invar_txt   ${CMAKE_CURRENT_SOURCE_DIR}/${_manpage}.txt)
    set(_outvar_xml  ${CMAKE_CURRENT_BINARY_DIR}/${_manpage}.xml)
    set(_outvar_html ${CMAKE_CURRENT_BINARY_DIR}/${_manpage}.html)
    set(_outvar_man  ${CMAKE_CURRENT_BINARY_DIR}/${_manpage}.${_section})

    ADD_CUSTOM_COMMAND(
        OUTPUT  ${_outvar_xml}
        COMMAND ${ASCIIDOC_EXE}
                -b docbook -d manpage
                ${_asciidoc_opts}
                -o ${_outvar_xml}
                ${_invar_txt}
        MAIN_DEPENDENCY
                ${_invar_txt}
        WORKING_DIRECTORY
                ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Running asciidoc for xml on \"${_manpage}.txt\"")

    ADD_CUSTOM_COMMAND(
        OUTPUT  ${_outvar_man}
        COMMAND ${XMLTO_EXE}
                ${_xmlto_opts}
                man
                ${_outvar_xml}
        MAIN_DEPENDENCY
                ${_outvar_xml}
        WORKING_DIRECTORY
                ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Generating manpage for \"${_manpage}.xml\"")

    ADD_CUSTOM_COMMAND(
        OUTPUT  ${_outvar_html}
        COMMAND  ${ASCIIDOC_EXE}
                -b xhtml11 -d manpage
                ${_asciidoc_opts}
                -o ${_outvar_html}
                ${_invar_txt}
        MAIN_DEPENDENCY
                ${_invar_txt}
        WORKING_DIRECTORY
                ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Running asciidoc for html on \"${_manpage}.txt\"")

    ADD_CUSTOM_TARGET(doc-man-${_manpage} ALL
        DEPENDS
            ${_outvar_man})

    ADD_CUSTOM_TARGET(doc-html-${_manpage} ALL
        DEPENDS
            ${_outvar_html})

    INSTALL(
        FILES       ${_outvar_man}
        DESTINATION ${MANPAGE_INSTALL_PATH}/man${_section}/
        COMPONENT   documentation)

    INSTALL(
        FILES       ${_outvar_html}
        DESTINATION ${DOCUMENTATION_INSTALL_PATH}/html/
        COMPONENT   documentation)
  ENDMACRO (ASCIIDOC)
ELSE()
  MESSAGE(WARNING "asciidoc and xmlto are required for docs generation, will skip")
  MACRO (ASCIIDOC)
  ENDMACRO (ASCIIDOC)
ENDIF (ASCIIDOC_EXE AND XMLTO_EXE)
