# A collection of libraries that can be tested, but are not enabled by default (since they are usually not installed by developers)

TEST = ../../../../rtest -v

TESTFILES = \
Modelica_Synchronous.Examples.SimpleControlledDrive.Continuous.mos \
Modelica_Synchronous.Examples.SimpleControlledDrive.ClockedWithDiscreteTextbookController.mos \
Modelica_Synchronous.Examples.SimpleControlledDrive.ClockedWithDiscreteController.mos \
Modelica_Synchronous.Examples.CascadeControlledDrive.Continuous.mos \
Modelica_Synchronous.Examples.Systems.Utilities.ComponentsMixingUnit.MixingUnitWithContinuousControl.mos \
Modelica_Synchronous.Examples.Elementary.ClockSignals.ShiftSample.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.TimeBasedStep.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.TickBasedStep.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.TimeBasedSine.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.TimeBasedRamp.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.TickBasedRamp.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.TimeBasedStep.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.TickBasedStep.mos \


# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES=  \
Modelica_Synchronous.Examples.SimpleControlledDrive.ExactlyClockedWithDiscreteController.mos \
Modelica_Synchronous.Examples.SimpleControlledDrive.ClockedWithDiscretizedContinuousController.mos \
Modelica_Synchronous.Examples.SimpleControlledDrive.ClockedWith_AD_DA_Effects.mos \
Modelica_Synchronous.Examples.CascadeControlledDrive.SubClocked.mos \
Modelica_Synchronous.Examples.CascadeControlledDrive.SuperSampled.mos \
Modelica_Synchronous.Examples.CascadeControlledDrive.AbsoluteClocks.mos \
Modelica_Synchronous.Examples.Systems.ControlledMixingUnit.mos \
Modelica_Synchronous.Examples.Systems.EngineThrottleControl.mos \
Modelica_Synchronous.Examples.Elementary.ClockSignals.SubSample.mos \
Modelica_Synchronous.Examples.Elementary.ClockSignals.SuperSample.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.Sample1.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.Sample2.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.Sample3.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.SampleClocked.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.SampleVectorizedAndClocked.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.SampleWithADeffects.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.HoldWithDAeffects1.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.HoldWithDAeffects2.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.SubSample.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.SuperSample.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.SuperSampleInterpolated.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.ShiftSample.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.BackSample.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.AssignClock.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.AssignClockVectorized.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.UpSample1.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.UpSample2.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.AssignClockToTriggerHold.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.AssignClockToSquareWaveHold.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.UniformNoise.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.FractionalDelay.mos \
Modelica_Synchronous.Examples.Elementary.RealSignals.TickBasedSine.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.Sample1.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.Sample2.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.SampleClocked.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.SampleVectorizedAndClocked.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.Hold.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.SubSample.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.SuperSample.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.ShiftSample.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.BackSample.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.AssignClock.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.AssignClockVectorized.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.UpSample.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.TimeBasedStep.mos \
Modelica_Synchronous.Examples.Elementary.IntegerSignals.TickBasedStep.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.Sample1.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.Sample2.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.SampleClocked.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.SampleVectorizedAndClocked.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.Hold.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.SubSample.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.SuperSample.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.ShiftSample.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.BackSample.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.AssignClock.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.AssignClockVectorized.mos \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.UpSample \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.TimeBasedPulse \
Modelica_Synchronous.Examples.Elementary.BooleanSignals.TickBasedPulse \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
 *.mo \
 *.mos \
 *.mat \
 Makefile \
 ReferenceFiles \
 simulateAll.sh \
 simulateAll.cmd \
 sortResults.py


CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps failingtest

test :
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES)

# Cleans all files that are not listed as dependencies
clean :
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@rm -f *.mos.txt
	@rm -rf $(CLEAN)

# Run this if you want to list out the files (dependencies).
# do it after cleaning and updating the folder
# then you can get a list of file names (which must be dependencies
# since you got them from repository + your own new files)
# then add them to the DEPENDENCIES. You can find the
# list in deps.txt
getdeps:
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@echo $(CLEAN) | sed -r 's/deps.txt|deps.tmp//g' | sed 's/ / \\\n/g' > deps.txt
	@echo Dependency list saved in deps.txt.
	@echo Copy the list from deps.txt and add it to the Makefile @DEPENDENCIES

failingtest :
	@echo
	@echo Running failing tests...
	@echo
	@$(TEST) $(FAILINGTESTFILES) \
