.PHONE: clean test

# Note: Requires PATH to include:
# all cross-compilation targets (including OSX)
# fmuCheck.linux32 fmuCheck.linux64 fmuCheck.win32.exe fmuCheck.win64.exe

OMC=../../../build/bin/omc
# FMUCHECKERBIN=~/bin/
WINE32=$(shell which fmuCheck.win32.exe)
WINE64=$(shell which fmuCheck.win64.exe)

test: clean
	$(OMC) fmuExportCrossCompile.mos
	unzip -q FmuExportCrossCompile.fmu -d FmuExportCrossCompile.fmutmp
	$(MAKE) check-files
	$(MAKE) fmu-check
	$(MAKE) clean
check-files:
	@file FmuExportCrossCompile.fmutmp/binaries/win32/FmuExportCrossCompile.dll | grep "PE32 executable (DLL) (console) Intel 80386, for MS Windows" || (file FmuExportCrossCompile.fmutmp/binaries/win32/FmuExportCrossCompile.dll ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/win64/FmuExportCrossCompile.dll | grep "PE32+ executable (DLL) (console) x86-64, for MS Windows" || (file FmuExportCrossCompile.fmutmp/binaries/win64/FmuExportCrossCompile.dll ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/darwin32/FmuExportCrossCompile.dylib | grep "Mach-O i386 dynamically linked shared library" || (file FmuExportCrossCompile.fmutmp/binaries/darwin32/FmuExportCrossCompile.dylib ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/darwin64/FmuExportCrossCompile.dylib | grep "Mach-O 64-bit x86_64 dynamically linked shared library" || (file FmuExportCrossCompile.fmutmp/binaries/darwin64/FmuExportCrossCompile.dylib ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/linux32/FmuExportCrossCompile.so | grep "ELF *32-bit *LSB *shared *object, Intel 80386, version 1 (SYSV), dynamically linked" || (file FmuExportCrossCompile.fmutmp/binaries/linux32/FmuExportCrossCompile.so ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/linux64/FmuExportCrossCompile.so | grep "ELF *64-bit *LSB *shared *object, x86-64, version 1 (SYSV), dynamically linked" || (file FmuExportCrossCompile.fmutmp/binaries/linux64/FmuExportCrossCompile.so ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/arm-linux-gnueabihf/FmuExportCrossCompile.so | grep "ELF *32-bit *LSB *shared *object, ARM, EABI5 version 1 (SYSV), dynamically linked" || (file FmuExportCrossCompile.fmutmp/binaries/arm-linux-gnueabihf/FmuExportCrossCompile.so ; false)
fmu-check:
	@test ! -z "$(WINE32)" || (echo Did not find fmuCheck.win32.exe on the PATH; false)
	@test ! -z "$(WINE64)" || (echo Did not find fmuCheck.win64.exe on the PATH; false)
	wine $(WINE32) -f -n 2000 -k me -o win32-me.csv FmuExportCrossCompile.fmu
	WINEARCH=win64 WINEPREFIX=~/.wine64 wine $(WINE64) -f -k me -o win64-me.csv FmuExportCrossCompile.fmu
	wine $(WINE32) -f -n 2000 -k cs -o win32-cs.csv FmuExportCrossCompile.fmu
	WINEARCH=win64 WINEPREFIX=~/.wine64 wine $(WINE64) -f -k cs -o win64-cs.csv FmuExportCrossCompile.fmu
	fmuCheck.linux32 -f -n 2000 -k me -o linux32-me.csv FmuExportCrossCompile.fmu
	fmuCheck.linux64 -f -n 2000 -k me -o linux64-me.csv FmuExportCrossCompile.fmu
	fmuCheck.linux32 -f -n 2000 -k cs -o linux32-cs.csv FmuExportCrossCompile.fmu
	fmuCheck.linux64 -f -n 2000 -k cs -o linux64-cs.csv FmuExportCrossCompile.fmu
	$(OMC) check-files.mos
clean:
	rm -rf FmuExportCrossCompile.fmu* FmuExportCrossCompile.c FmuExportCrossCompile.makefile FmuExportCrossCompile.log FmuExportCrossCompile.o FmuExportCrossCompile.libs FmuExportCrossCompile_* *.csv
