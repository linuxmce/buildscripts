#!/bin/bash -e

. /etc/lmce-build/builder.conf
. /usr/local/lmce-build/common/env.sh

if [[ -f "$log_file" ]] ;then
	mv "$log_file" "$log_file.$(date '+%Y%m%d-%H%M%S')"
fi
# Clean up old changes files from broken duploads, as well as any upload file.
mkdir -p "$replacements_dir"	# /var/lmce-build/replacements
mkdir -p "$local_mirror_dir"	# /var/www (or /var/lmce-build/www in docker)
pushd "$replacements_dir"	# /var/lmce-build/replacements
rm *.changes || :
rm *.upload || :
popd
pushd "$local_mirror_dir"
rm *.changes || :
rm *.upload || :
popd

"${build_scripts_dir}/clone-git.sh"
"${build_scripts_dir}/import-win32bins.sh"

"${build_scripts_dir}/build-replacements.sh"
"${build_scripts_dir}/build-makerelease.sh"
"${build_scripts_dir}/import-databases.sh"

"${build_scripts_dir}/build-maindebs.sh"
"${build_scripts_dir}/get-closed-source-debs.sh"

"${build_scripts_dir}/create-repo.sh"

# push stuff into deb
pushd "$local_mirror_dir"
dupload --to linuxmce `ls *.changes | grep -v svdrpservice | grep -v platform | grep -v libcec`
popd

# Don't dupload twice, these files are copied into $local_mirror_dir during create-repo.sh
#pushd /var/lmce-build/replacements
#dupload --to linuxmce *.changes
#popd

VERSION=`grep "g_szSourceRevision" "${scm_dir}/src/version.h" | grep -v extern | cut -f2 -d"=" | cut -f1 -d";"`
wget --no-check-certificate  https://vt100.at/announce.php?text=$build_name\ $arch\ $(hostname)\ is\ done\ with\ $VERSION -O /dev/null
