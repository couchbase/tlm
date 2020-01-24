Currently the Windows build is not integrated into the cbdeps system fully.

We have an ansible playbook setup for window2016 to build Erlang R20
https://github.com/couchbase/build-infra/tree/master/ansible/windows/erlang

Following are steps to build Erlang R20 on window2016 VM
1. Start up a zz-Windows-2016-Ansible-Template
2. Install a downloaded full EXE version of OpenSSL 1.1.1d from http://slproweb.com/products/Win32OpenSSL.html and install to **C:\OpenSSL**
4. Build manually on the VM (the following build steps should be done inside cygwin terminal)
    a. Copy the 'cygwin.bash_profile' from https://github.com/couchbase/tlm/blob/master/deps/packages/erlang/windows_buildscript/cygwin.bash_profile to ~/.bash_profile and source it.
    b. Copy the scripts 'erlang-windows.sh' from https://github.com/couchbase/tlm/blob/master/deps/packages/erlang/windows_buildscript/erlang_windows.sh to ~/build.
    c. Ensure https://github.com/couchbasedeps/erlang has the correct/latest tags required for the build
    d. `cd ~/build`
    e. Run `./erlang_windows.sh 9.3.3.9 20 OTP-20.3.8.20` (see http://server.jenkins.couchbase.com/view/cbdeps/job/cbdeps-erlang-window-build for reference)

If successful, a '.tgz' file should be in ~/build, which can then be copied into place in the releases directory on latest-builds.