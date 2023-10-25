
FMPY_CALL = python3 -m fmpy

FMU_DIRECTORY = ../FmuExportCrossCompile
FMU = FmuExportCrossCompile.fmu \
      RoomHeating_OM_RH.fmu \
      WaterTank_Control.fmu \
      WaterTank_TestSingleWaterTank.fmu \
      BouncingBall.fmu

.PHONY: all test

all: compile_FMUs
	$(MAKE) test
test: $(FMU)

%.fmu:
	@echo -----------------------------------------------------------------------
	@echo $@
	$(FMPY_CALL) compile $(FMU_DIRECTORY)/$@
	$(FMPY_CALL) simulate $(FMU_DIRECTORY)/$@
	@echo -----------------------------------------------------------------------

compile_FMUs:
	make -C ../FmuExportCrossCompile
