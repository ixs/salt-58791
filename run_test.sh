#!/bin/bash

set -xeuo pipefail

DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)
. $DIR/test_conf.sh

LOG=/tmp/highstate.log

pkill -9 -f salt-master || true
pkill -9 -f salt-minion || true
rm -f /tmp/{highstate,master,minion}.log || true

echo "Starting master"
{
	/usr/bin/time -v salt-master -l quiet &
} > /tmp/master.log 2>&1
TIME_PID=$!
sleep 5
MASTER_PID=$(ps -o pid --no-headers --ppid $TIME_PID)

echo "Starting minion"
{
	/usr/bin/time -v salt-minion -l quiet &
} > /tmp/minion.log 2>&1
TIME_PID=$!
sleep 5
MINION_PID=$(ps -o pid --no-headers --ppid $TIME_PID)

if [ -z "${MASTER_PID}" ] || [ -z "${MINION_PID}" ]; then
	echo "Couldn't determine master or minion PID. Aborting"
	exit 125
fi

echo "Run highstate"
{
	/usr/bin/time -v $COMMAND
	ret=$?
	echo "ret: $ret"
} > $LOG 2>&1

echo "Stopping master"
kill $MASTER_PID
echo "Stopping minion"
kill $MINION_PID

sleep 10

ret=$(awk 'END { print $2 }' $LOG)
SALT_TIME=$(grep -E "^Total run time" $LOG | awk '{ print $4 }')
REAL_TIME=$(grep -E "(wall clock)" $LOG | awk '{ print $8 }')
MAX_MEM_HIGHSTATE=$(grep -E "Maximum resident set size" $LOG | awk '{ print $6 }')
MAX_MEM_MASTER=$(grep -E "Maximum resident set size" /tmp/master.log | awk '{ print $6 }')
MAX_MEM_MINION=$(grep -E "Maximum resident set size" /tmp/minion.log | awk '{ print $6 }')

mv /tmp/{highstate,master,minion}.log "${DIR}/archive/${GIT_COMMIT}"

if [ -z "${SALT_TIME}" ]; then
	echo "salt-call did not succeed"
	exit 125
fi

if [ -z "${MAX_MEM_MASTER}" ]; then
	echo "master memory consumption unknown"
	exit 125
fi

if [ "${MAX_MEM_MASTER}" -lt 110000 ]; then
	echo "Salt-master memory consumption at ${MAX_MEM_MASTER}. Less than 110MB. PASS!"
	exit 0
else
	echo "Salt-master memory consumption at ${MAX_MEM_MASTER}. More than 110MB. FAIL!"
	exit 1
fi

