TERMUX_PKG_HOMEPAGE=https://github.com/AndreRH/hangover
TERMUX_PKG_DESCRIPTION="A compatibility layer for running Windows programs"
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_LICENSE_FILE="\
LICENSE
LICENSE.OLD
COPYING.LIB"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=8.3
TERMUX_PKG_SRCURL=https://dl.winehq.org/wine/source/8.x/wine-$TERMUX_PKG_VERSION.tar.xz
TERMUX_PKG_SHA256=410269000292c3bfadd2561fdde06d9bcb2bc958b49b03e963f14177a27631f0
TERMUX_PKG_DEPENDS="freetype, xwayland, cups, libdrm, libgmp, openldap, sdl2"
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

HANGOVER_COMMITS=(82ba597dd51df7492b8660751ce44d180a4c6c0e 8cea43858807ee327d0207633f53423c0f2ff85a 6e4bad080e609d6a67b5d56c53595136b738ce72 3dc78463cb5a162503fca680c076e17cbd951767 f01cfef6c37e5e2750f7525c75cee3aaa0c92559 0f799e0791d6cdd1502f9734a8a677339e3fcef9 e59cf11af767ad462d3727e72fb3f94d57803dd7 ec6362c6096e5a38879926c625d94559a783c7dc 7c5e0292d6c1bc55e76cb2ab7f9ed48dac8c438f 024decb450d080f165f100e3f9a5aeaa21f77e7a 910d34d43687d3fe88c036f0aac758febba8d264 d3ae82a6a35284694f410d448ce4cf056d6b1210 3f85d5db1c828130a43f79f2085db995a2a9b1e2 c69e054db64c2a305872f5bbef6118b19e3f0cc3 e2db337895325a064b7a5ba7bdec7c657763c5ba 4490a1d37b05eeb2fe57c07a21e2b3f5239f161a 983ce3010a7a1f88221cca9d1d8adde89496b083 5773c018e341dbe1d76d776029bac8d3ca4e354c 8cd8787ab3237ba4da88904015485abca2627eeb d3ef45b791be9a680e08062df2acde93092dc65d 983b9a803e2d62b26c1224ba235f3e2e8850493a d7632807a6b96de69b54408f8ccf2a20a997c5be 39c8d95fb61de9f463353fcbaffc0adadb4a0add f019c96b1e1124fd3686d9d7af0ec8f33bcebd92 86d0c5964c8ef7d8d1b084cf808f1dbb1f654cae 47e0962ffa20151cc0be1874c7919c1250af631b 2205ba5f02698ca08f9e447e3a6b61e50a7fde73 cf65b19290602992492de8d08b8a1afcde4ca330 4dc72cbfdaee0edbc78a45f3f3c1c52d90a5b22c aee404a566559fdf60477f6d17f331bf75b944e4 7e52e2b943941988b3f48a8c8ce2e3f1fda7bc73)
_download_commits() {
	cd $1
	local num_jobs="\j"
	local num_procs=4 #$(nproc)
	for commitsha in ${HANGOVER_COMMITS[@]}; do
		while (( ${num_jobs@P} >= num_procs )); do
			wait -n
		done
		if [ ! -f "hangover_$commitsha.patch" ]; then
			curl -so "hangover_$commitsha.patch" --retry 5 "https://github.com/AndreRH/wine/commit/$commitsha.patch" &
		fi

		echo "Downloaded commit $commitsha."
	done
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

termux_step_configure() {
	_configure_qemu

	cd "$TERMUX_PKG_BUILDDIR"
	#_setup_llvm_mingw_toolchain
	termux_step_configure_autotools
}

termux_step_make() {
	local QUIET_BUILD=
	if [ "$TERMUX_QUIET_BUILD" = true ]; then
		QUIET_BUILD="-s"
	fi

	if [ -z "$TERMUX_PKG_EXTRA_MAKE_ARGS" ]; then
		make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD
	else
		make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD ${TERMUX_PKG_EXTRA_MAKE_ARGS}
	fi

	cd "$TERMUX_PKG_BUILDDIR/qemu"
	make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD
}

termux_step_make_install() {
	make -j "$TERMUX_MAKE_PROCESSES" install-lib
	mkdir -p "$TERMUX_PREFIX/opt/hangover/lib"
	cp -f qemu/libqemu-i386.so "$TERMUX_PREFIX/opt/hangover/lib"
}