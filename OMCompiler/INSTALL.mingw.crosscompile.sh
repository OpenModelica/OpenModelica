# Some small directions to get compilation of Windows executables on Linux
# apt-get install gcc-mingw32
# Note: This is still work in progress. ranlib is not called on the .a-files, wrong linking flags are used in the end. The wrong config.h is used
OMDEV=~/dev/OMDev
autoconf
./configure --host=i586-mingw32msvc AR=i586-mingw32msvc-ar "CPPFLAGS=-I$OMDEV/tools/mingw/include -I$OMDEV/lib/3rdParty/Sundials/include" "LDFLAGS=-L/usr/i586-mingw32msvc/lib/ -L$OMDEV/tools/mingw/lib -L$OMDEV/tools/mingw/mingw32/lib" --with-lapack="-llapack-mingw -lblas-mingw -lg2c"

# Some old config lines; maybe still useful. Remove when everything is working
# ./configure AR=i586-mingw32msvc-ar CC=i586-mingw32msvc-cc CXX=i586-mingw32msvc-c++ "CPPFLAGS=-I$OMDEV/tools/mingw/include -I$OMDEV/lib/3rdParty/Sundials/include" "LDFLAGS=-L$OMDEV/tools/mingw/lib" --with-lapack="-llapack-mingw -lblas-mingw -lg2c"
#./configure --host=amd64-linux CC=i586-mingw32msvc-cc "CPPFLAGS=-I/usr/i686-w64-mingw32/include -I$OMDEV/tools/mingw/include -I$OMDEV/lib/3rdParty/Sundials/include" --with-lapack="-llapack-mingw -lblas-mingw -lg2c"
# For libgc; if stuff still fails...
# ./configure  '--target=i586-mingw32msvc' '--enable-large-config' 'CC=i586-mingw32msvc-cc' 'CXX=i586-mingw32msvc-c++' 'CFLAGS=' 'CPPFLAGS=-I/home/martin/dev/OMDev/tools/mingw/include' LDFLAGS="-L/home/martin/dev/OMDev/tools/mingw/lib" 'target_alias=i586-mingw32msvc' --disable-threads --with-cross-host=i586-mingw32msvc --host=i586-mingw32msvc
