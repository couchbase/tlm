# Locate and configure Valgrind for memory checking.

find_program( MEMORYCHECK_COMMAND valgrind )
set( _valgrind_options "--gen-suppressions=all"
                       "--leak-check=full"
                       "--num-callers=32"
                       "--partial-loads-ok=yes"
                       "--show-leak-kinds=all"
                       "--suppressions=${CMAKE_SOURCE_DIR}/tlm/valgrind.supp"
                       "--trace-children=yes"
                       "--track-origins=yes"
                       "--xml=yes --xml-file=memcheck.%p.xml" )

string(REPLACE ";" " " MEMORYCHECK_COMMAND_OPTIONS "${_valgrind_options}")
