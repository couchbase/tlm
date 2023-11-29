set INSTALL_DIR=%1
set PLATFORM=%2
set VERSION=%3
set CBDEPS_DIR=%4

rem Build and install abseil, cares and protobuf from third_party
cd third_party/abseil-cpp

rem Fix missing iomanip include
setlocal enabledelayedexpansion
set "inputfile=.\absl\time\civil_time_test.cc"
set "outputfile=.\absl\time\civil_time_test.cc.fixed"
set "missing_include=#include ^<iomanip^>"
findstr /m /c:"%missing_include%" "%inputfile%"
if %errorlevel%==1 (
    (
        echo %missing_include%
        type "%inputfile%"
    ) > "%outputfile%"
)
move /Y "%outputfile%" "%inputfile%"
type "%inputfile%"
endlocal

mkdir build
cd build
cmake -G Ninja ^
  -DCMAKE_CXX_STANDARD=17 ^
  -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
  -DABSL_BUILD_TESTING=OFF ^
  -DABSL_PROPAGATE_CXX_STD=ON ^
  -DABSL_USE_GOOGLETEST_HEAD=ON ^
  -DCMAKE_INSTALL_PREFIX=%INSTALL_DIR% ^
  -DCMAKE_INSTALL_LIBDIR=lib ^
  .. || goto error
ninja install || goto error
cd ../../..

cd third_party\protobuf\cmake
mkdir build
cd build
cmake -G Ninja ^
  -DCMAKE_CXX_STANDARD=17 ^
  -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl ^
  -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
  -DCMAKE_INSTALL_PREFIX="%INSTALL_DIR%" ^
  -DCMAKE_INSTALL_LIBDIR=lib ^
  -Dprotobuf_ABSL_PROVIDER=package ^
  -Dprotobuf_BUILD_TESTS=OFF ^
  -Dprotobuf_MSVC_STATIC_RUNTIME=OFF ^
  -DCMAKE_PREFIX_PATH="%CBDEPS_DIR%/zlib.exploded;%INSTALL_DIR%" ^
  ../.. || goto error
ninja install || goto error
cd ..\..\..\..

cd third_party\cares\cares
mkdir build
cd build
cmake -G Ninja ^
  -DCMAKE_CXX_STANDARD=17 ^
  -DCMAKE_C_COMPILER=cl ^
  -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
  -DCMAKE_INSTALL_PREFIX=%INSTALL_DIR% ^
  -DCARES_STATIC=ON -DCARES_STATIC_PIC=ON -DCARES_SHARED=OFF ^
  .. || goto error
ninja install || goto error
cd ..\..\..\..

rem Build grpc binaries and libraries
rem Protobuf_USE_STATIC_LIBS necessary due to bug in CMake:
rem https://gitlab.kitware.com/paraview/paraview/issues/19527
mkdir .build
cd .build
cmake -G Ninja ^
  -DCMAKE_CXX_STANDARD=17 ^
  -D CMAKE_C_COMPILER=cl -D CMAKE_CXX_COMPILER=cl ^
  -D CMAKE_BUILD_TYPE=RelWithDebInfo ^
  -D "CMAKE_INSTALL_PREFIX=%INSTALL_DIR%" ^
  -D "CMAKE_PREFIX_PATH=%CBDEPS_DIR%/zlib.exploded;%CBDEPS_DIR%/openssl.exploded;%INSTALL_DIR%" ^
  -DABSL_PROPAGATE_CXX_STD=ON ^
  -DgRPC_INSTALL=ON ^
  -DgRPC_BUILD_TESTS=OFF ^
  -DgRPC_PROTOBUF_PROVIDER=package ^
  -DgRPC_ZLIB_PROVIDER=package ^
  -DgRPC_CARES_PROVIDER=package ^
  -DgRPC_SSL_PROVIDER=package ^
  -DgRPC_BUILD_GRPC_RUBY_PLUGIN=OFF ^
  -DgRPC_BUILD_GRPC_PHP_PLUGIN=OFF ^
  -DgRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF ^
  -DgRPC_BUILD_GRPC_CSHARP_PLUGIN=OFF ^
  -DgRPC_BUILD_GRPC_NODE_PLUGIN=OFF ^
  .. || goto error
ninja install || goto error

goto :eof

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
