#!/bin/bash

. /etc/lmce-build/builder.conf
. /usr/local/lmce-build/build-scripts/version-helper.sh
set -e
set -x

make_jobs=""
# set NUMCORES=X in /etc/lmce-build/builder.conf to enable multi-job builds
[[ -n "$NUM_CORES" ]] && [[ 1 -lt "$NUM_CORES" ]] && make_jobs="-j $NUM_CORES"

case "${flavor}" in
        "ubuntu")
		Main_Version="2.0.0.44."
                case "${build_name}" in
                        "gutsy")
                                Distro_ID="15"
                                RepositorySource=21
                                ;;
                        "hardy")
                                Distro_ID="16"
                                RepositorySource=21
                                ;;
                        "intrepid")
                                Distro_ID="17"
                                RepositorySource=21
                                ;;
                        "lucid")
                                Distro_ID="18"
                                RepositorySource=21
				Main_Version="2.0.0.45."
                                ;;
                        "precise")
                                Distro_ID="20"
                                RepositorySource=25
				Main_Version="2.0.0.46."
                                ;;
                        "trusty")
                                Distro_ID="21"
                                RepositorySource=25
				Main_Version="2.0.0.47."
                                ;;
                        "xenial")
                                Distro_ID="23"
                                RepositorySource=25
				Main_Version="2.0.0.48."
                                ;;
                        "bionic")
                                Distro_ID="24"
                                RepositorySource=25
				Main_Version="2.0.0.48."
                                ;;
                        "jammy")
                                Distro_ID="27"
                                RepositorySource=25
				Main_Version="2.0.0.48."
                                ;;
                        "noble")
                                Distro_ID="27"
                                RepositorySource=25
				Main_Version="2.0.0.48."
                                ;;
                esac
                ;;
        "raspbian")
                case "${build_name}" in
                        "wheezy")
                        Distro_ID="19"
                        RepositorySource=23
			Main_Version="2.0.0.46."
                        ;;
                        "jessie")
                        Distro_ID="22"
                        RepositorySource=23
			Main_Version="2.0.0.47."
                        ;;
                        "buster")
                        Distro_ID="25"
                        RepositorySource=23
			Main_Version="2.0.0.48."
                        ;;
		esac
		;;
esac

export SNR_CPPFLAGS="$compile_defines"
export PATH=$PATH:${scm_dir}/src/bin
export LD_LIBRARY_PATH="$mkr_dir:${scm_dir}/src/lib"

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

pushd ${scm_dir}
GITrevision=$(git log -1 --pretty=oneline | cut -d' ' -f1 | cut -c1-8)
popd

# Set version of packages to todays date, plus 00:00 as time, plus the GITrevision number
Q="Update Version Set VersionName= concat('$Main_Version',substr(now()+0,1,12),'+$GITrevision') Where PK_Version = 1;"
mysql $PLUTO_BUILD_CRED -D 'pluto_main_build' -e "$Q"

create_version_h ${scm_dir} . ${Main_Version} $GITrevision

# Compile the packages
arch=$arch "${mkr_dir}/MakeRelease" $make_jobs -R "$GITrevision" $PLUTO_BUILD_CRED -O "$out_dir" -D 'pluto_main_build' -o "$Distro_ID" -r "$RepositorySource" -m 1,1176 -k "$1" -s "${scm_dir}" -n / -d

