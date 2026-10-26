#!/bin/bash
# --------------------------------------------------
# 编译入口脚本：更新 mediaxx 源码 -> 编译依赖与目标库 -> 整理输出目录
# 注意：脚本里使用了 pushd/popd 等 bash 语法，必须用 bash 执行

export build_home_dir="$PWD/../"

# TODO: coolight --- temp
# - 第一次编译或需要重新下载依赖时，解注释下面两行并执行 ./download.sh ./patch.sh
# if [ ! -f "deps" ]; then
#   rm -rf deps
# fi
# if [ ! -f "prefix" ]; then
#   rm -rf prefix
# fi

# ./download.sh
# ./patch.sh

# --------------------------------------------------

if [ ! -f "scripts/ffmpeg" ]; then
  rm scripts/ffmpeg.sh
fi
cp flavors/default.sh scripts/ffmpeg.sh

# --------------------------------------------------

cd deps/mpv && git switch extend && git pull && git submodule update --init && cd -
cd deps/mediaxx && git pull && git submodule update --init && cd -

# coolight --- temp
# 根据需要选择编译前清理的范围
# ./build.sh
# ./build.sh --prebuild-rm-mediaxx              # 只重新编译 mediaxx
./build.sh --prebuild-rm-ff-mpv                 # 重新编译 ffmpeg/libmpv/mediaxx

if [ $? -ne 0 ]; then
  exit 1
fi

# --------------------------------------------------
# 本项目只编译 x86_64，且 ffmpeg/libmpv 均为静态库，
# 最终只输出一个动态库 libmediaxx.so
arch=x86_64

stripLib() {
  for f in "$@"; do
    if [ -f "$f" ]; then
      strip --strip-all "$f"
    fi
  done
}

stripLib prefix/$arch/lib/libmediaxx.so

# --------------------------------------------------

rm -rf $build_home_dir/output/
mkdir -p $build_home_dir/output/

copyLib() {
  if [[ $1 != "x86_64" && $1 != "x86" && $1 != "arm64-v8a" && $1 != "armeabi-v7a" ]]; then
    echo "call copyLib 参数 {cpu} 不正确: $1"
    exit 1
  fi

  mkdir -p $build_home_dir/output/$1/
  cp prefix/$1/lib/libmediaxx.so               $build_home_dir/output/$1/

  #  for lib in $(ldd libmediaxx.so | grep -oP '(?<==>\s)\S+'); do echo "$lib"; done
  # 通过在 新装的 ubuntu20 系统上 ldd libmediaxx.so 得到缺失这些库：
  # 用 || true 允许某些库在当前系统上不存在，避免中断打包
  for lib in libva.so.2 libva-drm.so.2 libva-x11.so.2 libva-wayland.so.2 \
             libvdpau.so.1 libpipewire-0.3.so.0 libXpresent.so.1; do
    cp /lib/x86_64-linux-gnu/$lib $build_home_dir/output/$1/ 2>/dev/null || true
  done

  cp /usr/local/lib64/libstdc++.so.6           $build_home_dir/output/$1/
  cp /usr/local/lib64/libgcc_s.so.1            $build_home_dir/output/$1/

  cp $build_home_dir/help/*                    $build_home_dir/output/$1/

  # 符号对比脚本需要 libmpv 的符号，而本项目的 libmpv 是静态库，
  # 因此临时复制过来供脚本读取，生成符号表后再删掉，不作为交付文件
  libmpv_file=
  for candidate in libmpv.a libmpv.so; do
    if [ -f "prefix/$1/lib/$candidate" ]; then
      cp "prefix/$1/lib/$candidate" $build_home_dir/output/$1/
      libmpv_file=$candidate
      break
    fi
  done

	pushd $build_home_dir/output/$1/
  ./create_comm_syms.sh
  [ -n "$libmpv_file" ] && rm -f "$libmpv_file"

  # 检查 mediaxx 的 Dart 侧预加载符号列表（lib/ffi/system_library_preload.dart）是否过期：
  # 依赖升级后 libmediaxx.so 用到新符号时列表需要重新生成，这里只提示，不影响编译结果
  sh ./check_preload_syms.sh \
    "$build_home_dir/buildscripts/deps/mediaxx/lib/ffi/system_library_preload.dart"
  popd
}

copyLib $arch

stripLib $build_home_dir/output/$arch/libstdc++.so.6 \
         $build_home_dir/output/$arch/libgcc_s.so.1

# 本项目使用 libstdc++，没有 libc++ 符号表，因此只汇总 libmpv 相关的符号表
cat $build_home_dir/output/$arch/comm_syms.txt \
    | sort | uniq > $build_home_dir/output/comm_syms.txt
cat $build_home_dir/output/$arch/libmpv_undef_syms.txt \
    | sort | uniq > $build_home_dir/output/libmpv_undef_syms.txt
cat $build_home_dir/output/$arch/libmpv_def_syms.txt \
    | sort | uniq > $build_home_dir/output/libmpv_def_syms.txt

echo "current dir: vvvvvvvvvvvvvvvvvvvv"
pwd

echo "target dir: vvvvvvvvvvvvvvvvvvvv"
echo $build_home_dir/output/
