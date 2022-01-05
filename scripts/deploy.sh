#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
VestingAddr=$(deploy Vesting 0x7EeF591A6CC0403b9652E98E88476fe1bF31dDeb 42)
log "Vesting deployed at:" $VestingAddr
