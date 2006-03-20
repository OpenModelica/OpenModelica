Compiling OMC using OMDev-mingw package
========================================
Adrian Pop, adrpo@ida.liu.se, 2006-02-01


1. Get the OMDev package from:
   http://www.ida.liu.se/~adrpo/omc/omdev/mingw
   + this package contains all prerequisites
     to compile OMC on Windows using MinGW+MSys

2. Unpack for example into:
   c:\OMDev-mingw\
   + Follow the instructions in the INSTALL file

3. get the sources from Subversion:
   svn co svn://mir20.ida.liu.se/modelica/OpenModelica/trunk/

4. inside the trunk directory you will find a .project-sample
   which you should rename to .project and do whatever modifications
   you need on it

5. rename the file the trunk/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder.launch-sample
   to trunk/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder.launch and do whatever
   modifications are needed on it.

5. Open the OpenModelica project in Eclipse
   and run the OMDev-MINGW-OpenModelicaBuilder (Ctrl+B in general)
   If it doesn't work just edit a file, but back what you edited, 
   save, then CTRL+B.


For problems with OMDev package, contact:
Adrian Pop, 
adrpo@ida.liu.se
           
Last Update:2006-03-20