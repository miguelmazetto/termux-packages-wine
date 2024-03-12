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
	local _llvm_mingw_version=17
	local _version="20231003"
	local _suffix="ucrt-ubuntu-20.04-x86_64"
	local _url="https://github.com/mstorsjo/llvm-mingw/releases/download/$_version/llvm-mingw-$_version-$_suffix.tar.xz"
	local _path="$TERMUX_PKG_CACHEDIR/$(basename $_url)"
	local _sha256sum=df6b9bcfac48c926aa8f6ccd6179ae7b8eeccd9f5fdf4a2c10b601b6b58e4c83
	termux_download $_url $_path $_sha256sum
	local _extract_path="$TERMUX_PKG_CACHEDIR/llvm-mingw-toolchain-$_llvm_mingw_version"
	if [ ! -d "$_extract_path" ]; then
		mkdir -p "$_extract_path"-tmp
		tar -C "$_extract_path"-tmp --strip-component=1 -xf "$_path"
		mv "$_extract_path"-tmp "$_extract_path"
	fi
	export PATH="$PATH:$_extract_path/bin"
}

HANGOVER_COMMITS=(fc4267d4707e992d8881826bd6f880ea2a37974a bd0f5914b3adb0560ab4638f06e27139aa2f3eb9 dcee4ec9b337ca767123b5463595e1f6ddd27fff 898daa85de866a45da64c12b3873f95c5cb46613 048a2380ddac258b19219d829cfde4532b45d598 565b43e1d245bf77938d02de3f135966275ec531 685e7f37086cc8921d7523be64f2a3efef96d407 dc70302adbabc8fb741bd972eec803f2680cd1a1 c38be59b1cc94cc3dbef30d665091c2b5a830c6d 59bd4b5a752b646bf64320526eb3600b0c845203 a71795548bea02deda03a0d013209ab177fb3d08 5298ee61a7cde7bf4a7e8a568afa65f168f8bcef 30064e95a9dc30418cbcec03ce5921d014ded74c 116db95cf482e4c423cf3ce33d93bd0f125e1001 c67e7e00ca6dc15794b4d6d7298360940ffe058d a86887912cc27c3b8d0914b5cf0af382a8c92cae 831c9a8eebe685b2a5114bba0f7ddfc434a45ad6 c8cdadee22fedb5863c2438a46ae4e2a7af9dffa 8922f604d8107505b076e28f34802d4d2567a22d 588b83f4b34dcec44332372e2393eeb88d0fdf5e f3645912d724f96b158b63f2f8d4ffca71b7f61a a034f3f63325995ba7c21f18cb95cb57eca33541 6f15920d23dc81a570181067648c70ddb3f5dbba 0d722b512a93ec81df40ff316b13ffaefeaff821 da0d00866db4d3fec8dcdbfd5a3f3ed48611d933)
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
		fi
	done
	wait
	cd $2
}

BUILD_WINE=1
BUILD_QEMU=1
BUILD_FEXUNIX=1
BUILD_FEXPE=1

_wineact(){
	if [ ! -z "$BUILD_WINE" ]; then "$@"; fi
}
_qemuact(){
	if [ ! -z "$BUILD_QEMU" ]; then "$@"; fi
}
_unixfexact(){
	if [ ! -z "$BUILD_FEXUNIX" ]; then "$@"; fi
}
_pefexact(){
	if [ ! -z "$BUILD_FEXPE" ]; then "$@"; fi
}
_anyfexact(){
	if [ ! -z "$BUILD_FEXUNIX" ] || [ ! -z "$BUILD_FEXPE" ]; then "$@"; fi
}

_apply_commits() {
	cd $2
	for commitsha in ${HANGOVER_COMMITS[@]}; do
		patch -p1 < "$1/hangover_$commitsha.patch"
	done
}

_setup_qemu(){
	local _url="https://download.qemu.org/qemu-5.2.0.tar.xz"
	local _path="$TERMUX_PKG_CACHEDIR/$(basename $_url)"
	termux_download "$_url" "$_path" \
		cb18d889b628fbe637672b0326789d9b0e3b8027e0445b936537c78549df17bc

	rm -rf "$TERMUX_PKG_CACHEDIR/qemu-tmp"
	rm -rf "$TERMUX_PKG_SRCDIR/qemu"
	mkdir -p "$TERMUX_PKG_CACHEDIR/qemu-tmp"

	tar -C "$TERMUX_PKG_CACHEDIR/qemu-tmp" \
		--strip-component=1 -xf "$_path" --exclude "roms/*"

	mv -f "$TERMUX_PKG_CACHEDIR/qemu-tmp" "$TERMUX_PKG_SRCDIR/qemu"
	cd "$TERMUX_PKG_SRCDIR/qemu"
	find "$PKG_SCRIPTDIR/qemu" -type f -name '*.patch' -print0 | sort -z | xargs -t -0 -n 1 patch -p1 -i
	cd $1
}

