#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

os=linux
export os

[ -z "$cores" ] && cores=$(grep -c ^processor /proc/cpuinfo)
cores=${cores:-4}

# configure pkg-config paths if inside buildscripts
# 搜索重定向根目录，因此 库写入 .pc 文件时路径应该保持原本的 /lib 一类的默认目录，不写入实际路径
# 而指定 install 目录安装到正确的路径
if [ -n "$ndk_triple" ]; then
	export PKG_CONFIG_SYSROOT_DIR="$prefix_dir"
	export PKG_CONFIG_LIBDIR="$PKG_CONFIG_SYSROOT_DIR/lib/pkgconfig"
	unset PKG_CONFIG_PATH
fi

export MY_CMAKE_EXE_DIR=/usr/bin/
export MY_NINJA_EXE_DIR=/usr/bin/

export PATH="$MY_CMAKE_EXE_DIR:$PATH"