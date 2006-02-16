EXTERNAL PROGRAM
----------------
The following external program are needed:

ANTLR v2.7.4
Antlr and its code library is needed to create the files for the projects parser.
Version 2.7.5 of antlr dosen't work correctly with this project. 

QT
Qt version 4 has to be installed to compile the project. Qt version 4.0 works
fine with the project.

MICO CORBA
Mico Corba is needed to communicate with OMC. Currently the project is using
version 2.3.11.

MODELICA
Modelica (OMC) is needed to evaluate the openmodelica expression in the documents.



VARIABLES
---------
This environment variables are needed:

> QNBHOME	: Should point at the folder containing the tre sub projects,
                  for example "C:\Projects\OMNotebook",
                  > used like "$(QNBHOME)\NotebookParser".

> ANTLRHOME	: Should point at the folder containing Antlr, 
		  for example "C:\antlr\antlr-2.7.4",
		  > used like "$(ANTLRHOME)\lib\cpp".

> QTHOME	: Should point at the home folder for Qt, 
		  for example "C:\Qt\4.0.1".

> MICOHOME	: Should point at the folder containing Mico Corba
		  for example "C:\Program\mico",
		  > used like "$(MICOHOME)\include".

> MODELICAHOME	: Should point at the home folder containing c++ files for 
                  corba communication with OMC, 
		  for example "C:\Program\modelica_omc",
		  > used like "$(MODELICAHOME)".



MISC
----
> Probably the file path for the antlr files have to be change in the antlr project
  file (antlr.vcproj), because the paths are relative the location of the project
  file.

> Probably the path to the file "omc_communicator.cc" in the OMNotebook project has
  to be change, because this path is relative also. The file is added to the project
  to avoid link error and the file is located in modelicas winruntime library.


