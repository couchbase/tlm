# Couchbase use a different SSL implementation on various platforms.
# For Mac we want to use Transport Security
# For Windows we want to use Secure Channels (Not there yet, not even started)
# If we don't have a specialized implementation, we're using OpenSSL

if (APPLE)
    include(FindCouchbaseTransportSecurity)
    # The transition to Transport Security is not complete, so we still need
    # OpenSSL available
    include(FindCouchbaseOpenSSL)
    set(CB_SSL_INCLUDE_DIR "")
    set(CB_SSL_LIBRARIES "${TRANSPORT_SECURITY_LIBRARIES}")
else (APPLE)
    include(FindCouchbaseOpenSSL)
    set(CB_SSL_INCLUDE_DIR ${OPENSSL_INCLUDE_DIR})
    set(CB_SSL_LIBRARIES ${OPENSSL_LIBRARIES})
endif (APPLE)

MARK_AS_ADVANCED(CB_SSL_INCLUDE_DIR CB_SSL_LIBRARIES)
