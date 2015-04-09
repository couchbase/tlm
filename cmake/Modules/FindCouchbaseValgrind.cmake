# Locate and configure Valgrind for memory checking.

find_program( MEMORYCHECK_COMMAND valgrind )
set( MEMORYCHECK_COMMAND_OPTIONS "--trace-children=yes --leak-check=full --xml=yes --xml-file=memcheck.%p.xml" )
