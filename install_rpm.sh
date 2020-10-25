#!/bin/bash
# Intall a new RPM

DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)
. $DIR/test_conf.sh

set -eu

echo "Stopping master"
systemctl stop salt{-master,-minion,-api} || true

echo "Installing RPMS on master"
yum remove -y salt{,-master,-minion,-api,-cloud,-ssh}
yum install -y /var/lib/mock/epel-7-x86_64/result/salt{,-master,-minion,-api,-cloud,-ssh}-${RPM_VERSION}.noarch.rpm

exit

# unused below. earlier edition
echo "Starting master"
systemctl start salt{-master,-minion,-api}

echo "Wait 30sec for master to come up fully"
sleep 30

echo "Stopping minion"
ssh $MINION "systemctl stop salt-minion" || true

echo "Copying RPMS to test minion"
scp /var/lib/mock/epel-7-x86_64/result/salt{,-minion}-${RPM_VERSION}.noarch.rpm $MINION:/tmp

echo "Install RPMS on test minion"
ssh $MINION "yum remove -y salt{,-minion}"
ssh $MINION "yum install -y /tmp/salt{,-minion}-${RPM_VERSION}.noarch.rpm"

echo "Starting salt-minion on test minion"
ssh $MINION "systemctl restart salt-minion"

echo "Wait 30sec for minion to come up fully"
sleep 30
