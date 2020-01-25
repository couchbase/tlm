Currently the Windows build is not integrated into the cbdeps system fully.

We have an ansible playbook setup for window2016 to build Erlang R20
https://github.com/couchbase/build-infra/tree/master/ansible/windows/erlang

Attach this VM as a slave to server.jenkins with the label "windows-erlang",
and then run

http://server.jenkins.couchbase.com/job/cbdeps-erlang-window-build/

passing in the same arguments as the _ADD_DEP_PACKAGE(erlang ...) line in
tlm/deps/packages/CMakeLists.txt.

Note: Currently the erlang_windows.sh script in this directory creates
cbdeps packages with the platform "windows_msvc2017", although the VM used
in fact has MSVC 2013 or MSVC 2015. This is because Server itself is built
with MSVC 2017, and the cbdeps platform name reflectst the Server build
environment.
