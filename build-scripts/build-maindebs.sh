#!/bin/bash

. /etc/lmce-build/builder.conf
. /usr/local/lmce-build/common/logging.sh
. /usr/local/lmce-build/build-scripts/name-packages.sh
. /usr/local/lmce-build/build-scripts/version-helper.sh

LC_ALL=C

set -e
#set -x

make_jobs=""
# set NUMCORES=X in /etc/lmce-build/builder.conf to enable multi-job builds
[[ -n "$NUM_CORES" ]] && [[ "$NUM_CORES" -gt 1 ]] && make_jobs="-j $NUM_CORES"

PLUTO_BUILD_CRED=""
if [ "$sql_build_host" ] ; then PLUTO_BUILD_CRED="$PLUTO_BUILD_CRED -h $sql_build_host"; fi
if [ "$sql_build_port" ] ; then PLUTO_BUILD_CRED="$PLUTO_BUILD_CRED -P $sql_build_port"; fi
if [ "$sql_build_user" ] ; then PLUTO_BUILD_CRED="$PLUTO_BUILD_CRED -u $sql_build_user"; fi
if [ "$sql_build_pass" ] ; then PLUTO_BUILD_CRED="$PLUTO_BUILD_CRED -p $sql_build_pass"; fi
export PLUTO_BUILD_CRED

MYSQL_BUILD_CRED=""
if [ "$sql_build_host" ] ; then MYSQL_BUILD_CRED="$MYSQL_BUILD_CRED -h$sql_build_host"; fi
if [ "$sql_build_port" ] ; then MYSQL_BUILD_CRED="$MYSQL_BUILD_CRED -P$sql_build_port"; fi
if [ "$sql_build_user" ] ; then MYSQL_BUILD_CRED="$MYSQL_BUILD_CRED -u$sql_build_user"; fi
if [ "$sql_build_pass" ] ; then MYSQL_BUILD_CRED="$MYSQL_BUILD_CRED -p$sql_build_pass"; fi
export MYSQL_BUILD_CRED

export SNR_CPPFLAGS="$compile_defines"

function build_main_debs() {
	export PATH=$PATH:${scm_dir}/src/bin
	echo "PATH=$PATH"
	export LD_LIBRARY_PATH="$mkr_dir:${scm_dir}/src/lib"
	echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"

	# Clear the debs output directory
	DisplayMessage "Cleaning MakeRelease debs output directory"
	rm -rf "${out_dir}" || Error "Cannot clean MakeRelease debs output directory"
	mkdir -p "${out_dir}" || Error "Cannot create MakeRelease debs output directory"
	mkdir -p ${scm_dir}/src/bin
        mkdir -p ${scm_dir}/src/lib
	DisplayMessage "Compiling and building packages"

	pushd ${scm_dir}
	GITrevision=$(git log -1 --pretty=oneline | cut -d' ' -f1 | cut -c1-8)
	popd

	exclude_list=${exclude_list:-0}

	# The default version string is 2.0.0.44 and gets amended by the git revision plus time of day and date
	Main_Version='2.0.0.44.'
	case "${flavor}" in
		"ubuntu")
                        #FIXME Hackozaurus for ubuntu-diskless-tools
                        mkdir -p /home/DisklessFS/
                        diskless_image_name="PlutoMD_Debootstraped.tar.bz2"
