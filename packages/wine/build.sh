TERMUX_PKG_HOMEPAGE=https://www.winehq.org/
TERMUX_PKG_DESCRIPTION="A compatibility layer for running Windows programs"
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_LICENSE_FILE="\
LICENSE
LICENSE.OLD
COPYING.LIB"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=7.0.1
TERMUX_PKG_SRCURL=https://dl.winehq.org/wine/source/${TERMUX_PKG_VERSION:0:3}/wine-$TERMUX_PKG_VERSION.tar.xz
TERMUX_PKG_SHA256=807caa78121b16250f240d2828a07ca4e3c609739e5524ef0f4cf89ae49a816c
TERMUX_PKG_DEPENDS="freetype, mesa-dev, xwayland, cups, libdrm, libgmp, openldap, sdl2"
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS=" \
 -C \
 	enable_wineandroid_drv=no \
 	--enable-win64 --without-alsa --without-capi --without-coreaudio --without-cups --without-dbus \
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

termux_step_host_build() {

	# Make host wine-tools
	"$TERMUX_PKG_SRCDIR/configure" ${TERMUX_PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS}

	make -j "$TERMUX_MAKE_PROCESSES" tools/all tools/sfnt2fon/all tools/widl/all tools/winebuild/all \
		tools/winedump/all tools/winegcc/all tools/wmc/all \
		tools/wrc/all nls/all
}

termux_step_pre_configure() {

	# Fix overoptimization
	CFLAGS="${CFLAGS/-Oz/}"
	CXXFLAGS="${CFLAGS/-Oz/}"

	# Fix dlltool & windres
	ln -sf "$(which llvm-ar)" "$(dirname "$(which llvm-ar)")/llvm-dlltool"
	ln -sf "$(which llvm-rc)" "$(dirname "$(which llvm-rc)")/llvm-windres"

	# Enable win64 on 64-bit arches.
	if [ "$TERMUX_ARCH_BITS" = 64 ]; then
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --enable-win64"
	fi
}

termux_step_make_install() {
	make -j "$TERMUX_MAKE_PROCESSES" install-lib
}