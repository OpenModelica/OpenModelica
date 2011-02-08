include $(PRJDIR)/Build/MakeConf.inc
	
Euler: $(SRCDIR)/Solver/Euler/Implementation/Euler.cpp  $(SRCDIR)/Solver/Euler/Implementation/EulerSettings.cpp
	@echo " "
	@echo "--------- Making $(LIBEULER) ----------------"
	$(CC)  $(CFLAGS) -c $(INCLUDES) -o $(TMPBINPATH)/EulerSettings.o $(SRCDIR)/Solver/Euler/Implementation/EulerSettings.cpp
	$(CC)  $(CFLAGS) -c $(INCLUDES) -o $(TMPBINPATH)/Euler.o $(SRCDIR)/Solver/Euler/Implementation/Euler.cpp
	$(CC) -shared  -o $(LIBEULER) $(TMPBINPATH)/Euler.o $(TMPBINPATH)/EulerSettings.o $(LIBBOOST) -lboost_serialization-mgw34-mt-1_45  -L$(TMPBINPATH)/ -lDAESolver  -L$(FORTRANPATH) -lifcoremd -L$(LAPACKPATH) -lBlasSource -lLapackSource -Wl
	
clean:
	rm -f Euler
	rm -f $(TMPBINPATH)/Euler.o
	rm -f $(TMPBINPATH)/EulerSettings.o