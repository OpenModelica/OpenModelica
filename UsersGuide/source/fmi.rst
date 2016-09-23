Functional Mock-up Interface - FMI
==================================

The new standard for model exchange and co-simulation with Functional
Mockup Interface (`FMI <http://www.fmi-standard.org>`_) allows export of pre-compiled models, i.e.,
C-code or binary code, from a tool for import in another tool, and vice
versa. The FMI standard is Modelica independent. Import and export works
both between different Modelica tools, or between certain non-Modelica
tools. OpenModelica supports FMI 1.0 & 2.0,

-  Model Exchange

-  Co-Simulation (under development)

FMI Export
----------

To export the FMU use the OpenModelica command
`translateModelFMU(ModelName) <https://build.openmodelica.org/Documentation/OpenModelica.Scripting.translateModelFMU.html>`_ 
from command line interface, OMShell, OMNotebook or MDT. 
The export FMU command is also integrated with OMEdit. 
Select FMI > Export FMU the FMU package is generated in the
current directory of omc. You can use the cd() command to see the
current location. You can set which version of FMI to export through
OMEdit settings, see section :ref:`omedit-fmi-settings`.

To export the bouncing ball example to an FMU, use the following commands:

.. omc-mos ::
  :erroratend:

  loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/BouncingBall.mo")
  translateModelFMU(BouncingBall)
  system("unzip -l BouncingBall.fmu | egrep -v 'sources|files' | tail -n+3 | grep -o '[A-Za-z._0-9/]*$' > BB.log")

After the command execution is complete you will see that a file
BouncingBall.fmu has been created. Its contents varies depending on the
current platform.
On the machine generating this documentation, the contents in
:numref:`BouncingBall FMU contents` are generated (along with the C source code).

.. literalinclude :: ../tmp/BB.log
  :name: BouncingBall FMU contents
  :caption: BouncingBall FMU contents

A log file for FMU creation is also generated named ModelName\_FMU.log.
If there are some errors while creating FMU they will be shown in the
command line window and logged in this log file as well.

By default an FMU that can be used for both Model Exchange and 
Co-Simulation is generated. We only support FMI 2.0 for Co-Simulation FMUs.

Currently the Co-Simulation FMU supports only the forward Euler solver 
with root finding which does an Euler step of communicationStepSize 
in fmi2DoStep. Events are checked for before and after the call to
fmi2GetDerivatives.

FMI Import
----------

To import the FMU package use the OpenModelica command importFMU,

.. omc-mos ::
  :parsed:

  list(OpenModelica.Scripting.importFMU, interfaceOnly=true)

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

When importing the model into OMEdit, roughly the following commands will be executed:

.. omc-mos ::
  :erroratend:

  imported_fmu_mo_file:=importFMU("BouncingBall.fmu")
  loadFile(imported_fmu_mo_file)

The imported FMU can then be simulated like any normal model:

.. omc-mos ::

  simulate(BouncingBall_me_FMU, stopTime=3.0)

.. omc-gnuplot :: bouncingball_fmu
  :caption: Height of the bouncing ball, simulated through an FMU.

  h
