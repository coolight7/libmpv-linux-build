# libmpv-linux-build
- 由 libmpv-android-build 复制修改而来

## 编译
- docker 拉取镜像 `ubuntu:20.04`，创建容器，进入容器
- cd ${项目根目录}/buildscripts/
- 执行编译 `./bundle_default.sh`
- 编译结果在 ${项目根目录}/output/x86_64

## 编译产物
- 只编译 x86_64，且 `ffmpeg`、`libmpv` 都按静态库编译，最终只输出一个动态库 `libmediaxx.so`
- 因为 ffmpeg/libmpv 已经合进这个动态库，所以它体积较大，约 45 MB
- 依赖的系统库（`libva` 等）由 bundle_default.sh 一起复制到输出目录
- 同时输出符号对照表：`libmpv_def_syms.txt`（libmpv 导出的符号）、`libmpv_undef_syms.txt`（libmpv 需要外部提供的符号）、`comm_syms.txt`（libmpv 实际用到、由 libmediaxx 提供的符号）

## 系统库副本与系统版本的选择
- 输出目录里除了 `libmediaxx.so`，还有 `libva.so.2`、`libva-drm.so.2`、`libva-x11.so.2`、`libva-wayland.so.2`、`libvdpau.so.1`、`libpipewire-0.3.so.0`、`libXpresent.so.1`、`libstdc++.so.6`、`libgcc_s.so.1` 的副本，`libmediaxx.so` 通过 `DT_RUNPATH=$ORIGIN` 找到它们，目标是：用户系统没装这些库时也能加载
- 这样做的代价是副本排在系统同名库前面（RUNPATH 优先于系统库目录），会挡住用户系统里更新的库，而副本里的信息是打包机器上的：
  - `libpipewire-0.3.so.0` 里的模块目录、SPA 插件目录是 `/usr/lib/x86_64-linux-gnu/pipewire-0.3`、`/usr/lib/x86_64-linux-gnu/spa-0.2`
  - `libva.so.2` 里的驱动目录是 `/usr/lib/x86_64-linux-gnu/dri`
  - 在 Fedora/openSUSE/Arch 等目录布局不同的发行版上，用这些副本会导致 pipewire 音频输出、VA-API 初始化失败
- 因此应用侧在加载 `libmediaxx.so` 之前先加载系统里的同名库（mediaxx 的 dart 代码见 `lib/ffi/system_library_preload.dart`）：
  - 系统库存在，并且提供了 `libmediaxx.so` 需要的全部符号 -> 使用系统版本，副本不再生效
  - 系统没装该库，或者系统库缺少符号（版本太旧）-> 使用副本，也就是原来的行为
  - `libXpresent.so.1` 没有模块/驱动目录耦合，不参与这个过程，始终用副本
- 其它语言/项目直接使用 `libmediaxx.so` 时需要自己做同样的预加载（按绝对路径先 `dlopen` 系统库），否则会一直使用副本
- 符号列表与检查：
  - `help/create_preload_syms.sh`：在 `output/<arch>` 目录下执行，打印各库的符号列表（`libmediaxx.so` 的未定义符号与各库导出符号的交集），用于更新 mediaxx 里的 `_requiredSymbols`
  - `help/check_preload_syms.sh`：比对本次编译的 `libmediaxx.so` 和 mediaxx 里的列表，`bundle_default.sh` 每次都会调用，不一致时打印提示（不影响编译结果）
  - 依赖升级（`libpipewire`、`libva` 版本变化）后用到了新符号时，需要重新生成并更新 mediaxx 里的列表，否则可能会预加载缺少新符号的系统库

