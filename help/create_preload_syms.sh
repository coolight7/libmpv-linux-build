#!/bin/sh
# 打印 mediaxx 的 Dart 侧预加载符号列表，也就是 mediaxx 源码里
# lib/ffi/system_library_preload.dart 中 _requiredSymbols 的内容。
#
# 列表含义：libmediaxx.so 会从这些随包分发的系统库里取用的符号。
# 只有系统库全部提供这些符号时，mediaxx 才会优先使用系统版本，否则退回同目录下的副本。
# 列表由 libmediaxx.so 的未定义符号与各库导出符号取交集得到，因此依赖升级
# （libpipewire、libva 等版本变化）后需要重新生成。
#
# 用法：在 output/<arch> 目录下执行，目录里要有 libmediaxx.so 和各库的副本
#   ./create_preload_syms.sh > /tmp/preload_syms.txt
# 把输出整段替换到 system_library_preload.dart 的 _requiredSymbols 即可，
# 粘贴后执行一次 dart format（短列表会被合并成一行，格式以 dart format 为准）。

preload_libs="libpipewire-0.3.so.0 libva.so.2 libva-drm.so.2 libva-x11.so.2 libva-wayland.so.2 libvdpau.so.1"

if [ ! -f libmediaxx.so ]; then
	echo "当前目录没有 libmediaxx.so，请在 output/<arch> 目录下执行" >&2
	exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# libmediaxx.so 需要外部提供的符号
readelf -W --dyn-syms libmediaxx.so \
	| awk '$7 == "UND" { print $8 }' \
	| sed 's/@.*//' | sort -u > "$tmp/undef.txt"

echo "const Map<String, List<String>> _requiredSymbols = <String, List<String>>{"
for lib in $preload_libs; do
	if [ ! -f "$lib" ]; then
		echo "# 缺少 $lib，跳过" >&2
		continue
	fi
	nm -D --defined-only "$lib" 2>/dev/null \
		| awk 'NF >= 2 { print $NF }' \
		| sed 's/@.*//' | sort -u > "$tmp/def.txt"
	echo "  '$lib': <String>["
	comm -12 "$tmp/undef.txt" "$tmp/def.txt" | sed "s/^/    '/; s/\$/',/"
	echo "  ],"
done
echo "};"
