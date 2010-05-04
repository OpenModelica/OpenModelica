A Lexer/Parser for Modelica based on ANTLR3.2
---------------------------------------------
Adrian Pop [adpo@ida.liu.se] 2010-05-04

Visual Studio:
1. Open ModelicaParser.sln and build the project.
2. To test the parser use -d for directories -f for files.
   adrpo@KAFKA ~/dev/OpenModelica/Parser
   $ time ./Release/ModelicaParser.exe -d ~/dev/OpenModelica/build/ModelicaLibrary/
   adrpo@KAFKA ~/dev/OpenModelica/Parser
   $ time ./Release/ModelicaParser.exe -f FullModelica3.1.mo

MinGW GCC /Linux GCC
$ make clean all test

In the future antlr files will be moved to OMDev.


Cheers,
Adrian Pop/