#_setup_fex(){
#	local _commit="ec31f24dcf038e45e1cb168f45862bf26e41aab8"
#	local _url="https://github.com/AndreRH/FEX/archive/$_commit.zip"
#	local _path="$TERMUX_PKG_CACHEDIR/fex-$(basename $_url)"
#	termux_download "$_url" "$_path" \
#		a98886978c5300668f7a5067f5e059f4ba4930b1241cb2cb0f627c6a1a17884b
#
#	rm -rf "$TERMUX_PKG_CACHEDIR/fex-tmp"
#	rm -rf "$TERMUX_PKG_SRCDIR/fex"
#	mkdir -p "$TERMUX_PKG_CACHEDIR/fex-tmp"
#
#	unzip -d "$TERMUX_PKG_CACHEDIR/fex-tmp" "$_path"
#
#	mv -f "$TERMUX_PKG_CACHEDIR/fex-tmp/FEX-$_commit" "$TERMUX_PKG_SRCDIR/fex"
#	#cd "$TERMUX_PKG_SRCDIR/fex"
#	#find "$PKG_SCRIPTDIR/fex" -type f -name '*.patch' -print0 | sort -z | xargs -t -0 -n 1 patch -p1 -i
#	#cd $1
#}

_run_patches(){
	local _prevPath=$PWD
	cd "$1"
	find "$2" -type f -name '*.patch' -print0 | sort -z | xargs -t -0 -n 1 patch -p1 -i
	cd "$_prevPath"
}

_doon() {
	local _prevPath="$PWD"
	cd "$1"
	"${@:2}"
	cd "$_prevPath"
}

_setup_fex(){
	local _commit="ec31f24dcf038e45e1cb168f45862bf26e41aab8"
	local FEXCACHE="$TERMUX_PKG_CACHEDIR/fex"

	if [ -d "$FEXCACHE" ] && \
	   [ -f "$FEXCACHE/commitversion" ]
	then
		if [ $(cat "$FEXCACHE/commitversion") = "$_commit" ]; then
			cd "$FEXCACHE"
			git reset --hard $_commit
			_doon "External/jemalloc" git reset --hard
			cd $1

			_run_patches "$FEXCACHE" "$PKG_SCRIPTDIR/fex"
			cp -rf "$PKG_SCRIPTDIR/fex/include/"* "$FEXCACHE/Source"
			ln -sf "$FEXCACHE" "$TERMUX_PKG_SRCDIR/fex"
			return
		else
			cd "$FEXCACHE"
			git pull
			git reset --hard $_commit
			_doon "External/jemalloc" git reset --hard
			git submodule update --init --recursive --depth=1
			cd $1

			echo "$_commit" > "$FEXCACHE/commitversion"
			_run_patches "$FEXCACHE" "$PKG_SCRIPTDIR/fex"
			cp -rf "$PKG_SCRIPTDIR/fex/include/"* "$FEXCACHE/Source"
			ln -sf "$FEXCACHE" "$TERMUX_PKG_SRCDIR/fex"
			return
		fi
	fi

	#local FEXCACHEDIR="$TERMUX_PKG_CACHEDIR/fex-cache"
	#mkdir -p "$FEXCACHEDIR"
#
	#TERMUX_PKG_CACHEDIR="$FEXCACHEDIR" \
	#TERMUX_PKG_VERSION="$_commit" \
	#TERMUX_PKG_GIT_BRANCH="hangover-8.17" \

	rm -rf "$FEXCACHE"
	rm -rf "$TERMUX_PKG_SRCDIR/fex"

	git clone \
		--single-branch \
		--branch "wow" \
		https://github.com/AndreRH/FEX \
		"$FEXCACHE"

	cd "$FEXCACHE"
	git checkout $_commit
	git submodule update --init --recursive --depth=1
	cd $1

	echo "$_commit" > "$FEXCACHE/commitversion"
	_run_patches "$FEXCACHE" "$PKG_SCRIPTDIR/fex"
	cp -rf "$PKG_SCRIPTDIR/fex/include/"* "$FEXCACHE/Source"
	ln -sf "$FEXCACHE" "$TERMUX_PKG_SRCDIR/fex"

	#mv -f "$TERMUX_PKG_CACHEDIR/fex-tmp" "$TERMUX_PKG_SRCDIR/fex"

#	local _url="https://github.com/AndreRH/FEX/archive/$_commit.zip"
#	local _path="$TERMUX_PKG_CACHEDIR/fex-$(basename $_url)"
#	termux_download "$_url" "$_path" \
#		a98886978c5300668f7a5067f5e059f4ba4930b1241cb2cb0f627c6a1a17884b
#
#	rm -rf "$TERMUX_PKG_CACHEDIR/fex-tmp"
#	rm -rf "$TERMUX_PKG_SRCDIR/fex"
#	mkdir -p "$TERMUX_PKG_CACHEDIR/fex-tmp"
#
#	unzip -d "$TERMUX_PKG_CACHEDIR/fex-tmp" "$_path"
#
#	mv -f "$TERMUX_PKG_CACHEDIR/fex-tmp/FEX-$_commit" "$TERMUX_PKG_SRCDIR/fex"

	#cd "$TERMUX_PKG_SRCDIR/fex"
	#find "$PKG_SCRIPTDIR/fex" -type f -name '*.patch' -print0 | sort -z | xargs -t -0 -n 1 patch -p1 -i
	#cd "$1"
}

