# FIXME: before you push into master...
RUNTIMEDIR=E:/apps/workspace/topenmodelica/build_cmake/install_cmake/include/omc/c/
#COPY_RUNTIMEFILES=$(FMI_ME_OBJS:%= && (OMCFILE=% && cp $(RUNTIMEDIR)/$$OMCFILE.c $$OMCFILE.c))

fmu:
	rm -f TestFMU.fmutmp/sources/TestFMU_init.xml
	cp -a "E:/apps/workspace/topenmodelica/build_cmake/install_cmake/share/omc/runtime/c/fmi/buildproject/"* TestFMU.fmutmp/sources
	cp -a TestFMU_FMU.libs TestFMU.fmutmp/sources/

