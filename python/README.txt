Due to Anaconda's increased enforcement of access to their repositories,
we are switching Couchbase Server 6.6.x to use the cbdeps version of
cbpy that is pre-built, which makes our build simpler and faster. It
also has more updated third-party components which have fewer security
vulnerabilities.

As of now the cbdeps package itself does not contain a Black Duck
manifest, so we have to manually copy it from the cheshire-cat branch of
tlm. Whenever we update the cbpy package used in 6.6.x, we must remember
to copy the corresponding couchbase-server-black-duck-manifest.yaml into
this directory so it will be picked up by our scans.
