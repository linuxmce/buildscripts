#!/bin/bash -e

. /etc/lmce-build/builder.conf
. /usr/local/lmce-build/common/env.sh
. /usr/local/lmce-build/common/logging.sh
. /usr/local/lmce-build/common/utils.sh

set -e
set -x

build_opts="-tc"
make_jobs=""
ver_split="~"

# set NUMCORES=X in /etc/lmce-build/builder.conf to enable multi-job builds
[[ -n "$NUM_CORES" ]] && [[ "$NUM_CORES" -gt 1 ]] && make_jobs="-j$NUM_CORES"

cache_name=".cache"

function Changed_Since_Last_Build
{
	# set cache_replacements=yes in /etc/lmce-build/builder.conf to enable caching replacements
	# cacheing is disabled by default, you must enable it for it to have any affect
	# if you need to manually build while using the replacement cache, outside a build cycle
	# delete the file: /var/lmce-build/replacements/.cache
	[[ -z "$cache_replacements" ]] && return $(/bin/true) #Zaerc HACK

	local fs_path="$1"
	DisplayMessage "Checking build stamp on '$fs_path'"
	local cache_file="${replacements_dir}/${cache_name}"
	local path_id=$(md5sum <<<"$fs_path" | awk '{ print $1 }')
	pushd "$fs_path" 2>&1 >/dev/null
	local revision_new=$(git log -1 --oneline -- . | cut -d' ' -f1)
	popd 2>&1 >/dev/null
	local revision_old=$(cat "$cache_file" | grep "^${path_id}" | cut -d'|' -f2) || :
	if [ "$revision_new" = "$revision_old" ] && [ -n "$revision_old" ]; then
		return $(/bin/false)
	fi

	return $(/bin/true)
}

function Update_Changed_Since_Last_Build
{
	# Set cache_replacements=yes in /etc/lmce-build/builder.conf to enable caching replacements
	# cacheing is disabled by default, you must enable it for it to have any affect
	#
	# If you need to manually build while using the replacement cache, outside a build cycle
	# delete the file: /var/lmce-build/replacements/.cache
	[[ -z "$cache_replacements" ]] && return $(/bin/true) #Zaerc HACK

        local fs_path="$1"
        DisplayMessage "Updating build stamp for '$fs_path'"
        local cache_file="${replacements_dir}/${cache_name}"
	local path_id=$(md5sum <<<"$fs_path" | awk '{ print $1 }')
	pushd "$fs_path" 2>&1 >/dev/null
	local revision_new=$(git log -1 --oneline -- . | cut -d' ' -f1)
	popd 2>&1 >/dev/null

        [[ -f "$cache_file" ]] && grep -v "$path_id" "$cache_file" > "${cache_file}.tmp" || :
        echo "$path_id|$revision_new" >> "${cache_file}.tmp"
        mv "${cache_file}.tmp" "$cache_file"

	return $(/bin/true)
}

