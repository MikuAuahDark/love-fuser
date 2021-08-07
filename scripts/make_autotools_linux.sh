#!/bin/bash
set -e

BUILDDIR=build-$RANDOM

pushd $1
shift
mkdir $BUILDDIR
cd $BUILDDIR
LDFLAGS="-Wl,-rpath,'\$\$ORIGIN/../lib' $LDFLAGS" PKG_CONFIG_PATH=$INSTALLPREFIX/lib/pkgconfig ../configure --prefix=$INSTALLPREFIX $@
make install -j`nproc`
popd
