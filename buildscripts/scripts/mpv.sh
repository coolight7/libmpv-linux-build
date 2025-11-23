#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

build=_build$cpu_suffix

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$cpu_suffix
	exit 0
else
	exit 255
fi

unset CC CXX # meson wants these unset

# 清理标准库依赖
sed -i '/^Libs/ s|-lstdc++| |' $prefix_dir/lib/pkgconfig/*.pc
sed -i '/^Libs/ s|-lc++_static| |' $prefix_dir/lib/pkgconfig/*.pc
sed -i '/^Libs/ s|-lc++abi| |' $prefix_dir/lib/pkgconfig/*.pc
sed -i '/^Libs/ s|-lc++_shared| |' $prefix_dir/lib/pkgconfig/*.pc
sed -i '/^Libs/ s|-lc++| |' $prefix_dir/lib/pkgconfig/*.pc

# 可用于限制导出的符号
# CFLAGS、CXXFLAGS 中添加  -fvisibility=hidden
# -Wl,--undefined-version,--version-script=$mpv_EXPORT_IDS
mpv_EXPORT_IDS=$build_home_dir/buildscripts/mpv-export.lds

export PKG_CONFIG_SYSROOT_DIR="$prefix_dir"
export PKG_CONFIG_LIBDIR="$prefix_dir/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/local/share/pkgconfig:/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig"

[ -f /home/coolight/program/media/libmpv-linux-build/buildscripts/prefix/x86_64/usr/local/share/wayland-protocols ] && ln -s /usr/local/share/wayland-protocols /home/coolight/program/media/libmpv-linux-build/buildscripts/prefix/x86_64/usr/local/share/wayland-protocols

# c++std: libjxl、shaderc
# 由 mediaxx 静态链接标准库并导出符号，libmpv 动态链接使用
LDFLAGS="$LDFLAGS -L$prefix_dir/lib/ $default_ld_cxx_stdlib -lm" meson setup $build \
	--cross-file "$prefix_dir/crossfile.txt" \
	--default-library static \
    -Dbuildtype=release \
    -Db_lto=true \
	-Db_lto_mode=default \
	-Db_ndebug=true \
	-Dc_args="$CFLAGS -I$prefix_dir/include -I/usr/include/pipewire-0.3/ -I/usr/include/spa-0.2/" \
	-Dcpp_args="$CXXFLAGS -I$prefix_dir/include -I/usr/include/pipewire-0.3/ -I/usr/include/spa-0.2/" \
	-Ddebug=false \
	-Doptimization=3 \
	-Dlibmpv=true \
 	-Dcplayer=false \
	-Dgpl=true \
    -Dbuild-date=false \
	\
	-Dhtml-build=disabled \
	-Dmanpage-build=disabled \
	-Dpdf-build=disabled \
	\
	-Dcplugins=disabled \
	-Dlua=disabled \
	-Djavascript=disabled \
	\
	-Dlibbluray=disabled \
	-Ddvdnav=disabled \
	-Dvapoursynth=disabled \
	-Duchardet=disabled \
	\
	-Diconv=enabled \
	-Dlibarchive=enabled \
	-Drubberband=enabled \
	-Dlcms2=enabled \
	\
	-Dalsa=enabled \
	-Dpipewire=enabled \
	-Dpulse=enabled \
	-Dsdl2-audio=disabled \
    -Dopensles=disabled \
	\
	-Dx11=enabled \
	-Dwayland=enabled \
	-Degl=enabled \
	-Dplain-gl=enabled \
	-Dgl=enabled \
	-Dvaapi-drm=disabled \
	-Dvulkan=disabled \
	-Dsdl2-video=disabled \
	-Dcaca=disabled \
	-Dsixel=disabled \
	\
	-Dcuda-hwaccel=disabled \
	-Dcuda-interop=disabled \


"${MY_NINJA_EXE_DIR}/ninja" -C $build -j$cores
DESTDIR="$prefix_dir" "${MY_NINJA_EXE_DIR}/ninja" -C $build install

