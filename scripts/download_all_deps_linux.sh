#!/bin/bash
set -e

SCRIPT_DIR=`dirname "$0"`
DOWNLOAD="python $SCRIPT_DIR/download_deps_linux.py"

$DOWNLOAD http://downloads.xiph.org/releases/ogg/libogg-$LIBOGG_VERSION.tar.gz ogg
$DOWNLOAD http://downloads.xiph.org/releases/vorbis/libvorbis-$LIBVORBIS_VERSION.tar.gz vorbis
$DOWNLOAD http://downloads.xiph.org/releases/theora/libtheora-$LIBTHEORA_VERSION.tar.gz theora
$DOWNLOAD http://prdownloads.sourceforge.net/libpng/libpng-$LIBPNG_VERSION.tar.gz?download png
$DOWNLOAD https://download.savannah.gnu.org/releases/freetype/freetype-$FT_VERSION.tar.gz ft
$DOWNLOAD https://sourceware.org/pub/bzip2/bzip2-$BZIP2_VERSION.tar.gz bz2
$DOWNLOAD https://www.mpg123.de/download/mpg123-$MPG123_VERSION.tar.bz2 mpg123
