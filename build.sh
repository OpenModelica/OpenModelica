#! /usr/bin/env bash

# for configure include the system's ipopt/coin include paths
# just in case (is pkgconfig used?)
autoconf
./configure --prefix=/opt/OpenModelica --without-ipopt --with-omlibrary=all \
    CFLAGS="-I/usr/include/qwt -I/usr/include/coin-or -I/usr/include/coin -L/usr/lib"
