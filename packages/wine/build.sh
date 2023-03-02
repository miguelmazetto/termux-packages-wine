TERMUX_PKG_HOMEPAGE=https://www.winehq.org/
TERMUX_PKG_DESCRIPTION="A compatibility layer for running Windows programs"
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_LICENSE_FILE="\
LICENSE
LICENSE.OLD
COPYING.LIB"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=8.0
TERMUX_PKG_SRCURL=https://dl.winehq.org/wine/source/${TERMUX_PKG_VERSION:0:3}/wine-$TERMUX_PKG_VERSION.tar.xz
TERMUX_PKG_SHA256=0272c20938f8721ae4510afaa8b36037457dd57661e4d664231079b9e91c792e
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

TERMUX_PKG_EXTRA_CONFIGURE_ARGS=" \
 -C \
	enable_wineandroid_drv=no \
	exec_prefix=$TERMUX_PREFIX \
	--with-wine-tools=$TERMUX_PKG_HOSTBUILD_DIR \
	--enable-nls \
	--disable-tests \
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

termux_step_host_build() {

	#_setup_llvm_mingw_toolchain

	# Make host wine-tools
	"$TERMUX_PKG_SRCDIR/configure" ${TERMUX_PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS}

	echo "wine-tools config done!"

	make -j "$TERMUX_MAKE_PROCESSES" tools/all tools/sfnt2fon/all tools/widl/all tools/winebuild/all \
		tools/winedump/all tools/winegcc/all tools/wmc/all \
		tools/wrc/all nls/all

	echo "wine-tools build done!"
}

termux_step_pre_configure() {

	#_setup_llvm_mingw_toolchain

	# Fix dlltool & windres
	ln -sf "$(which llvm-ar)" "$(dirname "$(which llvm-ar)")/llvm-dlltool"
	ln -sf "$(which llvm-rc)" "$(dirname "$(which llvm-rc)")/llvm-windres"
	export DLLTOOL="llvm-dlltool"
	export WINDRES="llvm-windres"

	echo "wine config started! $PWD"

	# Fix overoptimization
	CFLAGS="${CFLAGS/-Oz/} -v"
	CXXFLAGS="${CFLAGS/-Oz/} -v"

	# Enable win64 on 64-bit arches.
	if [ "$TERMUX_ARCH_BITS" = 64 ]; then
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --enable-win64"
	fi

	cd $TERMUX_PKG_SRCDIR
	cp -f ../configure.ac configure.ac
	cp -f ../aclocal.m4 aclocal.m4
	cp -f ../file.c dlls/ntdll/unix/file.c
	cp -f ../env.c dlls/ntdll/unix/env.c
	autoreconf -i
}

termux_step_post_configure(){
	read -p "Configure done! ..."
}

termux_step_make_install() {
	make -j "$TERMUX_MAKE_PROCESSES" install-lib
}