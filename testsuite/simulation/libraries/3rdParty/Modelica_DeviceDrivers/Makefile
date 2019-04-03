# A collection of libraries that can be tested, but are not enabled by default (since they are usually not installed by developers)

TEST = ../../../../rtest -v

TESTFILES = \
Modelica_DeviceDrivers.Blocks.Examples.TestSerialPackager.mos \
Modelica_DeviceDrivers.Blocks.Examples.TestSerialPackager_String.mos \
Modelica_DeviceDrivers.Blocks.Examples.TestSerialPackager_ExternalTrigger.mos \

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES=  \
Modelica_DeviceDrivers.ClockedBlocks.Examples.TestSerialPackager.mos \
Modelica_DeviceDrivers.ClockedBlocks.Examples.TestSerialPackager_String.mos \

# 2017-05-31 bthiele: MDD specific manual tests
# The problem with the cases below is, that they open sockets and if
# executed in parallel, this will fail due to the same address being already in use.
# There is also a source of indeterminism due to UDP communication delays.
# Don't know yet how to provide good automatic regression tests for these and for
# similar guys (the hardware related tests of MDD are difficult to automatize).
MANUALTESTFILES=  \
Modelica_DeviceDrivers.Blocks.Examples.TestSerialPackager_UDP.mos \
Modelica_DeviceDrivers.Blocks.Examples.TestSerialPackager_UDPExternalTrigger.mos \
Modelica_DeviceDrivers.Blocks.Examples.TestSerialPackager_UDPAutoBufferSize.mos \


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

manualtest :
	@echo
	@echo Running manual tests...
	@echo
	@$(TEST) $(MANUALTESTFILES) \
