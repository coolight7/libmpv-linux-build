# --------------------------------------------------

export build_home_dir="$PWD/../"

# TODO: coolight --- temp
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

cd deps/mediaxx && git pull && git submodule update --init && cd -

# coolight --- temp
# ./build.sh 
# ./build.sh --prebuild-rm-mediaxx
./build.sh --prebuild-rm-ff-mpv

if [ $? -ne 0 ]; then
  exit -1
fi

stripLib() {
  strip --strip-all prefix/arm64-v8a/lib/$1
  strip --strip-all prefix/armeabi-v7a/lib/$1
  strip --strip-all prefix/x86/lib/$1
  strip --strip-all prefix/x86_64/lib/$1
}

stripLib libmediaxx.so
stripLib libmpv.so
stripLib libavcodec.so
stripLib libavutil.so
stripLib libavfilter.so
stripLib libavformat.so
stripLib libavdevice.so
stripLib libswresample.so
stripLib libswscale.so

# --------------------------------------------------

rm -rf $build_home_dir/output/
mkdir -p $build_home_dir/output/

copyLib() {
  if [[ $1 != "arm64-v8a" && $1 != "armeabi-v7a" && $1 != "x86" && $1 != "x86_64" ]]; then
    echo "call copyLib 参数 {cpu} 不正确: $1"
    exit -1
  fi

  mkdir -p $build_home_dir/output/$1/
  cp prefix/$1/lib/libmediaxx.so               $build_home_dir/output/$1/
  cp prefix/$1/lib/libmpv.so                   $build_home_dir/output/$1/
  cp prefix/$1/lib/libswresample.so            $build_home_dir/output/$1/
  cp prefix/$1/lib/libswscale.so               $build_home_dir/output/$1/
  cp prefix/$1/lib/libavutil.so                $build_home_dir/output/$1/
  cp prefix/$1/lib/libavcodec.so               $build_home_dir/output/$1/
  cp prefix/$1/lib/libavformat.so              $build_home_dir/output/$1/
  cp prefix/$1/lib/libavfilter.so              $build_home_dir/output/$1/
  cp prefix/$1/lib/libavdevice.so              $build_home_dir/output/$1/

  #  for lib in $(ldd libmediaxx.so | grep -oP '(?<==>\s)\S+'); do echo "$lib"; done
  # 通过在 新装的 ubuntu20 系统上 ldd libmediaxx.so 得到缺失这些库：
  cp /lib/x86_64-linux-gnu/libva.so.2           $build_home_dir/output/$1/
  cp /lib/x86_64-linux-gnu/libva-drm.so.2       $build_home_dir/output/$1/
  cp /lib/x86_64-linux-gnu/libva-x11.so.2       $build_home_dir/output/$1/
  cp /lib/x86_64-linux-gnu/libva-wayland.so.2   $build_home_dir/output/$1/
  cp /lib/x86_64-linux-gnu/libvdpau.so.1        $build_home_dir/output/$1/
  cp /lib/x86_64-linux-gnu/libpipewire-0.3.so.0 $build_home_dir/output/$1/
  cp /lib/x86_64-linux-gnu/libXpresent.so.1     $build_home_dir/output/$1/

  cp $build_home_dir/help/*                    $build_home_dir/output/$1/
	pushd $build_home_dir/output/$1/
  ./create_comm_syms.sh
  popd
}

copyLib arm64-v8a
copyLib armeabi-v7a
copyLib x86
copyLib x86_64

cat $build_home_dir/output/arm64-v8a/comm_cxx_syms.txt \
    $build_home_dir/output/armeabi-v7a/comm_cxx_syms.txt \
    $build_home_dir/output/x86/comm_cxx_syms.txt \
    $build_home_dir/output/x86_64/comm_cxx_syms.txt \
    | sort | uniq > $build_home_dir/output/comm_cxx_syms.txt
cat $build_home_dir/output/arm64-v8a/comm_syms.txt \
    $build_home_dir/output/armeabi-v7a/comm_syms.txt \
    $build_home_dir/output/x86/comm_syms.txt \
    $build_home_dir/output/x86_64/comm_syms.txt \
    | sort | uniq > $build_home_dir/output/comm_syms.txt
cat $build_home_dir/output/arm64-v8a/libmpv_undef_syms.txt \
    $build_home_dir/output/armeabi-v7a/libmpv_undef_syms.txt \
    $build_home_dir/output/x86/libmpv_undef_syms.txt \
    $build_home_dir/output/x86_64/libmpv_undef_syms.txt \
    | sort | uniq > $build_home_dir/output/libmpv_undef_syms.txt
cat $build_home_dir/output/arm64-v8a/libmpv_def_syms.txt \
    $build_home_dir/output/armeabi-v7a/libmpv_def_syms.txt \
    $build_home_dir/output/x86/libmpv_def_syms.txt \
    $build_home_dir/output/x86_64/libmpv_def_syms.txt \
    | sort | uniq > $build_home_dir/output/libmpv_def_syms.txt

echo "current dir: vvvvvvvvvvvvvvvvvvvv"
pwd

echo "target dir: vvvvvvvvvvvvvvvvvvvv"
echo $build_home_dir/output/