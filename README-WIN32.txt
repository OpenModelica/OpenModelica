---------------------------------------------------------------------------
         How to compile, test and use OMC under Windows
---------------------------------------------------------------------------


             Last update 2005-09-26 David Broman
             Last update 2009-11-10 Adrian Pop
             Last update 2010-04-27 Adrian Pop

The following step-by-step guides explain how to compile the
Open Modelica Compiler using:
- Microsoft Visual Studio 2008
under Windows XP.
See the file:
- README.Cygwin.or.Linux.txt
   for a general overview and how to compile it under a UNIX systems.
- README-OMDev-MINGW.txt
   for a general overview and how to compile it on windows using
   OMDev:http://www.ida.liu.se/~adrpo/omc/omdev/mingw/
   which contains the gcc compiler, mico, antlr, rml packed togheter.

Checkout the sources from Subversion:
   https://openmodelica.org/svn/OpenModelica/trunk -> trunk
   user: anonymous
   pass: none      <- write none here

------------------------------------------------------------------------------------------------
       Compiling OMC using  Microsoft Visual Studio 2008
------------------------------------------------------------------------------------------------

0.  Install MS Visual Studio 2008

1.  Install OMDev from http://www.ida.liu.se/~adrpo/omc/omdev/mingw/
    Do all the steps in trunk\README-OMDev-MINGW.txt
    This is needed to build the simulation runtime.
    We consider OMDev installed into $(OMDEV) environment variable

2.  Get the qt libraries from:
      http://www.ida.liu.se/~adrpo/omc/omdev/qtlibs/
    and unpack them somewhere into OpenModelicaLibs.
    Set environment variables:
    COINDIR=OpenModelicaLibs\coin3d
    QTHOME=OpenModelicaLibs\qt-win-opensource-src-4.4.3

3.  Checkout the VC7 directory from Subversion:
      https://openmodelica.org/svn/OpenModelica/installers/VC7
    into directory:
      trunk\Compiler\VC7
    IMPORTANT: VC7 HAS TO BE CHECKOUT into trunk\Compiler\VC7
               as the Visual Studio projects are based on 
               relative paths.

5.  Open the visual studio solution located at path:
    trunk\Compiler\VC7\omc\omc.sln
    - VS 2008 Express will not be able to build the Setup project
      as there are no deployment projects available in this version.

6. In the VS development environment, select from the menu:
    Build->Configuration Manager and select "Release" as the active
    solution configuration.

7. Press Ctrl-Shift-B to build the whole project.
   If something failed hit Ctrl-Shift-B as it might work the secod time.

8. The compiled libraries and executables are now located under:
    C:\code\omc\trunk\Compiler\VC7\Release and
    C:\code\omc\trunk\build\bin

9. To test omc.exe follow the step 11 in README-OMDev-MINGW.txt

---------------------------------------------------------------------------
                Compiling .mo files and executing .mos scripts
---------------------------------------------------------------------------
To "compile" a .mo file, write the following

  omc example.mo

This command will display the "flatten" Modelica representation
of the model.
It is also possible to create script files where
executable statements are entered. To compile and execute such a
script, use the following command

  omc example.mos


---------------------------------------------------------------------------
                         Running the test suite
---------------------------------------------------------------------------
Follow step 11 from README-OMDev-MINGW.txt.


