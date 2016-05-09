# Compiling OMC using OMDev package

- Checkout the OMDev package from Subversion:
  https://openmodelica.org/svn/OpenModelicaExternal/trunk/tools/windows/OMDev
  + this package contains all prerequisites to compile OMC on Windows using MinGW+MSys
  + NOTE THAT YOU MUST UPDATE THIS PACKAGE IF YOU CANNOT COMPILE OpenModelica any longer!
- Make sure you place the OMDev package into:
  c:\OMDev\
  + Follow the instructions in the c:\OMDev\INSTALL.txt file
- You should have an OpenModelica directory you got from OpenModelica GIT repository
  https://github.com/OpenModelica/OpenModelica
- You could use msys or eclipse to build OMC. Follow the instructions in **Compiling OMC using MSYS** or **Compiling OMC using Eclipse**.

## Compiling OMC using MSYS

- For 32-bit OMC start $OMDEV\tools\msys\mingw32_shell.bat and for 64-bit OMC start $OMDEV\tools\msys\mingw64_shell.bat
```bash
cd \path\to\OpenModelica
make -f Makefile.omdev.mingw -j8
```

## Compiling OMC using Eclipse

- Inside the OpenModelica directory you will find a .project-sample file
  which you should rename to OpenModelica/.project and do whatever modifications
  you need on it to reflect your paths. Windows doesn't let you create files
  that start with dot (.) so you do like this:
  Copy your .project-sample to .project again from DOS:
    Start->Run->cmd.exe
    $ cd \path\to\OpenModelica
    $ ren ".project-sample" ".project"
- rename the file OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder32bit.launch-sample or OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder64bit.launch-sample
  to OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder32bit.launch or OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder64bit.launch and do whatever
  modifications are needed on it to reflect your paths.
- Installing Modelica Development Tooling (MDT) and setting your Eclipse workspace
  Start Eclipse and follow instructions from:
  https://trac.openmodelica.org/documents/MDT/install/InstallingMDT.pdf
  to install MDT. Eclipse will restart at the end.
  Start Eclipse, change workspace to your installation:
    - note here that your workspace must point one directory
      up the OpenModelica svn directory (for me named OpenModelica)
      Example: if you downloaded OpenModelica in a directory like this:
      c:\some_paths\dev\OpenModelica then your workspace must point to:
      c:\some_patsh\dev\
- Setting your project.
    - File -> New -> (Modelica Project) or
      File -> New -> Project -> Modelica -> Modelica Project
    - Type the name of your OpenModelica directory installation
      For me "OpenModelica"
    - Say Finish.
- Editing the OMDev-MINGW-OpenModelicaBuilder
    - Project->Project Properties->Builders->OMDev-MINGW-OpenModelicaBuilder->Edit
    - NOTE: In tab Main you have to change the Working Directory from "OpenModelica" to
            your directory name
    - Go to Environment tab and change the name of the OMDEV variable from there
      to point to your OMDev installation:
      /c/path/to/your/omdev (/c/OMDev)
- Running the OMDev-MINGW-OpenModelica builder:
    - To run the OMDev-MINGW-OpenModelicaBuilder press Ctrl+B or right-click project and say rebuild.
    - Then the OMDev-MINGW-OpenModelicaBuilder will start
      and compile an OpenModelica/build/omc.exe.
    - If the builder refuse to start, please check the **NOTES** below.

## NOTES ON PROBLEMS WITH THE ECLIPSE PROJECT/OMDev BUILDER

If something does not work in Eclipse, please check:
1. is the Modelica perspective chosen in eclipse?
   Set it up in the right top corner.
2. is OMDev installed into c:\OMDev?
   Be sure in C:\OMDev you have directories "tools", "bin", "include"
   and not another OMDev directory.
   Set a OMDEV variable to point to it. Right Click on
   My Computer->Properties->Advanced Tab->Environment Variables
   Add variable OMDEV and set the text to C:\OMDev
   Close and restart Eclipse to pick up the OMDEV variable.
3. rename the file OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder32bit.launch-sample or OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder64bit.launch-sample
   to OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder32bit.launch or OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder64bit.launch and do whatever
4. right click on the OpenModelica project in Eclipse and say Refresh
5. right click on the OpenModelica project in Eclipse and say Properties
  + go to Builders and see if you have the builder :
    OMDev-MINGW-OpenModelicaBuilder available.
6. right click on the OpenModelica project and say "Rebuild"

If these do not work, look into your OpenModelica/.project
to see if you have any reference to: OMDev-MINGW-OpenModelicaBuilder
there. If you don't, then:
- close Eclipse
- copy your .project-sample to .project again from DOS:
  Start->Run->cmd
  $ cd \path\to\OpenModelica
  $ ren ".project-sample" ".project"
- open Eclipse and do step 3-5 above.

For problems with OMDev package, contact:
Adrian Pop,
adrpo@ida.liu.se