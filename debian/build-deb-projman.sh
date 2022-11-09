#!/bin/bash

cd ../

VERSION=$(grep Version projman.tcl | grep -oE '\b[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}\b')
RELEASE=$(grep Release projman.tcl | grep -oE '\b[0-9A-Za-z]{1,3}\b')
BUILD_DATE=$(date +%d%m%Y%H%M%S)
TXT="# Build: ${BUILD_DATE}"

sed -i "/# Build:.*/c$TXT" projman.tcl

cp projman.tcl projman


sed -i "s+^set\ dir(lib)+set\ dir(lib)\ /usr/share/projman/lib ;#+g" projman
   
sed -i "s+\[pwd\]+/usr/share/projman+g" projman


tar czf ../projman_${VERSION}.orig.tar.gz .

dpkg-buildpackage

#cp ../projman_${VERSION}-${RELEASE}_amd64.deb /files/

rm -v projman
rm -r -v debian/projman
