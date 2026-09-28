OMC := $(shell test -e ../../../build/install_cmake/bin/omc && echo ../../../build/install_cmake/bin/omc \
               || test -e ../../../build_cmake/install_cmake/bin/omc && echo ../../../build_cmake/install_cmake/bin/omc \
               || echo ../../../build/bin/omc )
OMC := $(shell realpath $(OMC))

FMPY_CALL = python3 -m fmpy

# Simulated with the binaries OpenModelica built: their sources need the Rust
# runtime, which FMPy cannot compile.
FMU = FmuExportCrossCompile.fmu \
      RoomHeating_OM_RH.fmu \
      WaterTank_Control.fmu \
      WaterTank_TestSingleWaterTank.fmu \
      BouncingBall.fmu

# Exported with --simCodeTarget=C.old, whose sources are plain C, and re-compiled
# by FMPy.
SOURCE_FMU = TableTest.fmu

.PHONY: all test clean copy $(FMU) $(SOURCE_FMU)

all: compile_FMUs
	$(MAKE) test

test: $(FMU) $(SOURCE_FMU)

copy:
	cp ../FmuExportCrossCompile/*.fmu .

$(FMU): copy
	@echo -----------------------------------------------------------------------
	@echo $@
	$(FMPY_CALL) simulate $@
	@echo -----------------------------------------------------------------------

$(SOURCE_FMU):
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
	rm -f $(FMU) $(SOURCE_FMU) *.fmu
	rm -rf $(addsuffix _FMU/,$(FMU) $(SOURCE_FMU))
	rm -rf TableTest/
