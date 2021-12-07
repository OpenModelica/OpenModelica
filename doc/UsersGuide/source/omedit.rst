OMEdit – OpenModelica Connection Editor
=======================================

OMEdit – OpenModelica Connection Editor is the new Graphical User
Interface for graphical model editing in OpenModelica. It is implemented
in C++ using the Qt graphical user interface library and supports
the Modelica Standard Library that is included in the latest
OpenModelica installation. This chapter gives a brief introduction to
OMEdit and also demonstrates how to create a DCMotor model using the
editor.

OMEdit provides several user friendly features for creating, browsing,
editing, and simulating models:

-  *Modeling* – Easy model creation for Modelica models.

-  *Pre-defined models* – Browsing the Modelica Standard library to
   access the provided models.

-  *User defined models* – Users can create their own models for
   immediate usage and later reuse.

-  *Component interfaces* – Smart connection editing for drawing and
   editing connections between model interfaces.

-  *Simulation* – Subsystem for running simulations and specifying
   simulation parameters start and stop time, etc.

-  *Plotting* – Interface to plot variables from simulated models.

Starting OMEdit
---------------

A splash screen similar to the one shown in :numref:`omedit-splash` will
appear indicating that it is starting OMEdit.
The executable is found in different places depending on the platform
(see below).

.. figure :: media/omedit_splashscreen.png
  :name: omedit-splash

  OMEdit Splash Screen.

Microsoft Windows
~~~~~~~~~~~~~~~~~

OMEdit can be launched using the executable placed in
OpenModelicaInstallationDirectory/bin/OMEdit/OMEdit.exe. Alternately,
choose OpenModelica > OpenModelica Connection Editor from the start menu
in Windows.

Linux
~~~~~

Start OMEdit by either selecting the corresponding menu application item
or typing “\ **OMEdit**\ ” at the shell or command prompt.

Mac OS X
~~~~~~~~

The default installation is /Application/MacPorts/OMEdit.app.

MainWindow & Browsers
---------------------

The MainWindow contains several dockable browsers,

-  Libraries Browser

-  Documentation Browser

-  Variables Browser

-  Messages Browser

:numref:`omedit-mainwindow-browsers` shows the MainWindow and browsers.

.. figure :: media/omedit-mainwindow-browsers.png
  :name: omedit-mainwindow-browsers

  OMEdit MainWindow and Browsers.

The default location of the browsers are shown in :numref:`omedit-mainwindow-browsers`.
All browsers except for Message Browser can be docked into left or right
column. The Messages Browser can be docked into top or bottom
areas. If you want OMEdit to remember the new docked position of the
browsers then you must enable Preserve User's GUI Customizations option,
see section :ref:`omedit-options-general`.

.. _omedit-filter-classes :

Filter Classes
~~~~~~~~~~~~~~

To filter a class click Edit > Filter Classes or press keyboard
shortcut Ctrl+Shift+F. The loaded Modelica classes can be filtered by
typing any part of the class name.

Libraries Browser
~~~~~~~~~~~~~~~~~

To view the Libraries Browser click View > Windows > Libraries Browser.
Shows the list of loaded Modelica classes. Each item of the Libraries
Browser has right click menu for easy manipulation and usage of the
class. The classes are shown in a tree structure with name and icon. The
protected classes are not shown by default. If you want to see the
protected classes then you must enable the Show Protected Classes
option, see section :ref:`omedit-options-general`.

Documentation Browser
~~~~~~~~~~~~~~~~~~~~~

Displays the HTML documentation of Modelica classes. It contains the
navigation buttons for moving forward and backward. It also contains
a WYSIWYG editor which allows writing class documentation in HTML format.
To view the Documentation Browser click View > Windows > Documentation Browser.

.. figure :: media/omedit-documentation-browser.png

  Documentation Browser.

.. _omedit-variables-browser :

Variables Browser
~~~~~~~~~~~~~~~~~

The class variables are structured in the form of the tree and are
displayed in the Variables Browser. Each variable has a checkbox.
Ticking the checkbox will plot the variable values. There is a find box
on the top for filtering the variable in the tree. The filtering can be
done using Regular Expression, Wildcard and Fixed String. The complete
Variables Browser can be collapsed and expanded using the Collapse All
and Expand All buttons.

The browser allows manipulation of changeable parameters for
:ref:`omedit-resimulation`. It also displays the unit and
description of the variable.

The browser also contains the slider and animation buttons. These controls
are used for variable graphics and schematic animation of models i.e.,
DynamicSelect annotation. They are also used for debugging of state machines.
Open the :ref:`omedit-diagram-window` for animation. It is only possible
to animate one model at a time. This is achieved by marking the result
file active in the Variables Browser. The animation only read the values
from the active result file. It is possible to simulate several models.
In that case, the user will see a list of result files in the Variables Browser.
The user can switch between different result files by right clicking
on the result file and selecting **Set Active** in the context menu.

.. figure :: media/omedit-variables-browser.png

  Variables Browser.

Messages Browser
~~~~~~~~~~~~~~~~

Shows the list of errors. Following kinds of error can occur,

-  Syntax

-  Grammar

-  Translation

-  Symbolic

-  Simulation

-  Scripting

See section :ref:`omedit-options-messages` for Messages Browser options.

Perspectives
------------

The perspective tabs are loacted at the bottom right of the MainWindow:

-  Welcome Perspective

-  Modeling Perspective

-  Plotting Perspective

-  Debugging Perspective

Welcome Perspective
~~~~~~~~~~~~~~~~~~~

.. figure :: media/omedit-welcome.png
  :name: omedit-welcome

  OMEdit Welcome Perspective.

The Welcome Perspective shows the list of recent files and the list of
latest news from https://www.openmodelica.org.
See :numref:`omedit-welcome`. The orientation of recent files and latest news can be
horizontal or vertical. User is allowed to show/hide the latest news.
See section :ref:`omedit-options-general`.

Modeling Perspective
~~~~~~~~~~~~~~~~~~~~

The Modeling Perpective provides the interface where user can create and
design their models. See :numref:`omedit-modeling-perspective`.

.. figure :: media/omedit-modeling-perspective.png
  :name: omedit-modeling-perspective

  OMEdit Modeling Perspective.

The Modeling Perspective interface can be viewed in two different modes,
the tabbed view and subwindow view, see section :ref:`omedit-options-general`.

Plotting Perspective
~~~~~~~~~~~~~~~~~~~~

The Plotting Perspective shows the simulation results of the models.
Plotting Perspective will automatically become active when the
simulation of the model is finished successfully. It will also become
active when user opens any of the OpenModelica’s supported result file.
Similar to Modeling Perspective this perspective can also be viewed in
two different modes, the tabbed view and subwindow view, see section
:ref:`omedit-options-general`.

.. figure :: media/omedit-plotting-perspective.png
  :name: omedit-plotting-perspective

  OMEdit Plotting Perspective.

Debugging Perspective
~~~~~~~~~~~~~~~~~~~~~

The application automatically switches to Debugging Perpective
when user simulates the class with algorithmic debugger.
The prespective shows the list of stack frames, breakpoints and variables.

.. figure :: media/omedit-debugging-perspective.png
  :name: omedit-debugging-perspective

  OMEdit Debugging Perspective.

File Menu
---------

-  *New*
  -  *New Modelica Class* - Creates a new Modelica class.
  -  *New SSP Model* - Creates a new SSP model.
-  *Open Model/Library File(s)* - Opens the Modelica file or a library.
-  *Open/Convert Modelica File(s) With Encoding* - Opens the Modelica file or
   a library with a specific encoding. It is also possible to convert to UTF-8.
-  *Load Library* - Loads a Modelica library. Allows the user to select the
   library path assuming that the path contains a package.mo file.
-  *Load Encrypted Library* - Loads an encrypted library. see :ref:`encryption`
-  *Open Result File(s)* - Opens a result file.
-  *Open Transformations File* - Opens a transformational debugger file.
-  *New Composite Model* - Creates a new composite model.
-  *Open Composite Model(s)* - Loads an existing composite model.
-  *Load External Model(s)* - Loads the external models that can be used within
   composite model.
-  *Open Directory* - Loads the files of a directory recursively. The files
   are loaded as text files.
