#!/bin/bash
#TODO:
# Implement a system that compiles the bins only when they're changed (similar to replacements)
. /etc/lmce-build/builder.conf
. /usr/local/lmce-build/common/logging.sh 

#set -x 
set -e

make_jobs=""
# set NUMCORES=X in /etc/lmce-build/builder.custom.conf to enable multi-job builds
[[ -n "$NUM_CORES" ]] && [[ "$NUM_CORES" -gt 1 ]] && make_jobs="-j $NUM_CORES"

function Precompile
{
	local pkg_name="$1"
	local pkg_dir="$2"

	local makefile_opt



	DisplayMessage "Precompiling $pkg_name"
	pushd "$pkg_dir"
		if [ -r "Makefile.bootstrap" ]
		then
			makefile_opt="-f Makefile.bootstrap"

		elif [ -r "Makefile.no-wrapper" ]
		then
			makefile_opt="-f Makefile.no-wrapper"

		elif [ -r "Makefile" ]
		then
			makefile_opt=""

		elif [ -r "Makefile.MakeRelease" ]
		then
			makefile_opt="-f Makefile.MakeRelease"

		elif [ -r "Makefile.prep" ]
		then
			makefile_opt="-f Makefile.prep"

		else
			Error "Could not find a Makefile for ${pkg_name} in ${pkg_dir}"
		fi

		echo "SNR_CPPFLAGS=\"\" make $makefile_opt clean"
		SNR_CPPFLAGS="" make $makefile_opt clean || Error "Failed to clean ${pkg_name} to use for MakeRelease"
		echo "SNR_CPPFLAGS=\"\" make $make_jobs $makefile_opt"
		SNR_CPPFLAGS="" make $make_jobs $makefile_opt || Error "Failed to precompile ${pkg_name} to use for MakeRelease"

	 popd


}

function Build_MakeRelease {

	mkdir -p "${scm_dir}/src/lib"

	Precompile pluto_main "${scm_dir}/src/pluto_main"
	Precompile PlutoUtils "${scm_dir}/src/PlutoUtils"
	Precompile SerializeClass "${scm_dir}/src/SerializeClass"
	Precompile LibDCE "${scm_dir}/src/DCE"
	Precompile WindowUtils "${scm_dir}/src/WindowUtils"
	Precompile MakeRelease "${scm_dir}/src/MakeRelease"
	Precompile MakeRelease_PrepFiles "${scm_dir}/src/MakeRelease_PrepFiles"

	DisplayMessage "Copy MakeRelease files to ${mkr_dir}"
	mkdir -pv "${mkr_dir}"

	cp -v "${scm_dir}/src/bin/MakeRelease" "${mkr_dir}"
	cp -v "${scm_dir}/src/bin/MakeRelease_PrepFiles" "${mkr_dir}"
	cp -v "${scm_dir}/src/lib/"*.so "${mkr_dir}"

}

DisplayMessage "**** STEP : PREPARING BUILD SYSTEM (MakeRelease)"
trap 'Error "Undefined error in $0"' EXIT

Build_MakeRelease

trap - EXIT
