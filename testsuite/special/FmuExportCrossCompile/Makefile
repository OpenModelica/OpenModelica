.PHONE: clean test fmuExportCrossCompile CMakeCrossCompile

# Note: Requires PATH to include:
# all cross-compilation targets (including OSX)
# fmuCheck.linux32 fmuCheck.linux64 fmuCheck.win32.exe fmuCheck.win64.exe

# I hate if conditions in make...
OMC := $(shell test -e ../../../build/install_cmake/bin/omc && echo ../../../build/install_cmake/bin/omc \
               || test -e ../../../build_cmake/install_cmake/bin/omc && echo ../../../build_cmake/install_cmake/bin/omc \
               || echo ../../../build/bin/omc )
OMC := $(shell realpath $(OMC))

test: clean
	$(MAKE) fmuExportCrossCompile
	$(MAKE) CMakeCrossCompile

dockerpull:
	docker pull openmodelica/crossbuild

fmuExportCrossCompile:
	HOME=$(CURDIR)/../../../libraries/ $(OMC) fmuExportCrossCompile.mos
	unzip -q FmuExportCrossCompile.fmu -d FmuExportCrossCompile.fmutmp
	$(MAKE) check-FmuExportCrossCompile-files

CMakeCrossCompile:
	HOME=$(CURDIR)/../../../libraries/ $(OMC) CMakeCrossCompile.mos
	unzip -qq CMakeCrossCompile/Modelica.Mechanics.MultiBody.Examples.Elementary.Pendulum.fmu -d CMakeCrossCompile/Pendulum_FMU/
	$(MAKE) check-CMakeCrossCompile-files

check-FmuExportCrossCompile-files:
	@file FmuExportCrossCompile.fmutmp/binaries/win32/FmuExportCrossCompile.dll | grep "PE32 executable (DLL) (console) Intel 80386, for MS Windows" || (file FmuExportCrossCompile.fmutmp/binaries/win32/FmuExportCrossCompile.dll ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/win64/FmuExportCrossCompile.dll | grep "PE32+ executable (DLL) (console) x86-64, for MS Windows" || (file FmuExportCrossCompile.fmutmp/binaries/win64/FmuExportCrossCompile.dll ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/darwin64/FmuExportCrossCompile.dylib | grep "Mach-O 64-bit x86_64 dynamically linked shared library" || (file FmuExportCrossCompile.fmutmp/binaries/darwin64/FmuExportCrossCompile.dylib ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/linux32/FmuExportCrossCompile.so | grep "ELF *32-bit *LSB *shared *object, Intel 80386, version 1 (SYSV), dynamically linked" || (file FmuExportCrossCompile.fmutmp/binaries/linux32/FmuExportCrossCompile.so ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/linux64/FmuExportCrossCompile.so | grep "ELF *64-bit *LSB *shared *object, x86-64, version 1 (SYSV), dynamically linked" || (file FmuExportCrossCompile.fmutmp/binaries/linux64/FmuExportCrossCompile.so ; false)
	@file FmuExportCrossCompile.fmutmp/binaries/arm-linux-gnueabihf/FmuExportCrossCompile.so | grep "ELF *32-bit *LSB *shared *object, ARM, EABI5 version 1 (SYSV), dynamically linked" || (file FmuExportCrossCompile.fmutmp/binaries/arm-linux-gnueabihf/FmuExportCrossCompile.so ; false)

check-CMakeCrossCompile-files:
	@file CMakeCrossCompile/Pendulum_FMU/binaries/win32/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.dll | grep "PE32 executable (DLL) (console) Intel 80386, for MS Windows" || (file Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.fmutmp/binaries/win32/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.dll ; false)
	@file CMakeCrossCompile/Pendulum_FMU/binaries/win64/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.dll | grep "PE32+ executable (DLL) (console) x86-64, for MS Windows" || (file Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.fmutmp/binaries/win64/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.dll ; false)
	@file CMakeCrossCompile/Pendulum_FMU/binaries/darwin64/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.dylib | grep "Mach-O 64-bit x86_64 dynamically linked shared library" || (file Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.fmutmp/binaries/darwin64/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.dylib ; false)
	@file CMakeCrossCompile/Pendulum_FMU/binaries/linux32/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.so | grep "ELF *32-bit *LSB *shared *object, Intel 80386, version 1 (SYSV), dynamically linked" || (file Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.fmutmp/binaries/linux32/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.so ; false)
	@file CMakeCrossCompile/Pendulum_FMU/binaries/linux64/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.so | grep "ELF *64-bit *LSB *shared *object, x86-64, version 1 (SYSV), dynamically linked" || (file Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.fmutmp/binaries/linux64/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.so ; false)
#	@file CMakeCrossCompile/Pendulum_FMU/binaries/arm-linux-gnueabihf/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.so | grep "ELF *32-bit *LSB *shared *object, ARM, EABI5 version 1 (SYSV), dynamically linked" || (file Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.fmutmp/binaries/arm-linux-gnueabihf/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.so ; false)

fmu-check:
	rm -rf ./Test_FMUs
	./fmu-run.sh FmuExportCrossCompile
	./fmu-run.sh RoomHeating_OM_RH
	./fmu-run.sh WaterTank_Control
	./fmu-run.sh WaterTank_TestSingleWaterTank
	$(OMC) check-files.mos

clean:
	rm -rf *.json *.xml *.html *.fmu* *.c *.makefile *.log *.o *.opt *.libs *.h *.mat *.csv
	rm -f BouncingBall FmuExportCrossCompile RoomHeating_OM_RH WaterTank_Control WaterTank_TestSingleWaterTank
	rm -rf CMakeCrossCompile/ Test_FMUs/
