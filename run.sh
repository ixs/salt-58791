#!/bin/bash

set -euo pipefail

DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)

$DIR/build_rpm.sh
$DIR/install_rpm.sh
$DIR/run_test.sh
