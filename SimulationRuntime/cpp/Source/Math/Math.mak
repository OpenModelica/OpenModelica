include $(PRJDIR)/Build/MakeConf.inc

Math:  $(SRCDIR)/Math/Implementation/Functions.cpp  $(SRCDIR)/Math/Implementation/Functions.h
	@echo " "
	@echo "--------- Making $(LIBMATH) ----------------"
	$(CC)  $(CFLAGS) -I"$(SRCDIR)/3rdParty/boost_1_45_0" -o $(TMPBINPATH)/Math.o $(SRCDIR)/Math/Implementation/ArrayOperations.cpp 
	$(AR) rcs $(LIBMATH) $(TMPBINPATH)/Math.o 
	
clean:
	rm -f Math
	rm -f $(TMPBINPATH)/Math.o