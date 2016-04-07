# Locate and configure Valgrind for memory checking.

find_program( MEMORYCHECK_COMMAND valgrind )
set( MEMORYCHECK_COMMAND_OPTIONS "--trace-children=yes --leak-check=full --show-leak-kinds=all --partial-loads-ok=yes --num-callers=32 --track-origins=yes --suppressions=${CMAKE_SOURCE_DIR}/tlm/valgrind.supp --xml=yes --xml-file=memcheck.%p.xml" )
