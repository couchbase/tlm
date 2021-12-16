# Overview

This directory contains build steps to create "cbpy", which is a
standalone customized Python 3 package. This package will be installed
on customer machines as part of Server, and will be used for all Python
3 scripts that we ship.

Therefore, if you write any Python 3 scripts that require a new third-party
Python library, we must add it here to ensure that it is available in
production.

This used to be part of the Server build itself, but as it grew somewhat
more complex, it made sense to pull it out to a separate build. I'm
making this a cbdeps 1.0 package (ie, here in tlm/deps/packages rather
than driven by a separate manifest) because this actually IS effectively
part of the Server build. This also means we can keep the
couchbase-server-specific Black Duck manifest here in the same location
as the environment files which define what python libraries are
included, making it easier to keep them in sync.

# Adding new packages

When adding new packages, you'll need to create new environment files. Some
helpers are provided to automate this. It's not fully automated end-to-end,
but much of the legwork has been removed.

Firstly, any new packages should be added to cb-dependencies.txt. If it does
not exist in the conda-forge package repo you'll need to create a recipe.
Creating recipes is beyond the scope of this readme, but note that their
folders should be created in conda-pkgs/all/ to be picked up by our scripts.

Once packages have been added/modified, you'll need to carry out discovery
on each platform, at time of writing the targeted platforms are:

- linux (aarch64)
- linux (x86_64)
- macos
- windows

## Linux

On the targeted architecture, build and run `Dockerfile.linux`. e.g:

`docker build . -t cbpy -f Dockerfile.linux && docker run --rm -it cbpy`

The results should be redirected/copied to `package-lists/linux-$(uname -m)`

## Windows

Run `windows.cmd` on a Windows system, redirect/copy the output to
`package-lists/win`

## MacOS

Run macos.sh when in this directory

`./macos.sh`

The list of packages shown at the end should be copied/redirected into
`package-lists/osx`

# Generating new environment files

When the containers/scripts have been run on all platforms, you should have:

    package-lists/
        linux-aarch64
        linux-x86_64
        osx
        win

At that point, run `create-environment-files.py`. It will error out if
blackduck manifest changes are required, if no blackduck changes
are needed the new environment-*.txt files will be created.
