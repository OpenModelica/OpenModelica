export PRJDIR=$(PWD)/..
include $(PRJDIR)/Build/MakeConf.inc
.PHONY: all
all: \
	Math \
	Solver \
	Euler \
	SettingsFactory \
	System \
	Newton \
	Modelica \
	Main \
	
.PHONY: Main
Main: System Math Newton Solver Euler SettingsFactory 
	$(MAKE) -f $(SRCDIR)/SimManager/Main.mak
	$(MAKE) copy

.PHONY: ReduceDAE
ReduceDAE: System Math Newton Solver Euler SettingsFactory 
	$(MAKE) -f $(SRCDIR)/ReduceDAE/Implementation/ReduceDAE.mak
	$(MAKE) copy
ifeq ($(PLT),mingw)
	cp -u -v $(SRCDIR)/ReduceDAE/Interfaces/ReduceDAESettings.xml $(BINPATH)/config
	cp -u -v $(MICOPATH)/mico2313.dll $(BINPATH)
	
	
else ifeq ($(PLT),win32)
	xcopy $(SRCDIRWIN32)\ReduceDAE\Interfaces\ReduceDAESettings.xml $(BINPATHWIN32)\config\  /D /F /Y
	xcopy $(MICOPATHWIN32)\mico2313.dll $(BINPATHWIN32)  /D /F /Y
endif

.PHONY: Math
Math: 
	$(MAKE) -f  $(SRCDIR)/Math/Math.mak
	
.PHONY: System
System: 
	$(MAKE) -f $(SRCDIR)/System/Implementation/System.mak

.PHONY: Newton
Newton: 
	$(MAKE) -f $(SRCDIR)/System/Newton/Implementation/Newton.mak

.PHONY: Modelica
Modelica: 
	$(MAKE) -f $(SRCDIR)/System/Modelica/Modelica.mak

.PHONY: SettingsFactory
SettingsFactory: 
	$(MAKE) -f $(SRCDIR)/SettingsFactory/Implementation/SettingsFactory.mak

.PHONY: Euler
Euler: 
	$(MAKE) -f $(SRCDIR)/Solver/Euler/Implementation/Euler.mak

.PHONY: Solver
Solver:
	$(MAKE) -f $(SRCDIR)/Solver/Implementation/Solver.mak
	
.PHONY: clean
clean:
	cd $(SRCDIR)/SimulationRuntime/ && $(MAKE) -f Main.mak clean
	cd $(SRCDIR)/Math/ && $(MAKE) -f Math.mak clean
	cd $(SRCDIR)/System/Implementation/ && $(MAKE) -f System.mak clean
	cd $(SRCDIR)/System/Newton/Implementation/ && $(MAKE) -f Newton.mak clean
	cd $(SRCDIR)/System/Modelica/ && $(MAKE) -f Modelica.mak clean
	cd $(SRCDIR)/Solver/Implementation/ && $(MAKE) -f Solver.mak clean
	cd $(SRCDIR)/Solver/Euler/Implementation/ && $(MAKE) -f Euler.mak clean
	cd $(SRCDIR)/SettingsFactory/Implementation/ && $(MAKE) -f SettingsFactory.mak clean
	
.PHONY: clear
	cd $(BINPATH) && rm -f *.*
clear: clean
copy:
ifeq ($(PLT),mingw)
	mkdir -p $(BINPATH)
	mkdir -p $(CONFPATH)
	cp -u -r -v $(FORTRANPATH)/libifcoremd.dll $(BINPATH)/
	cp -u -r -v $(FORTRANPATH)/libmmd.dll $(BINPATH)/
	cp -u -r -v $(BOOSTPATH)/libboost_serialization-mgw34-mt-1_45.* $(BINPATH)
	cp -u -v $(SRCDIR)/SettingsFactory/Interfaces/GlobalSettings.xml $(CONFPATH)
	cp -u -v $(SRCDIR)/Solver/Euler/Interfaces/EulerSettings.xml $(CONFPATH)
	cp -u -v $(TMPBINPATH)/SimModel.exe  $(BINPATH)
	cp -u -v $(TMPBINPATH)/DAESolver.dll $(BINPATH)
	cp -u -v $(TMPBINPATH)/DAESystem.dll  $(BINPATH)
	cp -u -v $(TMPBINPATH)/Euler.dll  $(BINPATH)
	cp -u -v $(TMPBINPATH)/Newton.dll  $(BINPATH)
	cp -u -v $(TMPBINPATH)/SettingsFactory.dll  $(BINPATH)
	cp -u -v $(TMPBINPATH)/libMath.a  $(LIBPATH)
	cp -u -v $(MINGW)/mingwm10.dll $(BINPATH)\
	
else ifeq ($(PLT),win32)
	xcopy $(BOOSTPATHWIN32)\libboost_serialization-mgw34-mt-1_45.* $(BINPATHWIN32)\   /F /Y /I
	xcopy $(FORTRANWIN32)\libifcoremd.dll $(BINPATHWIN32)\  /F /Y /I
	xcopy $(FORTRANWIN32)\libmmd.dll $(BINPATHWIN32)\   /F /Y /I
	xcopy $(TMPBINPATHWIN32)\SimModel.exe  $(BINPATHWIN32)\   /F /Y /I
	xcopy $(TMPBINPATHWIN32)\DAESolver.dll $(BINPATHWIN32)\   /F /Y /I
	xcopy $(TMPBINPATHWIN32)\DAESystem.dll  $(BINPATHWIN32)\   /F /Y /I
	xcopy $(TMPBINPATHWIN32)\Euler.dll  $(BINPATHWIN32)\   /F /Y /I
	xcopy $(TMPBINPATHWIN32)\Newton.dll  $(BINPATHWIN32)\   /F /Y /I
	xcopy $(TMPBINPATHWIN32)\SettingsFactory.dll  $(BINPATHWIN32)\   /F /Y /I
	xcopy $(TMPBINPATHWIN32)\libMath.a  $(LIBPATHWIN32)\   /F /Y /I
	xcopy $(MINGW32)\mingwm10.dll $(BINPATHWIN32)\   /F /Y /I
	xcopy $(SRCDIRWIN32)\SettingsFactory\\Interfaces\GlobalSettings.* $(CONFPATHWIN32)\  /F /Y /I
	xcopy $(SRCDIRWIN32)\Solver\\Euler\Interfaces\EulerSettings.xml $(CONFPATHWIN32)\  /F /Y /I
endif

