OMSimulator - FMI and TLM-Based Simulation and Co-simulation of External Models
===============================================================================

Functional Mock-up Interface - FMI
----------------------------------

The new standard for model exchange and co-simulation with Functional
Mockup Interface (`FMI <http://www.fmi-standard.org>`_) allows export of pre-compiled models, i.e.,
C-code or binary code, from a tool for import in another tool, and vice
versa. The FMI standard is Modelica independent. Import and export works
both between different Modelica tools, or between certain non-Modelica
tools. OpenModelica supports FMI 1.0 & 2.0,

-  Model Exchange

-  Co-Simulation (under development)

FMI Export
~~~~~~~~~~

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
~~~~~~~~~~

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

Transmission Line Modeling (TLM) Based Co-Simulation
----------------------------------------------------

This chapter gives a short description how to get started using the TLM-Based
co-simulation in the tool OMSimulator accessible via OMEdit.

The TLM Based co-simulation provides the following general functionalities:

-  Import and add External non-Modelica models such as **Matlab/SimuLink**, **Adams**, and **BEAST** models

-  External Modelica models such as **Dymola** and **Wolfram SystemModeler** models

-  Specify startup methods and interfaces of the external model

-  Build the composite models by connecting the external models

-  Set the co-simulation parameters in the composite model

-  Simulate the composite models using TLM based co-simulation

Composite Model Editing of External Models
------------------------------------------

The graphical composite model editor is an extension and specialization of the
OpenModelica connection editor OMEdit. A composite model is composed of several
external sub-models including the interconnections between these sub-models.
External models are models which need not be in Modelica, they can be FMUs,
or models accessed by proxies for co-simulation and connected by TLM-connections.
The standard way to store a composite model is in an XML format. The XML schema
standard is accessible from tlmModelDescription.xsd. Currently composite models
can only be used for TLM based co-simulation of external models.

Loading a Composite Model for Co-Simulation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To load the composite model, select **File > Open Composite Model(s)** from the
menu and select compositemodel.xml.

OMEdit loads the composite model and show it in the **Libraries
Browser**. Double-clicking the composite model in the **Libraries Browser** will display
the composite model as shown below in
:numref:`tlm-double-pendulum-compositemodel`.

.. figure :: media/tlm-double-pendulum-compositemodel.png
  :name: tlm-double-pendulum-compositemodel

  Composite Model with 3D View.

Co-Simulating the Composite Model
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

There are two ways to start co-simulation:

-  Click **TLM Co-Simulation setup button** (|tlm-simulate|) from the toolbar (requires a composite model to be active in ModelWidget)

.. |tlm-simulate| image:: media/omedit-icons/tlm-simulate.*
  :alt: Composite Model simulate Icon
  :height: 14pt

-  Right click the composite model in the **Libraries Browser** and choose **TLM Co-Simulation setup** from the popup menu (see :numref:`tlm-library-browser-popup-menu`)

.. figure :: media/tlm-library-browser-popup-menu.png
  :name: tlm-library-browser-popup-menu

  Co-simulating and Fetching Interface Data of a composite model from the Popup Menu .

The TLM Co-Simulation setup appears as shown below in :numref:`tlm-cosimulation-setup`.

.. figure :: media/tlm-cosimulation-setup.png
  :name: tlm-cosimulation-setup

  TLM Co-simulation Setup.

Click **Simulate** from the Co-simulation setup to confirm the co-simulation.
:numref:`tlm-cosimulation-progress` will appears in which you will be able to see
the progress information of the running co-simulation.

.. figure :: media/tlm-cosimulation-progress.png
  :name: tlm-cosimulation-progress

  TLM Co-Simulation Progress.

The editor also provides the means of reading the log files generated by the simulation manager and monitor.
When the simulation ends, click **Open Manager Log File** or **Open Monitor Log File** from the co-simulation progress bar
to check the log files.

Plotting the Simulation Results
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When the co-simulation of the composite model is completed successful, simulation results are collected and visualized
in the OMEdit plotting perspective as shown in :numref:`tlm-plotting-cosimulation-results` and :numref:`tlm-cosimulation-visualization`.
The **Variables Browser** display variables that can be plotted. Each variable has a checkbox, checking it will plot the variable.

.. figure :: media/tlm-plotting-cosimulation-results.png
  :name: tlm-plotting-cosimulation-results

  TLM Co-Simulation Results Plotting.

.. figure :: media/tlm-cosimulation-visualization.png
  :name: tlm-cosimulation-visualization

  TLM Co-Simulation Visualization.

Preparing External Models
~~~~~~~~~~~~~~~~~~~~~~~~~

First step in co-simulation Modeling is to prepare the different external simulation
models with TLM interfaces. Each external model belongs to a specific simulation
tool, such as **MATLAB/Simulink***, **BEAST**, **MSC/ADAMS**, **Dymola** and **Wolfram SystemModeler**.

When the external models have all been prepared, the next step is to load external models
in OMEdit by selecting the **File > Load External Model(s)** from the menu.

OMEdit loads the external model and show it in the **Libraries Browser**
as shown below in :numref:`tlm-loaded-external-models-library-browser`.

.. figure :: media/tlm-loaded-external-models-library-browser.png
  :name: tlm-loaded-external-models-library-browser

  External Models in OMEdit.

Creating a New Composite Model
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We will use the "Double pendulum" composite model which is a multibody system that
consists of three sub-models: Two OpenModelica **Shaft** sub-models (**Shaft1**
and **Shaft2**) and one **SKF/BEAST bearing** sub-model that together build a
double pendulum. The **SKF/BEAST bearing** sub-model is a simplified model with
only three balls to speed up the simulation. **Shaft1** is connected with a
spherical joint to the world coordinate system. The end of **Shaft1** is
connected via a TLM interface to the outer ring of the BEAST bearing model. The
inner ring of the bearing model is connected via another TLM interface to
**Shaft2**. Together they build the double pendulum with two **shafts**, one
spherical OpenModelica joint, and one BEAST bearing.

