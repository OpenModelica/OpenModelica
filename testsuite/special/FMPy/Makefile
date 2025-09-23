OMC := $(shell test -e ../../../build/install_cmake/bin/omc && echo ../../../build/install_cmake/bin/omc \
               || test -e ../../../build_cmake/install_cmake/bin/omc && echo ../../../build_cmake/install_cmake/bin/omc \
               || echo ../../../build/bin/omc )
OMC := $(shell realpath $(OMC))

FMPY_CALL = python3 -m fmpy

FMU = ../FmuExportCrossCompile/FmuExportCrossCompile.fmu \
      ../FmuExportCrossCompile/RoomHeating_OM_RH.fmu \
      ../FmuExportCrossCompile/WaterTank_Control.fmu \
      ../FmuExportCrossCompile/WaterTank_TestSingleWaterTank.fmu \
      ../FmuExportCrossCompile/BouncingBall.fmu \
      TableTest.fmu

.PHONY: all test clean

all: compile_FMUs
	$(MAKE) test

test: $(FMU)

FORCE:

%.fmu: FORCE
	@echo -----------------------------------------------------------------------
	@echo $@
  # Remove binaries
	unzip -qq $@ -d $@_FMU/
	rm -rf $@_FMU/binaries
	cd $@_FMU/; zip -qqr ../$@ *
	rm -rf $@_FMU/
  # Compile sources and simulate
	$(FMPY_CALL) compile $@
	$(FMPY_CALL) simulate $@
	@echo -----------------------------------------------------------------------

compile_FMUs:
	make -C ../FmuExportCrossCompile

fmpy-fmus:
	$(OMC) testCompileModelicaStandardTables.mos

clean:
	rm -f $(FMU)
	rm -rf $(addsuffix _FMU/,$(FMU))
	rm -rf TableTest/