function Build_Replacement_Package
{
	local pkg_name="$1"
	local pkg_dir="$2"

	dir_="${scm_dir}/${pkg_dir}"
	if Changed_Since_Last_Build "$dir_" ;then
		pushd "$dir_"

		if [ -z "$(head -1 debian/changelog | grep .${build_name}.\))" ] ; then
			sed -i "1s/)/${ver_split}${build_name}1)/" debian/changelog
		fi

		DisplayMessage "Building ${pkg_name}"
		echo "dpkg-buildpackage -rfakeroot -us -uc -b $build_opts $make_jobs"
		dpkg-buildpackage -rfakeroot -us -uc -b $build_opts $make_jobs
		cp -fr ../*${pkg_name}*.deb "${replacements_dir}" || :
		cp -fr ../*${pkg_name}*.changes "${replacements_dir}" || :
		Update_Changed_Since_Last_Build "$dir_"
		popd
	fi
}

function Build_Replacements_Common_all
{
	Build_Replacement_Package lmce-sample-media assets/sample_media

	Build_Replacement_Package lmce-avwizard-sounds assets/avwizard-sounds

	Build_Replacement_Package video-wizard-videos assets/video-wizard-videos

	Build_Replacement_Package lmce-avwizard-skin assets/graphics
	#cp -fr ${scm_dir}/assets/lmce-avwizard-skin* "${replacements_dir}"
}

function Build_Replacements_Common_ubuntu
{
	#Package: dvdid
	Build_Replacement_Package dvdid external/dvdid-0.2.0a
	dpkg -i ${scm_dir}/external/libdvdid*.deb

	#Package: pthsem for bcusdk
	pushd 	${scm_dir}/external/pthsem-2.0.8
	autoreconf -i
	popd
	make_jobs="" Build_Replacement_Package pthsem external/pthsem-2.0.8
	dpkg -i ${scm_dir}/external/libpthsem-dev_*.deb ${scm_dir}/external/libpthsem20_*.deb

	#Package: bcusdk (eib)
	Build_Replacement_Package eib external/bcusdk-0.0.5
	dpkg -i ${scm_dir}/external/libeibclient*.deb
#	cp -fr ${scm_dir}/external/*eib*.deb ${replacements_dir}

	#Package: mbrola
	Build_Replacement_Package mbrola ubuntu/mbrola-3.01h+1

	#Package: motion
#	Build_Replacement_Package motion ubuntu/motion-3.2.12+git20150610

	#Package: lmce-core-locator
	Build_Replacement_Package core-locator src/Core/locator

	#Package: tee-pluto
	Build_Replacement_Package tee-pluto misc_utils/tee-pluto

	#Package: pluto-asterisk
##	dir_="${scm_dir}/ubuntu/asterisk"
##	if Changed_Since_Last_Build "$dir_" ;then
##		pushd "$dir_"
##
##		#if [ -z "$(head -1 debian/changelog | grep .${build_name}.\))" ] ; then
##		#	sed -i "1s/)/${ver_split}${build_name}1)/" debian/changelog
##		#fi
##
##		DisplayMessage "Building pluto-asterisk"
##		./make_package_ubuntu.sh $KVER
##		cp -fr asterisk-pluto_*.deb ${replacements_dir}
##		cp -fr asterisk-pluto_*.changes ${replacements_dir}
##		Update_Changed_Since_Last_Build "$dir_"
##		popd
##	fi

	#Package: lirc-pluto
	Build_Replacement_Package lirc-pluto ubuntu/lirc-pluto-0.1

	#Package: mtx-pluto
	Build_Replacement_Package mtx-pluto ubuntu/mtx-1.3.11

	# lmce-asterisk
	Build_Replacement_Package lmce-asterisk src/lmce-asterisk

	# qhttpserver (for LinuxMCE NVR)
	Build_Replacement_Package qhttpserver external/qhttpserver
	dpkg -i ${scm_dir}/external/libqhttpserver*.deb

	#Package: raspi2png
#	if [[ "$arch" == "armhf" ]]; then
#		Build_Replacement_Package raspi2png external/raspi2png
#	fi

	if [[ "$arch" != "armhf" ]]; then
		#Package: linux-image-diskless
		dir_=${scm_dir}/ubuntu/linux-image-dummy
		if Changed_Since_Last_Build "$dir_" ;then
			pushd "$dir_"

			#if [ -z "$(head -1 debian/changelog | grep .${build_name}.\))" ] ; then
			#	sed -i "1s/)/${ver_split}${build_name}1)/" debian/changelog
			#fi

			DisplayMessage "Building linux-image-diskless for $KVER"
			./makepackage.sh && \
			cp -fr linux-image-diskless_*.deb "${replacements_dir}" && \
			cp -fr linux-image-diskless_*.changes "${replacements_dir}" && \
			Update_Changed_Since_Last_Build "$dir_"
			popd
		fi
	fi
}

function Build_Replacements_ubuntu_noble
{
	#  It needs to be mentioned that these packages build prior
	#  to the general ubuntu packages.  If anything here depends
	#  on something that builds in the general ubuntu section,
	#  then that package build needs to move to this section,
	#  prior to any packages that require it.  -- TODO: xine

	mkdir -pv "$replacements_dir"
}

function Build_Replacements_ubuntu_jammy
{
	#  It needs to be mentioned that these packages build prior
	#  to the general ubuntu packages.  If anything here depends
	#  on something that builds in the general ubuntu section,
	#  then that package build needs to move to this section,
	#  prior to any packages that require it.  -- TODO: xine

	mkdir -pv "$replacements_dir"
}

function Build_Replacements_ubuntu_precise
{
	#  It needs to be mentioned that these packages build prior
	#  to the general ubuntu packages.  If anything here depends
	#  on something that builds in the general ubuntu section,
	#  then that package build needs to move to this section,
	#  prior to any packages that require it.  -- TODO: xine

	mkdir -pv "$replacements_dir"

	# ola needs to be configured to the current build environment
	dir_=${scm_dir}/external/ola-0.9.0
	if Changed_Since_Last_Build "$dir_" ;then
		pushd "$dir_"
		if [ -z "$(head -1 debian/changelog | grep .${build_name}.\))" ] ; then
			sed -i "1s/)/${ver_split}${build_name}1)/" debian/changelog
		fi
		DisplayMessage "Building ola-0.9.0"
		autoreconf -i
		dpkg-buildpackage -uc -b $build_opts $make_jobs
		cp -fr ${scm_dir}/external/ola*.deb "${replacements_dir}"
		cp -fr ${scm_dir}/external/ola*.changes "${replacements_dir}"
		Update_Changed_Since_Last_Build "$dir_"
		popd
	fi
	DEBIAN_FRONTEND="noninteractive" dpkg -i ${scm_dir}/external/ola*.deb

	#Package: external/owfs-2.8p5
	pushd ${scm_dir}/external/owfs-2.8p5 ; autoreconf -i ; popd
	Build_Replacement_Package ow external/owfs-2.8p5
	dpkg -i ${scm_dir}/external/owfs-dev*.deb ${scm_dir}/external/libowfs27*.deb

	#Package: gsoap
	Build_Replacement_Package gsoap ubuntu/gsoap-2.8.16
	dpkg -i ${scm_dir}/ubuntu/libgsoap-dev_*.deb ${scm_dir}/ubuntu/libgsoap4_*.deb ${scm_dir}/ubuntu/gsoap_*.deb

	#Package: libsoxr-0.1.1 - for squeezelite
	Build_Replacement_Package soxr ubuntu/libsoxr-0.1.1
	dpkg -i ${scm_dir}/ubuntu/libsoxr*.deb

	#Package: squeezelite-1.8
	Build_Replacement_Package squeezelite ubuntu/squeezelite-1.8

	Build_Replacement_Package chan-sccp-b ubuntu/asterisk/chan-sccp-b_V4.2

	#Package: lirc
	build_opts="" Build_Replacement_Package lirc ubuntu/lirc-0.9.0-0ubuntu1+lmce1

	##Package: platform for libcec
	#Build_Replacement_Package platform ubuntu/platform-1.0.10

	##Package: libcec
	#Build_Replacement_Package cec ubuntu/libcec-3.0.1

	# libical-1.0 for asterisk 11.7
	Build_Replacement_Package libical ubuntu/libical-1.0
	dpkg -i ${scm_dir}/ubuntu/libical*.deb

	# asterisk
	Build_Replacement_Package asterisk ubuntu/asterisk-11.7.0~dfsg

	# lmce-asterisk
	Build_Replacement_Package lmce-asterisk src/lmce-asterisk

	Build_Replacement_Package coherence ubuntu/Coherence-0.6.6.2

	#Package: libbluray1 - for libxine2
	Build_Replacement_Package bluray ubuntu/libbluray-0.5.0
	dpkg -i ${scm_dir}/ubuntu/libbluray*.deb

	#Package: libxine2
	build_opts="" Build_Replacement_Package xine ubuntu/xine-lib-1.2.6

	# precise libsmbclient doesn't ship a pkg-config file, but xine checks for it, so lets provide one for libxine2
	cp ${scm_dir}/ubuntu/smbclient.pc /usr/lib/pkgconfig/

	# libhupnp and libhupnp-av need to build under qt4.
	QT_SELECT=4 Build_Replacement_Package libhupnp-core external/hupnp/hupnp
	# hupnp core debs need to be installed for hupnp_av building
	dpkg -i ${scm_dir}/external/hupnp/libhupnp-core*.deb
	QT_SELECT=4 Build_Replacement_Package libhupnp-av external/hupnp/hupnp_av
	dpkg -i ${scm_dir}/external/hupnp/libhupnp-av-dev*deb  ${scm_dir}/external/hupnp/libhupnp-av_*deb

	#Package: logitechmediaserver-7.8.1
	Build_Replacement_Package logitechmediaserver external/logitechmediaserver-7.8.1

	#Package: libtaglib - for UpdateMedia
	Build_Replacement_Package libtag ubuntu/taglib-1.9.1
	dpkg -i ${scm_dir}/ubuntu/libtag1*.deb

	# Open ZWave library
	ver_split="-" Build_Replacement_Package zwave external/openzwave-1.3.1224
	dpkg -i ${scm_dir}/external/libopenzwave*deb
	cp ${scm_dir}/external/*zwave*.deb "${replacements_dir}"
	cp ${scm_dir}/external/*zwave*.changes "${replacements_dir}"

	# mythtv
	#QT_SELECT=4 Build_Replacement_Package myth ubuntu/mythtv-0.27.5+fixes.20150921.fbd5ef3

	Build_Replacement_Package vdrnfofs ubuntu/vdrnfofs-0.5

#	# ZFS
#	Build_Replacement_Package mountall ubuntu/mountall-2.53
#	Build_Replacement_Package spl ubuntu/spl-linux-0.6.5.9
#	Build_Replacement_Package ubuntu-zfs ubuntu/ubuntu-zfs-8~trusty
#	Build_Replacement_Package zfs-auto-snapshot ubuntu/zfs-auto-snapshot-1.1.0
#	## ZFS has a few non-zfs named subpackages, grrr. Is there a better way to handle this?
#	Build_Replacement_Package zfs ubuntu/zfs-linux-0.6.5.9
#	Build_Replacement_Package libzpool ubuntu/zfs-linux-0.6.5.9
#	Build_Replacement_Package libuutil ubuntu/zfs-linux-0.6.5.9
#	Build_Replacement_Package libnvpair ubuntu/zfs-linux-0.6.5.9
}

function Build_Replacements_ubuntu_trusty
{
	#  It needs to be mentioned that these packages build prior
	#  to the general ubuntu packages.  If anything here depends
	#  on something that builds in the general ubuntu section,
	#  then that package build needs to move to this section,
	#  prior to any packages that require it.  -- TODO: xine

	mkdir -pv "$replacements_dir"

	#Package: libxine2
	build_opts="" Build_Replacement_Package xine ubuntu/xine-lib-1.2.6
	dpkg -i ${scm_dir}/ubuntu/libxine2*.deb

	Build_Replacement_Package vdrnfofs ubuntu/vdrnfofs-0.5

	#Package: vdr-2.2.0
	Build_Replacement_Package vdr external/vdr/vdr-2.2.0
	dpkg -i ${scm_dir}/external/vdr/vdr-dev_*deb

	#Package: vdr-plugin-svdrpservice is needed by remotetimers
	Build_Replacement_Package vdr-plugin-svdrpservice external/vdr/vdr-plugin-svdrpservice-1.0.0
	dpkg -i ${scm_dir}/external/vdr/svdrpservice-dev_*.deb

	#Package: vdr-remotetimers-1.0.2
	Build_Replacement_Package remotetimers external/vdr/remotetimers-1.0.2

	#Package: vdr-streamdev
	Build_Replacement_Package streamdev external/vdr/vdr-plugin-streamdev-d66c635a80b312e2e7277a8fe10f500b05317acd

	#Package: platform for libcec
	Build_Replacement_Package platform ubuntu/platform-1.0.10
	dpkg -i ${replacements_dir}/libplatform*.deb

	#Package: libcec
	Build_Replacement_Package cec ubuntu/libcec-3.0.1
	dpkg -i ${replacements_dir}/libcec3*.deb ${replacements_dir}/libcec-dev*.deb

	#Package: vdr-xineliboutput
	Build_Replacement_Package xineliboutput external/vdr/xineliboutput-fd21e7a0936b984e76eb01c308ccc5a811c68918
	cp ${scm_dir}/external/vdr/*xine*.deb "${replacements_dir}"

	#Package: vdr-iptv
	Build_Replacement_Package iptv external/vdr/iptv-2.2.1


# error
	# softhddevice is build for Intel architecture.
#	if [[ "$arch" != "armhf" ]]; then  
#		#Package: vdr-plugin-softhddevice
#		Build_Replacement_Package softhddevice external/vdr/vdr-plugin-softhddevice-0.6.1rc1.git20150630.0812
#	fi

	#Package: vdr-plugin-xmltv2vdr
	Build_Replacement_Package vdr-plugin-xmltv2vdr external/vdr/vdr-plugin-xmltv2vdr-0.2.0pre.git20140902

	#Package: ruby1.8-1.8.7.375
	Build_Replacement_Package ruby1.8 ubuntu/ruby1.8-1.8.7.375
	dpkg -i ${scm_dir}/ubuntu/ruby*dev*deb ${scm_dir}/ubuntu/libruby1.8_*deb
	cp ${scm_dir}/ubuntu/ri*1.8*.deb "${replacements_dir}"

	# ola needs to be configured to the current build environment
	dir_=${scm_dir}/external/ola-0.9.0
	if Changed_Since_Last_Build "$dir_" ;then
		pushd "$dir_"
		if [ -z "$(head -1 debian/changelog | grep .${build_name}.\))" ] ; then
			sed -i "1s/)/${ver_split}${build_name}1)/" debian/changelog
		fi
		DisplayMessage "Building ola-0.9.0"
		autoreconf -i
		dpkg-buildpackage -uc -b $build_opts $make_jobs
		cp -fr ${scm_dir}/external/ola*.deb "${replacements_dir}"
		cp -fr ${scm_dir}/external/ola*.changes "${replacements_dir}"
		Update_Changed_Since_Last_Build "$dir_"
		popd
	fi
	DEBIAN_FRONTEND="noninteractive" dpkg -i ${scm_dir}/external/ola*.deb

	#Package: squeezelite-1.8
	Build_Replacement_Package squeezelite ubuntu/squeezelite-1.8

	Build_Replacement_Package chan-sccp-b ubuntu/asterisk/chan-sccp-b_V4.2

	#Package: lirc
	build_opts="" Build_Replacement_Package lirc ubuntu/lirc-0.9.0-0ubuntu1+lmce1

	# shairport (AirPlay Audio)
	Build_Replacement_Package shairport ubuntu/shairport-0.05

	#Build_Replacement_Package python-coherence ubuntu/Coherence-0.6.6.2

#	# Open ZWave library
#	ver_split="-" Build_Replacement_Package zwave external/openzwave-1.3.1224
#	dpkg -i ${scm_dir}/external/libopenzwave*deb
#	cp ${scm_dir}/external/*zwave*.deb "${replacements_dir}"
#	cp ${scm_dir}/external/*zwave*.changes "${replacements_dir}"

	# Open ZWave library
	ver_split="-" Build_Replacement_Package zwave ubuntu/open-zwave-1.5
	dpkg -i ${scm_dir}/ubuntu/libopenzwave*deb
	cp ${scm_dir}/ubuntu/*zwave*.deb "${replacements_dir}"
	cp ${scm_dir}/ubuntu/*zwave*.changes "${replacements_dir}"

	# libhupnp and libhupnp-av need to build under qt4.
	QT_SELECT=4 Build_Replacement_Package libhupnp-core external/hupnp/hupnp
	# hupnp core debs need to be installed for hupnp_av building
	dpkg -i ${scm_dir}/external/hupnp/libhupnp-core*.deb
	QT_SELECT=4 Build_Replacement_Package libhupnp-av external/hupnp/hupnp_av
	dpkg -i ${scm_dir}/external/hupnp/libhupnp-av-dev*deb  ${scm_dir}/external/hupnp/libhupnp-av_*deb

	#Package: logitechmediaserver-7.8.1
	Build_Replacement_Package logitechmediaserver external/logitechmediaserver-7.8.1

	# mythtv
	Build_Replacement_Package myth ubuntu/mythtv-0.27.5+fixes.20150921.fbd5ef3

#	# ZFS
#	Build_Replacement_Package mountall ubuntu/mountall-2.53
#	Build_Replacement_Package spl ubuntu/spl-linux-0.6.5.9
#	Build_Replacement_Package ubuntu-zfs ubuntu/ubuntu-zfs-8~trusty
#	Build_Replacement_Package zfs-auto-snapshot ubuntu/zfs-auto-snapshot-1.1.0
#	## ZFS has a few non-zfs named subpackages, grrr. Is there a better way to handle this?
#	Build_Replacement_Package zfs ubuntu/zfs-linux-0.6.5.9
#	Build_Replacement_Package libzpool ubuntu/zfs-linux-0.6.5.9
#	Build_Replacement_Package libuutil ubuntu/zfs-linux-0.6.5.9
#	Build_Replacement_Package libnvpair ubuntu/zfs-linux-0.6.5.9
}

function Build_Replacements_ubuntu_xenial
{
	#  It needs to be mentioned that these packages build prior
	#  to the general ubuntu packages.  If anything here depends
	#  on something that builds in the general ubuntu section,
	#  then that package build needs to move to this section,
	#  prior to any packages that require it.  -- TODO: xine

	mkdir -pv "$replacements_dir"

	Build_Replacement_Package chan-sccp-b ubuntu/asterisk/chan-sccp-b_V4.2

	#Package: lirc
	build_opts="" Build_Replacement_Package lirc ubuntu/lirc-0.9.0-0ubuntu1+lmce1

# build fail missing package 'python-support' required for build.
	#Build_Replacement_Package vdrnfofs ubuntu/vdrnfofs-0.5

# build fail missing package 'libsystemd-daemon-dev' required for build. renamed 'libsystemd-dev' -- vdr needs update
	##Package: vdr-2.2.0
	#Build_Replacement_Package vdr external/vdr/vdr-2.2.0
	#dpkg -i ${scm_dir}/external/vdr/vdr-dev_*deb

	#Package: vdr-plugin-svdrpservice is needed by remotetimers
	Build_Replacement_Package vdr-plugin-svdrpservice external/vdr/vdr-plugin-svdrpservice-1.0.0
	dpkg -i ${scm_dir}/external/vdr/svdrpservice-dev_*.deb

	#Package: vdr-remotetimers-1.0.2
	Build_Replacement_Package vdr-plugin-remotetimers external/vdr/remotetimers-1.0.2

	#Package: vdr-streamdev
	Build_Replacement_Package vdr-plugin-streamdev external/vdr/vdr-plugin-streamdev-d66c635a80b312e2e7277a8fe10f500b05317acd

	#Package: vdr-xineliboutput
#	Build_Replacement_Package xineliboutput external/vdr/xineliboutput-fd21e7a0936b984e76eb01c308ccc5a811c68918
#	cp ${scm_dir}/external/vdr/*xine*.deb "${replacements_dir}"

	#Package: vdr-iptv
	Build_Replacement_Package iptv external/vdr/iptv-2.2.1

# build fail missing vdr dependency?? from vdr-2.2.0 -- maybe need more than just vdr-dev installed??
	## softhddevice is build for Intel architecture.
	#if [[ "$arch" != "armhf" ]]; then  
	#	#Package: vdr-plugin-softhddevice
	#	Build_Replacement_Package softhddevice external/vdr/vdr-plugin-softhddevice-0.6.1rc1.git20150630.0812
	#fi

	#Package: vdr-plugin-xmltv2vdr
	Build_Replacement_Package vdr-plugin-xmltv2vdr external/vdr/vdr-plugin-xmltv2vdr-0.2.0pre.git20140902

	#Package: ruby1.8-1.8.7.375
	Build_Replacement_Package ruby1.8 ubuntu/ruby1.8-1.8.7.375
	dpkg -i ${scm_dir}/ubuntu/ruby*dev*deb ${scm_dir}/ubuntu/libruby1.8_*deb
	cp ${scm_dir}/ubuntu/ri*1.8*.deb "${replacements_dir}"

	# shairport (AirPlay Audio)
	Build_Replacement_Package shairport ubuntu/shairport-0.05

	#Build_Replacement_Package python-coherence ubuntu/Coherence-0.6.6.2

#	# Open ZWave library
#	ver_split="-" Build_Replacement_Package zwave external/openzwave-1.3.1224
#	dpkg -i ${scm_dir}/external/libopenzwave*deb
#	cp ${scm_dir}/external/*zwave*.deb "${replacements_dir}"
#	cp ${scm_dir}/external/*zwave*.changes "${replacements_dir}"

	# Open ZWave library
	ver_split="-" Build_Replacement_Package zwave ubuntu/open-zwave-1.5
	dpkg -i ${scm_dir}/ubuntu/libopenzwave*deb
	cp ${scm_dir}/ubuntu/*zwave*.deb "${replacements_dir}"
	cp ${scm_dir}/ubuntu/*zwave*.changes "${replacements_dir}"

	# libhupnp and libhupnp-av need to build under qt4.
	QT_SELECT=4 Build_Replacement_Package libhupnp-core external/hupnp/hupnp
	# hupnp core debs need to be installed for hupnp_av building
	dpkg -i ${scm_dir}/external/hupnp/libhupnp-core*.deb
	QT_SELECT=4 Build_Replacement_Package libhupnp-av external/hupnp/hupnp_av
	dpkg -i ${scm_dir}/external/hupnp/libhupnp-av-dev*deb  ${scm_dir}/external/hupnp/libhupnp-av_*deb

	#Package: logitechmediaserver-7.9.0
	Build_Replacement_Package logitechmediaserver external/logitechmediaserver-deb

	# mythtv
	Build_Replacement_Package myth ubuntu/mythtv-0.27.5+fixes.20150921.fbd5ef3
}

function Build_Replacements_ubuntu_bionic
{
	#  It needs to be mentioned that these packages build prior
	#  to the general ubuntu packages.  If anything here depends
	#  on something that builds in the general ubuntu section,
	#  then that package build needs to move to this section,
	#  prior to any packages that require it.  -- TODO: xine

	mkdir -pv "$replacements_dir"

#	Build_Replacement_Package vdrnfofs ubuntu/vdrnfofs-0.5
#
#	#Package: vdr-2.2.0
#	Build_Replacement_Package vdr external/vdr/vdr-2.2.0
#	dpkg -i ${scm_dir}/external/vdr/vdr-dev_*deb
#
#	#Package: vdr-plugin-svdrpservice is needed by remotetimers
#	Build_Replacement_Package vdr-plugin-svdrpservice external/vdr/vdr-plugin-svdrpservice-1.0.0
#	dpkg -i ${scm_dir}/external/vdr/svdrpservice-dev_*.deb
#
#	#Package: vdr-remotetimers-1.0.2
#	Build_Replacement_Package vdr-plugin-remotetimers external/vdr/remotetimers-1.0.2
#
#	#Package: vdr-streamdev
#	Build_Replacement_Package vdr-plugin-streamdev external/vdr/vdr-plugin-streamdev-d66c635a80b312e2e7277a8fe10f500b05317acd
#
#	#Package: vdr-xineliboutput
#	Build_Replacement_Package xineliboutput external/vdr/xineliboutput-fd21e7a0936b984e76eb01c308ccc5a811c68918
#	cp ${scm_dir}/external/vdr/*xine*.deb "${replacements_dir}"
#
#	#Package: vdr-iptv
#	Build_Replacement_Package iptv external/vdr/iptv-2.2.1
#
#	# softhddevice is build for Intel architecture.
#	if [[ "$arch" != "armhf" ]]; then  
#		#Package: vdr-plugin-softhddevice
#		Build_Replacement_Package softhddevice external/vdr/vdr-plugin-softhddevice-0.6.1rc1.git20150630.0812
#	fi
#
#	#Package: vdr-plugin-xmltv2vdr
#	Build_Replacement_Package vdr-plugin-xmltv2vdr external/vdr/vdr-plugin-xmltv2vdr-0.2.0pre.git20140902

#	#Package: ruby1.8-1.8.7.375
#	Build_Replacement_Package ruby1.8 ubuntu/ruby1.8-1.8.7.375
#	dpkg -i ${scm_dir}/ubuntu/ruby*dev*deb ${scm_dir}/ubuntu/libruby1.8_*deb
#	cp ${scm_dir}/ubuntu/ri*1.8*.deb "${replacements_dir}"

#	# shairport (AirPlay Audio)
#	Build_Replacement_Package shairport ubuntu/shairport-0.05

	#Build_Replacement_Package python-coherence ubuntu/Coherence-0.6.6.2

#	# libhupnp and libhupnp-av need to build under qt4.
#	QT_SELECT=4 Build_Replacement_Package libhupnp-core external/hupnp/hupnp
#	# hupnp core debs need to be installed for hupnp_av building
#	dpkg -i ${scm_dir}/external/hupnp/libhupnp-core*.deb
#	QT_SELECT=4 Build_Replacement_Package libhupnp-av external/hupnp/hupnp_av
#	dpkg -i ${scm_dir}/external/hupnp/libhupnp-av-dev*deb  ${scm_dir}/external/hupnp/libhupnp-av_*deb

	Build_Replacement_Package chan-sccp-b ubuntu/asterisk/chan-sccp-4.3.1

	#Package: logitechmediaserver-7.9.0
	Build_Replacement_Package logitechmediaserver external/logitechmediaserver-deb

#	package lirc fails to build on bionic, needs update?
#	#Package: lirc
#	build_opts="" Build_Replacement_Package lirc ubuntu/lirc-0.9.0-0ubuntu1+lmce1

#	Open Zwave is not in the debian/ubuntu repositories, no longer need to build as a replacement.
#	# Open ZWave library
#	ver_split="-" Build_Replacement_Package zwave ubuntu/open-zwave-1.5
#	dpkg -i ${scm_dir}/ubuntu/libopenzwave*deb
#	cp ${scm_dir}/ubuntu/*zwave*.deb "${replacements_dir}"
#	cp ${scm_dir}/ubuntu/*zwave*.changes "${replacements_dir}"

}

function Build_Replacements_Common_raspbian
{
	#Package: pthsem for bcusdk
	pushd 	${scm_dir}/external/pthsem-2.0.8 ; autoreconf -i ; popd
	make_jobs="" Build_Replacement_Package pthsem external/pthsem-2.0.8
	dpkg -i ${scm_dir}/external/libpthsem-dev*.deb  ${scm_dir}/external/libpthsem20*.deb

	#Package: bcusdk (eib)
	Build_Replacement_Package bcusdk external/bcusdk-0.0.5
	cp -fr ${scm_dir}/external/*eib*.deb ${replacements_dir}

	#Package: mbrola
	Build_Replacement_Package mbrola ubuntu/mbrola-3.01h+1

	#Package: lmce-core-locator
	Build_Replacement_Package core-locator src/Core/locator

	#Package: tee-pluto
	Build_Replacement_Package tee-pluto misc_utils/tee-pluto

	# qhttpserver (for LinuxMCE NVR)
	Build_Replacement_Package libqhttpserver external/qhttpserver
	cp ${scm_dir}/external/libqhttpserver*.deb "${replacements_dir}"

	#Package: raspi2png
	if [[ "$arch" == "armhf" ]]; then
		Build_Replacement_Package raspi2png external/raspi2png
	fi
}

function Build_Replacements_raspbian_wheezy
{
	#  It needs to be mentioned that these packages build prior
	#  to the general ubuntu packages.  If anything here depends
	#  on something that builds in the general ubuntu section,
	#  then that package build needs to move to this section,
	#  prior to any packages that require it.  -- TODO: xine

	mkdir -pv "$replacements_dir"

	# Open ZWave library
	Build_Replacement_Package zwave external/openzwave-1.3.1224
	dpkg -i ${scm_dir}/external/libopenzwave*deb
        cp ${scm_dir}/external/openzwave*.deb "${replacements_dir}"
        cp ${scm_dir}/external/openzwave*.changes "${replacements_dir}"

	#Package: motion
	Build_Replacement_Package motion ubuntu/motion-3.2.12+git20150610

	#ubuntu/squeezelite-1.8
	#Package: squeezelite-1.8
	Build_Replacement_Package squeezelite ubuntu/squeezelite-1.8

}

function Build_Replacements_raspbian_jessie
{
	#  It needs to be mentioned that these packages build prior
	#  to the general ubuntu packages.  If anything here depends
	#  on something that builds in the general ubuntu section,
	#  then that package build needs to move to this section,
	#  prior to any packages that require it.  -- TODO: xine

	mkdir -pv "$replacements_dir"

	# Open ZWave library
	Build_Replacement_Package zwave external/openzwave-1.3.1224
	dpkg -i ${scm_dir}/external/libopenzwave*deb
        cp ${scm_dir}/external/openzwave*.deb "${replacements_dir}"
        cp ${scm_dir}/external/openzwave*.changes "${replacements_dir}"

	#Package: motion
	Build_Replacement_Package motion ubuntu/motion-3.2.12+git20150610

	#Package: vdr-2.2.0
	Build_Replacement_Package vdr external/vdr/vdr-2.2.0
	dpkg -i ${scm_dir}/external/vdr/vdr-dev_*deb

	#Package: vdr-plugin-svdrpservice is needed by remotetimers
	Build_Replacement_Package vdr-plugin-svdrpservice external/vdr/vdr-plugin-svdrpservice-1.0.0
	dpkg -i ${scm_dir}/external/vdr/svdrpservice-dev_*.deb

	#Package: vdr-remotetimers-1.0.2
	Build_Replacement_Package remotetimers external/vdr/remotetimers-1.0.2

	#Package: vdr-streamdev
	Build_Replacement_Package streamdev external/vdr/vdr-plugin-streamdev-d66c635a80b312e2e7277a8fe10f500b05317acd

	#Package: vdr-plugin-rpihddevice
	Build_Replacement_Package rpihddevice external/vdr/vdr-plugin-rpihddevice

	#Package: vdr-iptv
	Build_Replacement_Package iptv external/vdr/iptv-2.2.1

	#Package: vdr-plugin-xmltv2vdr
	Build_Replacement_Package vdr-plugin-xmltv2vdr external/vdr/vdr-plugin-xmltv2vdr-0.2.0pre.git20140902

	#Package: platform for libcec
	Build_Replacement_Package platform raspbian/libcec-platform-1.0.10+dfsg1

	#Package: libcec
	Build_Replacement_Package cec raspbian/libcec-3.0.1+dfsg2

	#Package: logitechmediaserver-7.9.0
	Build_Replacement_Package logitechmediaserver external/logitechmediaserver-deb

	# mythtv
	Build_Replacement_Package myth ubuntu/mythtv-0.27.5+fixes.20150921.fbd5ef3

	#ubuntu/squeezelite-1.8
	#Package: squeezelite-1.8
	Build_Replacement_Package squeezelite ubuntu/squeezelite-1.8

}

function Build_Replacements_raspbian_buster
{
	#  It needs to be mentioned that these packages build prior
	#  to the general ubuntu packages.  If anything here depends
	#  on something that builds in the general ubuntu section,
	#  then that package build needs to move to this section,
	#  prior to any packages that require it.  -- TODO: xine

	mkdir -pv "$replacements_dir"

	#Package: logitechmediaserver-7.9.0
#	Build_Replacement_Package logitechmediaserver external/logitechmediaserver-deb
}

trap 'Error "Undefined error in $0" ; apt-get install libtool -y' EXIT

DisplayMessage "*** STEP: Building replacement debs"
# create dir, it is required even if no replacements are built
mkdir -pv "${replacements_dir}"

DisplayMessage "Building Replacements for $flavor $build_name"
Build_Replacements_${flavor}_${build_name}
DisplayMessage "Building Replacements for $flavor"
Build_Replacements_Common_${flavor}

if [[ -z "$BUILD_ALL_PKGS" ]] || [[ "$BUILD_ALL_PKGS" != "no" ]]; then
	DisplayMessage "Building Replacements for '_all' pkgs"
	Build_Replacements_Common_all
else
	DisplayMessage "NOT Building Replacements for '_all' pkgs"
fi

DisplayMessage "Removing duplicate debs from replacements"
remove_duplicate_debs "${replacements_dir}"

trap - EXIT

