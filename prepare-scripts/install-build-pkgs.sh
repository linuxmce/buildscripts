#!/bin/bash

. /etc/lmce-build/builder.conf
. /usr/local/lmce-build/common/env.sh

set -e

echo ""
echo "********************************************************************************"
echo "*** Running: $0"
echo "********************************************************************************"

# Install packages
DEBIAN_FRONTEND=noninteractive apt-get -q -f -y install `cat $lmce_build_conf_dir/build-packages`

export KVER=$(ls -vd /lib/modules/[0-9]* | sed 's/.*\///g' | tail -1)
export KVER_SHORT=$(echo $KVER | cut -d'-' -f1)

# Unpack kernel source
#pushd /usr/src
#	echo "Unpacking kernel source linux-source-"$KVER_SHORT".tar.bz2"
#	tar xjf linux-source-"$KVER_SHORT".tar.bz2
#popd

echo "*** Done: $0"
