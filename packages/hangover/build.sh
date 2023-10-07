TERMUX_PKG_HOMEPAGE=https://github.com/AndreRH/hangover
TERMUX_PKG_DESCRIPTION="A compatibility layer for running Windows programs"
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_LICENSE_FILE="\
LICENSE
LICENSE.OLD
COPYING.LIB"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=8.17
TERMUX_PKG_SRCURL=https://dl.winehq.org/wine/source/8.x/wine-$TERMUX_PKG_VERSION.tar.xz
TERMUX_PKG_SHA256=f01785bd3162c74e65deb13aa0add711e37c484454719bedd0e8c2b1a3469b7e
TERMUX_PKG_DEPENDS="freetype, xwayland, cups, libdrm, libgmp, openldap, sdl2, libandroid-shmem, libc++"
TERMUX_PKG_BUILD_DEPENDS="mesa-dev"
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS=" \
 -C \
 	enable_wineandroid_drv=no \
 	--enable-win64 --disable-tests --without-alsa --without-capi --without-coreaudio --without-cups --without-dbus \
	--without-fontconfig --without-gettext --without-gphoto --without-gnutls --without-gssapi --without-gstreamer \
	--without-inotify --without-krb5 --without-ldap --without-mingw --without-netapi --without-openal --without-opencl \
	--without-opengl --without-osmesa --without-oss --without-pcap --without-pthread --without-pulse --without-sane \
	--without-sdl --without-udev --without-unwind --without-usb --without-v4l2 --without-vulkan --without-x \
	--without-xcomposite --without-xcursor --without-xfixes --without-xinerama --without-xinput --without-xinput2 \
	--without-xrandr --without-xrender --without-xshape --without-xshm --without-xxf86vm \
"

PKG_SCRIPTDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

TERMUX_PKG_EXTRA_CONFIGURE_ARGS=" \
 -C \
	enable_wineandroid_drv=no \
	exec_prefix=$TERMUX_PREFIX \
	--with-wine-tools=$TERMUX_PKG_HOSTBUILD_DIR \
	--enable-nls \
	--disable-tests \
	--with-mingw \
	--enable-archs=i386,aarch64 \
	X_EXTRA_LIBS=-landroid-shmem \
"

_setup_llvm_mingw_toolchain() {
	# LLVM-mingw's version number must not be the same as the NDK's.
	local _llvm_mingw_version=13
	local _version="20211002"
	local _url="https://github.com/mstorsjo/llvm-mingw/releases/download/$_version/llvm-mingw-$_version-ucrt-ubuntu-18.04-x86_64.tar.xz"
	local _path="$TERMUX_PKG_CACHEDIR/$(basename $_url)"
	local _sha256sum=30e9400783652091d9278ce21e5c170d01a5f44e4f1a25717b63cd9ad9fbe13b
	termux_download $_url $_path $_sha256sum
	local _extract_path="$TERMUX_PKG_CACHEDIR/llvm-mingw-toolchain-$_llvm_mingw_version"
	if [ ! -d "$_extract_path" ]; then
		mkdir -p "$_extract_path"-tmp
		tar -C "$_extract_path"-tmp --strip-component=1 -xf "$_path"
		mv "$_extract_path"-tmp "$_extract_path"
	fi
	export PATH="$PATH:$_extract_path/bin"
}

HANGOVER_COMMITS=(1d2434b06d2c5245651817e668f7309ad443a1d2 8928b725c113b9cb4c0452eb4793544936b310f0 408224739530d9aadb22af4a5581f8b7e36e6b7e ac80087015eb09f9c24d57fa026ebfa76f760a6b 1b63385b4c54dd4f86356e401bea88e9dfe6590e 54a5334f6ea6fea2496f9b6b8f3bce98cb5d8d3b dd204ea956efffb4e00c0eb2ade2abc4ec521622 1508a0cc72685844b9529f1053832ec256dda63a 1e612d4df6acc03bccc107158334b239d09ff43f 8f5b5d2747d6e5b21bf7ccb294869f50d98d44ed e9dd0e86d1fdc476f0ee2b216178da9930a7f107 9d10d8dc30627c26b05e23a1b34b79fd0379ed67 f5f060d697e63199294c1e9824a6d0f2052304c3 08fb281712a3cee6983b9efa9129c9aed910cede ffc6cbdca066b1f39da56975b5d90629f30edd11 258a1eb65e8c7b2c7a2c8fd9520e3c28371dec1b a3c1b14a983a621459cf726f97635ff67e0d7a34 2c38c5bead8ab9a2ae571e0f2b285d4a08217f62 697e333944a55c4945534148810fdf96152f4b86 8fc4c9bbc7023565b6bcec6097e76cb421c3a237 f07527a3e7046785c14c3808cfd860e26d7a6121 c8cd948054cc7fcc6a34323b219dbc9de24f55b2 32b7f95ecec8f731abd3210bcda90fd5a8878845 0a79dc5cc596c1021644fee02b46657edb5d5f9c)
_download_commits() {
	cd $1
	local num_jobs="\j"
	local num_procs=4 #$(nproc)
	for commitsha in ${HANGOVER_COMMITS[@]}; do
		while (( ${num_jobs@P} >= num_procs )); do
			wait -n
		done
		if [ ! -f "hangover_$commitsha.patch" ]; then
			{
				curl -so "hangover_$commitsha.patch" --retry 5 "https://github.com/AndreRH/wine/commit/$commitsha.patch"
				echo "Downloaded commit $commitsha"
			} &
			#dos2unix "$1/hangover_$commitsha.patch"
		fi
	done
	wait
	cd $2
}

