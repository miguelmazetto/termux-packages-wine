TERMUX_PKG_HOMEPAGE=http://www.gnu.org/software/libmicrohttpd/
TERMUX_PKG_DESCRIPTION="A small C library that is supposed to make it easy to run an HTTP server as part of another application"
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.9.76
TERMUX_PKG_SRCURL=https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=f0b1547b5a42a6c0f724e8e1c1cb5ce9c4c35fb495e7d780b9930d35011ceb4c
TERMUX_PKG_DEPENDS="libgnutls"
TERMUX_PKG_BREAKS="libmicrohttpd-dev"
TERMUX_PKG_REPLACES="libmicrohttpd-dev"

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-examples
--enable-curl
--enable-https
--enable-largefile
--enable-messages"