#                       cp "${diskless_dir}/$diskless_image_name" /home/DisklessFS
#                       cp "${diskless_dir}/PlutoMD_Debootstraped.tar.bz2" /home/DisklessFS

			case "${build_name}" in
 				"precise")
					Distro_ID="20"
					RepositorySource=25
					Main_Version='2.0.0.46.'
					;;
				"trusty")
					Distro_ID="21"
					RepositorySource=25
					Main_Version='2.0.0.47.'
					exclude_list=$exclude_list,673,674 # lmce game player
					exclude_list=$exclude_list,826,827 # ago-control bridge - obsolete

					exclude_list=$exclude_list,858,859 # qorbitrer core gl - need to figure build-packages


					case "${arch}" in
						"armhf")
							exclude_list=$exclude_list,452,453 # IRTrans - no armhf .so
							exclude_list=$exclude_list,879,881 # qOrbiter for Android
							exclude_list=$exclude_list,682,683 # mame
							;;
						"amd64")
							exclude_list=$exclude_list,829,830 # omx player
							exclude_list=$exclude_list,879,881 # qorbiter android
							;;
						"i386")
							exclude_list=$exclude_list,829,830 # omx player
							exclude_list=$exclude_list,879,881 # qOrbiter for Android
							;;
					esac
					;;
				"xenial")
					Distro_ID="23"
					RepositorySource=25
					Main_Version='2.0.0.48.'

					#should be building but not...??
					exclude_list=$exclude_list,307,335 # Generic Serial Device - ruby 1.8 no longer available ???
					exclude_list=$exclude_list,498,499 # Simplephone - needs TLC, domain field added to auth calls, and more ???
					exclude_list=$exclude_list,505,506 # Pluto ZWave - change in namespace fixed for jammy - maybe messed up xenial? or trusty?
					exclude_list=$exclude_list,772,773 # EIB - missing lib from replacements

					#definitely not building
					exclude_list=$exclude_list,673,674 # lmce game player - fails to build
					exclude_list=$exclude_list,682,683 # mame - fails to build
					exclude_list=$exclude_list,879,881 # qorbiter android - no sdk/ndk
					exclude_list=$exclude_list,826,827 # ago-control bridge
					case "${arch}" in
						"armhf")
							exclude_list=$exclude_list,452,453 # IRTrans - no armhf .so
							: ;;
						"amd64")
							: ;;
					esac
					;;
				"bionic")
					Distro_ID="24"
					RepositorySource=25
					Main_Version='2.0.0.48.'
					exclude_list=$exclude_list,673,674 # lmce game player - fails to build
					exclude_list=$exclude_list,682,683 # mame - fails to build
					exclude_list=$exclude_list,879,881 # qorbiter android - no sdk/ndk
					exclude_list=$exclude_list,826,827 # ago-control bridge
					case "${arch}" in
						"armhf")
							exclude_list=$exclude_list,452,453 # IRTrans - no armhf .so
							: ;;
						"amd64")
							: ;;
					esac
					;;
				"jammy")
					Distro_ID="27"
					RepositorySource=25
					Main_Version='2.0.0.48.'
					exclude_list=$exclude_list,673,674 # lmce game player - fails to build
					exclude_list=$exclude_list,682,683 # mame - fails to build
					exclude_list=$exclude_list,879,881 # qorbiter android - no sdk/ndk
					exclude_list=$exclude_list,826,827 # ago-control bridge - ago control no longer exists

					exclude_list=$exclude_list,307,335 # Generic Serial Device - ruby 1.8 no longer available
					exclude_list=$exclude_list,498,499 # Simplephone - needs TLC, domain field added to auth calls, and more

					exclude_list=$exclude_list,871,872 # CEC_Adaptor - lib updates
					exclude_list=$exclude_list,780,781 # LMCE media-tagging - qt issues - no qt5?
					exclude_list=$exclude_list,812,813 # Advanced IP Camera - gsoap compile issues
					exclude_list=$exclude_list,914,917 # LMCE Cloud Interface
					exclude_list=$exclude_list,405,406 # IRTrans - missing variable from library
					exclude_list=$exclude_list,452,453 # IRTrans Wrapper - missing variable from library
					exclude_list=$exclude_list,772,773 # EIB - missing lib from replacements
					exclude_list=$exclude_list,842,843 # DLNA
					exclude_list=$exclude_list,858,859 # qorbitrer core gl

					#exclude_list=$exclude_list,405,406 # UpdateMedia - Exiv2 missing variable
					#exclude_list=$exclude_list,529,530 # HAL
					#exclude_list=$exclude_list,931,932 # LMCE Media Identifier
					#exclude_list=$exclude_list,505,506 # Pluto ZWave - change in namespace fixed

					case "${arch}" in
						"armhf")
							exclude_list=$exclude_list,452,453 # IRTrans - no armhf .so
							: ;;
						"amd64")
							: ;;
					esac
					;;
			esac
			;;
				"noble")
					Distro_ID="27"
					RepositorySource=25
					Main_Version='2.0.0.48.'
					exclude_list=$exclude_list,673,674 # lmce game player - fails to build
					exclude_list=$exclude_list,682,683 # mame - fails to build
					exclude_list=$exclude_list,879,881 # qorbiter android - no sdk/ndk
					exclude_list=$exclude_list,826,827 # ago-control bridge - ago control no longer exists

					exclude_list=$exclude_list,307,335 # Generic Serial Device - ruby 1.8 no longer available
					exclude_list=$exclude_list,498,499 # Simplephone - needs TLC, domain field added to auth calls, and more

					exclude_list=$exclude_list,871,872 # CEC_Adaptor - lib updates
					exclude_list=$exclude_list,780,781 # LMCE media-tagging - qt issues - no qt5?
					exclude_list=$exclude_list,812,813 # Advanced IP Camera - gsoap compile issues
					exclude_list=$exclude_list,914,917 # LMCE Cloud Interface
					exclude_list=$exclude_list,405,406 # IRTrans - missing variable from library
					exclude_list=$exclude_list,452,453 # IRTrans Wrapper - missing variable from library
					exclude_list=$exclude_list,772,773 # EIB - missing lib from replacements
					exclude_list=$exclude_list,842,843 # DLNA
					exclude_list=$exclude_list,858,859 # qorbitrer core gl

					#exclude_list=$exclude_list,405,406 # UpdateMedia - Exiv2 missing variable
					#exclude_list=$exclude_list,529,530 # HAL
					#exclude_list=$exclude_list,931,932 # LMCE Media Identifier
					#exclude_list=$exclude_list,505,506 # Pluto ZWave - change in namespace fixed

					case "${arch}" in
						"armhf")
							exclude_list=$exclude_list,452,453 # IRTrans - no armhf .so
							: ;;
						"amd64")
							: ;;
					esac
					;;
			esac
			;;
		"raspbian")
			#FIXME Hackozaurus for ubuntu-diskless-tools
			mkdir -p /home/DisklessFS/
		        diskless_image_name="PlutoMD_Debootstraped-$flavor-$build_name-$arch.tar.bz2"
