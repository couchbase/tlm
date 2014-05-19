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
- [SmartOS containers](#user-content-smartos)
	- [CentOS 6](#user-content-centos-6)
	- [Ubuntu](#user-content-ubuntu)

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
    trond@ok build> cmake -D CMAKE_INSTALL_PREFIX=/opt/couchbase -D CMAKE_BUILD_TYPE=Debug -D ERLANG_FOUND:BOOL=True -D ERLANG_INCLUDE_PATH:PATH=/opt/r14b04/lib/erlang/usr/include -D ERLC_EXECUTABLE:FILEPATH=/opt/r14b04/bin/erlc -D ERL_EXECUTABLE:FILEPATH=/opt/r14b04/bin/erl -D ESCRIPT_EXECUTABLE:FILEPATH=/opt/r14b04/bin/escript -DREBAR_SCRIPT=/root/src/repo3/tlm/cmake/Modules/rebar -G "Unix Makefiles" ../source
    trond@ok build> gmake all install

Or pass extra options to the convenience Makefile provided:

    trond@ok > mkdir source
    trond@ok > mkdir build
    trond@ok > cd source
    trond@ok source> repo init -u git://github.com/couchbase/manifest -m branch-master.xml
    trond@ok source> repo sync
    trond@ok source> make PREFIX=/opt/couchbase EXTRA_CMAKE_OPTIONS='-D ERLANG_FOUND:BOOL=True -D ERLANG_INCLUDE_PATH:PATH=/opt/r14b04/lib/erlang/usr/include -D ERLC_EXECUTABLE:FILEPATH=/opt/r14b04/bin/erlc -D ERL_EXECUTABLE:FILEPATH=/opt/r14b04/bin/erl -D ESCRIPT_EXECUTABLE:FILEPATH=/opt/r14b04/bin/escript -DREBAR_SCRIPT=/root/src/repo3/tlm/cmake/Modules/rebar'

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
* Create a directory named `c:\tools` and add it to your path.. Copy `environment.bat` and `repo.exe` from the google drive folder into this directory (@todo figure out where to store them)
* Copy the directory depot from google drive to `c:\` (endind up as: `c:\depot`)

### Configuration

#### git

Repo will complain if git isn't properly configured. Setting name and
email should be sufficient

    C:\> git config --global user.email trond.norbye@gmail.com
    C:\> git config --global user.name "Trond Norbye"

### How to build

Before you may start to build on Microsoft Windows you have to set up
the environment.

Open cmd.com and type in the following (assuming c:\compile\couchbase
is the directory holding your source):

    C:\> set source_root=c:\compile\couchbase
    C:\> set target_platform=amd64
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

    trond@ok> brew install cmake erlang git icu4c libevent snappy v8

Ensure that your `PATH` variable includes `/usr/local/opt/icu4c/bin`:

    trond@ok> export PATH=$PATH:/usr/local/bin:/usr/local/opt/icu4c/bin

You should be all set to start compile the server as described above.

## SmartOS

The following chapters describes how to configure and build under
various containers hosted by SmartOS. [Joyent][joyent_link] provides a
variety of datasets for various operating systems (CentOS, Fedora,
FreeBSD, Debian, SmartOS, ...). This section is not intended to cover
all of these, but covers a set of configurations known to work.

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
                                 perl-ExtUtils-MakeMaker tcl gettext

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
    cd ..

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
                                     libv8-dev make ccache ibcurl4-openssl-dev

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

[Install Google repo][google_repo_link] and you should be all set to
start building the code as described above.








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