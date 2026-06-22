TEST = ../../../../rtest -v

TESTFILES = \
array_start_vector.mos \
BenchmarksForResizeableArrays.ArrayEquations.CascadedFirstOrder1.mos \
BenchmarksForResizeableArrays.ArrayEquations.CascadedFirstOrder2.mos \
BenchmarksForResizeableArrays.ArrayEquations.CascadedFirstOrder3.mos \
BenchmarksForResizeableArrays.ArrayEquations.CascadedFirstOrder4.mos \
BenchmarksForResizeableArrays.ArrayEquations.WaterHammer.mos \
BenchmarksForResizeableArrays.ArrayEquationsWithIndexReduction.SlidingMass3D.mos \
BenchmarksForResizeableArrays.ComponentArrays.FiltersInSeries.mos \
BenchmarksForResizeableArrays.ComponentArrays.TransmissionLine.mos \
BenchmarksForResizeableArrays.ErrorsIfArraysNotExpanded.LinearSystemOfEquations.mos \
BenchmarksForResizeableArrays.ErrorsIfArraysNotExpanded.MixedAlgebraicAndStatesArray.mos \
BenchmarksForResizeableArrays.ErrorsIfArraysNotExpanded.WrongNumberOfArrayEquations.mos \
BenchmarksForResizeableArrays.ErrorsIfArraysNotExpandedCorrected.FailedConsistencyCheckCorrected.mos \
BenchmarksForResizeableArrays.ForLoops.CascadedFirstOrder.mos \
BenchmarksForResizeableArrays.ForLoops.CocurrentHeatExchanger.mos \
BenchmarksForResizeableArrays.Resizable.CascadedFirstOrder_Resizable.mos \
BenchmarksForResizeableArrays.Resizable.CascadedFirstOrder1_Resizable.mos \
BenchmarksForResizeableArrays.Resizable.CascadedFirstOrder2_Resizable.mos \
BenchmarksForResizeableArrays.Resizable.CascadedFirstOrder3_Resizable.mos \
BenchmarksForResizeableArrays.Resizable.CascadedFirstOrder4_Resizable.mos \
BenchmarksForResizeableArrays.Resizable.FiltersInSeries_Resizable.mos \
diagonal_slice_for.mos \
EnumIndex.mos \
exemplary.mos \
for_exp.mos \
for_if.mos \
for_list.mos \
irregular_for.mos \
matrix_vector_product.mos \
MultiDimensionalArrays1.mos \
MultiDimensionalArrays2.mos \
MultiDimensionalArrays3.mos \
MultiDimensionalArrays4.mos \
Resizable_HeatTransfer_equations.mos \
scalar_product.mos \
simple_der_for.mos \
simple_for.mos \
simple_nested_for.mos \
slice_for.mos \
subscripted_expression.mos \
testVectorizedPowerSystem.mos \
testVectorizedSolarSystem.mos \

# test that currently fail. Move up when fixed.
# Run make failingtest
FAILINGTESTFILES = \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
ReferenceFiles \

CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps failingtest

test:
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES)

# Cleans all files that are not listed as dependencies
clean:
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

failingtest:
	@echo
	@echo Running failing tests...
	@echo
	@$(TEST) $(FAILINGTESTFILES)