-  *Save* - Saves the class.
-  *Save As* - Save as the class.
-  *Save Total* - Saves the class and all the classes it uses in a single file. The class and its dependencies can only be loaded later by using the *loadFile()* API function in a script. Allows third parties to reproduce an issue with a class without worrying about library dependencies.
-  *Import*
  -  *FMU* - Imports the FMU.
  -  *FMU Model Description* - Imports the FMU model description.
  -  *From OMNotbook* - Imports the Modelica models from OMNotebook.
  -  *Ngspice netlist* - Imports the ngspice netlist to Modelica code.
-  "Export"
  -  *To Clipboard* - Exports the current model to clipboard.
  -  *Image* - Exports the current model to image.
  -  *FMU* - Exports the current model to FMU.
  -  *Read-only Package* - Exports a zipped Modelica library with file extension .mol
  -  *Encrypted Package* - Exports an encrypted package. see :ref:`encryption`
  -  *XML* - Exports the current model to a xml file.
  -  *Figaro* - Exports the current model to Figaro.
  -  *To OMNotebook* - Exports the current model to a OMNotebook file.
-  *System Libraries* - Contains a list of system libraries.
-  *Recent Files* - Contains a list of recent files.
-  *Clear Recent Files* - Clears the list of recent files.
-  *Print* - Prints the current model.
-  *Quit* - Quit the OpenModelica Connection Editor.

Edit Menu
---------

-  *Undo* - Undoes the last change.
-  *Redo* - Redoes the last undone change.
-  *Filter Classes* - Filters the classes in Libraries Browser. see :ref:`omedit-filter-classes`

.. _omedit-view-menu :

View Menu
---------

-  *Toolbars* - Toggle visibility of toolbars.
-  *Windows* - Toggle visibility of windows.
  -  *Close Window* - Closes the current model window.
  -  *Close All Windows* - Closes all the model windows.
  -  *Close All Windows But This* - Closes all the model windows except the current.
  -  *Cascade Windows* - Arranges all the child windows in a cascade pattern.
  -  *Tile Windows Horizontally* - Arranges all child windows in a horizontally tiled pattern.
  -  *Tile Windows Vertically* - Arranges all child windows in a vertically tiled pattern.
-  *Toggle Tab/Sub-window View* - Switches between tab and subwindow view.
-  *Grid Lines* - Toggle grid lines of the current model.
-  *Reset Zoom* - Resets the zoom of the current model.
-  *Zoom In* - Zoom in the current model.
-  *Zoom Out* - Zoom out the current model.

Simulation Menu
---------------

-  *Check Model* - Checks the current model.
-  *Check All Models* - Checks all the models of a library.
-  *Instantiate Model* - Instantiates the current model.
-  *Simulation Setup* - Opens the simulation setup window.
-  *Simulate* - Simulates the current model.
-  *Simulate with Transformational Debugger* - Simulates the current model and
   opens the transformational debugger.
-  *Simulate with Algorithmic Debugger* - Simulates the current model and
   opens the algorithmic debugger.
-  *Simulate with Animation* - Simulates the current model and open the animation.
-  *Archived Simulations* - Shows the list of simulations already finished or running.
   Double clicking on any of them opens the simulation output window.

Debug Menu
----------

-  *Debug Configurations* - Opens the debug configurations window.
-  *Attach to Running Process* - Attaches the algorithmic debugger to a running process.

SSP Menu
--------

-  *Add System* - Adds the system to a model.
-  *Add/Edit Icon* - Add/Edit the system/submodel icon.
-  *Delete Icon* - Deletes the system/submodel icon.
-  *Add Connector* - Adds a connector to a system/submodel.
-  *Add Bus* - Adds a bus to a system/submodel.
-  *Add TLM Bus* - Adds a TLM bus to a system/submodel.
-  *Add SubModel* - Adds a submodel to a system.

Sensitivity Optimization Menu
-----------------------------

- *Run Sensitivity Analysis and Optimization* - Runs the sensitivity analysis and optimization.

Tools Menu
----------

-  *OpenModelica Compiler CLI* - Opens the OpenModelica Compiler command line
   interface window.
-  *OpenModelica Command Prompt* - Opens the OpenModelica Command Prompt (Only
   available on Windows).
-  *Open Working Directory* - Opens the current working directory.
-  *Open Terminal* - Runs the terminal command set in :ref:`omedit-options-general`.
-  *Options* - Opens the options window.

Help Menu
---------

-  *OpenModelica Users Guide* - Opens the OpenModelica Users Guide.
-  *OpenModelica Users Guide (PDF)* - Opens the OpenModelica Users Guide (PDF).
-  *OpenModelica System Documentation* - Opens the OpenModelica System Documentation.
-  *OpenModelica Scripting Documentation* - Opens the OpenModelica Scripting Documentation.
-  *Modelica Documentation* - Opens the Modelica Documentation.
-  *OMSimulator Users Guide* - Opens the OMSimulator Users Guide.
-  *OpenModelica TLM Simulator Documentation* - Opens the OpenModelica TLM Simulator Documentation.
-  *About OMEdit* - Shows the information about OpenModelica Connection Editor.

Modeling a Model
----------------

.. _creating-new-class :

Creating a New Modelica Class
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Creating a new Modelica class in OMEdit is rather straightforward.
Choose any of the following methods,

-  Select File > New > New Modelica Class from the menu.

-  Click on New Modelica Class toolbar button.

-  Click on the Create New Modelica Class button available at the left
   bottom of Welcome Perspective.

-  Press Ctrl+N.

Opening a Modelica File
~~~~~~~~~~~~~~~~~~~~~~~

Choose any of the following methods to open a Modelica file,

-  Select File > Open Model/Library File(s) from the menu.

-  Click on Open Model/Library File(s) toolbar button.

-  Click on the Open Model/Library File(s) button available at the right
   bottom of Welcome Perspective.

-  Press Ctrl+O.

(Note, for editing Modelica system files like MSL (not recommended), see :ref:`editingMSL`)

Opening a Modelica File with Encoding
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Select File > Open/Convert Modelica File(s) With Encoding from the menu.
It is also possible to convert files to UTF-8.

Model Widget
~~~~~~~~~~~~

For each Modelica class one Model Widget is created. It has a statusbar
and a view area. The statusbar contains buttons for navigation between
the views and labels for information. The view area is used to display
the icon, diagram and text layers of Modelica class. See :numref:`omedit-model-widget`.

.. figure :: media/omedit-model-widget.png
  :name: omedit-model-widget

  Model Widget showing the Diagram View.

Adding Component Models
~~~~~~~~~~~~~~~~~~~~~~~

Drag the models from the Libraries Browser and drop them on either
Diagram or Icon View of Model Widget.

Making Connections
~~~~~~~~~~~~~~~~~~

In order to connect one component model to another the user first needs
to enable the connect mode (|connect-mode|) from the toolbar.

Move the mouse over the connector. The mouse cursor will change from arrow cursor to cross cursor.
To start the connection press left button and move while keeping the button pressed. Now release the left button.
Move towards the end connector and click when cursor changes to cross cursor.

.. |connect-mode| image:: media/omedit-icons/connect-mode.*
  :height: 14pt
  :alt: OMEdit connect mode icon

Simulating a Model
------------------

The simulation process in OMEdit is split into three main phases:

#. The Modelica model is translated into C/C++ code. The model is first instantiated by the
   frontend, which turns it into a flat set of variables, parameters, equations,
   algorithms, and functions. The backend then analyzes the mathematical structure
   of the flat model, applies symbolic simplifications and determines how the equations can be solved efficiently.
   Finally, based on this information, model-specific C/C++ code is generated. This part of
   the process can be influenced by setting :ref:`Translation Flags <omedit-options-simulation-translationflags>` (a.k.a. *Command Line Options*),
   e.g. deciding which kind of structural simplifications should be performed during the translation phase.
#. The C/C++ code is compiled and linked into an executable simulation code. Additional :ref:`C/C++ compiler flags <omedit-C-Compiler-flags>`
   can be given to influence this part of the process, e.g. by setting compiler optimizations
   such as ``-O3``. Since multiple C/C++ source code files are generated for a given model, they
   are compiled in parallel by OMEdit, exploiting the power of multi-core CPUs.
#. The simulation executable is started and produces the simulation results in a `.mat` or
   `.csv` file. The runtime behaviour can be influenced by *Simulation Flags*, e.g. by choosing
   specific solvers, or changing the output file name. Note that it it possible to re-simulate a model
   multiple times, changing parameter values from the Variables Browser and/or changing some
   Simulation Flags. In this case, only Phase 3. is repeated, skipping Phases 1. and 2., which
   enables much faster iterations.

