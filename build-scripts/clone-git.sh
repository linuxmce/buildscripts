#!/bin/bash
. /etc/lmce-build/builder.conf
. /usr/local/lmce-build/common/logging.sh

set -x

dir=""

Pull_SubModules() {
	cat ".gitmodules" | grep path | awk '{ print $3 }' |
	while IFS='' read -r submodule ; do
		if [[ -f "${submodule}/.git" ]] ; then
			gitbranch=$(cat ".gitmodules" | grep "${submodule}" -A2 | grep branch | awk '{ print $3 }')
			pushd "${submodule}"
			DisplayMessage "Pulling submodule: $(pwd), branch: ${gitbranch}"
			git checkout "${gitbranch}"
			git pull
			popd
		else
			DisplayMessage "Initializing submodule: $(pwd)"
			git submodule init
			git submodule update
		fi
		pushd "${submodule}"
		Pull_SubModules
		popd
	done
}

Clone_Git() {
	DisplayMessage "**** STEP : GIT CLONE (INITIAL CHECKOUT)"

	pushd ${build_dir}
		LASTVERSION="<none>"
		DisplayMessage "Cloning ${git_url} into ${scm_dir}"
		git clone --recursive ${git_url} ${scm_dir} || Error "Failed to clone ${git_url}"
	popd

	if [[ "$no_clean_scm" != "true" ]] ; then
		cp -R ${scm_dir} ${scm_dir}-last
	fi
}

Pull_Git() {
	DisplayMessage "**** STEP : GIT PULL (UPDATE)"

	if [[ "$no_clean_scm" != "true" ]] ; then
		pushd ${scm_dir}-last
	else
		pushd ${scm_dir}
	fi
		LASTVERSION="$(git log -1 --pretty=oneline | cut -d' ' -f1 | cut -c1-10)"
		DisplayMessage "Updating GIT $LASTVERSION to latest, branch: $git_branch_name"
		git pull ||  Error "Failed to update ${git_url}"
		Pull_SubModules
	popd

	if [[ "$no_clean_scm" != "true" ]] ; then
		rm -R ${scm_dir}
		DisplayMessage "Copying checkout to work"
		cp -R ${scm_dir}-last ${scm_dir}
	fi
}

mkdir -p ${build_dir}

if [ -d ${scm_dir} ] ; then
	Pull_Git
else
	Clone_Git
fi

pushd ${scm_dir}
	git checkout $git_branch_name
	VERSION="$(git log -1 --pretty=oneline | cut -d' ' -f1 | cut -c1-10)"
popd

DisplayMessage "Old version was $LASTVERSION, new version is $VERSION, branch: $git_branch_name"