_apply_commits() {
	cd $2
	for commitsha in ${HANGOVER_COMMITS[@]}; do
		patch -p1 < "$1/hangover_$commitsha.patch"
	done
}

_setup_qemu(){
	local _url="https://download.qemu.org/qemu-7.2.0.tar.xz"
	local _path="$TERMUX_PKG_CACHEDIR/$(basename $_url)"
	termux_download "$_url" "$_path" 5b49ce2687744dad494ae90a898c52204a3406e84d072482a1e1be854eeb2157

	rm -rf "$TERMUX_PKG_CACHEDIR/qemu-tmp"
	rm -rf "$TERMUX_PKG_SRCDIR/qemu"
	mkdir -p "$TERMUX_PKG_CACHEDIR/qemu-tmp"

	tar -C "$TERMUX_PKG_CACHEDIR/qemu-tmp" --strip-component=1 \
		-xf "$_path" --exclude "roms/*"

	mv -f "$TERMUX_PKG_CACHEDIR/qemu-tmp" "$TERMUX_PKG_SRCDIR/qemu"
	cd "$TERMUX_PKG_SRCDIR/qemu"
	find "$PKG_SCRIPTDIR/qemu" -type f -name '*.patch' -print0 | sort -z | xargs -t -0 -n 1 patch -p1 -i
	#cp -rf "$TERMUX_PKG_SRCDIR/qemu" "$TERMUX_PKG_SRCDIR/qemu-orig"
	#patch -p1 < "$PKG_SCRIPTDIR/current_patch"
	cd $1
}

_setup_fex(){
	local _url="https://github.com/AndreRH/FEX/archive/68033cf25e0ded85a2e21fd696dc305bdc458ca7.zip"
	local _path="fex-2308.zip"
	termux_download "$_url" "$_path" "9b7435729bd2ff9ce4636a924dad25e33a848e4cd4cc0aa89dcb803737b41189"

	rm -rf "$TERMUX_PKG_CACHEDIR/fex-tmp"
	rm -rf "$TERMUX_PKG_SRCDIR/fex"
	mkdir -p "$TERMUX_PKG_CACHEDIR/fex-tmp"

	unzip "$_path" -d "$TERMUX_PKG_CACHEDIR/fex-tmp"

	mv -f "$TERMUX_PKG_CACHEDIR/fex-tmp" "$TERMUX_PKG_SRCDIR/fex"
	cd "$TERMUX_PKG_SRCDIR/fex"
	find "$PKG_SCRIPTDIR/fex" -type f -name '*.patch' -print0 | sort -z | xargs -t -0 -n 1 patch -p1 -i
	cd $1
}

termux_step_post_get_source() {
	_download_commits $TERMUX_PKG_CACHEDIR $PWD
	_apply_commits $TERMUX_PKG_CACHEDIR $PWD
	_setup_qemu $PWD
}

termux_step_host_build() {

	# Make host wine-tools
	"$TERMUX_PKG_SRCDIR/configure" ${TERMUX_PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS}

	make -j "$TERMUX_MAKE_PROCESSES" tools/all tools/sfnt2fon/all tools/widl/all tools/winebuild/all \
		tools/winedump/all tools/winegcc/all tools/wmc/all \
		tools/wrc/all nls/all
}

termux_step_pre_configure() {
	#_setup_qemu $PWD
	_setup_fex $PWD

	# Fix dlltool & windres
	ln -sf "$(which llvm-ar)" "$(dirname "$(which llvm-ar)")/llvm-dlltool"
	ln -sf "$(which llvm-rc)" "$(dirname "$(which llvm-rc)")/llvm-windres"

	echo "wine config started! $PWD"

	# Fix overoptimization
	CFLAGS="${CFLAGS/-Oz/} -v"
	CXXFLAGS="${CFLAGS/-Oz/} -v"

	# Enable win64 on 64-bit arches.
	if [ "$TERMUX_ARCH_BITS" = 64 ]; then
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --enable-win64"
	fi

	#cd $TERMUX_PKG_SRCDIR
	#autoreconf -i
}