The simulation options for each model are stored inside the OMEdit data structure.
They are set according to the following sequence,

-  Each model has its own translation and simulation options.

-  If the model is opened for the first time then the translation and simulation options
   are set to defaults, that can be customized in Tools | Options | Simulation.

-  ``experiment``,  ``__OpenModelica_commandLineOptions`` and ``__OpenModelica_simulationFlags``
   annotations are applied if the model contains them.

-  After that all the changes done via Simulation Setup window for a certain model are
   preserved for the whole session. If you want to use the same settings in
   future sessions then you should store them inside ``experiment``, ``__OpenModelica_commandLineOptions``, and ``__OpenModelica_simulationFlags``
   annotations.

The OMEdit Simulation Setup can be launched by,

-  Selecting Simulation > Simulation Setup from the menu. (requires a
   model to be active in ModelWidget)

-  Clicking on the Simulation Setup toolbar button. (requires a model to
   be active in ModelWidget)

-  Right clicking the model from the Libraries Browser and choosing
   Simulation Setup.

General
~~~~~~~

-  Simulation Interval

  -  *Start Time* – the simulation start time.

  -  *Stop Time* – the simulation stop time.

  -  *Number of Intervals* – the simulation number of intervals.

  -  *Interval* – the length of one interval (i.e., stepsize)

-  Integration

  -  *Method* – the simulation solver. See section :ref:`cruntime-integration-methods` for solver details.

  -  *Tolerance* – the simulation tolerance.

  -  *Jacobian* - the jacobian method to use.

  -  DASSL/IDA Options

    -  *Root Finding* - Activates the internal root finding procedure of dassl.

    -  *Restart After Event* - Activates the restart of dassl after an event is performed.

    -  *Initial Step Size*

    -  *Maximum Step Size*

    -  *Maximum Integration Order*

.. _omedit-C-Compiler-flags :

-  *C/C++ Compiler Flags (Optional)* – the optional C/C++ compiler flags.

-  *Number of Processors* – the number of processors used to build the simulation.

-  *Build Only* – only builds the class.

-  *Launch Transformational Debugger* – launches the transformational debugger.

-  *Launch Algorithmic Debugger* – launches the algorithmic debugger.

-  *Launch Animation* – launches the 3d animation window.

:ref:`omedit-interactive`
~~~~~~~~~~~~~~~~~~~~~~~~

-  Simulate with steps (makes the interactive simulation synchronous; plots nicer curves at the expense of performance)

-  Simulation server port

:ref:`Translation Flags <omedit-options-simulation-translationflags>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Simulation Flags
~~~~~~~~~~~~~~~~

-  *Model Setup File (Optional)* – specifies a new setup XML file to the generated simulation code.

-  *Initialization Method (Optional)* – specifies the initialization method.

-  *Equation System Initialization File (Optional)* – specifies an
   external file for the initialization of the model.

-  *Equation System Initialization Time (Optional)* – specifies a time
   for the initialization of the model.

-  *Clock (Optional)* – the type of clock to use.

-  *Linear Solver (Optional)* – specifies the linear solver method.

-  *Non Linear Solver (Optional)* – specifies the nonlinear solver.

-  *Linearization Time (Optional)* – specifies a time where the
   linearization of the model should be performed.

-  *Output Variables (Optional)* – outputs the variables a, b and c at
   the end of the simulation to the standard output.

-  *Profiling* – creates a profiling HTML file.

-  *CPU Time* – dumps the cpu-time into the result file.

-  *Enable All Warnings* – outputs all warnings.

-  *Logging (Optional)*

  -  *stdout* - standard output stream. This stream is always active, can be disabled with -lv=-stdout
  -  *assert* - This stream is always active, can be disabled with -lv=-assert
  -  *LOG_DASSL* - additional information about dassl solver.
  -  *LOG_DASSL_STATES* - outputs the states at every dassl call.
  -  *LOG_DEBUG* - additional debug information.
  -  *LOG_DSS* - outputs information about dynamic state selection.
  -  *LOG_DSS_JAC* - outputs jacobian of the dynamic state selection.
  -  *LOG_DT* - additional information about dynamic tearing.
  -  *LOG_DT_CONS* - additional information about dynamic tearing (local and global constraints).
  -  *LOG_EVENTS* - additional information during event iteration.
  -  *LOG_EVENTS_V* - verbose logging of event system.
  -  *LOG_INIT* - additional information during initialization.
  -  *LOG_IPOPT* - information from Ipopt.
  -  *LOG_IPOPT_FULL* - more information from Ipopt.
  -  *LOG_IPOPT_JAC* - check jacobian matrix with Ipopt.
  -  *LOG_IPOPT_HESSE* - check hessian matrix with Ipopt.
  -  *LOG_IPOPT_ERROR* - print max error in the optimization.
  -  *LOG_JAC* - outputs the jacobian matrix used by dassl.
  -  *LOG_LS* - logging for linear systems.
  -  *LOG_LS_V* - verbose logging of linear systems.
  -  *LOG_NLS* - logging for nonlinear systems.
  -  *LOG_NLS_V* - verbose logging of nonlinear systems.
  -  *LOG_NLS_HOMOTOPY* - logging of homotopy solver for nonlinear systems.
  -  *LOG_NLS_JAC* - outputs the jacobian of nonlinear systems.
  -  *LOG_NLS_JAC_TEST* - tests the analytical jacobian of nonlinear systems.
  -  *LOG_NLS_RES* - outputs every evaluation of the residual function.
  -  *LOG_NLS_EXTRAPOLATE* - outputs debug information about extrapolate process.
  -  *LOG_RES_INIT* - outputs residuals of the initialization.
  -  *LOG_RT* - additional information regarding real-time processes.
  -  *LOG_SIMULATION* - additional information about simulation process.
  -  *LOG_SOLVER* - additional information about solver process.
  -  *LOG_SOLVER_V* - verbose information about the integration process.
  -  *LOG_SOLVER_CONTEXT* - context information during the solver process.
  -  *LOG_SOTI* - final solution of the initialization.
  -  *LOG_STATS* - additional statistics about timer/events/solver.
  -  *LOG_STATS_V* - additional statistics for LOG_STATS.
  -  *LOG_SUCCESS* - This stream is always active, can be disabled with -lv=-LOG_SUCCESS.
  -  *LOG_UTIL*.
  -  *LOG_ZEROCROSSINGS* - additional information about the zerocrossings.

-  *Additional Simulation Flags (Optional)* – specify any other simulation flag.

Output
~~~~~~

-  *Output Format* – the simulation result file output format.

-  *Single Precision* - Output results in single precision (only for mat output format).

-  *File Name Prefix (Optional)* – the name is used as a prefix for the output files.

-  *Result File (Optional)* - the simulation result file name.

-  *Variable Filter (Optional)*

-  *Protected Variables –* adds the protected variables in result file.

-  *Equidistant Time Grid –* output the internal steps given by dassl instead of interpolating results into an equidistant time grid as given by stepSize or numberOfIntervals

-  *Store Variables at Events –* adds the variables at time events.

-  *Show Generated File* – displays the generated files in a dialog box.

.. _omedit-2d-plotting :

Data Reconciliation
~~~~~~~~~~~~~~~~~~~

-  *Algorithm* – data reconciliation algorithm.

-  *Measurement Input File* – measurement input file.

-  *Correlation Matrix Input File* – correlation matrix file.

-  *Epsilon*

2D Plotting
-----------

Successful simulation of model produces the result file which contains
the instance variables that are candidate for plotting. Variables
Browser will show the list of such instance variables. Each variable has
a checkbox, checking it will plot the variable. See :numref:`omedit-plotting-perspective`.
To get several plot windows tiled horizontally or vertically use the
menu items *Tile Windows Horizontally* or *Tile Windows Vertically* under :ref:`omedit-view-menu`.

Types of Plotting
~~~~~~~~~~~~~~~~~

The plotting type depends on the active Plot Window. By default the
plotting type is Time Plot.

Time Plot
^^^^^^^^^

Plots the variable over the simulation time. You can have multiple Time
Plot windows by clicking on New Plot Window toolbar button (|plot-window|).

.. |plot-window| image:: media/omedit-icons/plot-window.*
  :alt: OMEdit New Plot Window Icon
  :height: 14pt

Plot Parametric
^^^^^^^^^^^^^^^

Draws a two-dimensional parametric diagram, between variables x and y,
with *y* as a function of *x*. You can have multiple Plot Parametric
windows by clicking on the New Plot Parametric toolbar button (|parametric-plot-window|).

.. |parametric-plot-window| image:: media/omedit-icons/parametric-plot-window.*
  :alt: OMEdit New Parametric Plot Window Icon
  :height: 14pt

.. _array-plot :

Select the x-axis variable while holding down the shift key, release the shift key and then select
y-axis variables. One or many y-axis variables can be selected against one x-axis variable. To select
a new x-axis variable press and hold the shift key again.

Unchecking the x-axis variable will uncheck all y-axis variables linked to it.

Array Plot
^^^^^^^^^^

Plots an array variable so that the array elements' indexes are on the x-axis and corresponding
elements' values are on the y-axis. The time is controlled by the slider above the variable tree.
When an array is present in the model, it has a principal array node in the variable tree.
To plot this array as an Array Plot, match the principal node. The principal node may be expanded
into particular array elements. To plot a single element in the Time Plot, match the element.
A new Array Plot window is opened using the New Array Plot Window toolbar button (|array-plot-window|).

.. |array-plot-window| image:: media/omedit-icons/array-plot-window.*
  :alt: OMEdit New Array Plot Window Icon
  :height: 14pt

.. _array-parametric-plot :

Array Parametric Plot
^^^^^^^^^^^^^^^^^^^^^

Plots the first array elements' values on the x-axis versus the second array elements' values on the y-axis. The time
is controlled by the slider above the variable tree. To create a new Array Parametric Plot, press
the New Array Parametric Plot Window toolbar button (|array-parametric-plot-window|), then match the principle
array node in the variable tree view to be plotted on the x-axis and match the principle array node to be plotted
on the y-axis.

.. |array-parametric-plot-window| image:: media/omedit-icons/array-parametric-plot-window.*
  :alt: OMEdit New Array Parametric Plot Window Icon
  :height: 14pt

.. _omedit-diagram-window :

Diagram Window
^^^^^^^^^^^^^^

Shows the active ModelWidget as a read only diagram. You can only have one
Diagram Window. To show it click on Diagram Window toolbar button (|diagram-window|).

.. |diagram-window| image:: ../../../OMEdit/OMEditLIB/Resources/icons/modeling.*
  :alt: OMEdit Diagram Window Icon
  :height: 14pt

.. _omedit-resimulation :

Plot Window
~~~~~~~~~~~

A plot window shows the plot curve of instance variables. Several plot curves can be plotted in the
same plot window. See :numref:`omedit-plotting-perspective`.

.. _omedit-plot-window-menu :

Plot Window Menu
^^^^^^^^^^^^^^^^

-  *Auto Scale* - Automatically scales the horizontal and vertical axes.
-  *Fit in View* - Adjusts the plot canvas to according to the size of plot curves.
-  *Save* - Saves the plot to file system as .png, .svg or .bmp.
-  *Print* - Prints the plot.
-  *Grid* - Shows grid lines.
-  *Detailed Grid* - Shows detailed grid lines.
-  *No Grid* - Hides grid lines.
-  *Log X* - Logarithmic scale of the horizontal axis.
-  *Log Y* - Logarithmic scale of the vertical axis.
-  *Setup* - Shows a setup window.
  -  *Variables* - List of all plotted variables.
    -  *General* - Variable general information.
      -  *Legend* - Display name for legend.
      -  *File* - File name where variable data is stored.
    -  *Appearance* - Visual settings of variable.
      -  *Color* - Display color.
      -  *Pattern* - Line pattern of curve.
      -  *Thickness* - Line thickness of curve.
      -  *Hide* - Hide/Show the curve.
      -  *Toggle Sign* - Toggles the sign of curve.
    -  *Titles* - Plot, axes and footer titles settings.
    -  *Legend* - Sets legend position and font.
    -  *Range* - Automatic or manual axes range.
      -  *Auto Scale* - Automatically scales the horizontal and vertical axes.
      -  *X-Axis*
        -  *Minimum* - Minimum value for x-axis.
        -  *Maximum* - Maximum value for x-axis.
      -  *Y-Axis*
        -  *Minimum* - Minimum value for y-axis.
        -  *Maximum* - Maximum value for y-axis.
    -  *Prefix Units* - Automatically pick the right prefix for units.

Re-simulating a Model
---------------------

The :ref:`omedit-variables-browser` allows manipulation of changeable
parameters for re-simulation.
After changing the parameter values user can click on the re-simulate
toolbar button (|re-simulate|), or right click the model in Variables Browser and choose
re-simulate from the menu.

.. |re-simulate| image:: media/omedit-icons/re-simulate.*
  :alt: OMEdit Re-simulate button
  :height: 14pt

3D Visualization
----------------

.. highlight:: modelica

Since OpenModelica 1.11 , OMEdit has built-in 3D visualization,
which replaces third-party libraries (such as `Modelica3D
<https://github.com/OpenModelica/Modelica3D>`_) for 3D visualization.

