#!/bin/sh
# 读取 libmpv 的符号，生成下面两个文件：
# - libmpv_def_syms.txt  : libmpv 自己定义并对外可见的符号
# - libmpv_undef_syms.txt: libmpv 需要外部提供的符号
#
# libmpv 在本项目里是静态库（用 -flto 编译），归档文件里的目标文件是 LTO 中间格式，
# readelf 只能看到 __gnu_lto_slim 这样的占位符号，因此改用 nm 并加载 gcc 的 LTO 插件。
# 如果存在动态库 libmpv.so，则直接用 readelf 读取，结果更直观。

libmpv_file=libmpv.a
reader=readelf
if [ -f libmpv.so ]; then
	libmpv_file=libmpv.so
else
	lto_plugin=$(gcc -print-file-name=liblto_plugin.so)
	if [ ! -f "$lto_plugin" ]; then
		lto_plugin=$(find /usr/local/libexec/gcc /usr/lib/gcc -name 'liblto_plugin.so' 2>/dev/null | head -n 1)
	fi
	if [ -n "$lto_plugin" ]; then
		reader=nm
	fi
fi

if [ "$reader" = "nm" ]; then
	nm_args="--plugin=$lto_plugin"
	nm $nm_args -g --defined-only "$libmpv_file" 2>/dev/null | awk 'NF >= 3 {print $NF}' | sort -u > libmpv_def_syms.txt
	nm $nm_args -g --undefined-only "$libmpv_file" 2>/dev/null | awk 'NF >= 1 {print $NF}' | sort -u > libmpv_undef_syms.txt
else
	readelf -W --symbols "$libmpv_file" | grep ' GLOBAL ' | grep -v ' UND ' | awk '{print $8}' | sort -u > libmpv_def_syms.txt
	readelf -W --symbols "$libmpv_file" | grep ' UND ' | awk '{print $8}' | sort -u > libmpv_undef_syms.txt
fi

echo "libmpv symbols read from $libmpv_file with $reader"
