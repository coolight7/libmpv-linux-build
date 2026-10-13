#!/bin/sh
# 检查 mediaxx 的 Dart 侧预加载符号列表是否与本次编译的 libmediaxx.so 一致。
#
# mediaxx 在 Linux 上会先加载系统里的 libva、libpipewire 等库，只有系统库提供了
# libmediaxx.so 需要的全部符号时才使用系统版本（细节见 mediaxx 源码的
# lib/ffi/system_library_preload.dart）。符号列表写在那个 Dart 文件里，
# 依赖升级后 libmediaxx.so 可能用到新符号，列表就会过期，因此这里做一次比对。
#
# 不一致时用 create_preload_syms.sh 重新生成，再更新 mediaxx 里的列表。
# 本脚本只提示，不会让编译失败。
#
# 用法（在 output/<arch> 目录下执行，两个脚本由 bundle_default.sh 一起复制过来）：
#   ./check_preload_syms.sh <system_library_preload.dart 的路径>

dart_file="$1"

if [ -z "$dart_file" ] || [ ! -f "$dart_file" ]; then
	echo "check_preload_syms: 没有找到 $dart_file（mediaxx 源码里还没有这个文件），跳过检查"
	exit 0
fi

here=$(cd "$(dirname "$0")" && pwd)
generate="$here/create_preload_syms.sh"
[ -f "$generate" ] || generate="$here/../help/create_preload_syms.sh"

if [ ! -f "$generate" ]; then
	echo "check_preload_syms: 找不到 create_preload_syms.sh，跳过检查"
	exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# 把两边都整理成 “库名 符号名” 的形式（一行一个，去掉引号和格式差异），
# 这样 Dart 文件里写成单行还是多行都不影响比对
normalize () {
	awk '
	BEGIN { q = sprintf("%c", 39) }
	{
		line = $0
		while (match(line, q "[^" q "]+" q)) {
			item = substr(line, RSTART + 1, RLENGTH - 2)
			line = substr(line, RSTART + RLENGTH)
			if (item ~ /\.so/) {
				lib = item
			} else if (lib != "") {
				print lib, item
			}
		}
	}' | sort
}

sh "$generate" 2>/dev/null | normalize > "$tmp/generated.txt"
sed -n '/_requiredSymbols = <String, List<String>>{/,/^};/p' "$dart_file" | normalize > "$tmp/current.txt"

if [ ! -s "$tmp/generated.txt" ]; then
	echo "check_preload_syms: 生成符号列表失败，跳过检查"
	exit 0
fi

if ! cmp -s "$tmp/generated.txt" "$tmp/current.txt"; then
	echo "---------------------------------------------------------------"
	echo "提示：mediaxx 的预加载符号列表和本次编译的 libmediaxx.so 不一致"
	echo "  Dart 文件：$dart_file"
	echo "  需要重新生成：cd output/<arch> && ./create_preload_syms.sh"
	echo "  两边差异（左：本次编译，右：Dart 文件）："
	diff "$tmp/generated.txt" "$tmp/current.txt" | head -40
	echo "---------------------------------------------------------------"
fi

exit 0
