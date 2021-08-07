#!/bin/sh
# Script based on love-appimages
# https://github.com/pfirsich/love-appimages/blob/b58084eb23f6595617ad9511b5b136a7523e2f4d/build.py#L46

cd "$OWD"
love_files=$(find $APPDIR/share -type d -name lovegame)
if [ -z "$love_files" ]; then
	$APPDIR/bin/love "$@"
else
	$APPDIR/bin/love --fused "$love_files" "$@"
fi
