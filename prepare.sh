#!/bin/bash

set -e

prepare_scripts_dir="/usr/local/lmce-build/prepare-scripts"

"${prepare_scripts_dir}/install-build-pkgs.sh"

# we ship a full diskless image, no need to duplicate 100MB in a bootstrap image
#"${prepare_scripts_dir}/create-diskless-debootstrap.sh"
# obsolete, these are all in the repository now and part of the build scripts.
#"${prepare_scripts_dir}/import-external-files.sh"

"${prepare_scripts_dir}/preseed-build-pkgs.sh"

