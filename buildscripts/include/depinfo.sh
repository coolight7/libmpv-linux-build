#!/bin/bash -e

## Dependency versions

v_cmake=3.31.6

# 编译 ffmpeg 的 x86 汇编需要的 nasm 最低版本，低于它会在编译汇编文件时报错
nasm_min=2.15
nasm_fullver=2.16.03

# 各依赖库版本与 libmpv-android-video-build 保持一致，便于两端共用同一套 ffmpeg/mediaxx 代码
v_libass=0.17.5
v_libunibreak=7.0
v_harfbuzz=14.4.0
v_fribidi=1.0.16
v_freetype=2-14-3
v_mbedtls=3.6.7
v_shaderc=2025.3
v_dav1d=1.5.4
v_libxml2=2.15.4
v_libplacebo=7.360.1
# https://ffmpeg.org/download.html
v_ffmpeg=9.0.1
# mpv 使用 fork 的 extend 分支，该分支在官方 0.41.0 基础上增加了音频分析相关的接口
# 下面的版本号仅表示 fork 分支基于的官方版本，实际编译的是 fork 分支
v_mpv=0.41.0
v_mpv_branch=extend
v_libogg=1.3.6
v_libvpx=1.14


## Dependency tree
# I would've used a dict but putting arrays in a dict is not a thing

dep_mbedtls=()
dep_dav1d=()
dep_harfbuzz=()
dep_fribidi=()
dep_libunibreak=()
dep_zstd=()
dep_zlib=()
dep_brotli=()
dep_shaderc=()
dep_opus_dnn=()
dep_libbs2b=()
dep_libsoxr=()
dep_expat=()
dep_bzip2=()
dep_lzo=()
dep_xz=()
dep_libsamplerate=()
dep_libpng=()
dep_libjpeg=()
dep_highway=()
dep_uchardet=()
dep_libzimg=()
dep_spirv_cross=()
dep_libiconv=()
dep_libmysofa=(zlib)
dep_libvorbis=(libogg)
dep_harfbuzz=(libpng)
dep_rubberband=(libsamplerate)
dep_lcms2=(libjpeg zlib)
dep_libwebp=(zlib libpng libjpeg)
dep_openssl=(zlib zstd brotli)
dep_libjxl=(lcms2 highway libpng brotli)
dep_freetype=(zlib harfbuzz brotli)
dep_fontconfig=(freetype libiconv expat)
dep_libxml2=(zlib libiconv)
dep_libarchive=(libxml2 openssl expat bzip2 lzo xz)
dep_libass=(freetype fribidi libunibreak libiconv harfbuzz)
dep_libplacebo=(shaderc lcms2 spirv_cross)
dep_opus=(opus_dnn)

# 依赖项的依赖已有，则不需要重复依赖编译
dep_ffmpeg=(libarchive uchardet libass mbedtls dav1d libxml2 libplacebo libvorbis libvpx libbs2b opus libsoxr openssl bzip2 rubberband libmysofa libwebp libjxl libzimg)
dep_mpv=(ffmpeg)
dep_mediaxx=(mpv)
