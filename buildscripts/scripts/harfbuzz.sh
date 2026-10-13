#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

build=_build$cpu_suffix

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf $build
	exit 0
else
	exit 255
fi

unset CC CXX # meson wants these unset

# utilities 会编译 hb-view/hb-shape 等命令行工具，这些工具要链接 freetype 等库，
# 而 freetype 又依赖 harfbuzz，形成先有鸡还是先有蛋的问题，因此只编译库本身
meson setup $build --cross-file "$prefix_dir/crossfile.txt" \
	-Dtests=disabled -Ddocs=disabled \
	-Dicu=disabled \
	-Dbenchmark=disabled \
	-Dutilities=disabled \
	-Dgpu_demo=disabled \
	-Dintrospection=disabled \

"${MY_NINJA_EXE_DIR}/ninja" -C $build -j$cores
DESTDIR="$prefix_dir" "${MY_NINJA_EXE_DIR}/ninja" -C $build install
