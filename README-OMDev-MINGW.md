# Compiling OMC using OMDev package

- Checkout the OMDev package from SVN https://openmodelica.org/svn/OpenModelicaExternal/trunk/tools/windows/OMDev
  - this package contains all prerequisites to compile OMC on Windows using msys2+mingw32+mingw64
  - if you get issues with OpenModelica compilation maybe you should update OMDev
- Make sure you place the OMDev package into `C:\OMDev\`
  - Follow the instructions in the `C:\OMDev\INSTALL.txt` file
- You should have an OpenModelica directory you got from OpenModelica GIT repository https://github.com/OpenModelica/OpenModelica
  - Follow the instructions at the bottom of the page on how to get OpenModelica sources
- You could use msys2+mingw32 or msys2+mingw64 or Eclipse to build OMC. Follow the instructions in **Compiling OMC using MSYS** or **Compiling OMC using Eclipse**.

## Compiling OMC using MSYS

- To compile 32bit OMC start `$OMDEV\tools\msys\mingw32_shell.bat`
- To compile 64bit OMC start `$OMDEV\tools\msys\mingw64_shell.bat`

After starting the terminal type:
```bash
cd /path/to/OpenModelica
make -f Makefile.omdev.mingw -j8
```


## Compiling OMC using Eclipse

- Inside the OpenModelica directory you will find a `.project-sample` file
  which you should rename to `.project` and do whatever modifications
  you need on it to reflect your paths. Windows doesn't let you create files
  that start with dot (.) so you do like this,
  - Start->Run->cmd.exe
  - $ cd \path\to\OpenModelica
  - $ ren ".project-sample" ".project"
- rename the file `OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder32bit.launch-sample` or `OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder64bit.launch-sample`
  to `OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder32bit.launch` or `OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder64bit.launch` and do whatever modifications are needed on it to reflect your paths.
- Installing Modelica Development Tooling (MDT) and setting your Eclipse workspace
  Start Eclipse and follow instructions from https://trac.openmodelica.org/documents/MDT/install/InstallingMDT.pdf
  to install MDT. Eclipse will restart at the end. Start Eclipse, change workspace to your installation:
  - note here that your workspace must point one directory up the OpenModelica GIT directory (for me named OpenModelica).
  - Example: if you cloned OpenModelica in a directory like this `c:\some_paths\dev\OpenModelica` then your workspace must point to `c:\some_paths\dev\`
- Setting your project.
    - File -> New -> (Modelica Project) or File -> New -> Project -> Modelica -> Modelica Project
    - Type the name of your OpenModelica directory installation. For me **OpenModelica**
    - Say Finish.
- Editing the OMDev-MINGW-OpenModelicaBuilder
    - Project->Project Properties->Builders->OMDev-MINGW-OpenModelicaBuilder->Edit
    - NOTE: In tab Main you have to change the Working Directory from "OpenModelica" to your directory name
- Running the OMDev-MINGW-OpenModelica builder:
    - To run the OMDev-MINGW-OpenModelicaBuilder press Ctrl+B or right-click project and say rebuild.
    - Then the OMDev-MINGW-OpenModelicaBuilder will start and compile an OpenModelica/build/omc.exe.
    - If the builder refuse to start, please check the **NOTES** below.

## Troubleshooting Eclipse/OMDev builder

If something does not work in Eclipse, please check:

1. Is the Modelica perspective chosen in eclipse? Set it up in the right top corner.
2. Is OMDev installed into c:\OMDev?
   - Be sure in C:\OMDev you have directories **tools**, **bin**, **include** and not another OMDev directory.
   - Set a OMDEV variable to point to it. Right Click on My Computer->Properties->Advanced Tab->Environment Variables. Add variable OMDEV and set the text to C:\OMDev
   - Close and restart Eclipse to pick up the OMDEV variable.
4. Right click on the OpenModelica project in Eclipse and say Refresh
5. Right click on the OpenModelica project in Eclipse and say Properties
   - Go to Builders and see if you have the builder `OMDev-MINGW-OpenModelicaBuilder32bit` or `OMDev-MINGW-OpenModelicaBuilder64bit` available.
6. Right click on the OpenModelica project and say **Rebuild**.

If these do not work, look into your OpenModelica/.project
to see if you have any reference to: `OMDev-MINGW-OpenModelicaBuilder32bit` or `OMDev-MINGW-OpenModelicaBuilder64bit` there. If you don't, then:
- close Eclipse
- copy your .project-sample to .project again from DOS:
  - Start->Run->cmd
  - $ cd \path\to\OpenModelica
  - $ ren ".project-sample" ".project"
- open Eclipse and do step 3-5 above.

For problems with OMDev package, contact Adrian Pop, adrian.pop@liu.se
