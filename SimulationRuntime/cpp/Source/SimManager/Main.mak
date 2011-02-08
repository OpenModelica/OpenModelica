include $(PRJDIR)/Build/MakeConf.inc

Main: $(SRCDIR)/SimManager/Main.cpp
	@echo " "
	@echo "--------- Making Main ----------------"
	$(CC) $(CFLAGS) $(INCLUDES) -o $(TMPBINPATH)/Main.o $(SRCDIR)/SimManager/Main.cpp
	$(CC) $(CFLAGS) $(INCLUDES) -o $(TMPBINPATH)/Configuration.o $(SRCDIR)/SimManager/Configuration.cpp
	$(CC) -o $(MAINFILE)  $(TMPBINPATH)/Main.o  $(TMPBINPATH)/Configuration.o   \
	$(LIBBOOST) -lboost_serialization-mgw34-mt-1_45 -Wl 
clean:
	rm -f Main
	rm -f $(TMPBINPATH)/Main.o
	rm -f $(TMPBINPATH)/Configuration.o
