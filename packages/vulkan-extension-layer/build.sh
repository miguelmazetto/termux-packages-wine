TERMUX_PKG_HOMEPAGE=https://github.com/KhronosGroup/Vulkan-ExtensionLayer
TERMUX_PKG_DESCRIPTION="Vulkan Extension Layer"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
# This package and vulkan-headers should be updated at same time. Otherwise, they do not compile successfully.
TERMUX_PKG_VERSION="1.3.261"
TERMUX_PKG_SRCURL=https://github.com/KhronosGroup/Vulkan-ExtensionLayer/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=970944aebdc8cabcfc381ea722e67576e243bc3cde7ec71e6f2dd9e026d50b2a
TERMUX_PKG_DEPENDS="libc++, vulkan-loader"
TERMUX_PKG_BUILD_DEPENDS="vulkan-headers (=${TERMUX_PKG_VERSION}), vulkan-loader-generic (=${TERMUX_PKG_VERSION})"
TERMUX_PKG_ANTI_BUILD_DEPENDS="vulkan-loader"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DBUILD_TESTS=OFF
-DVULKAN_HEADERS_INSTALL_DIR=${TERMUX_PREFIX}
"
