
FMPY_CALL = python3 -m fmpy

FMU = FmuExportCrossCompile.fmu \
      RoomHeating_OM_RH.fmu \
      WaterTank_Control.fmu \
      WaterTank_TestSingleWaterTank.fmu \
      BouncingBall.fmu \
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
	omc testCompileModelicaStandardTables.mos

clean:
	rm -f $(FMU)
	rm -rf $(addsuffix _FMU/,$(FMU))
	rm -rf Table/Test/