termux_step_post_get_source() {
	_download_commits $TERMUX_PKG_CACHEDIR $PWD
	_apply_commits $TERMUX_PKG_CACHEDIR $PWD
}

termux_step_host_build() {

	if [ ! -z "$BUILD_WINE" ]; then
		# Make host wine-tools
		"$TERMUX_PKG_SRCDIR/configure" ${TERMUX_PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS}

		make -j "$TERMUX_MAKE_PROCESSES" tools/all tools/sfnt2fon/all tools/widl/all tools/winebuild/all \
			tools/winedump/all tools/winegcc/all tools/wmc/all \
			tools/wrc/all nls/all
	fi
}

termux_step_pre_configure() {
	_qemuact _setup_qemu $PWD
	_anyfexact _setup_fex $PWD

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

	_setup_llvm_mingw_toolchain

	#cd $TERMUX_PKG_SRCDIR
	#autoreconf -i
}

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

	local _ANDROIDAPI=24
#		--cc="${TERMUX_HOST_PLATFORM}$_ANDROIDAPI-clang" \
#		--cxx="${TERMUX_HOST_PLATFORM}$_ANDROIDAPI-clang++" \
	"$TERMUX_PKG_SRCDIR/qemu/configure" \
		--prefix="$TERMUX_PREFIX" \
		--libdir="$TERMUX_PREFIX/opt/hangover/lib" \
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
		--disable-vnc-png \
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
		--disable-libxml2 \
		--disable-bochs \
		--disable-cloop \
		--disable-dmg \
		--disable-parallels \
		--disable-qed \
		--disable-sheepdog \
		--disable-spice \
		--disable-libusb \
		--disable-usb-redir \
		$QUIET_BUILD \
		|| (termux_step_configure_autotools_failure_hook && false)

	CFLAGS=$_saved_CFLAGS
	CXXFLAGS=$_saved_CXXFLAGS
	LDFLAGS=$_saved_LDFLAGS
}

run_cmake_unix(){
	TERMUX_PKG_SRCDIR=$1 TERMUX_PKG_EXTRA_CONFIGURE_ARGS="${*:3}" \
	TERMUX_CMAKE_BUILD="Unix Makefiles" _doon $2 \
		termux_step_configure_cmake
}

run_autotools_android(){
	TERMUX_PKG_SRCDIR=$1 TERMUX_CMAKE_BUILD=$2 TERMUX_PKG_EXTRA_CONFIGURE_ARGS="${*:4}" \
	TERMUX_PKG_TMPDIR=$TERMUX_PKG_TMPDIR/$3 \
		termux_step_configure_autotools
}

android_cmake() {
	CMAKE_PROC=$TERMUX_ARCH
	test $CMAKE_PROC == "arm" && CMAKE_PROC='armeabi-v7a'
	test $CMAKE_PROC == "aarch64" && CMAKE_PROC='arm64-v8a'
	test $CMAKE_PROC == "i686" && CMAKE_PROC='x86'
	test $CMAKE_PROC == "x86_64" && CMAKE_PROC='x86_64'
	cmake \
		-DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
		-DANDROID_NDK="$NDK" \
		-DCMAKE_ANDROID_NDK="$NDK" \
		-DANDROID_PLATFORM=android-24 \
		-DANDROID_ABI=$CMAKE_PROC \
		-DCMAKE_ANDROID_ARCH_ABI=$CMAKE_PROC \
		-DCMAKE_SYSTEM_NAME=Android \
		-DCMAKE_SYSTEM_VERSION=24 \
		"$@"
}