Running a Visualization
~~~~~~~~~~~~~~~~~~~~~~~

The 3d visualization is based on OpenSceneGraph. In order to run the
visualization simply right click the class in Libraries Browser an
choose “\ **Simulate with Animation**\ ” as shown in :numref:`omedit-simulate-animation`.

.. figure :: media/omedit_simulate_animation.png
  :name: omedit-simulate-animation

  OMEdit Simulate with Animation.

One can also run the visualization via Simulation > Simulate with Animation from the menu.

When simulating a model in animation mode, the flag *+d=visxml* is set.
Hence, the compiler will generate a scene description file *_visual.xml* which stores all information on the multibody shapes.
This scene description references all variables which are needed for the animation of the multibody system.
When simulating with *+d=visxml*, the compiler will always generate results for these variables.

Viewing a Visualization
~~~~~~~~~~~~~~~~~~~~~~~

After the successful simulation of the model, the visualization window will
show up automatically as shown in :numref:`omedit-visualization`.

.. figure :: media/omedit_visualization.png
  :name: omedit-visualization

  OMEdit 3D Visualization.

The animation starts with pushing the *play* button. The animation is played until stopTime or until the *pause* button is pushed.
By pushing the *previous* button, the animation jumps to the initial point of time.
Points of time can be selected by moving the *time slider* or by inserting a simulation time in the *Time-box*.
The speed factor of animation in relation to realtime can be set in the *Speed-dialog*.
Other animations can be openend by using the *open file* button and selecting a result file with a corresping scene description file.

The 3D camera view can be manipulated as follows:

========================  ============================== ========================
  Operation                Key                            Mouse Action
========================  ============================== ========================
Move Closer/Further        none                           Wheel
Move Closer/Further        Right Mouse Hold               Up/Down
Move Up/Down/Left/Right    Middle Mouse Hold              Move Mouse
Move Up/Down/Left/Right    Left and Right Mouse Hold      Move Mouse
Rotate                     Left Mouse Hold                Move Mouse
Shape context menu         Right Mouse + Shift
========================  ============================== ========================

Predefined views (Isometric, Side, Front, Top) can be selected and the scene can be tilted by 90° either clock or anticlockwise with the rotation buttons.

Additional Visualization Features
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The shapes that are displayed in the viewer can be selected with shift + right click.
If a shape is selected, a context menu pops up that offers additional visualization features

.. figure :: media/pick_shape.png
  :name: A context menu to set additional visualization features for the selected shape.

The following features can be selected:

========================  ================================================================================================
  Menu                      Description
========================  ================================================================================================
Change Transparency       The shape becomes either transparent or intransparent.
Make Shape Invisible      The shape becomes invisible.
Change Color              A color dialog pops up and the color of the shape can be set.
Apply Check Texture       A checked texture is applied to the shape.
Apply Custom Texture      A file selection dialog pops up and an image file can be selected as a texture.
Remove Texture            Removes the current texture of the shape.
========================  ================================================================================================

.. figure :: media/visual_features.png
  :name: Different visualization features.

Animation of Realtime FMUs
--------------------------

Instead of a result file, OMEdit can load Functional Mock-up Units to retrieve the data for the animation of multibody systems.
Just like opening a mat-file from the animation-plotting view, one can open an FMU-file.
Necessarily, the FMU has to be generated with the *+d=visxml* flag activated, so that a scene description file is generated in the same directory as the FMU.
Currently, only FMU 1.0 and FMU 2.0 model exchange are supported.
When choosing an FMU, the simulation settings window pops up to choose solver and step size.
Afterwards, the model initializes and can be simulated by pressing the play button.

