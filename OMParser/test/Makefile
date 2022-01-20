
EXT=.exe

CFLAGS=-O3
CXXFLAGS=$(CFLAGS) -I../install/include/antlr4-runtime -I../ -std=c++11 -DANTLR4CPP_STATIC
LDFLAGS=-L../install/lib -L../  -Bstatic -lOMParser -lantlr4-runtime -lstdc++ -Bdynamic -static-libgcc

all: mp$(EXT) runtest

mp$(EXT):
	$(CXX) -static main.cpp -o mp$(EXT) $(CXXFLAGS) $(LDFLAGS)

runtest: mp$(EXT)
	time ./mp$(EXT) msl.mo > trace.txt


clean:
	rm -rf mp$(EXT) trace.txt