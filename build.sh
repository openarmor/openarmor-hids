#!/bin/bash

set -e -o pipefail

scriptpath=$(dirname $0)
$scriptpath/contrib/debian-packages/generate_openarmor.sh -d
$scriptpath/contrib/debian-packages/generate_openarmor.sh -u
$scriptpath/contrib/debian-packages/generate_openarmor.sh -b
