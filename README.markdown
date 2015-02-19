# tlm - Top-level Makefile

What's this, then? The tlm project contains the make information for
building Couchbase on multiple platforms.

**Table of Contents**

- [Content](#user-content-content)
- [How to build](#user-content-how-to-build)
	- [Simple](#user-content-simple-build)
	- [Customize your builds](#user-content-customize-your-builds)
- [Microsoft Windows 2008R2](#user-content-microsoft-windows-2008r2)
	- [Configuration](#user-content-configuration)
		- [git](#user-content-git)
	- [How to build](#user-content-how-to-build-1)
- [MacOSX](#user-content-macosx)
- [Ubuntu 14.04](#user-content-ubuntu-1404)
- [Fedora 21](#user-content-fedora-21)
- [OpenSUSE](#opensuse)
- [SmartOS containers](#user-content-smartos)
	- [SmartOS](#user-content-smartos-container)
	- [CentOS 5](#user-content-centos-5)
	- [CentOS 6](#user-content-centos-6)
	- [CentOS 7](#user-content-centos-7)
	- [Ubuntu](#user-content-ubuntu)
	- [Debian 7](#user-content-debian7)
- [Static Analysis](#user-content-static-analysis)

## Content

The file named `CMakeLists.txt` contains the full build description
for Couchbase. It should be copied to the top of your source directory
(this happens automatically when you are using repo).

The `cmake` directory contains macros used by cmake to configure a
build of Couchbase.

`Makefile` is a convenience file that repo will put in the root of
your source directory. It invokes `cmake` with a specific set of
options. "All" flavors of make should be able to parse this makefile,
and its defaults are set to match building on Microsoft Windows.

`GNUmakefile` is another convenience file that repo will put in the
root of your source directory. GNU make will favor this file over
`Makefile` and this file just overrides the defaults specified in
`Makefile`.

## How to build

Couchbase utilizes [CMake][cmake_link] in order to provide build
support for a wide range of platforms. CMake isn't a build system
like GNU Autotools, but a tool that generates build information for
external systems like: Visual Studio projects, XCode projects and
Makefiles to name a few. Their good support for Microsoft Windows and
Makefiles is the primary reason why we decided to move away from GNU
Autotools. CMake isn't a magic pill that solves all our problems; it
comes with its own list of challenges.

It is recommended to perform "out of source builds", which means that
the build artifacts is stored _outside_ the source directory.

### Simple build

If you just want to build Couchbase and without any special
configuration, you may use the Makefile we've supplied for your
convenience:

    trond@ok > mkdir source
    trond@ok > mkdir build
    trond@ok > cd source
    trond@ok source> repo init -u git://github.com/couchbase/manifest -m branch-master.xml
    trond@ok source> repo sync
    trond@ok source> make

This would install the build software in a subdirectory named
`install`. To change this you may run:

    trond@ok source> make PREFIX=/opt/couchbase

### Customize your builds

CMake offers a wide range of customizations, and this chapter won't
try to cover all of them. There is plenty of documentation available
on the [webpage](http://www.cmake.org/cmake/help/documentation.html).

There is no point of trying to keep a list of all tunables in this
document. To find the tunables you have two options: look in
`cmake/Modules/*.cmake` or you may look in the cache file generated
during a normal build (see `build/CMakeCache.txt`)

There are two ways to customize your own builds. You can do it all by
yourself by invoking cmake yourself:

    trond@ok > mkdir source
    trond@ok > mkdir build
    trond@ok > cd source
    trond@ok source> repo init -u git://github.com/couchbase/manifest -m branch-master.xml
    trond@ok source> repo sync
    trond@ok source> cd ../build
    trond@ok build> cmake -D CMAKE_INSTALL_PREFIX=/opt/couchbase -D CMAKE_BUILD_TYPE=Debug -D DTRACE_FOUND:BOOL=True -D DTRACE:FILEPATH=/usr/sbin/dtrace CMAKE_PREFIX_PATH="/opt/r14b04;/opt/couchbase"
    trond@ok build> gmake all install

Or pass extra options to the convenience Makefile provided:

    trond@ok > mkdir source
    trond@ok > mkdir build
    trond@ok > cd source
    trond@ok source> repo init -u git://github.com/couchbase/manifest -m branch-master.xml
    trond@ok source> repo sync
    trond@ok source> make PREFIX=/opt/couchbase CMAKE_PREFIX_PATH="/opt/r14b04;/opt/couchbase" EXTRA_CMAKE_OPTIONS='-D DTRACE_FOUND:BOOL=True -D DTRACE:FILEPATH=/usr/sbin/dtrace'

Use `CMAKE_PREFIX_PATH` to specify a "list" of directories to search
for tools/libraries if they are stored in "non-standard"
locations. Ex:

    CMAKE_PREFIX_PATH="/opt/r14b04;/opt/couchbase;/opt/local"

## Microsoft Windows 2008R2

The following steps is needed to build Couchbase on Microsoft Windows 2008R2

* Install OS, activate and run Windows Update and install all updates
* Install Google Chrome (optional, but makes your life easier)
* Install [Visual Studio 2013 Professional][win_visual_studio_link]
* Install all updates from microsoft update
* Install [GIT][win_git_link] and select the option to add GIT to path
* Install [Python 2.7][win_python_link] and add c:\python27 to path (manually)
* Install [7-ZIP][win_7zip_link] and add the installation to path (manually)
* Install [CMake][win_cmake_link] and add to path
* Install [GO][win_go_link] and add to path
* Download and install [2008 runtime extensions][win_2008_runtime_ext_link]

### Configuration

#### git

Repo will complain if git isn't properly configured. Setting name and
email should be sufficient, but you also may at least want to set the
two additional settings suggested:

    C:\> git config --global user.email trond.norbye@gmail.com
    C:\> git config --global user.name "Trond Norbye"
    C:\> git config --global color.ui false
    C:\> git config --global core.autocrlf true

### How to build

Before you may start to build on Microsoft Windows you have to set up
the environment. The script `environment.bat` is located in the `win32`
directory.

Open cmd.com and type in the following (assuming c:\compile\couchbase
is the directory holding your source):

    C:\> set source_root=c:\compile\couchbase
    C:\> set target_arch=amd64
    C:\> environment

You may now follow the build description outlined in [How to
build](#user-content-how-to-build). Please note that the make utility
on windows is named `nmake`.

## MacOSX

Multiple versions of Mac OSX may work, but this list is verified with
Mavericks.

* Install XCode 5.1
* Install [Homebrew][homebrew_link]

Install the following packages from homebrew:

    trond@ok> brew install cmake git icu4c libevent snappy go

Ensure that your `PATH` variable includes `/usr/local/opt/icu4c/bin`:

    trond@ok> export PATH=$PATH:/usr/local/bin:/usr/local/opt/icu4c/bin

You should be all set to start compile the server as described above.

## Ubuntu 14.04

The steps below may work on other versions of Ubuntu as well, but this
procedure is verified with a clean installation of Ununtu 14.04.1

    sudo su -
    wget https://storage.googleapis.com/git-repo-downloads/repo
    chmod a+x repo
    mv repo /usr/local/bin
    apt-get install -y git gcc g++ ccache cmake libssl-dev libicu-dev \
                       erlang mercurial
    cd /usr/local
    hg clone -u release https://code.google.com/p/go
    cd go/src
    ./all.bash
    cd ../../bin
    ln -s ../go/bin/go
    ln -s ../go/bin/gofmt

## Fedora 21

The steps below may work on other versions of Fedora as well, but this
procedure is verified with a clean installation of Fedora 21

    sudo su -
    wget https://storage.googleapis.com/git-repo-downloads/repo
    chmod a+x repo
    mv repo /usr/local/bin
    yum install -y gcc gcc-c++ git cmake ccache redhat-lsb-core \
                   erlang mercurial openssl-devel libicu-devel
    cd /usr/local
    hg clone -u release https://code.google.com/p/go
    cd go/src
    ./all.bash
    cd ../../bin
    ln -s ../go/bin/go
    ln -s ../go/bin/gofmt

## OpenSUSE

I tested this on a clean install of OpenSUSE 13.2 by choosing the
defaults during the installer except choosing gnome desktop and enable
ssh access.

    sudo zypper install gcc gcc-c++ autoconf automake ncurses-devel \
                        git go ccache libopenssl-devel cmake

Open a new terminal to ensure you get an updated environment (the
package install modifies some of the environement variables)

    curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
    chmod a+x ~/bin/repo
    sudo mkdir /opt/couchbase
    sudo chown `whoami` /opt/couchbase
    mkdir -p compile/couchbase
    cd compile/couchbase
    repo init -u git://github.com/couchbase/manifest -m sherlock.xml -g default,build
    repo sync
    repo start opensuse --all
    mkdir cbdeps && cd cbdeps
    ../cbbuild/cbdeps/build-all-sherlock.sh
    export CB_DOWNLOAD_DEPS_CACHE=`pwd`/output
    export CB_DOWNLOAD_DEPS_MANIFEST=`pwd`/output/manifest.cmake
    unset GOBIN
    cd ..
    gmake PREFIX=/opt/couchbase

You should be able to start the server by running

    /opt/couchbase/bin/couchbase-server start

## SmartOS

The following chapters describes how to configure and build under
various containers hosted by SmartOS. [Joyent][joyent_link] provides a
variety of datasets for various operating systems (CentOS, Fedora,
FreeBSD, Debian, SmartOS, ...). This section is not intended to cover
all of these, but covers a set of configurations known to work.

### SmartOS container

The following descrtiption use the standard64 (14.2.1) image imported by:

    root@smartos~> imgadm import 3f57ffe8-47da-11e4-aa8b-dfb50a06586a

The KVM may be created with the following attributes (store in `smartos.json`):

    {
      "alias" : "compilesrv",
      "autoboot": true,
      "brand": "joyent",
      "dns_domain" : "norbye.org",
      "resolvers" : [ "8.8.4.4" ],
      "image_uuid" : "3f57ffe8-47da-11e4-aa8b-dfb50a06586a",
      "hostname" : "compilesrv",
      "filesystems" : [
       {
          "type" : "lofs",
          "source" : "/zones/home",
          "target" : "/home",
          "options" : "nodevices"
        }
      ],
      "max_physical_memory": 4096,
      "nics": [
         {
          "nic_tag": "admin",
          "ip": "10.0.0.207",
          "netmask": "255.255.255.0",
          "gateway": "10.0.0.1"
        }
      ]
    }

Create the KVM with:

    root@smartos~> vmadm create -f smartos.json

Log into the newly created zone and install the following packages:

    root@compilesrv~> pkgin update
    root@compilesrv~> pkgin -y in py27-expat-2.7.7 icu-53.1 erlang-16.1.2nb3 go-1.3

[Install Google repo][google_repo_link] and you should be all set to
start building the code as described above.

### CentOS 5

The following descrtiption use the Centos-5.7 image imported by:

    root@smartos~> imgadm import 2539f6de-0b5a-11e2-b647-fb08c3503fb2

The KVM may be created with the following attributes (store in `centos-5.7.json`):

    {
      "alias": "centos-5.7",
      "brand": "kvm",
      "resolvers": [
        "10.0.0.1",
        "8.8.4.4"
      ],
      "default-gateway": "10.0.0.1",
      "hostname":"centos",
      "ram": "8192",
      "vcpus": "4",
      "nics": [
        {
          "nic_tag": "admin",
          "ip": "10.0.0.206",
          "netmask": "255.255.255.0",
          "gateway": "10.0.0.1",
          "model": "virtio",
          "primary": true
        }
      ],
      "disks": [
        {
          "image_uuid": "2539f6de-0b5a-11e2-b647-fb08c3503fb2",
          "boot": true,
          "model": "virtio",
          "image_size": 5120
        },
        {
          "model": "virtio",
          "size": 10240
        }
      ],
    "customer_metadata": {
        "root_authorized_keys": "< my key >"
      }
    }

Create the KVM with:

    root@smartos~> vmadm create -f centos-5.7.json

You should now be able to ssh into the machine and run `yum update` and
install all of the updates ;-)

The source code in Couchbase server use some features defined in
C++11, and the compiler provided in CentOS 5.7 doesn't support
this. In order to be able to build Couchbase we have to install or
build a newer version of gcc.

    yum install -y gcc gcc-c++
    export LC_ALL=C
    cd /data
    wget ftp://ftp.fu-berlin.de/unix/languages/gcc/releases/gcc-4.9.1/gcc-4.9.1.tar.bz2
    bunzip2 gcc-4.9.1.tar.bz2
    tar xf gcc-4.9.1.tar
    wget https://gmplib.org/download/gmp/gmp-6.0.0a.tar.bz2
    bunzip2 gmp-6.0.0a.tar.bz2
    tar xf gmp-6.0.0a.tar
    mv gmp-6.0.0 gcc-4.9.1/gmp
    wget http://www.mpfr.org/mpfr-current/mpfr-3.1.2.tar.bz2
    bunzip2 mpfr-3.1.2.tar.bz2
    tar xf mpfr-3.1.2.tar
    mv mpfr-3.1.2 gcc-4.9.1/mpfr
    wget ftp://ftp.gnu.org/gnu/mpc/mpc-1.0.2.tar.gz
    tar xfz mpc-1.0.2.tar.gz
    mv mpc-1.0.2 gcc-4.9.1/mpc
    wget ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-0.12.2.tar.bz2
    bunzip2 isl-0.12.2.tar.bz2
    tar xf isl-0.12.2.tar
    mv isl-0.12.2 gcc-4.9.1/isl
    wget ftp://gcc.gnu.org/pub/gcc/infrastructure/cloog-0.18.1.tar.gz
    tar xfz cloog-0.18.1.tar.gz
    mv cloog-0.18.1 gcc-4.9.1/cloog
    cd gcc-4.9.1
    ./configure  --prefix=/opt/gcc-4.9.1 --disable-multiarch --disable-multilib --enable-languages=c,c++
    gmake BOOT_CFLAGS='-O' bootstrap
    gmake install

Let's set all of our tools in a separate directory:

    mkdir -p /opt/local/bin
    cd /opt
    ln -s gcc-4.9.1 gcc
    cd local/bin
    for f in ../../gcc/bin/*; do ln -s $f; done
    ln -s ../../gcc/bin/gcc cc
    cd /data
    yum remove -y gcc gcc-c++
    export PATH=/opt/local/bin:$PATH
    cd /usr/lib64
    cp /opt/gcc-4.9.1/lib64/libstdc++.so.6.0.20 .
    rm libstdc++.so.6
    ln -s libstdc++.so.6.0.20 libstdc++.so.6

Install as much as possible of the precompiled dependencies with:

    yum install -y libevent-devel libicu-devel \
                   make ncurses-devel openssl-devel \
                   expat-devel tcl gettext \
                   java-1.7.0-openjdk subversion \
                   bzip2-devel redhat-lsb

Unfortunately the YUM repository doesn't include all versions of what
we need, so you need to install the following from source:

Time to build the other build dependencies

    wget http://curl.haxx.se/download/curl-7.38.0.tar.gz
    gtar xf curl-7.38.0.tar.gz
    cd curl-7.38.0
    ./configure
    gmake -j 8 all install
    cd ..
    wget -Ogit-2.1.2.tar.gz https://github.com/git/git/archive/v2.1.2.tar.gz
    tar xfz git-2.1.2.tar.gz
    cd git-2.1.2
    gmake -j 8 prefix=/opt/local LDFLAGS=-Wl,--rpath,/usr/local/lib install
    cd ..
    wget http://www.cmake.org/files/v3.0/cmake-3.0.2.tar.gz
    tar xfz cmake-3.0.2.tar.gz
    cd cmake-3.0.2
    ./configure
    gmake -j 8 all install
    cd ..
    wget https://snappy.googlecode.com/files/snappy-1.1.1.tar.gz
    tar xfz snappy-1.1.1.tar.gz
    cd snappy-1.1.1
    ./configure
    gmake all install
    cd ..
    wget http://www.erlang.org/download/otp_src_R16B03.tar.gz
    tar xfz otp_src_R16B03.tar.gz
    cd otp_src_R16B03
    CFLAGS="-DOPENSSL_NO_EC=1" ./configure --prefix=/opt/erlang-16B03
    gmake all install
    cd /opt
    ln -s erlang-16B03 erlang
    cd local/bin
    for f in ../../erlang/bin/*; do ln -s $f; done
    cd /data
    wget https://www.python.org/ftp/python/2.6.9/Python-2.6.9.tgz
    gtar xfz Python-2.6.9.tgz
    cd Python-2.6.9
    ./configure  --prefix=/opt/python-2.6.9
    gmake all install
    cd /opt
    ln -s python-2.6.9 python
    cd local/bin
    for f in ../../python/bin/*; do ln -s $f; done
    cd /data
    git clone git://github.com/trondn/v8
    cd v8
    git checkout origin/3.21.17-couchbase
    gmake dependencies
    gmake library=shared x64
    cp out/x64.release/lib.target/libv8.so /usr/local/lib
    cp include/* /usr/local/include/

[Install Google repo][google_repo_link] and you should be all set to
start building the code as described above.

### CentOS 6

The following descrtiption use the Centos-6 image imported by:

    root@smartos~> imgadm import df81f45e-8f9f-11e3-a819-93fab527c81e

The KVM may be created with the following attributes (store in `centos.json`):

    {
      "alias": "centos-6",
      "brand": "kvm",
      "resolvers": [
        "10.0.0.1",
        "8.8.4.4"
      ],
      "default-gateway": "10.0.0.1",
      "hostname": "centos",
      "ram": "2048",
      "vcpus": "2",
      "nics": [
        {
          "nic_tag": "admin",
          "ip": "10.0.0.201",
          "netmask": "255.255.255.0",
          "gateway": "10.0.0.1",
          "model": "virtio",
          "primary": true
        }
      ],
      "disks": [
        {
          "image_uuid": "325dbc5e-2b90-11e3-8a3e-bfdcb1582a8d",
          "boot": true,
          "model": "virtio",
          "image_size": 10240
        }
      ],
      "customer_metadata": {
        "root_authorized_keys": "ssh-rsa <my-personal-public-key>"
      }
    }

Create the KVM with:

    root@smartos~> vmadm create -f centos.json

You should now be able to ssh into the machine and run `yum update` and
install all of the updates ;-)

Install as much as possible of the precompiled dependencies with:

    root@centos~> yum install -y libevent-devel libicu-devel \
                                 snappy-devel gcc gcc-c++ libcurl-devel \
                                 make ncurses-devel openssl-devel svn \
                                 expat-devel perl-ExtUtils-CBuilder \
                                 perl-ExtUtils-MakeMaker tcl gettext \
                                 mercurial redhat-lsb

Unfortunately the YUM repository don't include all (and new enough)
versions of all we need, so you need to install the following from
source:

    wget http://www.cmake.org/files/v2.8/cmake-2.8.12.1.tar.gz
    wget http://download.savannah.gnu.org/releases/libunwind/libunwind-1.1.tar.gz
    wget https://gperftools.googlecode.com/files/gperftools-2.1.tar.gz
    wget -Ov1.9.2.tar.gz https://github.com/git/git/archive/v1.9.2.tar.gz
    wget --no-check-certificate -Ov8.tar.gz \
         https://github.com/v8/v8/archive/3.19.0.tar.gz
    wget http://www.erlang.org/download/otp_src_R16B03.tar.gz

    gtar xfz cmake-2.8.12.1.tar.gz
    gtar xfz libunwind-1.1.tar.gz
    gtar xfz gperftools-2.1.tar.gz
    gtar xfz v1.9.2.tar.gz
    gtar xfz v8.tar.gz
    gtar xfz otp_src_R16B03.tar.gz

    cd git-1.9.2
    gmake prefix=/usr install
    cd ../cmake-2.8.12.1
    ./bootstrap && gmake all install
    cd ../libunwind-1.1
    ./configure && gmake all install
    cd ../gperftools-2.1
    ./configure && gmake all install
    cd ../v8-3.19.0
    gmake dependencies
    gmake x64 library=shared -j 4
    cp out/x64.release/lib.target/libv8.so /usr/local/lib
    cp include/* /usr/local/include/
    cd ../otp_src_R16B03
    CFLAGS="-DOPENSSL_NO_EC=1" ./configure && gmake all install
    cd /usr/local
    hg clone -u release https://code.google.com/p/go
    cd go/src
    ./all.bash
    cd ../../bin
    ln -s ../go/bin/go
    ln -s ../go/bin/gofmt


[Install Google repo][google_repo_link] and you should be all set to
start building the code as described above.

### CentOS 7

The following descrtiption use the Centos-7 image imported by:

    root@smartos~> imgadm import df81f45e-8f9f-11e3-a819-93fab527c81e

The KVM may be created with the following attributes (store in `centos.json`):

    {
      "alias": "centos-7",
      "brand": "kvm",
      "resolvers": [
        "10.0.0.1",
        "8.8.4.4"
      ],
      "default-gateway": "10.0.0.1",
      "hostname":"centos",
      "ram": "2048",
      "vcpus": "2",
      "nics": [
        {
          "nic_tag": "admin",
          "ip": "10.0.0.205",
          "netmask": "255.255.255.0",
          "gateway": "10.0.0.1",
          "model": "virtio",
          "primary": true
        }
      ],
      "disks": [
        {
          "image_uuid": "553da8ba-499e-11e4-8bee-5f8dadc234ce",
          "boot": true,
          "model": "virtio",
          "image_size": 10240
        },
       {
          "model": "virtio",
          "size": 10240
        }
      ],
    "customer_metadata": {
        "root_authorized_keys": "<my ssh key>"
      }
    }

Create the KVM with:

    root@smartos~> vmadm create -f centos.json

You should now be able to ssh into the machine and run `yum update` and
install all of the updates ;-)

Install as much as possible of the precompiled dependencies with:

    root@centos~> yum install -y libevent-devel libicu-devel \
                                 snappy-devel gcc gcc-c++ libcurl-devel \
                                 make ncurses-devel openssl-devel svn \
                                 expat-devel perl-ExtUtils-CBuilder \
                                 perl-ExtUtils-MakeMaker tcl gettext \
                                 mercurial bzip2-devel redhat-lsb

Unfortunately the YUM repository don't include all (and new enough)
versions of all we need, so you need to install the following from
source:

    wget http://www.cmake.org/files/v2.8/cmake-2.8.12.1.tar.gz
    wget http://download.savannah.gnu.org/releases/libunwind/libunwind-1.1.tar.gz
    wget https://gperftools.googlecode.com/files/gperftools-2.1.tar.gz
    wget -Ov1.9.2.tar.gz https://github.com/git/git/archive/v1.9.2.tar.gz
    wget http://www.erlang.org/download/otp_src_R16B03.tar.gz

    gtar xfz cmake-2.8.12.1.tar.gz
    gtar xfz libunwind-1.1.tar.gz
    gtar xfz gperftools-2.1.tar.gz
    gtar xfz v1.9.2.tar.gz
    gtar xfz otp_src_R16B03.tar.gz

    cd git-1.9.2
    gmake prefix=/usr install
    cd ../cmake-2.8.12.1
    ./bootstrap && gmake all install
    cd ../libunwind-1.1
    ./configure && gmake all install
    cd ../gperftools-2.1
    ./configure && gmake all install
    cd ..

    wget https://www.python.org/ftp/python/2.6.9/Python-2.6.9.tgz
    gtar xfz Python-2.6.9.tgz
    cd Python-2.6.9
    ./configure  --prefix=/opt/python-2.6.9
    gmake all install
    cd /opt
    ln -s python-2.6.9 python
    mkdir -p local/bin
    cd local/bin
    for f in ../../python/bin/*; do ln -s $f; done
    cd /data

    git clone git://github.com/trondn/v8
    cd v8
    git checkout origin/3.21.17-couchbase
    gmake dependencies
    gmake library=shared x64
    cp out/x64.release/lib.target/libv8.so /usr/local/lib
    cp include/* /usr/local/include/
    cd ../otp_src_R16B03
    CFLAGS="-DOPENSSL_NO_EC=1" ./configure --prefix=/opt/erlang-16B03
    gmake all install
    cd /opt
    ln -s erlang-16B03 erlang
    cd local/bin
    for f in ../../erlang/bin/*; do ln -s $f; done
    cd /usr/local
    hg clone -u release https://code.google.com/p/go
    cd go/src
    ./all.bash
    cd ../../bin
    ln -s ../go/bin/go
    ln -s ../go/bin/gofmt


[Install Google repo][google_repo_link] and you should be all set to
start building the code as described above.

### Ubuntu

The following descrtiption use the Ubuntu image imported by:

    root@smartos~> imgadm import d2ba0f30-bbe8-11e2-a9a2-6bc116856d85

The KVM may be created with the following attributes (store in `ubuntu.json`):

    {
      "alias": "ubuntu",
      "brand": "kvm",
      "resolvers": [
        "10.0.0.1",
        "8.8.4.4"
      ],
      "default-gateway": "10.0.0.1",
      "hostname":"ubuntu",
      "ram": "2048",
      "vcpus": "2",
      "nics": [
        {
          "nic_tag": "admin",
          "ip": "10.0.0.202",
          "netmask": "255.255.255.0",
          "gateway": "10.0.0.1",
          "model": "virtio",
          "primary": true
       }
      ],
      "disks": [
        {
          "image_uuid": "d2ba0f30-bbe8-11e2-a9a2-6bc116856d85",
          "boot": true,
          "model": "virtio",
          "image_size": 16384
        }
      ],
      "customer_metadata": {
        "root_authorized_keys": "ssh-rsa <my-personal-public-key>"
      }
    }

Create the KVM with:

    root@smartos~> vmadm create -f ubuntu.json

You should now be able to ssh into the machine and run `aptitude` and
install all of the updates ;-)

Install as much as possible of the precompiled dependencies with:

    root@ubuntu~> apt-get install -y git automake autoconf libtool clang \
                                     clang++ libevent-dev libicu-dev \
                                     libsnappy-dev libunwind7-dev erlang \
                                     libv8-dev make ccache \
                                     libcurl4-openssl-dev mercurial

A newer version of cmake and google perftools is needed so we have to compile them from source with:

    wget http://www.cmake.org/files/v2.8/cmake-2.8.12.1.tar.gz
    tar xfz cmake-2.8.12.1.tar.gz
    cd cmake-2.8.12.1
    ./bootstrap && make && make install
    cd ..
    wget https://gperftools.googlecode.com/files/gperftools-2.1.tar.gz
    tar xfz gperftools-2.1.tar.gz
    cd gperftools-2.1
    ./configure && make && make install
    cd /usr/local
    hg clone -u release https://code.google.com/p/go
    cd go/src
    ./all.bash
    cd ../../bin
    ln -s ../go/bin/go
    ln -s ../go/bin/gofmt

[Install Google repo][google_repo_link] and you should be all set to
start building the code as described above.

### Debian7

The following descrtiption use the Debian image imported by:

    root@smartos~> imgadm import b9c27838-1730-11e4-adbd-43d91422294f

The KVM may be created with the following attributes (store in `debian7.json`):

    {
      "alias": "debian-7",
      "brand": "kvm",
      "resolvers": [
        "10.0.0.1",
        "8.8.4.4"
      ],
      "default-gateway": "10.0.0.1",
      "hostname":"debian",
      "ram": "1027",
      "vcpus": "2",
      "nics": [
        {
          "nic_tag": "admin",
          "ip": "10.0.0.204",
          "netmask": "255.255.255.0",
          "gateway": "10.0.0.1",
          "model": "virtio",
          "primary": true
        }
      ],
      "disks": [
        {
          "image_uuid": "b9c27838-1730-11e4-adbd-43d91422294f",
          "boot": true,
          "model": "virtio",
          "image_size": 10240
        }
      ],
      "customer_metadata": {
        "root_authorized_keys": "ssh-rsa <my-personal-public-key>"
      }
    }

Create the KVM with:

    root@smartos~> vmadm create -f debian7.json

You should now be able to ssh into the machine and run `aptitude` and
install all of the updates ;-)

Install as much as possible of the precompiled dependencies with:

    root@debian~> apt-get install -y git automake autoconf libtool clang \
                                     libevent-dev libicu-dev \
                                     libsnappy-dev libunwind7-dev erlang \
                                     libv8-dev make ccache \
                                     libcurl4-openssl-dev mercurial \
                                     lsb-release


A newer version of cmake and google perftools is needed so we have to
compile them from source with:

    wget http://www.cmake.org/files/v2.8/cmake-2.8.12.1.tar.gz
    tar xfz cmake-2.8.12.1.tar.gz
    cd cmake-2.8.12.1
    ./bootstrap && make && make install
    cd ..
    wget https://gperftools.googlecode.com/files/gperftools-2.1.tar.gz
    tar xfz gperftools-2.1.tar.gz
    cd gperftools-2.1
    ./configure && make && make install
    cd /usr/local
    hg clone -u release https://code.google.com/p/go
    cd go/src
    ./all.bash
    cd ../../bin
    ln -s ../go/bin/go
    ln -s ../go/bin/gofmt


[Install Google repo][google_repo_link] and you should be all set to
start building the code as described above.

## Static Analysis

There are pre-canned build rules to allow you to run the
[Clang Static Analyzer][clang_static_analyzer_link] against the Couchbase
codebase.

So far this has only been tested on OS X, using Clang shipping as part
of OS X Developer Tools. It *should* be possible to also run on other
platforms which Clang/LLVM is available, however this isn't tested.

### Prerequisites

* Install `clang` (from OS X Developer Tools). If you can build from source you should already have this :)
* Download and extract clang Static Analyzer tools
  (from [clang-analyzer.llvm.org][clang_static_analyzer_link]).
  Note that while the actual analyzer functionality is built into
  clang, this is needed for `scan-build` and `scan-view` tools to
  invoke and display the analyser results.

### Running

*  Add `scan-build` and `scan-view` to your path:

        export PATH=$PATH:/path/to/checker-276

*  Run `make analyzer` at the top-level to configure clang-analyser as the 'compiler':

        make analyzer

*  At the end you will see a message similar to the following - Invoke the specified command to browse the found bugs:


        scan-build: 31 bugs found.
        scan-build: Run 'scan-view /source/build-analyzer/analyser-results/2014-06-05-173247-52416-1' to examine bug reports.



[win_visual_studio_link]: http://hub.internal.couchbase.com/confluence/download/attachments/7242678/en_visual_studio_professional_2013_x86_web_installer_3175305.exe?version=1&modificationDate=1389383332000
[win_git_link]: http://git-scm.com/download/win
[win_python_link]: http://www.python.org/download/releases/2.7/
[win_7zip_link]: http://downloads.sourceforge.net/sevenzip/7z920-x64.msi
[win_cmake_link]: http://www.cmake.org/cmake/resources/software.html
[win_go_link]: https://code.google.com/p/go/downloads/list
[win_2008_runtime_ext_link]: http://www.microsoft.com/en-us/download/confirmation.aspx?id=15336
[google_repo_link]: http://source.android.com/source/downloading.html#installing-repo
[homebrew_link]: http://brew.sh/
[cmake_link]: http://www.cmake.org/cmake/
[clang_static_analyzer_link]: http://clang-analyzer.llvm.org
