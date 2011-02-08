include $(PRJDIR)/Build/MakeConf.inc

System: $(SRCDIR)/System/Implementation/AlgLoopDefaultImplementation.cpp $(SRCDIR)/System/Implementation/AlgLoopSolverFactory.cpp $(SRCDIR)/System/Implementation/EventHandling.cpp $(SRCDIR)/System/Implementation/SystemDefaultImplementation.cpp
	@echo " "
	@echo "--------- Making $(LIBDAESYSTEM) ----------------"
	$(CC) -c $(INCLUDES) -o $(TMPBINPATH)/AlgLoopDefaultImplementation.o $(SRCDIR)/System/Implementation/AlgLoopDefaultImplementation.cpp
	$(CC) -c $(INCLUDES) -o $(TMPBINPATH)/AlgLoopSolverFactory.o $(SRCDIR)/System/Implementation/AlgLoopSolverFactory.cpp 
	$(CC) -c $(INCLUDES) -o $(TMPBINPATH)/EventHandling.o $(SRCDIR)/System/Implementation/EventHandling.cpp
	$(CC) -c $(INCLUDES) -o $(TMPBINPATH)/SystemDefaultImplementation.o $(SRCDIR)/System/Implementation/SystemDefaultImplementation.cpp
	$(CC) -shared  -o $(LIBDAESYSTEM) $(TMPBINPATH)/AlgLoopDefaultImplementation.o $(TMPBINPATH)/AlgLoopSolverFactory.o $(TMPBINPATH)/EventHandling.o  $(TMPBINPATH)/SystemDefaultImplementation.o  -Wl
	
clean:
	rm -f System
	rm -f $(TMPBINPATH)/AlgLoopDefaultImplementation.o
	rm -f $(TMPBINPATH)/AlgLoopSolverFactory.o
	rm -f $(TMPBINPATH)/EventHandling.o
	rm -f $(TMPBINPATH)/SystemDefaultImplementation.o
	