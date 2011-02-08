include $(PRJDIR)/Build/MakeConf.inc

Solver: $(SRCDIR)/Solver/Implementation/SolverDefaultImplementation.cpp
	@echo " "
	@echo "--------- Making $(LIBDAESOLVER) ----------------"
	$(CC)  $(CFLAGS) -c $(INCLUDES) -o $(TMPBINPATH)/SolverDefaultImplementation.o $(SRCDIR)/Solver/Implementation/SolverDefaultImplementation.cpp
	$(CC)  $(CFLAGS) -c $(INCLUDES) -o $(TMPBINPATH)/SolverSettings.o $(SRCDIR)/Solver/Implementation/SolverSettings.cpp
	$(CC) -shared  -o $(LIBDAESOLVER) $(TMPBINPATH)/SolverDefaultImplementation.o $(TMPBINPATH)/SolverSettings.o -Wl

clean:
	rm -f Solver
	rm -f $(TMPBINPATH)/SolverDefaultImplementation.o
	rm -f $(TMPBINPATH)/SolverSettings.o