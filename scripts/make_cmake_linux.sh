#!/bin/bash
set -e

BUILDDIR=build-$RANDOM

pushd $1
shift
cmake -B$BUILDDIR -H. -DCMAKE_INSTALL_RPATH='$ORIGIN/../lib' -DCMAKE_INSTALL_PREFIX=$INSTALLPREFIX -DCMAKE_BUILD_TYPE=Release $@
cmake --build $BUILDDIR --target install -j`nproc`
popd