To create a new composite model select **File > New Composite Model** from the menu.

Your new composite model will appear in the in the **Libraries Browser** once created.
To facilitate the process of textual composite modeling and to provide users with a
starting point, the **Text View** (see :numref:`tlm-new-compositemodel-textview`)
includes the composite model XML elements and the default simulation parameters.

.. figure :: media/tlm-new-compositemodel-textview.png
  :name: tlm-new-compositemodel-textview

  New composite model text view.

Adding Submodels
~~~~~~~~~~~~~~~~

It is possible to build the double pendulum by drag-and-drop of each simulation
model component (sub-model) from the **Libraries Browser** to the Diagram View.
To place a component in the Diagram View of the double pendulum model, drag each
external sub-model of the double pendulum (i.e. **Shaft1**, **Shaft2**, and
**BEAST bearing** sub-model) from the **Libraries Browser** to the **Diagram
View**.

.. figure :: media/tlm-add-submodels.png

  Adding sub-models to the double pendulum composite model.

Fetching Submodels Interface Data
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To retrieve list of TLM interface data for sub-models, do any of the following methods:

- Click **Fetch Interface Data button** (|interface-data|) from the toolbar (requires a composite model to be active in ModelWidget)

.. |interface-data| image:: media/omedit-icons/interface-data.*
  :alt: Composite Model Interface Data Icon
  :height: 14pt

- Right click the composite model in the **Library Browser** and choose **Fetch Interface Data** from the popup menu
  (see :numref:`tlm-library-browser-popup-menu`).

To retrieve list of TLM interface data for a specific sub-model,

- Right click the sub-model inside the composite model and choose **Fetch Interface Data** from the popup menu.

:numref:`tlm-fetch-interface-progress` will appear in which you will be able to see the progress information
of fetching the interface data.

.. figure :: media/tlm-fetch-interface-progress.png
  :name: tlm-fetch-interface-progress

  Fetching Interface Data Progress.

Once the TLM interface data of the sub-models are retrieved, the interface points will appear
in the diagram view as shown below in :numref:`tlm-fetched-interface-points`.

.. figure :: media/tlm-fetched-interface-points.png
  :name: tlm-fetched-interface-points

  Fetching Interface Data.

Connecting Submodels
~~~~~~~~~~~~~~~~~~~~

When the sub-models and interface points have all been placed in the Diagram
View, similar to :numref:`tlm-fetched-interface-points`, the next step is to
connect the sub-models. Sub-models are connected using the **Connection Line
Button** (|connect-mode|) from the toolbar.

.. |connect-mode| image:: media/omedit-icons/connect-mode.*
  :alt: Connection Line Icon
  :height: 14pt

To connect two sub-models, select the Connection Line Button and place the mouse cursor over an interface
and click the left mouse button, then drag the cursor to the other sub-model interface, and
click the left mouse button again. A connection dialog box as shown below in :numref:`tlm-submodels-connection-dialog` will
appear in which you will be able to specify the connection attributes.

.. figure :: media/tlm-submodels-connection-dialog.png
  :name: tlm-submodels-connection-dialog

  Sub-models Connection Dialog.

Continue to connect all sub-models until the composite model **Diagram View** looks like the one in :numref:`tlm-connecting-submodels-double-pendulum` below.

.. figure :: media/tlm-connecting-submodels-double-pendulum.png
  :name: tlm-connecting-submodels-double-pendulum

  Connecting sub-models of the Double Pendulum Composite Model.

Changing Parameter Values of Submodels
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To change a parameter value of a sub-model, do any of the following methods:

-  Double-click on the sub-model you want to change its parameter
-  Right click on the sub-model and choose **Attributes** from the popup menu

The parameter dialog of that sub-model appears as shown below in :numref:`tlm-change-submodel-parameters-dialog`
in which you will be able to specify the sub-models attributes.

.. figure :: media/tlm-change-submodel-parameters-dialog.png
  :name: tlm-change-submodel-parameters-dialog

  Changing Parameter Values of Sub-models Dialog.

Changing Parameter Values of Connections
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To change a parameter value of a connection, do any of the following methods:

- Double-click on the connection you want to change its parameter
- Right click on the connection and choose **Attributes** from the popup menu.

The parameter dialog of that connection appears (see :numref:`tlm-submodels-connection-dialog`)
in which you will be able to specify the connections attributes.

Changing Co-Simulation Parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To change the co-simulation parameters, do any of the following methods:

- Click Simulation Parameters button (|simulation-parameters|) from the toolbar (requires a composite model to be active in ModelWidget)

.. |simulation-parameters| image:: media/omedit-icons/simulation-parameters.*
  :alt: Composite Model Simulation Parameters Icon
  :height: 14pt

- Right click an empty location in the Diagram View of the composite model and choose **Simulation Parameters**
  from the popup menu (see :numref:`tlm-change-cosimulation-parameters-popup-menu`)

.. figure :: media/tlm-change-cosimulation-parameters-popup-menu.png
  :name: tlm-change-cosimulation-parameters-popup-menu

  Changing Co-Simulation Parameters from the Popup Menu.

The co-simulation parameter dialog of the composite model appears as shown below in :numref:`tlm-change-cosimulation-parameters-dialog` in
which you will be able to specify the simulation parameters.

.. figure :: media/tlm-change-cosimulation-parameters-dialog.png
  :name: tlm-change-cosimulation-parameters-dialog

  Changing Co-Simulation Parameters Dialog.
