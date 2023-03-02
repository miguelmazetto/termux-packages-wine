TERMUX_PKG_HOMEPAGE=https://github.com/AndreRH/hangover
TERMUX_PKG_DESCRIPTION="A compatibility layer for running Windows programs"
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_LICENSE_FILE="\
LICENSE
LICENSE.OLD
COPYING.LIB"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=8.1
TERMUX_PKG_SRCURL=https://dl.winehq.org/wine/source/8.x/wine-$TERMUX_PKG_VERSION.tar.xz
TERMUX_PKG_SHA256=4120ee6b3f294d97aaf2c73034cf1c2cbf13a195c94c5c74a646a81f92412598
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

HANGOVER_COMMITS=(f3e8f2619417d656d52fa9b17d19477a0dc6560b 1f266146841f10872f7a6c7de72ca118c7c67af2 774f067f2c18c9392dce4a0a14213d363a7ec9ec 02678a091c3a6ed472a8e6f5231497e37d4778c9 934ed1fc77a22c67f23b93ad169e903d93daabfe 74067c7390fa52386d0e1e9588426f2747e56f5a 5dd1e081346079e30639b45090d2fae43a513791 572aedf0201dcf8982a58cd046974c33b5651d4d 3b1d83b06239a42d644091e6da94c92292e9a965 1c770764c0c1e7035937bbfb053ec339564dcb8a 2cf93d3aff56b87a850d194d31606bbe5af25919 f54994ca134380e50bfea90e0cbf96f40894ecd2 cad9e71d4dcbe07409aad3ec5fdde78872e39187 f637cedec40baba7a1b631b5bdaf022c27fc99d4 268edbf9f5b34bf40336cb4675abce818b8c2bf4 ffb3b8770ea5a1616a95dec0978af973f2180319 0341f707004a191780aa6424481e9cb24d6c98cb b77aa1168f9246b709f131dcaac8f3db8528e6ba 973349985d8ff9d306e1d343ca195acbec678814 c156a906e08e2dbd87f7f0cb34f08f8a41f9a1d0 6ade0d181d45e90cc331297dd799a5f75a6159a5 1a95c9eb4c869fd82563e4d46d2d540dabf2ef27 ab22e3bbbaff276a343a11132ad7a417a87b67b6 566107dce4a586385504166480fa632ff093a34d c428c2490ded7229a0d013acf01b7058be079474 fd96c107f52c81e2a9185e5ef11e90ab37f4fc30 78678e064b20411e62b5d53f12a9620dc3172563 98cfd525e1f6f2c89bd097d66f38359c73fec425 1e8ab1acaacf3af006cea0550cf213c1dea2d49f 13341e1d64cb02efd6f9f668c809dd2f160fa29c)
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

	#local _extract_tar="${_path%.*}"
	#if [ ! -f "$_extract_tar" ]; then
	#	xz -dk "$_path"
	#fi
	#read -p "here.."

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
}

termux_step_configure() {
	_configure_qemu

	cd "$TERMUX_PKG_BUILDDIR"
	_setup_llvm_mingw_toolchain
	termux_step_configure_autotools
}

termux_step_make() {
	local QUIET_BUILD=
	if [ "$TERMUX_QUIET_BUILD" = true ]; then
		QUIET_BUILD="-s"
	fi

	#cd "$TERMUX_PKG_BUILDDIR/qemu"
	#make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD

	cd "$TERMUX_PKG_BUILDDIR"

	make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD dlls/xtajit/all

	#if [ -z "$TERMUX_PKG_EXTRA_MAKE_ARGS" ]; then
	#	make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD
	#else
	#	make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD ${TERMUX_PKG_EXTRA_MAKE_ARGS}
	#fi

	read -p "done.."
}

termux_step_make_install() {
	make -j "$TERMUX_MAKE_PROCESSES" install-lib
	mkdir -p "$TERMUX_PREFIX/opt/hangover/lib"
	cp -f qemu/libqemu-i386.so "$TERMUX_PREFIX/opt/hangover/lib"
}