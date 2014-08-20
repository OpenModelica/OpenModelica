# Adrian Pop, adrpo@ida.liu.se, 2006-02-01
# Makefile for compilation of OMC using OMDev-mingw
# OMDev-mingw: http://www.ida.liu.se/~adrpo/omc/omdev/

top_builddir = ../../..
builddir_build=$(top_builddir)/build
builddir_bin=$(top_builddir)/build/bin
builddir_lib=$(top_builddir)/build/lib/omc
builddir_inc=$(top_builddir)/build/include/omc

ANALYZATION_MODE_COMMAND="-DANALYZATION_MODE=ON"
PARALLEL_OUTPUT_COMMAND="-DUSE_PARALLEL_OUTPUT=ON"

runtimeCpp: clean
ifneq ("$(ANALYZATION_MODE)","true")
	$(eval ANALYZATION_MODE_COMMAND="")
endif
ifneq ("$(USE_PARALLEL_OUTPUT)","true")
	$(eval PARALLEL_OUTPUT_COMMAND="")
endif
	cd ./Build && echo "change to Build" && cmake $(ANALYZATION_MODE_COMMAND) $(PARALLEL_OUTPUT_COMMAND) -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX:PATH="$(builddir_build)"  ../
	$(MAKE) -C Build;

install: runtimeCpp
	(cd Build; $(MAKE) install)

clean:
	rm -R -f Build
	mkdir Build