Interactive Realtime Animation of FMUs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FMUs can be simulated with realtime user interaction.
A possible solution is to equip the model with an interaction model from the Modelica_DeviceDrivers library (https://github.com/modelica/Modelica_DeviceDrivers).
The realtime synchronization is done by OMEdit so no additional time synchronization model is necessary.

 .. figure :: media/interactive_model.png
  :name: An interactive multibody system model using Modelic_DeviceDrivers models.

.. _omedit-interactive :

Interactive Simulation
----------------------

.. warning ::
  Interactive simulation is an experimental feature.

Interactive simulation is enabled by selecting interactive simulation in the simulation setup.

There are two main modes of execution: asynchronous and synchronous
(simulate with steps). The difference is that in synchronous (step mode),
OMEdit sends a command to the simulation for each step that the simulation
should take. The asynchronous mode simply tells the simulation to run and
samples variables values in real-time; if the simulation runs very fast,
fewer values will be sampled.

When running in asynchronous mode, it is possible to simulate the model
in real-time (with a scaling factor just like simulation flag
:ref:`-rt <simflag-rt>`, but with the ability to change the scaling
factor during the interactive simulation). In the synchronous mode, the
speed of the simulation does not directly correspond to real-time.

.. raw:: html

   <video controls width="640" src="_static/interactive-simulation.mp4"></video>

How to Create User Defined Shapes – Icons
-----------------------------------------

Users can create shapes of their own by using the shape creation tools
available in OMEdit.

-  *Line Tool* – Draws a line. A line is created with a minimum of two
   points. In order to create a line, the user first selects the
   line tool from the toolbar and then click on the Icon/Diagram
   View; this will start creating a line. If a user clicks again on
   the Icon/Diagram View a new line point is created. In order to
   finish the line creation, user has to double click on the
   Icon/Diagram View.

-  *Polygon Tool* – Draws a polygon. A polygon is created in a similar
   fashion as a line is created. The only difference between a line
   and a polygon is that, if a polygon contains two points it will
   look like a line and if a polygon contains more than two points
   it will become a closed polygon shape.

-  *Rectangle Tool* – Draws a rectangle. The rectangle only contains two
   points where first point indicates the starting point and the
   second point indicates the ending the point. In order to create
   rectangle, the user has to select the rectangle tool from the
   toolbar and then click on the Icon/Diagram View, this click will
   become the first point of rectangle. In order to finish the
   rectangle creation, the user has to click again on the
   Icon/Diagram View where he/she wants to finish the rectangle. The
   second click will become the second point of rectangle.

-  *Ellipse Tool* – Draws an ellipse. The ellipse is created in a
   similar way as a rectangle is created.

-  *Text Tool* – Draws a text label.

-  *Bitmap Tool* – Draws a bitmap container.

The shape tools are located in the toolbar. See :numref:`omedit-user-defined-shapes`.

.. figure :: media/omedit-user-defined-shapes.png
  :name: omedit-user-defined-shapes

  User defined shapes.

The user can select any of the shape tools and start drawing on the
Icon/Diagram View. The shapes created on the Diagram View of Model
Widget are part of the diagram and the shapes created on the Icon View
will become the icon representation of the model.

For example, if a user creates a model with name testModel and add a
rectangle using the rectangle tool and a polygon using the polygon tool,
in the Icon View of the model. The model’s Modelica Text will appear as
follows:

.. code-block :: modelica

  model testModel
    annotation(Icon(graphics = {Rectangle(rotation = 0, lineColor = {0,0,255}, fillColor = {0,0,255}, pattern = LinePattern.Solid, fillPattern = FillPattern.None, lineThickness = 0.25, extent = {{ -64.5,88},{63, -22.5}}),Polygon(points = {{ -47.5, -29.5},{52.5, -29.5},{4.5, -86},{ -47.5, -29.5}}, rotation = 0, lineColor = {0,0,255}, fillColor = {0,0,255}, pattern = LinePattern.Solid, fillPattern = FillPattern.None, lineThickness = 0.25)}));
  end testModel;

In the above code snippet of testModel, the rectangle and a polygon are
added to the icon annotation of the model. Similarly, any user defined
shape drawn on a Diagram View of the model will be added to the diagram
annotation of the model.

Global head section in documentation
------------------------------------

If you want to use same styles or same JavaScript for the classes contained inside a package then
you can define ``__OpenModelica_infoHeader`` annotation inside the ``Documentation`` annotation of a package.
For example,

.. code-block :: modelica

  package P
    model M
      annotation(Documentation(info="<html>
        <a href=\"javascript:HelloWorld()\">Click here</a>
      </html>"));
    end M;
   annotation(Documentation(__OpenModelica_infoHeader="
       <script type=\"text/javascript\">
         function HelloWorld() {
           alert(\"Hello World!\");
         }
       </script>"));
  end P;

In the above example model ``M`` does not need to define the javascript function ``HelloWorld``.
It is only defined once at the package level using the ``__OpenModelica_infoHeader`` and then all classes
contained in the package can use it.

In addition styles and JavaScript can be added from file locations using Modelica URIs.
Example:

.. code-block :: modelica

  package P
    model M
      annotation(Documentation(info="<html>
        <a href=\"javascript:HelloWorld()\">Click here</a>
      </html>"));
    end M;
   annotation(Documentation(__OpenModelica_infoHeader="
       <script type=\"text/javascript\">
          src=\"modelica://P/Resources/hello.js\">
         }
       </script>"));
  end P;

Where the file ``Resources/hello.js`` then contains:

.. code-block :: javascript

  function HelloWorld() {
    alert("Hello World!");
  }


Options
-------

OMEdit allows users to save several options which will be remembered
across different sessions of OMEdit. The Options Dialog can be used for
reading and writing the options.

.. _omedit-options-general :

General
~~~~~~~

-  General

  -  *Language* – Sets the application language.

  -  *Working Directory* – Sets the application working directory.
     All files are generated in this directory.

  -  *Toolbar Icon Size* – Sets the size for toolbar icons.

  -  *Preserve User’s GUI Customizations* – If true then OMEdit will
     remember its windows and toolbars positions and sizes.

  -  *Terminal Command* – Sets the terminal command.
     When user clicks on Tools > Open Terminal then this command is executed.

  -  *Terminal Command Arguments* – Sets the terminal command arguments.

  -  *Hide Variables Browser* – Hides the variable browser when switching away from plotting perspective.

  -  *Activate Access Annotations* – Activates the access annotations
     for the non-encrypted libraries. Access annotations are always active
     for encrypted libraries.

  -  *Create a model.bak-mo backup file when deleting a model*

  -  *Display errors/warnings when instantiating the graphical annotations* - if true then the errors/warnings
     are shown when using OMC API for graphical annotations.

-  Libraries Browser

  -  *Library Icon Size* – Sets the size for library icons.

  -  *Max. Library Icon Text Length to Show* – Sets the maximum text length that can be shown
     in the icon in Libraries Browser.

  -  *Show Protected Classes* – If enabled then Libraries Browser will also list the protected classes.

  -  *Show Hidden Classes* – If enabled then Libraries Browser will also list the hidden classes.
     Ignores the annotation(Protection(access = Access.hide))

  -  *Synchronize with Model Widget* – If enabled then Libraries Browser will scroll automatically
     to the active Model Widget i.e., the current model.

-  Enable Auto Save - Enables/disables the auto save feature.

-  *Auto Save interval* – Sets the auto save interval value. The minimum
   possible interval value is 60 seconds.

-  Welcome Page

  -  *Horizontal View/Vertical View* – Sets the view mode for welcome page.

  -  *Show Latest News* - If enabled then the latest news from https://openmodelica.org are shown.

  -  *Recent Files and Latest News Size* - Sets the display size for recent files and latest news items.

-  Optional Features

  -  *Enable replaceable support* - Enables/disables the replaceable support.

  -  *Enable new frontend use in OMC API (faster GUI response)* - if true then uses the new frontend in OMC API calls.

Libraries
~~~~~~~~~

-  *System Libraries* – The list of system libraries that should be
   loaded every time OMEdit starts.

-  *Force loading of Modelica Standard Library* – If true then Modelica
   and ModelicaReference will always load even if user has removed
   them from the list of system libraries.

-  *Load OpenModelica library on startup* – If true then OpenModelica
   package will be loaded when OMEdit is started.

-  *User Libraries* – The list of user libraries/files that should be
   loaded every time OMEdit starts.

.. _omedit-options-text-editor :

Text Editor
~~~~~~~~~~~
-  Format

  -  *Line Ending* - Sets the file line ending.

  -  *Byte Order Mark (BOM)* - Sets the file BOM.

-  Tabs and Indentation

  -  *Tab Policy* – Sets the tab policy to either spaces or tabs only.

  -  *Tab Size* – Sets the tab size.

  -  *Indent Size* – Sets the indent size.

-  Syntax Highlight and Text Wrapping

  -  *Enable Syntax Highlighting* – Enable/Disable the syntax highlighting.

    -  *Enable Code Folding* - Enable/Disable the code folding. When code
       folding is enabled multi-line annotations are collapsed into a
       compact icon (a rectangle containing "...)"). A marker containing
       a "+" sign becomes available at the left-side of the involved line,
       allowing the code to be expanded/re-collapsed at will.

    -  *Match Parentheses within Comments and Quotes* – Enable/Disable the matching of parentheses within comments and quotes.

  -  *Enable Line Wrapping* – Enable/Disable the line wrapping.

-  Autocomplete

  -  *Enable Autocomplete* – Enables/Disables the autocomplete.

-  Font

  -  *Font Family* – Shows the names list of available fonts.
     Sets the font for the editor.

  -  *Font Size* – Sets the font size for the editor.

Modelica Editor
~~~~~~~~~~~~~~~

-  *Preserve Text Indentation* – If true then uses *diffModelicaFileListings* API call otherwise uses the OMC pretty-printing.

-  Colors

  -  *Items* – List of categories used of syntax highlighting the code.

  -  *Item Color* – Sets the color for the selected item.

  -  *Preview* – Shows the demo of the syntax highlighting.

MetaModelica Editor
~~~~~~~~~~~~~~~~~~~

-  Colors

  -  *Items* – List of categories used of syntax highlighting the code.

  -  *Item Color* – Sets the color for the selected item.

  -  *Preview* – Shows the demo of the syntax highlighting.

CompositeModel Editor
~~~~~~~~~~~~~~~~~~~~~

-  Colors

  -  *Items* – List of categories used of syntax highlighting the code.

  -  *Item Color* – Sets the color for the selected item.

  -  *Preview* – Shows the demo of the syntax highlighting.

SSP Editor
~~~~~~~~~~

-  Colors

  -  *Items* – List of categories used of syntax highlighting the code.

  -  *Item Color* – Sets the color for the selected item.

  -  *Preview* – Shows the demo of the syntax highlighting.

C/C++ Editor
~~~~~~~~~~~~

-  Colors

  -  *Items* – List of categories used of syntax highlighting the code.

  -  *Item Color* – Sets the color for the selected item.

  -  *Preview* – Shows the demo of the syntax highlighting.

HTML Editor
~~~~~~~~~~~

-  Colors

  -  *Items* – List of categories used of syntax highlighting the code.

  -  *Item Color* – Sets the color for the selected item.

  -  *Preview* – Shows the demo of the syntax highlighting.

Graphical Views
~~~~~~~~~~~~~~~

- General

  -  Modeling View Mode

    -  *Tabbed View/SubWindow View* – Sets the view mode for modeling.

  -  Default View

    -  *Icon View/DiagramView/Modelica Text View/Documentation View* – If no
       preferredView annotation is defined then this setting is used to show
       the respective view when user double clicks on the class in the
       Libraries Browser.

  -  *Move connectors together on both icon and diagram layers*

- Graphics

  - Icon/Diagram View

    -  Extent

      -  *Left* – Defines the left extent point for the view.

      -  *Bottom* – Defines the bottom extent point for the view.

      -  *Right* – Defines the right extent point for the view.

      -  *Top* – Defines the top extent point for the view.

    -  Grid

      -  *Horizontal* – Defines the horizontal size of the view grid.

      -  *Vertical* – Defines the vertical size of the view grid.

    -  Component

      -  *Scale factor* – Defines the initial scale factor for the component
         dragged on the view.

      -  *Preserve aspect ratio* – If true then the component’s aspect ratio
         is preserved while scaling.

.. _omedit-options-simulation :

Simulation
~~~~~~~~~~

-  Simulation

.. _omedit-options-simulation-translationflags :

  -  Translation Flags

    -  *Matching Algorithm* – sets the matching algorithm for simulation.

    -  *Index Reduction Method* – sets the index reduction method for
       simulation.

    -  *Show additional information from the initialization process* - prints the
       information from the initialization process

    -  *Evaluate all parameters (faster simulation, cannot change them at runtime)* - makes the simulation more
       efficient but you have to recompile the model if you want to change the
       parameter instead of re-simulate.

    -  *Enable analytical jacobian for non-linear strong components* - enables
       analytical jacobian for non-linear strong components without user-defined
       function calls.

    -  *Enable pedantic debug-mode, to get much more feedback*

    -  *Enable parallelization of independent systems of equations (Experimental)*

    -  *Enable old frontend for code generation*

    -  *Additional Translation Flags* – sets the translation flags see :ref:`omcflags-options`

  -  *Target Language* – sets the target language in which the code is generated.

  -  *Target Build* – sets the target build that is used to compile the generated code.

  -  *C Compiler* – sets the C compiler for compiling the generated code.

  -  *CXX Compiler* – sets the CXX compiler for compiling the generated code.

  -  *Use static linking* – if true then static linking is used for simulation executable.
     The default is dynamic linking. This option is only available on Windows.

  -  *Ignore __OpenModelica_commandLineOptions annotation* – if true then ignores the __OpenModelica_commandLineOptions
     annotation while running the simulation.

  -  *Ignore __OpenModelica_simulationFlags annotation* – if true then ignores the __OpenModelica_simulationFlags
     annotation while running the simulation.

  -  *Save class before simulation* – if true then always saves the class before running the simulation.

  -  *Switch to plotting perspective after simulation* – if true then GUI always switches to plotting
     perspective after the simulation.

  -  *Close completed simulation output windows before simulation* – if true
     then the completed simulation output windows are closed before starting
     a new simulation.

  -  *Delete intermediate compilation files* – if true then the files
     generated during the compilation are deleted automatically.

  -  *Delete entire simulation directory of the model when OMEdit is closed* –
     if true then the entire simulation directory is deleted on quit.

  -  Output

    -  *Structured* - Shows the simulation output in the form of tree structure.

    -  *Formatted Text* - Shows the simulation output in the form of formatted text.

    -  *Display Limit* - Sets the display limit for simulation output. A link to log file is shown
       once the limit is reached.

.. _omedit-options-messages :

Messages
~~~~~~~~

-  General

  -  *Output Size* - Specifies the maximum number of rows the Messages
     Browser may have. If there are more rows then the rows are removed
     from the beginning.

  -  *Reset messages number before simulation* – Resets the messages
     counter before starting the simulation.

  -  *Clear messages browser before checking, instantiation & simulation* – If enabled then the
     messages browser is cleared before checking, instantiation & simulation of model.

-  Font and Colors

  -  *Font Family* – Sets the font for the messages.

  -  *Font Size –* Sets the font size for the messages.

  -  *Notification Color* – Sets the text color for notification messages.

  -  *Warning Color* – Sets the text color for warning messages.

  -  *Error Color* – Sets the text color for error messages.

Notifications
~~~~~~~~~~~~~

-  Notifications

  -  *Always quit without prompt* – If true then OMEdit will quit without prompting the user.

  -  *Show item dropped on itself message* – If true then a message will
     pop-up when a class is dragged and dropped on itself.

  -  *Show model is partial and component is added as replaceable message* – If true then a
     message will pop-up when a partial class is added to another class.

  -  *Show component is declared as inner message* – If true then a
     message will pop-up when an inner component is added to another class.

  -  *Show save model for bitmap insertion message* – If true then a message will pop-up
     when user tries to insert a bitmap from a local directory to an unsaved class.

  -  *Always ask for the dragged component name* – If true then a message will pop-up when
     user drag & drop the component on the graphical view.

  -  *Always ask for what to do with the text editor error* – If true then a
     message will always pop-up when there is an error in the text editor.

  -  If new frontend for code generation fails

    -  *Always ask for old frontend*

    -  *Try with old frontend once*

    -  *Switch to old frontend permanently*

    -  *Keep using new frontend*

Line Style
~~~~~~~~~~

-  Line Style

  -  *Color* – Sets the line color.

  -  *Pattern* – Sets the line pattern.

  -  *Thickness* – Sets the line thickness.

  -  *Start Arrow* – Sets the line start arrow.

  -  *End Arrow* – Sets the line end arrow.

  -  *Arrow Size* – Sets the start and end arrow size.

  -  *Smooth* – If true then the line is drawn as a Bezier curve.

Fill Style
~~~~~~~~~~

-  Fill Style

  -  *Color* – Sets the fill color.

  -  *Pattern* – Sets the fill pattern.

Plotting
~~~~~~~~

-  General

  -  *Auto Scale* – Sets whether to auto scale the plots or not.
  -  *Prefix Units* – Automatically pick the right prefix for units for the new plot windows.
     For existing plot windows use the :ref:`omedit-plot-window-menu`.

-  Plotting View Mode

  -  *Tabbed View/SubWindow View* – Sets the view mode for plotting.

-  Curve Style

  -  *Pattern* – Sets the curve pattern.

  -  *Thickness* – Sets the curve thickness.

-  Variable filter

  - *Filter Interval* - Delay in filtering the variables. Set the value to 0
    if you don't want any delay.

-  Font Size - sets the font size for plot window items

  - *Title*

  - *Vertical Axis Title*

  - *Vertical Axis Numbers*

  - *Horizontal Axis Title*

  - *Horizontal Axis Numbers*

  - *Footer*

  - *Legend*

Figaro
~~~~~~

-  Figaro

  -  *Figaro Library* – the Figaro library file path.

  -  *Tree generation options* – the Figaro tree generation options file path.

  -  *Figaro Processor* – the Figaro processor location.

.. _omedit-options-debugger :

Debugger
~~~~~~~~

-  Algorithmic Debugger

  -  *GDB Path* – the gnu debugger path

  -  *GDB Command Timeout* – timeout for gdb commands.

  -  *GDB Output Limit* – limits the GDB output to N characters.

  -  *Display C frames* – if true then shows the C stack frames.

  -  *Display unknown frames* – if true then shows the unknown stack
     frames. Unknown stack frames means frames whose file path is unknown.

  -  *Clear old output on a new run* – if true then clears the output window on new run.

  -  *Clear old log on new run* – if true then clears the log window on new run.

-  Transformational Debugger

  -  *Always show Transformational Debugger after compilation* – if true
     then always open the Transformational Debugger window after model
     compilation.

  -  *Generate operations in the info xml* – if true then adds the
     operations information in the info xml file.

.. _omedit-options-fmi :

FMI
~~~

-  Export

  -  Version

    -  *1.0* – Sets the FMI export version to 1.0

    -  *2.0* – Sets the FMI export version to 2.0

  -  Type

    -  *Model Exchange* – Sets the FMI export type to Model Exchange.

    -  *Co-Simulation* – Sets the FMI export type to Co-Simulation.

    -  *Model Exchange and Co-Simulation* – Sets the FMI export type to Model Exchange and Co-Simulation.

  -  *FMU Name* – Sets a prefix for generated FMU file.

  -  *Move FMU* – Moves the generated FMU to a specified path.

  -  Platforms

    The list of platforms is created by searching for programs in the PATH matching pattern \"*-*-*-*cc\"."
    Add the host triple to the PATH to get it listed.
    A source-code only FMU is generated if no platform is selected.

  -  Solver for Co-Simulation

    -  *Explicit Euler*

    -  *CVODE*

  -  *Model Description Filters* - Sets the variable filter for model description file see :ref:`omcflag-fmifilter`

  -  *Include Modelica based resources via loadResource*

  -  *Include Source Code* - Sets if the exported FMU can contain source code.
     Model Description Filter \"blackBox\" will override this, because black box FMUs do never contain their source code.

  -  *Generate Debug Symbols* - Generates a FMU with debug symbols.

-  Import

  -  *Delete FMU directory and generated model when OMEdit is closed* - If true
     then the temporary FMU directory that is created for importing the FMU will be deleted.

OMTLMSimulator
~~~~~~~~~~~~~~

-  General

  -  *Path* - path to OMTLMSimulator bin directory.

  -  *Manager Process* - path to OMTLMSimulator managar process.

  -  *Monitor Process* - path to OMTLMSimulator monitor process.

OMSimulator/SSP
~~~~~~~~~~~~~~~

-  General

  -  *Command Line Options* - sets the OMSimulator command line options.
  -  *Logging Level* - OMSimulator logging level.

__OpenModelica_commandLineOptions Annotation
--------------------------------------------

OpenModelica specific annotation to define the command line options needed to simulate the model.
For example if you always want to simulate the model with a specific matching algorithm and index
reduction method instead of the default ones then you can write the following code,

.. code-block :: modelica

  model Test
    annotation(__OpenModelica_commandLineOptions = "--matchingAlgorithm=BFSB --indexReductionMethod=dynamicStateSelection");
  end Test;

The annotation is a space separated list of options where each option is either just a command line
flag or a flag with a value.

In OMEdit open the Simulation Setup and set the Translation Flags then
in the bottom check `Save translation flags inside model i.e., __OpenModelica_commandLineOptions annotation` and click on OK.

If you want to ignore this annotation then use `setCommandLineOptions("--ignoreCommandLineOptionsAnnotation=true")`.
In OMEdit *Tools > Options > Simulation* check `Ignore __OpenModelica_commandLineOptions annotation`.

__OpenModelica_simulationFlags Annotation
-----------------------------------------

OpenModelica specific annotation to define the simulation options needed to simulate the model.
For example if you always want to simulate the model with a specific solver instead of the
default DASSL and would also like to see the cpu time then you can write the following code,

.. code-block :: modelica

  model Test
    annotation(__OpenModelica_simulationFlags(s = "heun", cpu = "()"));
  end Test;

The annotation is a comma separated list of options where each option is a simulation flag
with a value. For flags that doesn't have any value use `()` (See the above code example).

In OMEdit open the Simulation Setup and set the Simulation Flags then
in the bottom check `Save simulation flags inside model i.e., __OpenModelica_simulationFlags annotation` and click on OK.

If you want to ignore this annotation then use `setCommandLineOptions("--ignoreSimulationFlagsAnnotation=true")`.
In OMEdit *Tools > Options > Simulation* check `Ignore __OpenModelica_simulationFlags annotation`.

Global and Local Flags
----------------------

There is a large number of optional settings and flags to influence the way OpenModelica generates
the simulation code (:ref:`Compiler flags <omcflags-options>`, a.k.a. Translation flags or Command Line Options)
and the way the simulation executable is run (:ref:`Simulation Flags <cruntime-simflags>`).

The global default settings can be accessed and changed with the *Tools > Options* menu.
It is also possible to reset them to factory state by clicking on the ``Reset`` button of the
*Tools > Options* dialog window.

When you start OMEdit and you simulate a model for the first time, the model-specific simulation
session settings are initialized by copying the global default settings, and then by applying any
further settings that are saved in the model within OpenModelica-specific ``__OpenModelica_commandLineOptions``
and ``__OpenModelica_simulationFlags`` annotations. Note that the latter may partially override the former,
if they give different values to the same flags.

You can change those model-specific settings at will with the Simulation Setup window.
Any change you make will be remembered until the end of the simulation session, i.e. until you close OMEdit.
This is very useful to experiment with different settings and find the optimal ones,
or to investigate bugs by turning on logging options, etc. If you check the ``Save translation flags``
and ``Save simulation flags`` options in the simulation setup, those settings will be saved in the
model within the corresponding OpenModelica-specific annotations, so that you can get the same behavior
when you start a new session later on, or if someone else loads the model on a different computer.
Otherwise, all of those changes will be forgotten when you exit OMEdit.

If you change the global default settings after running some models, the simulation settings of
those models will be reset as if you closed OMEdit and restarted a new session: the new global
options will first be applied, and then any further setting saved in the OpenModelica-specific annotations
will be applied, possibly overriding the global options if the same flags get different values from
the annotations. Any model-specific settings that you may have changed with Simulation Setup up to
that point will be lost, unless you saved them in the OpenModelica-specific annotations before changing the
global default settings.

Debugger
--------

For debugging capability, see :ref:`debugging`.

.. _editingMSL :

Editing Modelica Standard Library
---------------------------------

By default OMEdit loads the Modelica Standard Library (MSL) as a system library. System libraries are read-only.
If you want to edit MSL you need to load it as user library instead of system library. We don't recommend editing
MSL but if you really need to and understand the consequences then follow these steps,

-  Go to *Tools > Options > Libraries*.
-  Remove Modelica & ModelicaReference from list of system libraries.
-  Uncheck *force loading of Modelica Standard Library*.
-  Add *$OPENMODELICAHOME/lib/omlibrary/Modelica X.X/package.mo* under user libraries.
-  Restart OMEdit.

Install Library
---------------

A new library can be installed with the help of the :ref:`package manager <packagemanagement>`.
Click `File->Install Library` to open the install library dialog. OMEdit lists the libraries
that are available for installation through the package manager.

.. figure :: media/omedit_install_library.png
  :name: omedit-install-library

  Install Library.

Upgrade Libraries using Conversion Scripts
------------------------------------------

In order to upgrade the libraries used in the model/package right-click the model/package in the
`Libraries Browser` and choose `Convert to newer versions of used libraries`. OMEdit will read the used
libraries from the uses-annotation and list any new version of the library that provide the conversion
using the conversion script.

.. figure :: media/omedit_convert_library.png
  :name: omedit-convert-library

  Converts the model/package to newer version of used libraries.

State Machines
--------------

Creating a New Modelica State Class
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Follow the same steps as defined in :ref:`creating-new-class`.
Additionally make sure you check the *State* checkbox.

.. figure :: media/new-state.png
  :name: omedit-new-state

  Creating a new Modelica state.

Making Transitions
~~~~~~~~~~~~~~~~~~

In order to make a transition from one state to another the user first needs
to enable the transition mode (|transition-mode|) from the toolbar.

Move the mouse over the state. The mouse cursor will change from arrow cursor to cross cursor.
To start the transition press left button and move while keeping the button pressed. Now release the left button.
Move towards the end state and click when cursor changes to cross cursor.

A *Create Transition* dialog box will appear which allows you to set the transition attributes.
Cancelling the dialog will cancel the transition.

Double click the transition or right click and choose *Edit Transition* to modify the transition attributes.

.. |transition-mode| image:: media/omedit-icons/transition-mode.*
  :height: 14pt
  :alt: OMEdit transition mode icon

State Machines Simulation
~~~~~~~~~~~~~~~~~~~~~~~~~

Support for Modelica state machines was added in the Modelica Language Specification
v3.3. A subtle problem can occur if Modelica v3.2 libraries are loaded, e.g., the
Modelica Standard Library v3.2.2, because
in this case OMC automatically switches into Modelica v3.2 compatibility mode.
Trying to simulate a state machine in Modelica v3.2 compatibility mode results
in an error. It is possible to use the OMC flag *--std=latest* in order to ensure
(at least) Modelica v3.3 support. In OMEdit this can be achieved by
setting that flag in the *Tools > Options > Simulation* dialog.

.. figure :: media/omedit-state-machine-simulation-settings.png
  :name: omedit-state-machine-simulation-settings

  Ensure (at least) Modelica v3.3 support.

State Machines Debugger
~~~~~~~~~~~~~~~~~~~~~~~

Modelica state machines debugger is implemented as a visualization,
which allows the user to run the state machines simulation as an animation.

.. figure :: media/omedit-state-machine-debugger.png
  :name: omedit-state-machine-debugger

  State machine debugger in OMEdit.

A special Diagram Window is developed to visualize the active and inactive states.
The active and inactive value of the states are stored in the OpenModelica simulation result file.
After the successful simulation, of the state machine model, OMEdit reads the start,
stop time values, and initializes the visualization controls accordingly.

The controls allows the easy manipulation of the visualization,

* Rewind – resets the visualization to start.
* Play – starts the visualization.
* Pause – pauses the visualization.
* Time – allows the user to jump at any specific time.
* Speed – speed of the visualization.
* Slider – controls the time.

The visualization is based on the simulation result file.
All three formats of the simulation result file are supported i.e., mat, csv and plt
where mat is a matlab file format, csv is a comma separated file and plt is an ordered text file.

It is only possible to debug one state machine at a time.
This is achieved by marking the result file active in the Variables Browser.
The visualization only read the values from the active result file.
It is possible to simulate several state machine models.
In that case, the user will see a list of result files in the Variables Browser.
The user can switch between different result files by right clicking on the result file and selecting *Set Active* in the context menu.

Using OMEdit as Text Editor
---------------------------
OMEdit can be be used as a Text editor. Currently support for editing MetaModelica,Modelica and C/C++
are available with syntax highlighting and autocompletion of keywords and types. Additionaly the Modelica
and MetaModelica files are provided with autocompletion of code-snippets along with keywords and types.
The users can load the directory from file menu *File > Open Directory*. which opens the Directory structure
in the Libraries-browser.

.. figure :: media/omedit-open-directory.png
   :name: omedit-open-directory

   open-directory

After the directory is opened in the Libraries-browser, the users can expand the directory structure and click the file which
opens in the texteditor.

.. figure :: media/omedit-directory-file.png
   :name: omedit-directory-file

   openfile in texteditor

Advanced Search
~~~~~~~~~~~~~~~

Support to search in OMEdit texteditor is available. The search browser can be enabled by selecting
View > Windows > Search browser or through shortcut keys (ctrl+h).

.. figure :: media/omedit-search.png
  :name: omedit-search

  Enable omedit search browser

The users can start the search by loading the directory they want to search and fill in the text to be searched for
and file pattern if needed and click the search button.


.. figure :: media/omedit-start-search.png
  :name: omedit-start-search

  Start search in search browser


After the search is completed the results are presented to the users in a separate window, The search results contains
the following

1) The name of the files where the searched word is matched
2) The line number and text of the matched word.

The users can click the line number or the matched text and it will automatically open the file in the texteditor and
move the cursor to matched line number of the text.

.. figure :: media/omedit-search-results.png
  :name: omedit-search-results

  Search Results

The users can perform multiple searches and go back to old search results using search histroy option.

.. figure :: media/omedit-search-history.png
  :name: omedit-search-histroy

  Search History

Temporary Directory, Log Files and Working Directory
----------------------------------------------------

On Unix/Linux systems temporary directory is the path in the `TMPDIR` environment variable
or `/tmp` if `TMPDIR` is not defined appended with directory paths `OpenModelica<USERNAME>/OMEdit`
so the complete path is usually `/tmp/OpenModelica<USERNAME>/OMEdit`.

On Windows its the path in the `TEMP` or `TMP` environment variable appended with directory paths
`OpenModelica/OMEdit` so the complete path is usually `%TEMP%/OpenModelica/OMEdit`.

All the log files are always generated in the temporary directory. Choose *Tools > Open Temporary Directory*
to open the temporary directory.

By default the working directory has the same path as the temporary directory. You can change
the working directory from *Tools > Options > General* see section :ref:`omedit-options-general`.

For each simulation a new directory with the model name is created in the working directory and
then all the simulation intermediate and results files are generated in it.


High DPI Settings
-----------------

When the text is too big / too small to read there are options to change the font size
used in OMEdit, see :ref:`omedit-options-text-editor`.

If you are using a high-resolution screen (1080p, 4k and more) and the app is blurry or
the overall proportions of the different windows are off, it can help to change the DPI settings.

On Windows it is possible to change the scaling factor to adjust the size of text, apps
and other times, but the default setting might not be appropriate for OMEdit e.g., on
compact notebooks with high resolution screens.

You can either change the scaling factor for the whole Windows system or only change the
scaling used for OMEdit. This is done by changing the `Compatibility` settings for
`High DPI settings for OMEdit.exe` with the following steps:

1. Press `Windows-Key` and type `OpenModelica Connection Editor` and right-click on the
   app and `Open file location`, :numref:`omedit-file-location`.
2. Right-click on `OpenModelica Connection Editor` and open `Properties`.
3. In the properties window go to tab `Compatibility` and open `Change high DPI settings`.
   In the `High DPI settings for OMEdit.exe` choose
   `Use the settings to fix scaling problems for this program instead of the one in Settings`
   and `Override high DPI scaling behavior.Scaling performed by:` and choose `System` from
   the drop-down menu, :numref:`omedit-dpi-settings`.


.. figure :: media/omedit-dpi-settings-01.*
  :name: omedit-file-location

  Open file location of OpenModelica Connection Editor

.. figure :: media/omedit-dpi-settings-02.*
  :name: omedit-dpi-settings

  Change high DPI settings for OMEdit.exe
