#!/bin/sh
# 列出 libmpv 需要外部提供的符号（未定义符号）。
# create_libmpv_symb.sh 也会生成这个文件，此脚本保留给需要单独执行它的场合。
# 读取符号的细节见 create_libmpv_symb.sh 里的说明。

libmpv_file=libmpv.a
[ -f libmpv.so ] && libmpv_file=libmpv.so

if [ "$libmpv_file" = "libmpv.a" ]; then
	lto_plugin=$(gcc -print-file-name=liblto_plugin.so)
	[ -f "$lto_plugin" ] || lto_plugin=$(find /usr/local/libexec/gcc /usr/lib/gcc -name 'liblto_plugin.so' 2>/dev/null | head -n 1)
	nm --plugin="$lto_plugin" -g --undefined-only "$libmpv_file" 2>/dev/null | awk 'NF >= 1 {print $NF}' | sort -u > libmpv_undef_syms.txt
else
	readelf -W --symbols "$libmpv_file" | grep ' UND ' | awk '{print $8}' | sort -u > libmpv_undef_syms.txt
fi

echo "libmpv undefined symbols read from $libmpv_file"
