#!/bin/sh
# 对比 libmediaxx 导出的符号与 libmpv 需要的符号，得到两者共有的符号。
# 读取 libmpv 符号的细节见 create_libmpv_symb.sh
./create_libmediaxx_symb.sh
./create_libmpv_symb.sh

comm -12 libmediaxx_def_syms.txt libmpv_undef_syms.txt > comm_syms.txt
