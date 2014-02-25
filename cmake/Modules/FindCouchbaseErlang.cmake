#find the erlang path
#
# This file is based upon http://code.google.com/p/erlcmake/ which
# is released under MPL 1.1. We've however made "significant" changes
# to make it work for our needs.
#
# This module defines
#  ERLANG_FOUND, if erl and erlc is available
#  ERL_EXECUTABLE, The name of name of the erlang runtime
#  ERLC_EXECUTABLE, The name of name of the erlang compiler
#  ERLANG_INCLUDE_PATH, The directory for erl_nif.h

FIND_PROGRAM(ERLC_EXECUTABLE erlc)
FIND_PROGRAM(ERL_EXECUTABLE erl)

IF (ERLC_EXECUTABLE-NOTFOUND OR ERL_EXECUTABLE-NOTFOUND)
    SET(ERLANG_FOUND False)
    IF (ERL_EXECUTABLE-NOTFOUND)
       MESSAGE(STATUS "Erlang runtime (erl) not found")
    ENDIF (ERL_EXECUTABLE-NOTFOUND)
    IF (ERLC_EXECUTABLE-NOTFOUND)
       MESSAGE(STATUS "Erlang compiler (erlc) not found")
    ENDIF (ERLC_EXECUTABLE-NOTFOUND)
ELSE (ERLC_EXECUTABLE-NOTFOUND OR ERL_EXECUTABLE-NOTFOUND)
    SET(ERLANG_FOUND True)
    GET_FILENAME_COMPONENT(ERL_REAL_EXE ${ERL_EXECUTABLE} REALPATH)
    GET_FILENAME_COMPONENT(ERL_LOCATION ${ERL_REAL_EXE} PATH)
    FIND_PATH(ERLANG_INCLUDE_PATH erl_nif.h
              PATHS
                 ${ERL_LOCATION}/../usr/include
                 /usr/lib/erlang/usr/include
                 /usr/local/lib/erlang/usr/include
                 /opt/local/lib/erlang/usr/include)

    MESSAGE(STATUS "Erlang runtime and compiler found in ${ERL_EXECUTABLE} and ${ERLC_EXECUTABLE}")
    MESSAGE(STATUS "Erlang nif header in ${ERLANG_INCLUDE_PATH}")
ENDIF(ERLC_EXECUTABLE-NOTFOUND OR ERL_EXECUTABLE-NOTFOUND)


MARK_AS_ADVANCED(ERLANG_FOUND ERL_EXECUTABLE ERLC_EXECUTABLE ERLANG_INCLUDE_PATH)

# macro to a a directory to the Erlang include directories
MACRO(ADD_ERLANG_INCLUDE_DIR dir)
    SET(ERLANG_INCLUDE_DIR ${ERLANG_INCLUDE_DIR} -I ${dir})
ENDMACRO(ADD_ERLANG_INCLUDE_DIR)

# macro to compile erlang files
MACRO (ERL_BUILD AppName)
    SET(outfiles)
    GET_FILENAME_COMPONENT(EBIN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ebin" ABSOLUTE)
    IF (IS_DIRECTORY ${EBIN_DIR})
        SET(${AppName}_ebin ${EBIN_DIR})
    ELSE (IS_DIRECTORY ${EBIN_DIR})
        SET(${AppName}_ebin ${CMAKE_CURRENT_BINARY_DIR})
    ENDIF (IS_DIRECTORY ${EBIN_DIR})

    IF (ERLANG_INCLUDE_DIR)
        SET(ERLANG_INCLUDES ${ERLANG_INCLUDE_DIR})
    ENDIF (ERLANG_INCLUDE_DIR)

    SET(${AppName}_src ${CMAKE_CURRENT_SOURCE_DIR})

    #Set application modules
    SET(${AppName}_module_list)

    FOREACH (it ${ARGN})
        GET_FILENAME_COMPONENT(outfile ${it} NAME_WE)
        GET_FILENAME_COMPONENT(outfile_ext ${it} EXT)
        SET(${AppName}_module_list ${${AppName}_module_list} "'${outfile}'")
        IF (${outfile_ext} STREQUAL ".asn" OR ${outfile_ext} STREQUAL ".ASN")
            SET(outfile
                    ${${AppName}_ebin}/${outfile}.erl
                    ${${AppName}_ebin}/${outfile}.hrl
                    ${${AppName}_ebin}/${outfile}.asn1db
                    ${${AppName}_ebin}/${outfile}.beam)
        ELSE(${outfile_ext} STREQUAL ".asn" OR ${outfile_ext} STREQUAL ".ASN")
            SET(outfile
                ${${AppName}_ebin}/${outfile}.beam)
        ENDIF(${outfile_ext} STREQUAL ".asn" OR ${outfile_ext} STREQUAL ".ASN")
        SET(outfiles ${outfiles} ${outfile})
        GET_FILENAME_COMPONENT(it ${it} ABSOLUTE)
        ADD_CUSTOM_COMMAND(
            OUTPUT ${outfile}
            COMMAND ${ERLC_EXECUTABLE} -o ${${AppName}_ebin} ${ERLANG_INCLUDES} ${it}
            DEPENDS ${it}
            VERBATIM)
    ENDFOREACH(it)
    ADD_CUSTOM_TARGET(${AppName} ALL DEPENDS ${outfiles})
ENDMACRO (ERL_BUILD)