_configure_fex() {
	termux_setup_cmake
	_setup_llvm_mingw_toolchain

	mkdir -p "$TERMUX_PKG_BUILDDIR/fex-unix"
	mkdir -p "$TERMUX_PKG_BUILDDIR/fex-pe"
	
	#ln -sf "${TERMUX_STANDALONE_TOOLCHAIN}/bin/lld" \
	#	"$TERMUX_PKG_BUILDDIR/fex-unix/bin-tools/ld.gold"

	#PATH="$TERMUX_PKG_BUILDDIR/fex-unix/bin-tools/ld.gold:$PATH" \
	#run_cmake_unix "$TERMUX_PKG_SRCDIR/fex" "$TERMUX_PKG_BUILDDIR/fex-unix" \
	#	-DCMAKE_BUILD_TYPE=RelWithDebInfo -DENABLE_LTO=True -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False \
	#	-DENABLE_JEMALLOC_GLIBC_ALLOC=0 -DENABLE_TERMUX_BUILD=True

	if [ ! -z "$BUILD_FEXUNIX" ]; then
		cd "$TERMUX_PKG_BUILDDIR/fex-unix"
		android_cmake \
			-DCMAKE_BUILD_TYPE=RelWithDebInfo -DENABLE_LTO=True -DBUILD_TESTS=False \
			-DENABLE_ASSERTIONS=False -DENABLE_JEMALLOC_GLIBC_ALLOC=0 \
			-DENABLE_JEMALLOC=False -DBUILD_FEXCONFIG=False \
			"$TERMUX_PKG_SRCDIR/fex"
	fi
	
	if [ ! -z "$BUILD_FEXPE" ]; then
		cd "$TERMUX_PKG_BUILDDIR/fex-pe"
		env -i PATH="$PATH" cmake \
			-DCMAKE_TOOLCHAIN_FILE="$TERMUX_PKG_SRCDIR/fex/toolchain_mingw.cmake" -DENABLE_JEMALLOC=0 \
			-DENABLE_JEMALLOC_GLIBC_ALLOC=0 -DMINGW_TRIPLE=aarch64-w64-mingw32 \
			-DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False \
			-DCMAKE_CXX_FLAGS="-D_LIBCPP_STD_VER=20" \
			"$TERMUX_PKG_SRCDIR/fex"
	fi
}

termux_step_configure() {
	_qemuact _configure_qemu
	_anyfexact _configure_fex

	cd "$TERMUX_PKG_BUILDDIR"
	_wineact termux_step_configure_autotools
}

termux_step_make() {
	local QUIET_BUILD=
	if [ "$TERMUX_QUIET_BUILD" = true ]; then
		QUIET_BUILD="-s"
	fi

	_qemuact cd "$TERMUX_PKG_BUILDDIR/qemu"
	_qemuact make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD libqemu-i386.so

	_unixfexact cd "$TERMUX_PKG_BUILDDIR/fex-unix"
	_unixfexact make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD FEXCore_shared

	_pefexact cd "$TERMUX_PKG_BUILDDIR/fex-pe"
	_pefexact make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD wow64fex

	cd "$TERMUX_PKG_BUILDDIR"
	#_wineact make -j $TERMUX_MAKE_PROCESSES $QUIET_BUILD ${TERMUX_PKG_EXTRA_MAKE_ARGS}
}

termux_step_make_install() {
	mkdir -p \
		"$TERMUX_PREFIX/opt/hangover/lib"
	cd "$TERMUX_PKG_BUILDDIR"

	#_qemuact cd "$TERMUX_PKG_BUILDDIR/qemu"
	#_qemuact make -j install
#
	#_unixfexact cd "$TERMUX_PKG_BUILDDIR/fex-unix"
	#_unixfexact make -j install
#
	#_pefexact cd "$TERMUX_PKG_BUILDDIR/fex-pe"
	#_pefexact make -j install

	_qemuact cp -f \
		"$TERMUX_PKG_BUILDDIR/qemu/libqemu-i386.so" \
		"$TERMUX_PREFIX/opt/hangover/lib"

	_unixfexact cp -f \
		"$TERMUX_PKG_BUILDDIR/fex-unix/FEXCore/Source/libFEXCore.so" \
		"$TERMUX_PREFIX/opt/hangover/lib"

	_pefexact mkdir -p "$TERMUX_PREFIX/lib/wine/aarch64-windows"
	_pefexact cp -f \
		"$TERMUX_PKG_BUILDDIR/fex-pe/Bin/libwow64fex.dll" \
		"$TERMUX_PREFIX/lib/wine/aarch64-windows"

	_wineact make -j $TERMUX_MAKE_PROCESSES install-lib
}