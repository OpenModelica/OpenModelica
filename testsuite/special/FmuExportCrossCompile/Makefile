.PHONE: clean test fmuExportCrossCompile CMakeCrossCompile ExternalDependency

DOCKER_IMAGE := ghcr.io/openmodelica/crossbuild:v1.27.0

# Note: Requires PATH to include:
# all cross-compilation targets (no OSX)
# fmuCheck.linux32 fmuCheck.linux64 fmuCheck.win32.exe fmuCheck.win64.exe

# I hate if conditions in make...
OMC := $(shell test -e ../../../build/install_cmake/bin/omc && echo ../../../build/install_cmake/bin/omc \
               || test -e ../../../build_cmake/install_cmake/bin/omc && echo ../../../build_cmake/install_cmake/bin/omc \
               || echo ../../../build/bin/omc )
OMC := $(shell realpath $(OMC))

test: clean
	$(MAKE) fmuExportCrossCompile
	$(MAKE) CMakeCrossCompile
	$(MAKE) ExternalDependency

dockerpull:
	docker pull $(DOCKER_IMAGE)

fmuExportCrossCompile:
	HOME=$(CURDIR)/../../../libraries/ $(OMC) fmuExportCrossCompile.mos
	unzip -q FmuExportCrossCompile.fmu -d FmuExportCrossCompile.fmutmp
	$(MAKE) check-FmuExportCrossCompile-files

CMakeCrossCompile:
	HOME=$(CURDIR)/../../../libraries/ $(OMC) CMakeCrossCompile.mos
	unzip -qq CMakeCrossCompile/Modelica.Mechanics.MultiBody.Examples.Elementary.Pendulum.fmu -d CMakeCrossCompile/Pendulum_FMU/
	$(MAKE) check-CMakeCrossCompile-files

# Cross compile a model depending on a pre-compiled external C library. The library
# is built with the toolchains of the cross-build image, so no host toolchain is needed.
ExternalDependency:
	docker run --rm --user $(shell id -u) -v $(CURDIR)/ExtLib:/extlib -w /extlib $(DOCKER_IMAGE) sh -c "\
	  mkdir -p Resources/Library/linux64 Resources/Library/win64 && \
	  gcc -shared -fPIC -Wl,-soname,libaddOne.so -IResources/Include -o Resources/Library/linux64/libaddOne.so Resources/C-Sources/addOne.c && \
	  x86_64-w64-mingw32-gcc -shared -IResources/Include -o Resources/Library/win64/addOne.dll Resources/C-Sources/addOne.c"
	HOME=$(CURDIR)/../../../libraries/ $(OMC) ExternalDependency.mos
	unzip -q ExternalDependency.fmu -d ExternalDependency.fmutmp
	unzip -q ExternalDependencyCVode.fmu -d ExternalDependencyCVode.fmutmp
	$(MAKE) check-ExternalDependency-files

# The wording of `file` changed between versions, e.g. file 5.41 prints
#   PE32 executable (DLL) (console) Intel 80386, for MS Windows
# while file 5.46 prints
#   PE32 executable for MS Windows 4.00 (DLL), Intel i386
# so only match the words identifying object format and architecture.
# Usage: $(call assert-binary,<file>,<format regex>,<architecture regex>)
assert-binary = @file $(1) | grep -E '$(2)' | grep -E '$(3)' > /dev/null || (file $(1) ; false)

check-ExternalDependency-files:
	$(call assert-binary,ExternalDependency.fmutmp/binaries/linux64/ExternalDependency.so,ELF 64-bit .*shared object,x86-64)
	$(call assert-binary,ExternalDependency.fmutmp/binaries/win64/ExternalDependency.dll,PE32\+ .*\(DLL\),x86-64)
# The external library has to be shipped inside the FMU, otherwise it can't be loaded
# on a machine that doesn't have the Modelica library installed.
	@test -f ExternalDependency.fmutmp/binaries/linux64/libaddOne.so || (ls -l ExternalDependency.fmutmp/binaries/linux64/ ; false)
	@test -f ExternalDependency.fmutmp/binaries/win64/addOne.dll || (ls -l ExternalDependency.fmutmp/binaries/win64/ ; false)
# CoSimulation FMU with CVODE linked in, Linux only. SUNDIALS is a static library, so it
# leaves no trace in binaries/ and a successful build is what is being checked here.
	$(call assert-binary,ExternalDependencyCVode.fmutmp/binaries/linux64/ExternalDependencyCVode.so,ELF 64-bit .*shared object,x86-64)
	@test -f ExternalDependencyCVode.fmutmp/binaries/linux64/libaddOne.so || (ls -l ExternalDependencyCVode.fmutmp/binaries/linux64/ ; false)
	@grep -q cvode ExternalDependencyCVode.fmutmp/resources/ExternalDependencyCVode_flags.json || (cat ExternalDependencyCVode.fmutmp/resources/ExternalDependencyCVode_flags.json ; false)

check-FmuExportCrossCompile-files:
	$(call assert-binary,FmuExportCrossCompile.fmutmp/binaries/win32/FmuExportCrossCompile.dll,PE32 .*\(DLL\),Intel (80386|i386))
	$(call assert-binary,FmuExportCrossCompile.fmutmp/binaries/win64/FmuExportCrossCompile.dll,PE32\+ .*\(DLL\),x86-64)
	$(call assert-binary,FmuExportCrossCompile.fmutmp/binaries/linux32/FmuExportCrossCompile.so,ELF 32-bit .*shared object,Intel (80386|i386))
	$(call assert-binary,FmuExportCrossCompile.fmutmp/binaries/linux64/FmuExportCrossCompile.so,ELF 64-bit .*shared object,x86-64)
	$(call assert-binary,FmuExportCrossCompile.fmutmp/binaries/arm-linux-gnueabihf/FmuExportCrossCompile.so,ELF 32-bit .*shared object,ARM. EABI)

check-CMakeCrossCompile-files:
	$(call assert-binary,CMakeCrossCompile/Pendulum_FMU/binaries/win32/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.dll,PE32 .*\(DLL\),Intel (80386|i386))
	$(call assert-binary,CMakeCrossCompile/Pendulum_FMU/binaries/win64/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.dll,PE32\+ .*\(DLL\),x86-64)
	$(call assert-binary,CMakeCrossCompile/Pendulum_FMU/binaries/linux32/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.so,ELF 32-bit .*shared object,Intel (80386|i386))
	$(call assert-binary,CMakeCrossCompile/Pendulum_FMU/binaries/linux64/Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.so,ELF 64-bit .*shared object,x86-64)
# Only one linux64 binary type in a 2.0 FMU possible
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
	rm -rf CMakeCrossCompile/ Test_FMUs/ ExtLib/Resources/Library/
