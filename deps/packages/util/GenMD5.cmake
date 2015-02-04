# Generate the .md5 file for a given file
# args: FILE = filename to compute md5 of, MD5FILE = md5 filename
FILE (MD5 "${FILE}" _md5)
FILE (WRITE "${MD5FILE}" ${_md5})
