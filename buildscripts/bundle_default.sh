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

# coolight --- temp
# ./build.sh
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

copyLib() {
  if [[ $1 != "arm64-v8a" && $1 != "armeabi-v7a" && $1 != "x86" && $1 != "x86_64" ]]; then
    echo "call copyLib 参数 {cpu} 不正确: $1"
    exit -1
  fi

  mkdir -p app/build/outputs/release/lib/$1/
  cp prefix/$1/lib/libmediaxx.so                                    app/build/outputs/release/lib/$1/
  cp prefix/$1/lib/libmpv.so                                        app/build/outputs/release/lib/$1/
  cp prefix/$1/lib/ffmpeg-backup/libswresample.so                   app/build/outputs/release/lib/$1/
  cp prefix/$1/lib/ffmpeg-backup/libswscale.so                      app/build/outputs/release/lib/$1/
  cp prefix/$1/lib/ffmpeg-backup/libavutil.so                       app/build/outputs/release/lib/$1/
  cp prefix/$1/lib/ffmpeg-backup/libavcodec.so                      app/build/outputs/release/lib/$1/
  cp prefix/$1/lib/ffmpeg-backup/libavformat.so                     app/build/outputs/release/lib/$1/
  cp prefix/$1/lib/ffmpeg-backup/libavfilter.so                     app/build/outputs/release/lib/$1/
  cp prefix/$1/lib/ffmpeg-backup/libavdevice.so                     app/build/outputs/release/lib/$1/
}

copyLib arm64-v8a
copyLib armeabi-v7a
copyLib x86
copyLib x86_64

cd app/build/outputs/release

rm -rf $build_home_dir/output/
mkdir -p $build_home_dir/output/

resetSONAME() {
  if [[ $1 != "arm64-v8a" && $1 != "armeabi-v7a" && $1 != "x86" && $1 != "x86_64" ]]; then
    echo "call resetSONAME 参数 {cpu} 不正确: $1"
    exit -1
  fi

  mkdir -p $build_home_dir/output/$1/
  cp lib/$1/lib*.so             $build_home_dir/output/$1/
  cp $build_home_dir/help/*     $build_home_dir/output/$1/
  # rm lib/$1/libc++*.so
  zip -r default-$1.zip         lib/$1/lib*.so
  cp default-$1.zip             $build_home_dir/output/

	pushd $build_home_dir/output/$1/
  ./create_comm_syms.sh
  popd
}

resetSONAME arm64-v8a
resetSONAME armeabi-v7a
resetSONAME x86
resetSONAME x86_64

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

md5sum *.zip

echo "current dir: vvvvvvvvvvvvvvvvvvvv"
pwd

echo "target dir: vvvvvvvvvvvvvvvvvvvv"
echo $build_home_dir/output/