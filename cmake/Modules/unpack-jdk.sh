#!/bin/bash -e

jdkdmg=$1
outdir=$2

mkdir -p $outdir

echo "Mounting $jdkdmg..."
hdiutil attach $jdkdmg

echo "Expanding .pkg..."
pkgutil --expand /Volumes/JDK*/JDK*.pkg $outdir/tmp

echo "Unmounting $jdkdmg..."
hdiutil detach /Volumes/JDK*

echo "Expanding Payload..."
gzip -dc $outdir/tmp/jdk*.pkg/Payload | (
  cd $outdir/tmp
  cpio -im
)

echo "Moving contents..."
mv $outdir/tmp/Contents/Home/* $outdir

echo "Cleaning up..."
rm $outdir/*.zip
rm -rf $outdir/tmp

echo "Done!"
