DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)
VERSION=$(awk '/^Version:/ { print $2 }' $DIR/salt/salt.egg-info/PKG-INFO)
MINION=root@minion
LOG=/tmp/highstate.log
COMMAND="timeout -k 10 590 salt-call state.highstate test=True"
RPM_RELEASE=1.el7
BISECT_STEP=$(cd $DIR/salt; git bisect log 2> /dev/null | grep -c '^#' || true)
RC_VER="" #bisect #${BISECT_STEP}
RPM_VER=${VERSION//-/_}
RPM_VERSION=${RPM_VER}${RC_VER}-${RPM_RELEASE}
GIT_COMMIT=$(cd $DIR/salt; git rev-parse HEAD)
