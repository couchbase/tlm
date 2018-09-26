echo start build at `date`

thisdir=`pwd`
version="5.10.4.0.0.1"
release="R16B03-1"

## get the source code
git clone git://github.com/couchbasedeps/erlang otp_src_${release}
cd otp_src_${release}
git checkout couchbase

## per instructions, get tcl from erlang website
## without this the build will fail
## (alternative is to create a lib/gs/SKIP file)
wget http://www.erlang.org/download/tcltk85_win32_bin.tar.gz
gunzip tcltk85_win32_bin.tar.gz
tar xf tcltk85_win32_bin.tar

## build the source, as per instructions
eval `./otp_build env_win32 x64`
./otp_build autoconf 2>&1 | tee autoconf.out
./otp_build configure --with-ssl=/cygdrive/c/OpenSSL-Win64 2>&1 | tee configure.out
./otp_build boot -a 2>&1 | tee boot.out
./otp_build release -a 2>&1 | tee release.out
#./otp_build debuginfo_win32 -a 2>&1 | tee dbginfo.out

## what the "release -a" command generates above in release/win32
## is not ## what is packaged in the installer executable.
## the installer executable also has other files like
## lib, bin -- some of which are partly also in the release/win32
## folder but there are some extra files
## so, generate an installer and use that to install it to default
## location
./otp_build installer_win32 2>&1 | tee installerwin32.out
./release/win32/otp_win64_${release}.exe /S

installdir=/cygdrive/c/Program\ Files/erl${version}

## we need VERSION.txt, erl.in.ini and CMakeLists.txt for our internal
## cbdeps consumption. We could check the files in with placeholder
## tokens for version. But I am just generating them here dynamically
## because they are tiny files
echo $release > VERSION.txt
echo "[erlang]
Bindir=\${CMAKE_INSTALL_PREFIX}/erts-${version}/bin
Progname=erl
Rootdir=\${CMAKE_INSTALL_PREFIX}
" > erl.ini.in

echo "# Just copy contents to CMAKE_INSTALL_PREFIX
FILE (COPY bin erts-${version} lib releases usr DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")
# And install erl.ini with correct paths
CONFIGURE_FILE(\${CMAKE_CURRENT_SOURCE_DIR}/erl.ini.in \${CMAKE_INSTALL_PREFIX}/bin/erl.ini)
" > CMakeLists.txt

## tar 'em up
cp VERSION.txt erl.ini.in CMakeLists.txt "${installdir}"
cd "${installdir}"
tar --exclude="Install.exe" --exclude="Install.ini" --exclude="Uninstall.exe" -zcf ${thisdir}/erlang-windows_msvc2015-amd64-${release}-couchbase-cb9.tgz *
rm -f VERSION.txt erl.ini.in CMakeLists.txt

## uninstall the erlang installation
"${installdir}/Uninstall.exe" /S

echo end build at `date`
