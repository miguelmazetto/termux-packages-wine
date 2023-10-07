TERMUX_PKG_HOMEPAGE=https://github.com/pyca/cryptography
TERMUX_PKG_DESCRIPTION="Provides cryptographic recipes and primitives to Python developers"
# Licenses: Apache-2.0, BSD 3-Clause, PSFL
TERMUX_PKG_LICENSE="custom"
TERMUX_PKG_LICENSE_FILE="LICENSE, LICENSE.APACHE, LICENSE.BSD, LICENSE.PSF"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="40.0.1"
TERMUX_PKG_SRCURL=https://github.com/pyca/cryptography/archive/refs/tags/${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=1be6b818f81d38175fa8a1432c1c5337af6c3653f2912dd85fdfdc5cda7674e4
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_ENABLE_CLANG16_PORTING=false
TERMUX_PKG_DEPENDS="openssl, python, python-pip"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, cffi, setuptools-rust"
TERMUX_PKG_PYTHON_TARGET_DEPS="'cffi>=1.12'"

termux_step_post_get_source() {
	echo "Applying openssl-libs.diff"
	sed "s%@PYTHON_VERSION@%$TERMUX_PYTHON_VERSION%g" \
		$TERMUX_PKG_BUILDER_DIR/openssl-libs.diff | patch --silent -p1
}

termux_step_configure() {
	termux_setup_rust
	export CARGO_BUILD_TARGET=${CARGO_TARGET_NAME}
        export PYO3_CROSS_LIB_DIR=$TERMUX_PREFIX/lib
}

termux_step_create_debscripts() {
	cat <<- EOF > ./postinst
	#!$TERMUX_PREFIX/bin/sh
	echo "Installing dependencies through pip..."
	pip3 install $TERMUX_PKG_PYTHON_TARGET_DEPS
	EOF
}
