---------------------------------------------------------------------------
         How to compile, test and use OMC under Windows
---------------------------------------------------------------------------
           
             Last update 2005-09-26 David Broman
             Last update 2006-04-11 Adrian Pop

The following step-by-step guides explain how to compile the 
Open Modelica Compiler using RML and Microsoft Visual Studio .NET 2003
under Windows XP. See the file README for a general overview and how
to compile it under a UNIX systems.


---------------------------------------------------------------------------
       Compiling OMC using  Microsoft Visual Studio .NET 2003
---------------------------------------------------------------------------

1.  Download and unzip the OMC source code tree. In this example, it
    will be located at: c:\code\omc\trunk\

2.  Install MS Visual Studio .NET 2003

3.  Download Mico, a free CORBA implementation:
    http://www.mico.org/. The latest tested version was 2.3.11 but 
                          it should work also with  2.3.12
    Unzip the files into a folder, such as c:\code\mico

4.  - Open the MS Visual Studio command prompt by using the start menu:
      Start->Microsoft Visual Studio .NET 2003->Visual Studio .NET tools->
        Visual Studio .NET Command Prompt.  
    - Change directory:
        cd c:\code\mico  
    - Compile the mico library
        nmake /f Makefile.win32

5.  Make sure that a java runtime environment is installed and
    available in the path. Run "java -version" in the command line 
    prompt to see that you have a version 1.4 or later.

6.  Download the latest RML-compiler from 
    http://www.ida.liu.se/~pelab/rml/. Download the
    binary cygwin version and unzip it to a folder, such as:
    C:\code\rml-mmc-2.3.5-cygwin-mingw. 
    The latest OpenModelica compiles only with 
    rml-mmc version 2.3.5 and above.

7.  Download ANTLR from http://www.antlr.org/download.html
    Download the source distribution and unzip it to a folder, such as:
    C:\code\antlr-2.7.5. 
    The latest tasted version was 2.7.5

8.  In the windows control panel, select "system". Select the "Advanced"
    tab and click on the button "Environment Variables". Create the following
    system variables (using the paths that you selected when installing
    the above program and libraries.
     RMLHOME=C:\code\rml-2.3.0-cygwin\x86-cygwin-gcc\
     ANTLRHOME=C:\code\antlr-2.7.5\     
     MICOHOME=C:\code\mico\
     CLASSPATH=C:\code\antlr-2.7.5\antlr-2.7.5.jar
    Note that the paths MUST end with a back-slash. The classpath can of course
    include other java libraries as well.
 
9.  Open the visual studio solution located at path:
    trunk\Compiler\VC7\omc\modeq.sln

10. In the VS development environment, select from the menu:
    Build->Configuration Manager and select "Release" as the active
    solution configuration.

11. Press Ctrl-Shift-B to build the whole project.

12. The compiled libraries and executables are now located under:
    C:\code\omc\trunk\Compiler\VC7\Release

13. Set the following system environment variable (see item 8):
     OPENMODELICAHOME=C:\code\omc\trunk\build\
    This is the main path used by the compiler to located runtime files etc.

14. Unzip the file C:\code\omc\trunk\Compiler\VC7\Setup\mingw.tar.gz to
    OPENMODELICAHOME path, i.e. in this case a folder
    C:\code\omc\trunk\MinGW will be created. This is a C compiler used  
    by the Modelica runtime environment.

15. Open a command prompt and change to the following directory:
      cd C:\code\omc\trunk\c_runtime
    Run the following batch file to build runtime simulation libraries.
      build_mingw_libs.bat

16. Unzip the file C:\code\omc\trunk\Compiler\VC7\Setup\ModelicaLib.tar.gz to
    OPENMODELICAHOME path, i.e. in this case a folder
    C:\code\omc\trunk\ModelicaLibrary will be created. This is the Modelica
    standard library.

17. For the compiler to be able to find the standard library, we have to set
    the following environment variable:
    MODELICAPATH=C:\code\omc\trunk\ModelicaLibrary


18. If all compiling steps in the above instructions were successful,
    we have now build the following executables and libraries:
 
     Under C:\code\omc\trunk\Compiler\VC7\Release\
       omc.exe  - The Open Modelica Compiler
     
     Under C:\code\omc\trunk\WinMosh\Release
       WinMosh.exe - The corba client for interactive session handling.

     Under C:\code\mico\win32-bin
       mico2311.dll - the Mico corba runtime library
  
    Add the above paths to your global PATH, or copy the files into
    a directory which is located in the path.


---------------------------------------------------------------------------
                 Using the interactive session handler
---------------------------------------------------------------------------
The OpenModelica environment includes an interactive session handler
where expressions can be evaluated interactively. The architecture
is build on the client-server model, where omc.exe (the OpenModelica
compiler) acts as an runtime server. The client, WinMosh.exe, is a terminal 
application, which communicates with omc.exe using a CORBA interface. To be
able to use the interactive session handler, we first have to start the
server. Open a new command prompt and write the following line:

   omc +d=interactiveCorba

Then, open a new command prompt and write the following command to start the 
terminal

   winmosh

It is now possible to type in expressions and assignments directly in the 
terminal window. For example:

  >> x := 2:8
  
writes out the following output
  
  {2,3,4,5,6,7,8}

i.e. it creates an array that contain 7 elements and stores them in a 
variable x. To get help for available commands, please type:

  help()



---------------------------------------------------------------------------
                Compiling .mo files and executing .mos scripts
---------------------------------------------------------------------------
To "compile" a .mo file, write the following

  omc example.mo

This command will display the "flattern" Modelica representation 
of the model. 
It is also possible to create script files where
executable statements are entered. To compile and execute such a
script, use the following command
 
  omc example.mos


---------------------------------------------------------------------------
                         Running the test suite
---------------------------------------------------------------------------
To automate the testing of the compiler, a test suite is available
under C:\code\omc\trunk\testsuite. To be able to run this testsuite, 
the cygwin environment must be installed. Do the following to 
execute the test suite:
1. Install cygwin from www.cygwin.org 
2. Set the OPENMODELICAHOME=/cygdrive/c/code/omc/trunk/build
3. Set up the cygwin path to the build directory in omc, i.e.
   /code/omc/trunk/build/bin
4. The omc.exe we have build must be copied to the compiler directory.
   Copy the following two files:
      C:\code\omc\trunk\Compiler\VC7\Release\omc.exe
      C:\code\mico\win32-bin\mico2311.dll
   to 
      C:\code\omc\trunk\build\bin
5. Go to folder /trunk/testsuite/ and run "make".