#termux_step_post_configure(){
#	read -p "Configure done! ..."
#}

_configure_qemu(){
	termux_setup_ninja

	mkdir -p "$TERMUX_PKG_BUILDDIR/qemu"
	cd "$TERMUX_PKG_BUILDDIR/qemu"

	local QUIET_BUILD=
	if [ "$TERMUX_QUIET_BUILD" = true ]; then
		QUIET_BUILD="--enable-silent-rules --silent --quiet"
	fi

	local _saved_CFLAGS=$CFLAGS
	local _saved_CXXFLAGS=$CXXFLAGS
	local _saved_LDFLAGS=$LDFLAGS

	CFLAGS+=" $CPPFLAGS"
	CXXFLAGS+=" $CPPFLAGS"
	LDFLAGS+=" -landroid-shmem -llog"

	if [ "$TERMUX_ARCH" = "i686" ]; then
		LDFLAGS+=" -latomic"
	fi

	"$TERMUX_PKG_SRCDIR/qemu/configure" \
		--prefix="$TERMUX_PREFIX" \
		--cross-prefix="${TERMUX_HOST_PLATFORM}-" \
		--host-cc="gcc" \
		--cc="$CC" \
		--cxx="$CXX" \
		--objcc="$CC" \
		--disable-stack-protector \
		--target-list=i386-linux-user \
		--enable-coroutine-pool \
		--enable-trace-backends=nop \
		--disable-guest-agent \
		--disable-gnutls \
		--disable-nettle \
		--disable-gcrypt \
		--disable-sdl \
		--disable-sdl-image \
		--disable-gtk \
		--disable-vte \
		--disable-curses \
		--disable-iconv \
		--disable-vnc \
		--disable-vnc-sasl \
		--disable-vnc-jpeg \
		--disable-xen \
		--disable-xen-pci-passthrough \
		--disable-virtfs \
		--disable-curl \
		--disable-fdt \
		--disable-kvm \
		--disable-hax \
		--disable-hvf \
		--disable-whpx \
		--disable-libnfs \
		--disable-lzo \
		--disable-snappy \
		--disable-bzip2 \
		--disable-lzfse \
		--disable-seccomp \
		--disable-libssh \
		--disable-bochs \
		--disable-cloop \
		--disable-dmg \
		--disable-parallels \
		--disable-qed \
		--disable-spice \
		--disable-libusb \
		--disable-usb-redir \
		$QUIET_BUILD \
		|| (termux_step_configure_autotools_failure_hook && false)

	CFLAGS=$_saved_CFLAGS
	CXXFLAGS=$_saved_CXXFLAGS
	LDFLAGS=$_saved_LDFLAGS

	make -j $TERMUX_MAKE_PROCESSES
	read -p "build done!.."
}

_configure_fex() {
	termux_setup_cmake

	mkdir -p "$TERMUX_PKG_BUILDDIR/fex"
	cd "$TERMUX_PKG_BUILDDIR/fex"

	cmake \
		-DCMAKE_BUILD_TYPE=Release \
		-DENABLE_LTO=True \
		-DENABLE_LLD=True \
		-DBUILD_TESTS=False \
		-DENABLE_ASSERTIONS=False \
		-DENABLE_TERMUX_BUILD=True \
		"$TERMUX_PKG_SRCDIR/fex"
}

termux_step_configure() {
	#_configure_qemu
	_configure_fex

	cd "$TERMUX_PKG_BUILDDIR"
	#_setup_llvm_mingw_toolchain
	termux_step_configure_autotools
}

termux_step_make() {
	local QUIET_BUILD=
	if [ "$TERMUX_QUIET_BUILD" = true ]; then
		QUIET_BUILD="-s"
	fi

	#cd "$TERMUX_PKG_BUILDDIR/qemu"
	#make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD

	cd "$TERMUX_PKG_BUILDDIR/fex"
	make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD FEXCore_shared

	if [ -z "$TERMUX_PKG_EXTRA_MAKE_ARGS" ]; then
		make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD
	else
		make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD ${TERMUX_PKG_EXTRA_MAKE_ARGS}
	fi
}

termux_step_make_install() {
	make -j "$TERMUX_MAKE_PROCESSES" install-lib
	mkdir -p "$TERMUX_PREFIX/opt/hangover/lib"
	cp -f qemu/libqemu-i386.so "$TERMUX_PREFIX/opt/hangover/lib"
	cp -f fex/External/FEXCore/Source/libFEXCore.so "$TERMUX_PREFIX/opt/hangover/lib"
}