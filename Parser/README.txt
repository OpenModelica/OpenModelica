A Lexer/Parser for Modelica based on ANTLR3.2
---------------------------------------------
Adrian Pop [adpo@ida.liu.se] 2010-05-04


1. Open ModelicaParser.sln and build the project.

2. To test the parser use -d for directories -f for files.
   adrpo@KAFKA ~/dev/OpenModelica/Parser
   $ time ./Release/ModelicaParser.exe -d ~/dev/OpenModelica/build/ModelicaLibrary/

   adrpo@KAFKA ~/dev/OpenModelica/Parser
   $ time ./Release/ModelicaParser.exe -f FullModelica3.1.mo

There are no Makefiles to build with MinGW or gcc yet, but is rather easy:
$ cd antlr-3.2/runtime/C/src
# build the library
$ gcc -c *.c -I../include
$ ar -ru libantrl3.a *.o
$ ranlib libantrl3.a
# get back to Parser directory
$ cd ../../../../
# genarate the parser code
$ ./runantlr.sh
# build the executable
$ gcc -o ModelicaParser *.c -Iantlr-3.2/runtime/C/include -Lantlr-3.2/runtime/C/src -lantlr3

In the future antlr files will be moved to OMDev.


Cheers,
Adrian Pop/