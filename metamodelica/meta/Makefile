# BuiltinReal.mos fails when using Cevalfunc.mo! the values are OK, the display is different!
TEST = ../../rtest -v

TESTFILES = \
AlgPatternm.mos \
AllWild.mos \
ArraySubscripting.mos \
AssignMatchVar.mos \
AssignMetaRecordField.mos \
BuiltinArray.mos \
BuiltinBoolean.mos \
BuiltinInteger.mos \
BuiltinList.mos \
BuiltinMisc.mos \
BuiltinReal.mos \
BuiltinString.mos \
CheckPatternScope.mo \
ComplicatedInteractive.mos \
Continue.mo \
cref.mos \
Equality.mos \
EqPatternm.mos \
ErrorInteractiveCallFunctionPtr.mos \
ErrorInvalidComplexType.mo \
ErrorInvalidMetarecord.mo \
ErrorInvalidPattern1.mo \
ErrorInvalidPattern2.mo \
ErrorInvalidPattern3.mo \
ErrorLocalElement1.mo \
ErrorLocalElement2.mo \
ErrorLocalElement3.mo \
ErrorMatchInOut1.mo \
ErrorMatchNumOutput.mos \
ErrorNone.mos \
Failure.mos \
ForIterList.mos \
ForIterArray.mos \
FunctionPartialApplicationAsGeneralExp.mos \
FunctionReturningArray.mos \
InvalidWild1.mos \
IsPresent.mos \
List1.mos \
List2.mos \
List3.mos \
List4.mo \
List5.mo \
ListInteractive.mos \
ListReductionCodegen.mo \
ListReductionDimError.mo \
ListReductionInterpret.mo \
MatchCase1.mos \
MatchCase2.mos \
MatchCase3.mos \
MatchCase4.mos \
MatchCase5.mos \
MatchCase6.mos \
MatchCase7.mos \
MatchCase8.mos \
MatchCase9.mos \
MatchCase10.mos \
MatchCase11.mos \
MatchCase12.mos \
MatchCase13.mos \
MatchCase14.mo \
MatchCase15.mo \
MatchCase16.mo \
MatchCase17.mo \
MatchCaseGuard.mos \
MatchCaseInteractive1.mos \
MatchCaseInteractive2.mos \
MatchCaseInteractive3.mos \
MatchDotNotation.mos \
MatchElse1.mos \
MatchIfEquation1.mos \
MatchNoRetCall.mos \
MatchShadowing.mo \
OptimizeContinue.mo \
OptimizeMatchToIfExp.mo \
OptionInteractive.mos \
PartialFn1.mo \
PartialFn2.mo \
PartialFn3.mos \
PartialFn4.mo \
PartialFn5.mo \
PartialFn6.mo \
PartialFn7.mo \
PartialFn8.mos \
PartialFn9.mos \
PartialFn10.mos \
PartialFn11.mos \
PartialFn12.mos \
PartialFn13.mos \
PartialFn14.mos \
PartialFn15.mo \
PartialFn16.mos \
PartialFnDefaultBinding.mos \
PatternMatchInvalidType.mo \
Polymorphic.mos \
Polymorphic2.mos \
PolymorphicReduction.mos \
Recursive.mos \
ReturnInTryBlock.mos \
ScalarArrayOperations.mos \
Shadowing1.mos \
Shadowing2.mos \
Simplify1.mos \
StringBoxed.mos \
SwitchString.mos \
TailRecursion.mo \
TailRecursionNoretcall.mos \
Ticket2974.mos \
Ticket3005.mos \
ThreadedReduction.mos \
Try.mos \
TryExtends.mos \
TupleInteractive.mos \
UnboundLocal.mo \
UnboxCond.mo \
Uniontype1.mos \
Uniontype2.mos \
Uniontype3.mos \
Uniontype4.mos \
Uniontype5.mos \
Uniontype6.mos \
Uniontype7.mos \
Uniontype8.mos \
Uniontype9.mos \
Uniontype10.mos \
Uniontype11.mos \
Uniontype12.mos \
Uniontype13.mos \
Uniontype14.mos \
Uniontype15.mos \
UniontypeFunc1.mos

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES= \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
PartialFn6.ext_f.c \
compilelog.txt

CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps failingtest

test:
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
	@$(TEST) $(FAILINGTESTFILES)
