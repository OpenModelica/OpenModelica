Functional Mock-up Interface - FMI
==================================

The new standard for model exchange and co-simulation with Functional
Mockup Interface (FMI) allows export of pre-compiled models, i.e.,
C-code or binary code, from a tool for import in another tool, and vice
versa. The FMI standard is Modelica independent. Import and export works
both between different Modelica tools, or between certain non-Modelica
tools. OpenModelica supports FMI 1.0 & 2.0,

-  Model Exchange

-  Co-Simulation (under development)

FMI Import
----------

To import the FMU package use the OpenModelica command importFMU,

function importFMU

input String filename "the fmu file name";

input String workdir = "<default>" "The output directory for imported
FMU files. <default> will put the files to current working directory.";

input Integer loglevel = 3
"loglevel\_nothing=0;loglevel\_fatal=1;loglevel\_error=2;loglevel\_warning=3;loglevel\_info=4;loglevel\_verbose=5;loglevel\_debug=6";

input Boolean fullPath = false "When true the full output path is
returned otherwise only the file name.";

input Boolean debugLogging = false "When true the FMU's debug output is
printed.";

input Boolean generateInputConnectors = true "When true creates the
input connector pins.";

input Boolean generateOutputConnectors = true "When true creates the
output connector pins.";

output String generatedFileName "Returns the full path of the generated
file.";

end importFMU;

The command could be used from command line interface, OMShell,
OMNotebook or MDT. The importFMU command is also integrated with OMEdit.
Select FMI > Import FMU the FMU package is extracted in the directory
specified by workdir, since the workdir parameter is optional so if its
not specified then the current directory of omc is used. You can use the
cd() command to see the current location.

The implementation supports FMI for Model Exchange 1.0 & 2.0 and FMI for
Co-Simulation 1.0 stand-alone. The support for FMI Co-Simulation is
still under development.

The FMI Import is currently a prototype. The prototype has been tested
in OpenModelica with several examples. It has also been tested with
example FMUs from FMUSDK and Dymola. A more fullfleged version for FMI
Import will be released in the near future.

**Figure** \ **5**\ 40: Example of FMU Import in OpenModelica where a
bouncing ball model is imported.

FMI Export
----------

To export the FMU use the OpenModelica command
translateModelFMU(ModelName) from command line interface, OMShell,
OMNotebook or MDT. The export FMU command is also integrated with
OMEdit. Select FMI > Export FMU the FMU package is generated in the
current directory of omc. You can use the cd() command to see the
current location. You can set which version of FMI to export through
OMEdit settings, see section 2.9.13.

After the command execution is complete you will see that a file
ModelName.fmu has been created. As depicted in Figure 6-2, we first
changed the current directory to C:/OpenModelica1.7.0/bin , then we
loaded a Modelica file with BouncingBall example model and finally
created an FMU for it using the translateModelFMU call.

**Figure** \ **5**\ 41: OMShell screenshot for creating an FMU

A log file for FMU creation is also generated named ModelName\_FMU.log.
If there are some errors while creating FMU they will be shown in the
command line window and logged in this log file as well.
