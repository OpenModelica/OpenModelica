include $(PRJDIR)/Build/MakeConf.inc

Newton: $(SRCDIR)/System/Newton/Implementation/Newton.cpp $(SRCDIR)/System/Newton/Implementation/NewtonSettings.cpp
	@echo " "
	@echo "--------- Making $(LIBNEWTON) ----------------"
	$(CC)  $(CFLAGS) -c $(INCLUDES) -o $(TMPBINPATH)/Newton.o $(SRCDIR)/System/Newton/Implementation/Newton.cpp
	$(CC)  $(CFLAGS) -c $(INCLUDES) -o $(TMPBINPATH)/NewtonSettings.o $(SRCDIR)/System/Newton/Implementation/NewtonSettings.cpp
	$(CC) -shared  -o $(LIBNEWTON) $(TMPBINPATH)/Newton.o $(TMPBINPATH)/NewtonSettings.o  -L$(FORTRANPATH) -lifcoremd -L$(LAPACKPATH) -lBlasSource -lLapackSource -Wl
	
	
clean:
	rm -f Newton
	rm -f $(TMPBINPATH)/Newton.o
	rm -f $(TMPBINPATH)/NewtonSettings.o