# libmpv-linux-build
- 由 libmpv-android-build 复制修改而来

## 编译
- docker 拉取镜像 `ubuntu:20.04`，创建容器，进入容器
- cd ${项目根目录}/buildscripts/
- 执行编译 ./bundle_default.sh
- 编译结果在 ${项目根目录}/output/x86_64

## 依赖库预装
- 部分库由系统库提供，编译时报错缺少的库直接 apt 安装即可

## 可能的问题
- patch 应用失败
    - 可以直接手动按照 patch 修改内容
- mpv编译失败, 缺少 wayland-protocols 文件，直接从系统文件复制过去
    - `video/out/meson.build:45:27: ERROR: File /home/coolight/program/media/libmpv-linux-build/buildscripts/prefix/x86_64/usr/local/share/wayland-protocols/stable/presentation-time/presentation-time.xml does not exist.`
    - 执行:
```sh
mkdir -p /home/coolight/program/media/libmpv-linux-build/buildscripts/prefix/x86_64/usr/local/share/wayland-protocols/
cp -r /usr/local/share/wayland-protocols/ /home/coolight/program/media/libmpv-linux-build/buildscripts/prefix/x86_64/usr/local/share/
```