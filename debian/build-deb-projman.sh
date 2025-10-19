#!/bin/bash

cd ../

VERSION=$(grep "# :Version:" projman.tcl | grep -oE '\b[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}\b')
RELEASE=$(grep "# :Release:" projman.tcl | grep -oE '[0-9A-Za-z]+$')
BUILD_DATE=$(date +%d%m%Y%H%M%S)
BUILD_FIELD="# :Build: ${BUILD_DATE}"
sed -i "/# :Build:.*/c$BUILD_FIELD" projman.tcl
echo "$VERSION, $RELEASE, $BUILD_DATE"

cp projman.tcl projman
sed -i "s:# _INSTALLATION_SETUP_:set setup(PREFIX) /usr:g" projman
cp changelog-gen.tcl changelog-gen

./changelog-gen.tcl  --project-name projman --project-version ${VERSION} --project-release ${RELEASE} --out-file debian/changelog --deb --last



tar czf ../projman_${VERSION}.orig.tar.gz .

dpkg-buildpackage -d

#cp ../projman_${VERSION}-${RELEASE}_amd64.deb /files/

rm -v projman changelog-gen
rm -r -v debian/{projman,.debhelper}
