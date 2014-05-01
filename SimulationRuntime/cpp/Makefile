# Adrian Pop, adrpo@ida.liu.se, 2006-02-01
# Makefile for compilation of OMC using OMDev-mingw
# OMDev-mingw: http://www.ida.liu.se/~adrpo/omc/omdev/

top_builddir = ../../..
builddir_build=$(top_builddir)/build
builddir_bin=$(top_builddir)/build/bin
builddir_lib=$(top_builddir)/build/lib/omc
builddir_inc=$(top_builddir)/build/include/omc

runtimeCpp: clean
	#cd ./Build && echo "change to Build" && cmake -D ANALYZATION_MODE=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX:PATH="$(builddir_build)"  ../
	cd ./Build && echo "change to Build" &&	cmake -D CMAKE_BUILD_TYPE=RelWithDebInfo -D CMAKE_INSTALL_PREFIX:PATH="$(builddir_build)"  -D CMAKE_CXX_COMPILER="g++-4.4"  ../
	$(MAKE) -C Build

install: runtimeCpp
	(cd Build; $(MAKE) install)

clean:
	rm -R -f Build
	mkdir Build
