include $(PRJDIR)/Build/MakeConf.inc

Solver: $(SRCDIR)/SettingsFactory/Implementation/GlobalSettings.cpp $(SRCDIR)/SettingsFactory/Implementation/Factory.cpp
	@echo " "
	@echo "--------- Making $(LIBSETTINGSFACTORY) ----------------"
	$(CC) -DWIN32 $(CFLAGS) -c $(INCLUDES) -o $(TMPBINPATH)/GlobalSettings.o   $(SRCDIR)/SettingsFactory/Implementation/GlobalSettings.cpp 
	$(CC) -DWIN32 $(CFLAGS) -c $(INCLUDES) -o $(TMPBINPATH)/Factory.o   $(SRCDIR)/SettingsFactory/Implementation/Factory.cpp
	$(CC) -shared -o $(LIBSETTINGSFACTORY) $(TMPBINPATH)/GlobalSettings.o $(TMPBINPATH)/Factory.o  $(LIBBOOST) -lboost_serialization-mgw34-mt-1_45 -Wl 


clean:
	rm -f SettingsFactory
	rm -f $(TMPBINPATH)/Factory.o
	rm -f $(TMPBINPATH)/GlobalSettings.o