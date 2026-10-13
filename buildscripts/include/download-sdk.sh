#!/bin/bash -e

. ./include/depinfo.sh

. ./include/path.sh # load $os var

[ -z "$TRAVIS" ] && TRAVIS=0 # skip steps not required for CI?
[ -z "$WGET" ] && WGET=wget # possibility of calling wget differently

if [ $TRAVIS -eq 0 ]; then
	hash yum &>/dev/null && {
		yum install autoconf pkgconfig libtool ninja-build unzip \
		python3-pip python3-setuptools unzip wget;
		pip3 install meson; }
	apt-get -v &>/dev/null && {
		apt-get update;
		apt-get install -y autoconf pkg-config libtool ninja-build nasm unzip po4a libgtest-dev autopoint gperf gettext \
		python3-pip python3-setuptools unzip;
		pip3 install meson; }
fi

# ffmpeg 9.x 的 x86 汇编用到较新的宏写法，nasm 2.14 会在编译汇编文件时报
# "error: (ALLOC_STACK:4) expecting `)`"，因此要求 nasm >= 2.15。
# ubuntu 20.04 仓库里的 nasm 是 2.14，版本不够时从源码装一个到 /usr/local。
nasm_version=$(nasm -v 2>/dev/null | sed -n 's/^NASM version \([0-9][0-9.]*\).*/\1/p')
if [ -z "$nasm_version" ] || [ "$(printf '%s\n%s\n' "$nasm_version" "$nasm_min" | sort -V | head -n1)" != "$nasm_min" ]; then
	echo "nasm ${nasm_version:-未安装} 版本过低，编译安装 nasm $nasm_fullver"
	$WGET "https://www.nasm.us/pub/nasm/releasebuilds/$nasm_fullver/nasm-$nasm_fullver.tar.xz"
	tar -xf "nasm-$nasm_fullver.tar.xz"
	(cd "nasm-$nasm_fullver" && ./configure --prefix=/usr/local && make -j$cores && make install)
	rm -rf "nasm-$nasm_fullver" "nasm-$nasm_fullver.tar.xz"
	hash -r
	echo "nasm 版本: $(nasm -v)"
fi

os_ndk="linux"

# gas-preprocessor
mkdir -p bin
$WGET "https://github.com/FFmpeg/gas-preprocessor/raw/master/gas-preprocessor.pl" \
	-O bin/gas-preprocessor.pl
chmod +x bin/gas-preprocessor.pl

cd ..