## 依赖库版本
- 统一写在 [buildscripts/include/depinfo.sh](buildscripts/include/depinfo.sh)，与 [libmpv-android-video-build](https://github.com/coolight7/libmpv-android-video-build) 保持一致
- `ffmpeg` 使用官方 tag `n9.0.1`
- `mpv` 使用 fork 仓库 [coolight7/mpv](https://github.com/coolight7/mpv) 的 `extend` 分支（在官方 0.41.0 基础上增加了音频分析相关接口），分支名由 `v_mpv_branch` 指定
- `mediaxx` 跟随仓库主分支 `main`
- 其它库（`libass`、`harfbuzz`、`freetype`、`mbedtls`、`dav1d`、`libxml2`、`libplacebo` 等）版本同步到 android 项目的版本

## 工具链要求
- `ffmpeg` 9.x 的 x86 汇编用到较新的 nasm 语法，nasm 2.14 会报 `error: (ALLOC_STACK:4) expecting ')'`
- ubuntu 20.04 仓库里的 nasm 是 2.14，因此 `include/download-sdk.sh` 会在版本低于 2.15 时自动编译安装 nasm 2.16.03 到 `/usr/local`
- 版本要求写在 [buildscripts/include/depinfo.sh](buildscripts/include/depinfo.sh) 的 `nasm_min`

## 修改依赖版本后如何重新下载
- 删掉版本有变化的依赖源码目录，例如 `rm -rf deps/ffmpeg deps/mpv`，再执行 `./download.sh`
- 已存在的依赖目录不会被重新下载；如果 `deps/mpv` 原来是从官方仓库克隆的，`download.sh` 会自动把 remote 换成 fork 仓库并切到 `extend` 分支
- 同时删掉 `prefix/x86_64/lib` 下对应的库文件，否则 `build.sh` 会跳过重新编译
- 依赖源码更新后需要重新应用补丁：`./patch.sh`

## patch 说明
- `patches/ffmpeg` 下三个补丁已对应 ffmpeg 9.0.1：
    - `remove-dll-version.patch`：动态库文件名带上版本号会按 `$(SLIBNAME).$(LIBVERSION)` 生成，这里去掉版本号后缀
    - `disable-install-ln.patch`：去掉动态库安装时创建的软链接（与上一个补丁配合，避免产生 `libxxx.so.x` 之类的重复文件）
    - `id3v2-picture.patch`：内嵌封面图的 MIME 类型缺失或未知时，按文件头识别 JPEG/PNG；识别不出时按 JPEG 处理，避免封面被直接丢弃
- ffmpeg 9.0.1 已经自带 DASH baseurl 转义、FLAC 内嵌 ID3v2 封面读取，原先对应的 `dash_base_url_escape.patch`、`flac-id3-extmeta.patch` 已删除
- 应用失败时，可以按照补丁内容手动修改依赖源码

## ffmpeg 编译参数说明
- 参数见 [buildscripts/flavors/default.sh](buildscripts/flavors/default.sh)，由 `bundle_default.sh` 复制成 `scripts/ffmpeg.sh` 后使用
- 相对 ffmpeg 8.0.1 的调整：
    - 去掉 `--enable-nonfree`，改为 `--disable-nonfree`，构建结果可以自由分发
    - 去掉 ffmpeg 9.0 已经移除的 `--disable-libshaderc`，协议列表里去掉已移除的 `hls`，解复用器列表里去掉已移除的 `afx`
    - 补充 ffmpeg 9.0 新增的 `dovi_split` 比特流过滤器、`webp_anim` 解码器与解复用器、`afade`/`vibrato`/`tremolo` 音频滤镜
    - 补充 `--disable-amf`、`--optflags=-O3`
    - `--enable-hardcoded-tables` 换成 `--enable-small`（与 android 项目一致），同时保留 `--optflags=-O3`，避免 `--enable-small` 把优化级别改成 `-Os`
    - 解码器白名单改成 ffmpeg 9.0 的组件名（`4xm`→`fourxm`、`hnm4video`→`hnm4_video`、`interplayvideo`→`interplay_video`、`roqvideo`→`roq`、`rasc.rl2`→`rl2`、`interplayacm`→`interplay_acm`、`8svx_exp`→`eightsvx_exp` 等），原先那条与白名单重复的 `--disable-decoder=...` 列表已删除
- 注意：`sonic`、`gremlin_dpcm` 等解码器在 ffmpeg 9.0 里加了 `lgpl_gpl` 依赖，只有在 `--enable-gpl` 时才会编进来，本项目是 LGPL 构建，因此这两个解码器不再可用

## 可能的问题
- mpv 编译报错找不到 wayland-protocols 协议文件
    - 协议文件由系统包提供，而 `PKG_CONFIG_SYSROOT_DIR` 会给它的路径加上前缀目录，导致 meson 在前缀目录里找不到文件
    - `scripts/mpv.sh` 会先检查前缀目录，缺失时自动复制系统的 `/usr/local/share/wayland-protocols` 或 `/usr/share/wayland-protocols`
    - 若编译机上两个目录都没有，需要先安装 wayland-protocols（`apt install wayland-protocols`）
- `bundle_default.sh` 需要用 bash 执行（脚本内使用了 `pushd`/`popd` 等 bash 语法）
