#!/bin/bash
# Build an RPM of the salt git tree.

DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)
. $DIR/test_conf.sh

set -eu

#echo "Tar-ing Tree"
#(
#	cd $DIR
#	tar -czf salt-${VERSION}.tar.gz --transform "s,salt/,salt-${VERSION}/," --exclude-vcs salt
#)

echo "Preparing code"
(
	cd $DIR/salt
	python3 setup.py -q sdist
	. $DIR/test_conf.sh
	mv dist/salt-${VERSION}.tar.gz $DIR
)

# Reread config because the version changed
. $DIR/test_conf.sh

echo "Prepping .spec"
cp $DIR/salt.spec $DIR/rpmstuff/salt.spec
sed -i "s/Version: 3002/Version: ${VERSION//-/_}/" $DIR/rpmstuff/salt.spec
sed -i "s/%define __rc_ver %{nil}/%define __rc_ver ${RC_VER}/" $DIR/rpmstuff/salt.spec
sed -i "s/%autosetup /%autosetup -n salt-${VERSION} /" $DIR/rpmstuff/salt.spec
sed -i "s/Source0:.*/Source0: salt-${VERSION}.tar.gz/" $DIR/rpmstuff/salt.spec
sed -i "s/\$RPM_BUILD_DIR\/%{name}-%{version}/\$RPM_BUILD_DIR\/%{name}-${VERSION}/g" $DIR/rpmstuff/salt.spec

echo "Creating SRPMS"
(
	cd $DIR/rpmstuff
        mv $DIR/salt-${VERSION}.tar.gz salt-${VERSION}.tar.gz
	rpmbuild -bs --nodeps --define "_sourcedir ." --define "_srcrpmdir $DIR" ./salt.spec
)

echo "Building RPM"
mock -q $DIR/salt-${RPM_VERSION}.src.rpm

mkdir $DIR/archive/${GIT_COMMIT}
cp /var/lib/mock/epel-7-x86_64/result/*.rpm $DIR/archive/${GIT_COMMIT}
