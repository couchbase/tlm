# Unset GOROOT in the environment (which will make Go figure it out from
# the path to the go compiler on disk, which is what we want)
SET (ENV{GOROOT})

# Prevent Go from automatically downloading a different toolchain version
# based on 'toolchain' directives in go.mod files.
SET (ENV{GOTOOLCHAIN} "local")

# Use GOPATH to tell Go where to store downloaded and cached Go modules.
# It will put things into pkg/mod.
SET (ENV{GOPATH} "${GO_BINARY_DIR}")

# Use GOCACHE to tell Go where to store intermediate compilation artifacts.
# It places things directly into this directory, so we append /cache.
SET (ENV{GOCACHE} "${GO_BINARY_DIR}/cache")

# If this is a production build, set/override GOPROXY.
# (For now, not on AWS since it doesn't have access to our proxy.)
IF (CB_PRODUCTION_BUILD AND NOT EXISTS "/aws")
  SET (ENV{GOPROXY} "http://goproxy.build.couchbase.com/")
ENDIF ()

# Execute "go mod tidy".
EXECUTE_PROCESS (
  RESULT_VARIABLE _failure
  COMMAND "${GOEXE}" mod tidy -v -modcacherw)

IF (_failure)
  MESSAGE (FATAL_ERROR "Failed running go mod tidy")
ENDIF (_failure)
