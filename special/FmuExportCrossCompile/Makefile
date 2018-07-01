.PHONE: clean test

# Note: Requires PATH to include:
# all cross-compilation targets (including OSX)
# fmuCheck.linux32 fmuCheck.linux64 fmuCheck.win32.exe fmuCheck.win64.exe

OMC=../../../build/bin/omc

test: clean
	$(OMC) fmuExportCrossCompile.mos
	unzip -q FmuExportCrossCompile.fmu -d FmuExportCrossCompile.fmutmp
	$(MAKE) check-files
dockerpull:
	docker pull docker.openmodelica.org/osxcross-omsimulator:v2.0
	docker pull docker.openmodelica.org/armcross-omsimulator:v2.0
	docker pull docker.openmodelica.org/msyscross-omsimulator:v2.0
check-files:
	@file FmuExportCrossCompile.fmutmp/binaries/win32/FmuExportCrossCompile.dll | grep "PE32 executable (DLL) (console) Intel 80386, for MS Windows" || (file FmuExportCrossCompile.fmutmp/binaries/win32/FmuExportCrossCompile.dll ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/win64/FmuExportCrossCompile.dll | grep "PE32+ executable (DLL) (console) x86-64, for MS Windows" || (file FmuExportCrossCompile.fmutmp/binaries/win64/FmuExportCrossCompile.dll ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/darwin64/FmuExportCrossCompile.dylib | grep "Mach-O 64-bit x86_64 dynamically linked shared library" || (file FmuExportCrossCompile.fmutmp/binaries/darwin64/FmuExportCrossCompile.dylib ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/linux32/FmuExportCrossCompile.so | grep "ELF *32-bit *LSB *shared *object, Intel 80386, version 1 (SYSV), dynamically linked" || (file FmuExportCrossCompile.fmutmp/binaries/linux32/FmuExportCrossCompile.so ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/linux64/FmuExportCrossCompile.so | grep "ELF *64-bit *LSB *shared *object, x86-64, version 1 (SYSV), dynamically linked" || (file FmuExportCrossCompile.fmutmp/binaries/linux64/FmuExportCrossCompile.so ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/arm-linux-gnueabihf/FmuExportCrossCompile.so | grep "ELF *32-bit *LSB *shared *object, ARM, EABI5 version 1 (SYSV), dynamically linked" || (file FmuExportCrossCompile.fmutmp/binaries/arm-linux-gnueabihf/FmuExportCrossCompile.so ; false)
fmu-check:
	rm -rf ./Test_FMUs
	./fmu-run.sh FmuExportCrossCompile
	./fmu-run.sh RoomHeating_OM_RH
	./fmu-run.sh WaterTank_Control
	./fmu-run.sh WaterTank_TestSingleWaterTank
	$(OMC) check-files.mos
clean:
	rm -rf *.json *.xml *.html *.fmu* *.c *.makefile *.log *.o *.libs *.h *.mat *.csv Test_FMUs
