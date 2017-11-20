# Locate and configure Valgrind for memory checking.

find_program( MEMORYCHECK_COMMAND valgrind )
set( _valgrind_options "--gen-suppressions=all"
                       "--leak-check=full"
                       "--num-callers=32"
                       "--partial-loads-ok=yes"
                       "--show-leak-kinds=all"
                       # MB-26684: New features we introduced in RocksDBKVStore
                       # led to the execution of the 'malloc_usable_size' function.
                       # While the 'new' and  'delete' operators in 'libstd++' are
                       # correctly redirected to the Valgrind ones, we need to tell
                       # Valgrind to redirect also the 'malloc_usable_size' function in
                       # 'libplatform'. Missing that leads to SegFault when the
                       # non-Valgrind 'malloc_usable_size' is called giving in input a
                       # pointer to a Valgrind-allocated block of memory.
                       "--soname-synonyms=somalloc=libplatform_so.*"
                       "--suppressions=${CMAKE_SOURCE_DIR}/tlm/valgrind.supp"
                       "--trace-children=yes"
                       "--track-origins=yes"
                       "--xml=yes --xml-file=memcheck.%p.xml" )

string(REPLACE ";" " " MEMORYCHECK_COMMAND_OPTIONS "${_valgrind_options}")
