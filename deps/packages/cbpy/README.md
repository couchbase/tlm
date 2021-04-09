This directory contains build steps to create "cbpy-installer", which is an
Anaconda-based installer for a customized Python 3 distribution. This
distribution will be installed on customer machines, and that installation
will be used for all Python 3 scripts that we ship.

Therefore, if you write any Python 3 scripts that require a new third-party
Python library, we must add it here to ensure that it is available in
production.

This used to be part of the Server build itself, but as it grew somewhat more
complex, it made sense to pull it out to a separate build. I'm making this a
cbdeps 1.0 package (ie, here in tlm/deps/packages rather than driven by a
separate manifest) because this actually IS effectively part of the Server
build. This also means we can keep the couchbase-server-specific Black Duck
manifest here in the same location as construct.yaml, making it easier to keep
them in sync.