#			cp "${diskless_dir}/$diskless_image_name" /home/DisklessFS

			case "${build_name}" in
				wheezy)
					Distro_ID="19"
					RepositorySource=23
					Main_Version='2.0.0.46.'
					# not currently compatible
					:

					# does not compile
					exclude_list=$exclude_list,862,863	# Hue Controller (qt4)
		                        exclude_list=$exclude_list,682,683	# MAME
					;;
				jessie)
					Distro_ID="22"
					RepositorySource=23
					Main_Version='2.0.0.47.'
					# not currently compatible
					exclude_list=$exclude_list,498,499	# simplephone

					# does not compile
		                        exclude_list=$exclude_list,682,683	# MAME
					;;
				buster)
					Distro_ID="25"
					RepositorySource=23
					Main_Version='2.0.0.48.'
					# not currently compatible
					:

					# does not compile
					exclude_list=$exclude_list,862,863	# Hue Controller (qt4)
		                        exclude_list=$exclude_list,682,683	# MAME
					;;
			esac
			;;
	esac

	# Set version of packages to todays date, plus 00:19 as time
	Q="Update Version Set VersionName= concat('$Main_Version',substr(now()+0,1,12),'+$GITrevision') Where PK_Version = 1;"
	mysql $PLUTO_BUILD_CRED -D 'pluto_main_build' -e "$Q"

	create_version_h ${scm_dir} . ${Main_Version} $GITrevision

	# Compile the packages
	echo "\"${mkr_dir}/MakeRelease\" $make_jobs -a -R \"$GITrevision\" $PLUTO_BUILD_CRED -O \"$out_dir\" -D 'pluto_main_build' -o \"$Distro_ID\" -r \"$RepositorySource\" -m 1,1176 -K \"$exclude_list\" -s \"${scm_dir}\" -n / -d"
	arch=$arch "${mkr_dir}/MakeRelease" $make_jobs -a -R "$GITrevision" $PLUTO_BUILD_CRED -O "$out_dir" -D 'pluto_main_build' -o "$Distro_ID" -r "$RepositorySource" -m 1,1176 -K "$exclude_list" -s "${scm_dir}" -n / -d || Error "MakeRelease failed"
}


DisplayMessage "*** STEP: Running MakeRelease"
trap 'Error "Undefined error in $0"' EXIT

build_main_debs

trap - EXIT
DisplayMessage "*** STEP: Finished MakeRelease"
