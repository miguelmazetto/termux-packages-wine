TERMUX_PKG_HOMEPAGE=https://gitlab.gnome.org/GNOME/vte/
TERMUX_PKG_DESCRIPTION="Virtual Terminal library"
TERMUX_PKG_LICENSE="LGPL-3.0, GPL-3.0, MIT"
TERMUX_PKG_LICENSE_FILE="COPYING.GPL3, COPYING.LGPL3, COPYING.XTERM"
TERMUX_PKG_MAINTAINER="@termux"
_MAJOR_VERSION=0.72
_VERSION=${_MAJOR_VERSION}.1
TERMUX_PKG_VERSION=2:${_VERSION}
TERMUX_PKG_SRCURL=https://gitlab.gnome.org/GNOME/vte/-/archive/${_VERSION}/vte-${_VERSION}.tar.bz2
#TERMUX_PKG_SRCURL=https://ftp.gnome.org/pub/GNOME/sources/vte/${_MAJOR_VERSION}/vte-${_VERSION}.tar.xz
TERMUX_PKG_SHA256=2b081649ce5752004fcb339dfda6e592c9a95c7fe26f723a8f3a8bdfffaa1768
TERMUX_PKG_DEPENDS="atk, fribidi, gdk-pixbuf, gtk3, libc++, libcairo, libgnutls, libicu, pango, pcre2, zlib"
TERMUX_PKG_BUILD_DEPENDS="g-ir-scanner"
TERMUX_PKG_RM_AFTER_INSTALL="lib/locale"
TERMUX_PKG_DISABLE_GIR=false
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-Dgir=true
-Dvapi=false
"

termux_step_pre_configure() {
	termux_setup_gir

	CPPFLAGS+=" -DLINE_MAX=_POSIX2_LINE_MAX"
}
