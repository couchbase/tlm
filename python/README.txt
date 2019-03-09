This directory contains build steps to create "cbpy-installer", which is an
Anaconda-based installer for a customized Python 3 distribution. This
distribution will be installed on customer machines, and that installation
will be used for all Python 3 scripts that we ship.

Therefore, if you write any Python 3 scripts that require a new third-party
Python library, we must add it here to ensure that it is available in
production.

The generated installer will also be installed locally in
$BUILD_DIR/tlm/python/cbpy, for use by local scripts such as those created
by PyWrapper() (defined in tlm/cmake/Modules/FindCouchbasePython.cmake).
