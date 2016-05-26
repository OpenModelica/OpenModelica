TEST = ../../../../rtest


TESTFILES = \
DrModelicaForTesting.ABCDsystem.mos \
DrModelicaForTesting.Activate.mos \
DrModelicaForTesting.AddSub1.mos \
DrModelicaForTesting.AlgorithmSection.mos \
DrModelicaForTesting.AppendElement.mos \
DrModelicaForTesting.ArrayConstruct1.mos \
DrModelicaForTesting.ArrayDim1.mos \
DrModelicaForTesting.ArrayDim2.mos \
DrModelicaForTesting.ArrayDim3.mos \
DrModelicaForTesting.ArrayDim4.mos \
DrModelicaForTesting.ArrayDiv.mos \
DrModelicaForTesting.ArrayIndex.mos \
DrModelicaForTesting.ArrayMult.mos \
DrModelicaForTesting.ArrayReduce.mos \
DrModelicaForTesting.AssertTest2.mos \
DrModelicaForTesting.AssertTest3.mos \
DrModelicaForTesting.AssertTestInst.mos \
DrModelicaForTesting.BasicVolume1.mos \
DrModelicaForTesting.BasicVolume2.mos \
DrModelicaForTesting.BouncingBall.mos \
DrModelicaForTesting.Circuit.mos \
DrModelicaForTesting.Colors.mos \
DrModelicaForTesting.Concat3.mos \
DrModelicaForTesting.ConcatArr1.mos \
DrModelicaForTesting.ConcatArr2.mos \
DrModelicaForTesting.ConcatArr4.mos \
DrModelicaForTesting.CondAssign.mos \
DrModelicaForTesting.CondAssignFuncCall.mos \
DrModelicaForTesting.ConstructFunc.mos \
DrModelicaForTesting.DimConvert.mos \
DrModelicaForTesting.DVSSTest.mos \
DrModelicaForTesting.ElementWiseMultiplication.mos  \
DrModelicaForTesting.Engine.mos \
DrModelicaForTesting.Epidemics1.mos \
DrModelicaForTesting.EqualityEquationsCorrect.mos \
DrModelicaForTesting.EquationCall.mos \
DrModelicaForTesting.Equations.mos \
DrModelicaForTesting.Exp.mos \
DrModelicaForTesting.fCall.mos \
DrModelicaForTesting.FilterBlock1.mos \
DrModelicaForTesting.FiveForEquations.mos \
DrModelicaForTesting.FlatTank.mos \
DrModelicaForTesting.FuncDer.mos \
DrModelicaForTesting.getPerson.mos \
DrModelicaForTesting.HelloWorld.mos \
DrModelicaForTesting.HideVariableForEquations.mos \
DrModelicaForTesting.HydrogenIodide.mos \
DrModelicaForTesting.LogCall1.mos \
DrModelicaForTesting.LotkaVolterra.mos \
DrModelicaForTesting.ModifiedFiltersInSeries.mos \
DrModelicaForTesting.MoonLanding.mos \
DrModelicaForTesting.MRFcall.mos \
DrModelicaForTesting.MultFuncCall.mos \
DrModelicaForTesting.NamedCall.mos \
DrModelicaForTesting.OneReturnValue.mos \
DrModelicaForTesting.PolyEvaluate1.mos \
DrModelicaForTesting.PolyEvaluate2.mos \
DrModelicaForTesting.PolynomialEvaluator2.mos \
DrModelicaForTesting.PositionalCall.mos \
DrModelicaForTesting.RangeVector.mos \
DrModelicaForTesting.Sampler.mos \
DrModelicaForTesting.SampleSignalGenerator.mos \
DrModelicaForTesting.WhenStat.mos \
DrModelicaForTesting.WhenStat2.mos \
DrModelicaForTesting.Step.mos \
DrModelicaForTesting.SumVector.mos \
DrModelicaForTesting.SumZ.mos \
DrModelicaForTesting.Test.mos \
DrModelicaForTesting.VanDerPol.mos \
DrModelicaForTesting.WatchDogSystem1.mos \
DrModelicaForTesting.WatchDogSystem2.mos \
DrModelicaForTesting.WaveEquationSample.mos \
DrModelicaForTesting.WhenEquation.mos \
DrModelicaForTesting.WhenPriority.mos \
DrModelicaForTesting.WhenSet.mos \
DrModelicaForTesting.Xpowers1.mos \
DrModelicaForTesting.Xpowers2.mos \
DrModelicaForTesting.Xpowers3.mos \

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES=  \
DrModelicaForTesting.AddEmpty.mos \
DrModelicaForTesting.DAEexample.mos \
DrModelicaForTesting.DoubleWhenSequential.mos \
DrModelicaForTesting.BasicVolume3.mos \
DrModelicaForTesting.HideVariable.mos \
DrModelicaForTesting.PopulationGrowth.mos \
DrModelicaForTesting.SimpleValveFlow.mos \
DrModelicaForTesting.SynchCounters.mos \
DrModelicaForTesting.TwoRateSampler.mos \
DrModelicaForTesting.WhenStat3.mos \
DrModelicaForTesting.WhenValidResult.mos \
DrModelicaForTesting.KyenesianModel.mos \


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
 *.mo \
 *.mos \
 Makefile \
 ReferenceFiles



CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps

test :
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES)

# Cleans all files that are not listed as dependencies
clean :
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@rm -f $(CLEAN)

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



