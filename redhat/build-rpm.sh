#!/bin/bash

RPM_BUILD_DIR=${HOME}/rpmbuild

mkdir -p ${RPM_BUILD_DIR}/{SOURCES,RPMS,SRPMS,SPECS,RPMS/noarch}

cd ../

VERSION=$(grep "Version" projman.tcl | grep -oE '\b[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}\b')
RELEASE=$(grep "# Release" projman.tcl | grep -oE '[0-9A-Za-z]+$')
BUILD_DATE=$(date +%d%m%Y%H%M%S)
TXT="# Build: ${BUILD_DATE}"

sed -i "/# Build:.*/c$TXT" projman.tcl

cp projman.tcl projman

sed -i "s+^set\ dir(lib)+set\ dir(lib)\ /usr/share/projman/lib ;#+g" projman
sed -i "s+\[pwd\]+/usr/share/projman+g" projman

CUR_DIR=$(pwd)

cd ../

tar --exclude='.git' --exclude='debian' --exclude='redhat' --exclude='projman.tcl' -czf ${RPM_BUILD_DIR}/SOURCES/projman-${VERSION}-${RELEASE}.tar.gz projman

cd ${CUR_DIR}

cp redhat/projman.spec ${RPM_BUILD_DIR}/SPECS/projman.spec

sed -i "s/.*Version:.*/Version:\t${VERSION}/" ${RPM_BUILD_DIR}/SPECS/projman.spec
sed -i "s/.*Release:.*/Release:\t${RELEASE}/" ${RPM_BUILD_DIR}/SPECS/projman.spec

rpmbuild -ba "${RPM_BUILD_DIR}/SPECS/projman.spec"

# cp ${RPM_BUILD_DIR}/RPMS/noarch/projman-${VERSION}-${RELEASE}.noarch.rpm /files/
# cp ${RPM_BUILD_DIR}/SRPMS/projman-${VERSION}-${RELEASE}.src.rpm /files/

rm -v projman
rm -r -v ${RPM_BUILD_DIR}/SPECS/projman.spec
rm -r -v ${RPM_BUILD_DIR}/SOURCES/projman-${VERSION}-${RELEASE}.tar.gz
rm -r -v ${RPM_BUILD_DIR}/BUILD/projman
