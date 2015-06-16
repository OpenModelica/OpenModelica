Major OpenModelica Releases
===========================

This Appendix lists the most important OpenModelica releases and a brief
description of their contents. Right now the versions from 1.3.1 to
1.9.2 are described.

OpenModelica 1.9.2, February 2015
---------------------------------

The most important enhancements in the OpenModelica 1.9.2 release:

-  The OpenModelica compiler has moved to a new development and release
       platform: the bootstrapped OpenModelica compiler. This gives
       advantages in terms of better programmability, maintenance,
       debugging, modularity and current/future performance increases.

-  The OpenModelica graphic connection editor OMEdit has become 3-5
       times faster due to faster communication with the OpenModelica
       compiler linked as a DLL. This was made possible by moving to the
       bootstrapped compiler.

-  Further improved simulation coverage for a number of libraries.

-  OMEdit graphic connection editor improvements

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release mainly includes improvements of the OpenModelica Compiler
(OMC), including, but not restricted to the following:

-  The OpenModelica compiler has moved to a new development and release
       platform: the bootstrapped OpenModelica compiler. This gives
       advantages in terms of better programmability, maintenance,
       debugging, modularity and current/future performance increases.

-  Further improved simulation coverage for a number of libraries
       compared to 1.9.1 (Oct 25, 2014). For example:

   -  MSL 3.2.1 100% compilation, 97% simulation (3% increase)

   -  MSL Trunk 99% compilation (1% increase), 93% simulation (3%
      increase)

   -  ModelicaTest 3.2.1 99% compilation (2% increase), 95% simulation
      (6% increase)

   -  ThermoSysPro 100% compilation, 80% simulation (17% increase)

   -  ThermoPower 97% compilation (5% increase), 85% simulation (5%
      increase)

   -  Buildings 80% compilation (1% increase), 73% simulation (1%
      increase)

-  Further enhanced OMC compiler front-end coverage, scalability, speed
       and memory.

-  Better initialization.

-  Improved tearing.

-  Improved non-linear, linear and mixed system solving.

-  Common subexpression elimination support - drastically increases
       performance of some models.

   1. OpenModelica Notebook (OMNotebook)

No changes apart from bug fixing.

OpenModelica Shell (OMShell)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

No changes.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

No changes apart from bug fixing.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

No changes apart from bug fixing.

Graphic Editor OMEdit
~~~~~~~~~~~~~~~~~~~~~

-  The OpenModelica graphic connection editor OMEdit has become 3-5
       times faster due to faster communication with the OpenModelica
       compiler linked as a DLL. This was made possible by moving to the
       bootstrapped compiler.

-  Enhanced simulation setup window in OMEdit, which among other things
       include better support for integration methods and dassl options.

-  Support for running multiple simultaneous simulation.

-  Improved handling of modifiers.

-  Re-simulate with changed options, including history support and
       re-simulating with previous options possibly edited.

-  More user friendly user interface by improved connection line
       drawing, added snap to grid for icons and conversion of icons
       from PNG to SVG, and some additional fixes.

Optimization
~~~~~~~~~~~~

Some smaller improvements of the Dynamic Optimization module with
collocation, using Ipopt.

FMI Support
~~~~~~~~~~~

Further improved for FMI 2.0 model exchange import and export, now
compliant according to the FMI compliance tests. FMI 1.0 support has
been further improved.

OpenModelica 1.9.1, October 2014
--------------------------------

The most important enhancements in the OpenModelica 1.9.1 release:

-  Improved library support.

-  Further enhanced OMC compiler front-end coverage and scalability

-  Significant improved simulation support for libraries using Fluid and
       Media.

-  Dynamic model debugger for equation-based models integrated with
       OMEdit.

-  Dynamic algorithm model debugger with OMEdit; including support for
       MetaModelica when using the bootstrapped compiler.

New features: Dynamic debugger for equation-based models; Dynamic
Optimization with collocation built into OpenModelica, performance
analyzer integrated with the equation model debugger.

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release mainly includes improvements of the OpenModelica Compiler
(OMC), including, but not restricted to the following:

-  Further improved OMC model compiler support for a number of libraries
       including MSL 3.2.1, ModelicaTest 3.2.1, PetriNet, Buildings,
       PowerSystems, OpenHydraulics, ThermoPower, and ThermoSysPro.

-  Further enhanced OMC compiler front-end coverage, scalability, speed
       and memory.

-  Better coverage of Modelica libraries using Fluid and Media.

-  Automatic differentiation of algorithms and functions.

-  Improved testing facilities and library coverage reporting.

-  Improved model compilation speed by compiling model parts in parallel
       (bootstrapped compiler).

-  Support for running model simulations in a web browser.

-  New faster initialization that handles over-determined systems,
       under-determined systems, or both.

-  Compiler back-end partly redesigned for improved scalability and
       better modularity.

-  Better tearing support.

-  The first run-time Modelica equation-based model debugger, not
       available in any other Modelica tool, integrated with OMEdit.

-  Enhanced performance profiler integrated with the debugger.

-  Improved parallelization prototype with several parallelization
       strategies, task merging and duplication, shorter critical paths,
       several scheduling strategies.

-  Some support for general solving of mixed systems of equations.

-  Better error messages.

-  Improved bootstrapped OpenModelica compiler.

-  Better handling of array subscripts and dimensions.

-  Improved support for reduction functions and operators.

-  Better support for partial functions.

-  Better support for function tail recursion, which reduces memory
       usage.

-  Partial function evaluation in the back-end to improve solving
       singular systems.

-  Better handling of events/zero crossings.

-  Support for colored Jacobians.

-  New differentiation package that can handle a much larger number of
       expressions.

-  Support for sparse solvers.

-  Better handling of asserts.

-  Improved array and matrix support.

-  Improved overloaded operators support.

-  Improved handling of overconstrained connection graphs.

-  Better support for the cardinality operator.

-  Parallel compilation of generated code for speeding up compilation.

-  Split of model files into several for better compilation scalability.

-  Default linear tearing.

-  Support for impure functions.

-  Better compilation flag documentation.

-  Better automatic generation of documentation.

-  Better support for calling functions via instance.

-  New text template based unparsing for DAE, Absyn, SCode, TaskGraphs,
       etc.

-  Better support for external objects.

-  Improved C++ runtime.

-  Improved testing facilities.

-  New unit checking implementation.

-  Support for model rewriting expressions via rewriting rules in an
       external file.

   1. OpenModelica Notebook (OMNotebook)

No changes apart from bug fixing.

OpenModelica Shell (OMShell)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

No changes.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

No changes apart from bug fixing.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

No changes apart from bug fixing.

Graphic Editor OMEdit
~~~~~~~~~~~~~~~~~~~~~

-  Convenient editing of model parameter values and re-simulation
   without recompilation after parameter changes.

-  Improved plotting.

-  Better handling of flags/units/resources/crashes.

-  Run-time Modelica equation-based model debugger that provides both
   dynamic run-time debugging and debugging of symbolic transformations.

-  Run-time Modelica algorithmic code debugger; also MetaModelica
   debugger with the bootstrapped OpenModelica compiler.

Optimization
~~~~~~~~~~~~

A builtin integrated Dynamic Optimization module with collocation, using
Ipopt, is now available.

FMI Support
~~~~~~~~~~~

Support for FMI 2.0 model exchange import and export has been added. FMI
1.0 support has been further improved.

OpenModelica 1.9.0, October 2013
--------------------------------

The three most important enhancements in the OpenModelica 1.9.0 release:

-  OpenModelica compiler support for most of the Fluid library.

-  Support for the significantly updated library MSL 3.2.1 final
       version.

-  Significantly enhanced graphical user interface in OMEdit.

New features: integration of the PySimulator analysis package; Dynamic
Optimization with CasADi.

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release mainly includes improvements of the OpenModelica Compiler
(OMC), including, but not restricted to the following:

-  A more stable and complete OMC model compiler. The 1.9.0 final
       version simulates many more models than the previous 1.8.1
       version and OpenModelica 1.9.0 beta versions.

-  Much better simulation support for MSL 3.2.1, now 270 out of 274
       example models compile (98%) and 247 (90%) simulate, compared to
       30% simulating in the 1.9.0 beta1 release.

-  Much better simulation for the ModelicaTest 3.2.1 library, now 412
       out of 428 models compile (96%), and 380 (88%) simulate, compared
       to 32% in November 2012.

-  Improved tearing algorithm for the compiler backend. Tearing is by
       default used.

-  Much faster matching and dynamic state selection algorithms for the
       compiler backend.

-  New index reduction algorithm implementation.

-  New default initialization method that symbolically solves the
       initialization problem much faster and more accurately. This is
       the first version that in general initialize hybrid models
       correctly.

-  Better class loading from files. The package.order file is now
       respected and the file structure is more thoroughly examined.

-  Basic support for pure/impure functions.

-  It is now possible to translate the error messages in the omc kernel.

-  Enhanced ModelicaML version with support for value bindings in
       requirements-driven modeling available for the latest Eclipse and
       Papyrus versions. GUI specific adaptations. Automated model
       composition workflows (used for model-based design verification
       against requirements) are modularized and have improved in terms
       of performance.

-  FMI for co-simulation with OMC as master. Improved FMI import/export,
       model exchange.

-  Checking (when possible) that variables have been assigned to before
       they are used in algorithmic code.

-  Full version of Python scripting.

-  3D graphics visualization using the Modelica3D library.

-  The PySimulator package from DLR for additional analysis is
       integrated with OpenModelica (see Modelica2012 paper), and
       included in the OpenModelica distribution.

-  Prototype support for uncertainty computations, special feature
       enabled by special flag.

-  Parallel algorithmic Modelica support (ParModelica) for efficient
       portable parallel algorithmic programming based on the OpenCL
       standard, for CPUs and GPUs.

-  Support for optimization of semiLinear according to :ref:`modelicaspec:operator-semiLinear`.

OpenModelica Notebook (OMNotebook)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The DrModelica interactive document has been updated and the models
tested. Almost all models now simulate with OpenModelica.

OpenModelica Shell (OMShell)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

No changes.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Enhanced debugger for algorithmic Modelica code, supporting both
standard Modelica algorithmic code called from simulation models, and
MetaModelica code.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Migration of version handling and configuration management from
CodeBeamer to Trac.

Graphic Editor OMEdit
~~~~~~~~~~~~~~~~~~~~~

-  General GUI: backward and forward navigation support in Documentation
       view, enhanced parameters window with support for Dialog
       annotation. Most of the images are converted from raster to
       vector graphics i.e PNG to SVG.

-  Libraries Browser: better loading of libraries, library tree can now
       show protected classes, show library items class names as middle
       ellipses if the class name text is larger, more options via the
       right click menu for quick usage.

-  ModelWidget: add the partial class as a replaceable component, look
       for the default component prefixes and name when adding the
       component.

-  GraphicsView: coordinate system manipulation for icon and diagram
       layers. Show red box for models that do not exist. Show default
       graphical annotation for the components that doesn’t have any
       graphical annotations. Better resizing of the components.
       Properties dialog for primitive shapes i.e Line, Polygon,
       Rectangle, Ellipse, Text and Bitmap.

-  File Opening: open one or more Modelica files, allow users to select
       the encoding while opening the file, convert files to UTF-8
       encoding, allow users to open the OpenModelica result files.

-  Variables Browser: find variables in the variables browser, sorting
       in the variables browser.

-  Plot Window: clear all curves of the plot window, preserve the old
       selected variable and update its value with the new simulation
       result.

-  Simulation: support for all the simulation flags, read the simulation
       output as soon as is is obtained, output window for simulations,
       options to set matching algorithm and index reduction method for
       simulation. Display all the files generated during the simulation
       is now supported. Options to set OMC command line flags.

-  Options: options for loading libraries via loadModel and loadFile
       each time GUI starts, save the last open file directory location,
       options for setting line wrap mode and syntax highlighting.

-  Modelica Text Editor: preserving user customizations, new search &
       replace functionality, support for comment/uncomment.

-  Notifications: show custom dialogs to users allowing them to choose
       whether they want to see this dialog again or not.

-  Model Creation: Better support for creating new classes. Easy
       creation of extends classes or nested classes.

-  Messages Widget: Multi line error messages are now supported.

-  Crash Detection: The GUI now automatically detects the crash and
       writes a stack trace file. The user is given an option to send a
       crash report along with the stack trace file and few other useful
       files via email.

-  Autosave: OMEdit saves the currently edited model regularly, in order
       to avoid losing edits after GUI or compiler crash. The save
       interval can be set in the Options menu.

Optimization
~~~~~~~~~~~~

Dynamic optimization with XML export to the CaSAdi package is now
integrated with OpenModelica. Moreover, a native integrated Dynamic
Optimization prototype using Ipopt is now in the OpenModelica release,
but currently needs a special flag to be turned on since it needs more
testing and refinement before being generally made available.

FMI Support
~~~~~~~~~~~

FMI co-simulation with OpenModelica as master. Improved FMI Import and
export for model exchange. Simulation of multiple instances of the FMU
is now possible. Partial support for FMI 2.0 model exchange.

OpenModelica 1.8.1, March 2012
------------------------------

The OpenModelica 1.8.1 release has a faster and more stable OMC model
compiler. It flattens and simulates more models than the previous 1.8.0
version. Significant flattening speedup of the compiler has been
achieved for certain large models. It also contains a New ModelicaML
version with support for value bindings in requirements-driven modeling
and importing Modelica library models into ModelicaML models. A beta
version of the new OpenModelica Python scripting is also included.

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release includes bug fixes and improvements of the flattening
frontend part of the OpenModelica Compiler (OMC) and several
improvements of the backend, including, but not restricted to:

-  A faster and more stable OMC model compiler. The 1.8.1 version
       flattens and simulates more models than the previous 1.8.0
       version.

-  Support for operator overloading (except Complex numbers).

-  New ModelicaML version with support for value bindings in
       requirements-driven modeling and importing Modelica library
       models into ModelicaML models.

-  Faster plotting in OMNotebook. The feature sendData has been removed
       from OpenModelica. As a result, the kernel no longer depends on
       Qt. The plot3() family of functions have now replaced to plot(),
       which in turn have been removed. The non-standard visualize()
       command has been removed in favour of more recent alternatives.

-  Store OpenModelica documentation as Modelica Documentation
       annotations.

-  Re-implementation of the simulation runtime using C instead of C++
       (this was needed to export FMI source-based packages).

-  FMI import/export bug fixes.

-  Changed the internal representation of various structures to share
       more memory. This significantly improved the performance for very
       large models that use records.

-  Faster model flattening, Improved simulation, some graphical API bug
       fixes.

-  More robust and general initialization, but currently time-consuming.

-  New initialization flags to omc and options to simulate(), to control
       whether fast or robust initialization is selected, or
       initialization from an external (.mat) data file.

-  New options to API calls list, loadFile, and more.

-  Enforce the restriction that input arguments of functions may not be
       assigned to.

-  Improved the scripting environment. cl :=
       $TypeName(Modelica);getClassComment(cl); now works as expected.
       As does looping over lists of typenames and using reduction
       expressions.

-  Beta version of Python scripting.

-  Various bugfixes.

-  NOTE: interactive simulation is not operational in this release. It
       will be put back again in the near future, first available as a
       nightly build. It is also available in the previous 1.8.0
       release.

   1. OpenModelica Notebook (OMNotebook)

Faster and more stable plottning.

OpenModelica Shell (OMShell)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

No changes.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Small fixes and improvements.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

No changes.

Graphic Editor OMEdit
~~~~~~~~~~~~~~~~~~~~~

Bug fixes.

New OMOptim Optimization Subsystem
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Bug fixes.

FMI Support
~~~~~~~~~~~

Bug fixes.

OpenModelica 1.8, November 2011
-------------------------------

The OpenModelica 1.8 release contains OMC flattening improvements for
the Media library – it now flattens the whole library and simulates
about 20% of its example models. Moreover, about half of the Fluid
library models also flatten. This release also includes two new tool
functionalities – the FMI for model exchange import and export, and a
new efficient Eclipse-based debugger for Modelica/MetaModelica
algorithmic code.

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release includes bug fixes and improvements of the flattening
frontend part of the OpenModelica Compiler (OMC) and several
improvements of the backend, including, but not restricted to:

-  A faster and more stable OMC model compiler. The 1.8.1 version
       flattens and simulates more models than the previous 1.7.0
       version.

-  Flattening of the whole Media library, and about half of the Fluid
       library. Simulation of approximately 20% of the Media library
       example models.

-  Functional Mockup Interface FMI 1.0 for model exchange, export and
       import, for the Windows platform.

-  Bug fixes in the OpenModelica graphical model connection editor
       OMEdit, supporting easy-to-use graphical drag-and-drop modeling
       and MSL 3.1.

-  Bug fixes in the OMOptim optimization subsystem.

-  Beta version of compiler support for a new Eclipse-based very
       efficient algorithmic code debugger for functions in
       MetaModelica/Modelica, available in the development environment
       when using the bootstrapped OpenModelica compiler.

-  Improvements in initialization of simulations.

-  Improved index reduction with dynamic state selection, which improves
       simulation.

-  Better error messages from several parts of the compiler, including a
       new API call for giving better error messages.

-  Automatic partitioning of equation systems and multi-core parallel
       simulation of independent parts based on the shared-memory OpenMP
       model. This version is a preliminary experimental version without
       load balancing.

   1. OpenModelica Notebook (OMNotebook)

No changes.

OpenModelica Shell (OMShell)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Small performance improvements.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Small fixes and improvements. MDT now also includes a beta version of a
new Eclipse-based very efficient algorithmic code debugger for functions
in MetaModelica/Modelica.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Third party binaries, including Qt libraries and executable Qt clients,
are now part of the OMDev package. Also, now uses GCC 4.4.0 instead of
the earlier GCC 3.4.5.

Graphic Editor OMEdit
~~~~~~~~~~~~~~~~~~~~~

Bug fixes. Access to FMI Import/Export through a pull-down menu.
Improved configuration of library loading. A function to go to a
specific line number. A button to cancel an on-going simulation. Support
for some updated OMC API calls.

New OMOptim Optimization Subsystem
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Bug fixes, especially in the Linux version.

FMI Support
~~~~~~~~~~~

The Functional Mockup Interface FMI 1.0 for model exchange import and
export is supported by this release. The functionality is accessible via
API calls as well as via pull-down menu commands in OMEdit.

OpenModelica 1.7, April 2011
----------------------------

The OpenModelica 1.7 release contains OMC flattening improvements for
the Media library, better and faster event handling and simulation, and
fast MetaModelica support in the compiler, enabling it to compiler
itself. This release also includes two interesting new tools – the
OMOptim optimization subsystem, and a new performance profiler for
equation-based Modelica models.

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release includes bug fixes and performance improvements of the
flattening frontend part of the OpenModelica Compiler (OMC) and several
improvements of the backend, including, but not restricted to:

-  Flattening of the whole Modelica Standard Library 3.1 (MSL 3.1),
       except Media and Fluid.

-  Progress in supporting the Media library, some models now flatten.

-  Much faster simulation of many models through more efficient handling
       of alias variables, binary output format, and faster event
       handling.

-  Faster and more stable simulation through new improved event
       handling, which is now default.

-  Simulation result storage in binary .mat files, and plotting from
       such files.

-  Support for Unicode characters in quoted Modelica identifiers,
       including Japanese and Chinese.

-  Preliminary MetaModelica 2.0 support. (use
       setCommandLineOptions({"+g=MetaModelica"}) ). Execution is as
       fast as MetaModelica 1.0, except for garbage collection.

-  Preliminary bootstrapped OpenModelica compiler: OMC now compiles
       itself, and the bootstrapped compiler passes the test suite. A
       garbage collector is still missing.

-  Many bug fixes.

OpenModelica Notebook (OMNotebook)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Improved much faster and more stable 2D plotting through the new OMPlot
module. Plotting from binary .mat files. Better integration between
OMEdit and OMNotebook, copy/paste between them.

OpenModelica Shell (OMShell)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Same as previously, except the improved 2D plotting through OMPlot.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Same as previously.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

No changes.

Graphic Editor OMEdit
~~~~~~~~~~~~~~~~~~~~~

Several enhancements of OMEdit are included in this release. Support for
Icon editing is now available. There is also an improved much faster 2D
plotting through the new OMPlot module. Better integration between
OMEdit and OMNotebook, with copy/paste between them. Interactive on-line
simulation is available in an easy-to-use way.

New OMOptim Optimization Subsystem
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A new optimization subsystem called OMOptim has been added to
OpenModelica. Currently, parameter optimization using genetic algorithms
is supported in this version 0.9. Pareto front optimization is also
supported.

New Performance Profiler
~~~~~~~~~~~~~~~~~~~~~~~~

A new, low overhead, performance profiler for Modelica models has been
developed.

OpenModelica 1.6, November 2010
-------------------------------

The OpenModelica 1.6 release primarily contains flattening, simulation,
and performance improvements regarding Modelica Standard Library 3.1
support, but also has an interesting new tool – the OMEdit graphic
connection editor, and a new educational material called DrControl, and
an improved ModelicaML UML/Modelica profile with better support for
modeling and requirement handling.

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release includes bug fix and performance improvemetns of the
flattening frontend part of the OpenModelica Compiler (OMC) and some
improvements of the backend, including, but not restricted to:

-  Flattening of the whole Modelica Standard Library 3.1 (MSL 3.1),
       except Media and Fluid.

-  Improved flattening speed of a factor of 5-20 compared to
       OpenModelica 1.5 for a number of models, especially in the
       MultiBody library.

-  Reduced memory consumption by the OpenModelica compiler frontend, for
       certain large models a reduction of a factor 50.

-  Reorganized, more modular OpenModelica compiler backend, can now
       handle approximately 30 000 equations, compared to previously
       approximately 10 000 equations.

-  Better error messages from the compiler, especially regarding
       functions.

-  Improved simulation coverage of MSL 3.1. Many models that did not
       simulate before are now simulating. However, there are still many
       models in certain sublibraries that do not simulate.

-  Progress in supporting the Media library, but simulation is not yet
       possible.

-  Improved support for enumerations, both in the frontend and the
       backend.

-  Implementation of stream connectors.

-  Support for linearization through symbolic Jacobians.

-  Many bug fixes.

OpenModelica Notebook (OMNotebook)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A new DrControl electronic notebook for teaching control and modeling
with Modelica.

OpenModelica Shell (OMShell)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Same as previously.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Same as previously.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Several enhancements. Support for match-expressions in addition to
matchcontinue. Support for real if-then-else. Support for if-then
without else-branches. Modelica Development Tooling 0.7.7 with small
improvements such as more settings, improved error detection in console,
etc.

New Graphic Editor OMEdit
~~~~~~~~~~~~~~~~~~~~~~~~~

A new improved open source graphic model connection editor called
OMEdit, supporting 3.1 graphical annotations, which makes it possible to
move models back and forth to other tools without problems. The editor
has been implemented by students at Linköping University and is based on
the C++ Qt library.

OpenModelica 1.5, July 2010
---------------------------

This OpenModelica 1.5 release has major improvements in the OpenModelica
compiler frontend and some in the backend. A major improvement of this
release is full flattening support for the MultiBody library as well as
limited simulation support for MultiBody. Interesting new facilities are
the interactive simulation and the integrated UML-Modelica modeling with
ModelicaML. Approximately 4 person-years of additional effort have been
invested in the compiler compared to the 1.4.5 version, e.g., in order
to have a more complete coverage of Modelica 3.0, mainly focusing on
improved flattening in the compiler frontend.

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release includes major improvements of the flattening frontend part
of the OpenModelica Compiler (OMC) and some improvements of the backend,
including, but not restricted to:

-  Improved flattening speed of at least a factor of 10 or more compared
       to the 1.4.5 release, primarily for larger models with
       inner-outer, but also speedup for other models, e.g. the robot
       model flattens in approximately 2 seconds.

-  Flattening of all MultiBody models, including all elementary models,
       breaking connection graphs, world object, etc. Moreover,
       simulation is now possible for at least five MultiBody models:
       Pendulum, DoublePendulum, InitSpringConstant, World,
       PointGravityWithPointMasses.

-  Progress in supporting the Media library, but simulation is not yet
       possible.

-  Support for enumerations, both in the frontend and the backend.

-  Support for expandable connectors.

-  Support for the inline and late inline annotations in functions.

-  Complete support for record constructors, also for records containing
       other records.

-  Full support for iterators, including nested ones.

-  Support for inferred iterator and for-loop ranges.

-  Support for the function derivative annotation.

-  Prototype of interactive simulation.

-  Prototype of integrated UML-Modelica modeling and simulation with
       ModelicaML.

-  A new bidirectional external Java interface for calling external Java
       functions, or for calling Modelica functions from Java.

-  Complete implementation of replaceable model extends.

-  Fixed problems involving arrays of unknown dimensions.

-  Limited support for tearing.

-  Improved error handling at division by zero.

-  Support for Modelica 3.1 annotations.

-  Support for all MetaModelica language constructs inside OpenModelica.

-  OpenModelica works also under 64-bit Linux and Mac 64-bit OSX.

-  Parallel builds and running test suites in parallel on multi-core
       platforms.

-  New OpenModelica text template language for easier implementation of
       code generators, XML generators, etc.

-  New OpenModelica code generators to C and C# using the text template
       language.

-  Faster simulation result data file output optionally as
       comma-separated values.

-  Many bug fixes.

It is now possible to graphically edit models using parts from the
Modelica Standard Library 3.1, since the simForge graphical editor (from
Politecnico di Milano) that is used together with OpenModelica has been
updated to version 0.9.0 with a important new functionality, including
support for Modelica 3.1 and 3.0 annotations. The 1.6 and 2.2.1 Modelica
graphical annotation versions are still supported.

OpenModelica Notebook (OMNotebook)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Improvements in platform availability.

-  Support for 64-bit Linux.

-  Support for Windows 7.

-  Better support for MacOS, including 64-bit OSX.

OpenModelica Shell (OMShell)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Same as previously.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Minor bug fixes.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Minor bug fixes.

OpenModelica 1.4.5, January 2009
--------------------------------

This release has several improvements, especially platform availability,
less compiler memory usage, and supporting more aspects of Modelica 3.0.

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release includes small improvements and some bugfixes of the
OpenModelica Compiler (OMC):

-  Less memory consumption and better memory management over time. This
       also includes a better API supporting automatic memory management
       when calling C functions from within the compiler.

-  Modelica 3.0 parsing support.

-  Export of DAE to XML and MATLAB.

-  Support for several platforms Linux, MacOS, Windows (2000, Xp,
       Vista).

-  Support for record and strings as function arguments.

-  Many bug fixes.

-  (Not part of OMC): Additional free graphic editor SimForge can be
       used with OpenModelica.

OpenModelica Notebook (OMNotebook)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A number of improvements, primarily in the plotting functionality and
platform availability.

-  A number of improvements in the plotting functionality: scalable
       plots, zooming, logarithmic plots, grids, etc.

-  Programmable plotting accessible through a Modelica API.

-  Simple 3D visualization.

-  Support for several platforms Linux, MacOS, Windows (2000, Xp,
       Vista).

OpenModelica Shell (OMShell)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Same as previously.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Minor bug fixes.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Same as previously.

OpenModelica 1.4.4, Feb 2008
----------------------------

This release is primarily a bug fix release, except for a preliminary
version of new plotting functionality available both from the OMNotebook
and separately through a Modelica API. This is also the first release
under the open source license OSMC-PL (Open Source Modelica Consortium
Public License), with support from the recently created Open Source
Modelica Consortium. An integrated version handler, bug-, and issue
tracker has also been added.

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release includes small improvements and some bugfixes of the
OpenModelica Compiler (OMC):

-  Better support for if-equations, also inside when.

-  Better support for calling functions in parameter expressions and
       interactively through dynamic loading of functions.

-  Less memory consumtion during compilation and interactive evaluation.

-  A number of bug-fixes.

OpenModelica Notebook (OMNotebook)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Test release of improvements, primarily in the plotting functionality
and platform availability.

-  Preliminary version of improvements in the plotting functionality:
       scalable plots, zooming, logarithmic plots, grids, etc.,
       currently available in a preliminary version through the plot2
       function.

-  Programmable plotting accessible through a Modelica API.

OpenModelica Shell (OMShell)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Same as previously.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release includes minor bugfixes of MDT and the associated
MetaModelica debugger.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Extended test suite with a better structure. Version handling, bug
tracking, issue tracking, etc. now available under the integrated
Codebeamer

OpenModelica 1.4.3, June 2007
-----------------------------

This release has a number of significant improvements of the OMC
compiler, OMNotebook, the MDT plugin and the OMDev. Increased platform
availability now also for Linux and Macintosh, in addition to Windows.
OMShell is the same as previously, but now ported to Linux and Mac.

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release includes a number of improvements of the OpenModelica
Compiler (OMC):

-  Significantly increased compilation speed, especially with large
       models and many packages.

-  Now available also for Linux and Macintosh platforms.

-  Support for when-equations in algorithm sections, including elsewhen.

-  Support for inner/outer prefixes of components (but without type
       error checking).

-  Improved solution of nonlinear systems.

-  Added ability to compile generated simulation code using Visual
       Studio compiler.

-  Added "smart setting of fixed attribute to false. If initial
       equations, OMC instead has fixed=true as default for states due
       to allowing overdetermined initial equation systems.

-  Better state select heuristics.

-  New function getIncidenceMatrix(ClassName) for dumping the incidence
       matrix.

-  Builtin functions String(), product(), ndims(), implemented.

-  Support for terminate() and assert() in equations.

-  In emitted flat form: protected variables are now prefixed with
       protected when printing flat class.

-  Some support for tables, using omcTableTimeIni instead of
       dymTableTimeIni2.

-  Better support for empty arrays, and support for matrix operations
       like a\*[1,2;3,4].

-  Improved val() function can now evaluate array elements and record
       fields, e.g. val(x[n]), val(x.y) .

-  Support for reinit in algorithm sections.

-  String support in external functions.

-  Double precision floating point precision now also for interpreted
       expressions

-  Better simulation error messages.

-  Support for der(expressions).

-  Support for iterator expressions such as {3\*i for i in 1..10}.

-  More test cases in the test suite.

-  A number of bug fixes, including sample and event handling bugs.

   1. OpenModelica Notebook (OMNotebook)

A number of improvements, primarily in the platform availability.

-  Available on the Linux and Macintosh platforms, in addition to
       Windows.

-  Fixed cell copying bugs, plotting of derivatives now works, etc.

   1. OpenModelica Shell (OMShell)

Now available also on the Macintosh platform.

1. OpenModelica Eclipse Plug-in (MDT)

This release includes major improvements of MDT and the associated
MetaModelica debugger:

-  Greatly improved browsing and code completion works both for standard
       Modelica and for MetaModelica.

-  Hovering over identifiers displays type information.

-  A new and greatly improved implementation of the debugger for
       MetaModelica algorithmic code, operational in Eclipse. Greatly
       improved performance – only approx 10% speed reduction even for
       100 000 line programs. Greatly improved single stepping, step
       over, data structure browsing, etc.

-  Many bug fixes.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Increased compilation speed for MetaModelica. Better if-expression
support in MetaModelica.

OpenModelica 1.4.2, October 2006
--------------------------------

This release has improvements and bug fixes of the OMC compiler,
OMNotebook, the MDT plugin and the OMDev. OMShell is the same as
previously.

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release includes further improvements of the OpenModelica Compiler
(OMC):

-  Improved initialization and index reduction.

-  Support for integer arrays is now largely implemented.

-  The val(variable,time) scripting function for accessing the value of
       a simulation result variable at a certain point in the simulated
       time.

-  Interactive evalution of for-loops, while-loops, if-statements,
       if-expressions, in the interactive scripting mode.

-  Improved documentation and examples of calling the Model Query and
       Manipulation API.

-  Many bug fixes.

OpenModelica Notebook (OMNotebook)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Search and replace functions have been added. The DrModelica tutorial
(all files) has been updated, obsolete sections removed, and models
which are not supported by the current implementation marked clearly.
Automatic recognition of the .onb suffix (e.g. when double-clicking) in
Windows makes it even more convenient to use.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Two major improvements are added in this release:

-  Browsing and code completion works both for standard Modelica and for
       MetaModelica.

-  The debugger for algorithmic code is now available and operational in
       Eclipse for debugging of MetaModelica programs.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Mostly the same as previously.

OpenModelica 1.4.1, June 2006
-----------------------------

This release has only improvements and bug fixes of the OMC compiler,
the MDT plugin and the OMDev components. The OMShell and OMNotebook are
the same.

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release includes further improvements of the OpenModelica Compiler
(OMC):

-  Support for external objects.

-  OMC now reports the version number (via command line switches or
       CORBA API getVersion()).

-  Implemented caching for faster instantiation of large models.

-  Many bug fixes.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Improvements of the error reporting when building the OMC compiler. The
errors are now added to the problems view. The latest MDT release is
version 0.6.6 (2006-06-06).

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Small fixes in the MetaModelica compiler. MetaModelica Users Guide is
now part of the OMDev release. The latest OMDev was release in
2006-06-06.

OpenModelica 1.4.0, May 2006
----------------------------

This release has a number of improvements described below. The most
significant change is probably that OMC has now been translated to an
extended subset of Modelica (MetaModelica), and that all development of
the compiler is now done in this version..

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release includes further improvements of the OpenModelica Compiler
(OMC):

-  Partial support for mixed system of equations.

-  New initialization routine, based on optimization (minimizing
       residuals of initial equations).

-  Symbolic simplification of builtin operators for vectors and
       matrices.

-  Improved code generation in simulation code to support e.g. Modelica
       functions.

-  Support for classes extending basic types, e.g. connectors (support
       for MSL 2.2 block connectors).

-  Support for parametric plotting via the plotParametric command.

-  Many bug fixes.

OpenModelica Shell (OMShell)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Essentially the same OMShell as in 1.3.1. One difference is that now all
error messages are sent to the command window instead of to a separate
log window.

OpenModelica Notebook (OMNotebook)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Many significant improvements and bug fixes. This version supports
graphic plots within the cells in the notebook. Improved cell handling
and Modelica code syntax highlighting. Command completion of the most
common OMC commands is now supported. The notebook has been used in
several courses.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This is the first really useful version of MDT. Full browsing of
Modelica code, e.g. the MSL 2.2, is now supported. (MetaModelica
browsing is not yet fully supported). Full support for automatic
indentation of Modelica code, including the MetaModelica extensions.
Many bug fixes. The Eclipse plug-in is now in use for OpenModelica
development at PELAB and MathCore Engineering AB since approximately one
month.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following mechanisms have been put in place to support OpenModelica
development.

-  A separate web page for OMDev (OpenModelica Development Environment).

-  A pre-packaged OMDev zip-file with precompiled binaries for
       development under Windows using the mingw Gnu compiler from the
       Eclipse MDT plug-in. (Development is also possible using Visual
       Studio).

-  All source code of the OpenModelica compiler has recently been
       translated to an extended subset of Modelica, currently called
       MetaModelica. The current size of OMC is approximately 100 000
       lines All development is now done in this version.

-  A new tutorial and users guide for development in MetaModelica.

-  Successful builds and tests of OMC under Linux and Solaris.

OpenModelica 1.3.1, November 2005
---------------------------------

This release has several important highlights.

This is also the *first* release for which the New BSD (Berkeley)
open-source license applies to the source code, including the whole
compiler and run-time system. This makes is possible to use OpenModelica
for both academic and commercial purposes without restrictions.

OpenModelica Compiler (OMC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This release includes a significantly improved OpenModelica Compiler
(OMC):

-  Support for hybrid and discrete-event simulation (if-equations,
       if-expressions, when-equations; not yet if-statements and
       when-statements).

-  Parsing of full Modelica 2.2

-  Improved support for external functions.

-  Vectorization of function arguments; each-modifiers, better
       implementation of replaceable, better handling of structural
       parameters, better support for vector and array operations, and
       many other improvements.

-  Flattening of the Modelica Block library version 1.5 (except a few
       models), and simulation of most of these.

-  Automatic index reduction (present also in previous release).

-  Updated User's Guide including examples of hybrid simulation and
       external functions.

OpenModelica Shell (OMShell)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An improved window-based interactive command shell, now including
command completion and better editing and font size support.

OpenModelica Notebook (OMNotebook)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A free implementation of an OpenModelica notebook (OMNotebook), for
electronic books with course material, including the DrModelica
interactive course material. It is possible to simulate and plot from
this notebook.

OpenModelica Eclipse Plug-in (MDT)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An early alpha version of the first Eclipse plug-in (called MDT for
Modelica Development Tooling) for Modelica Development. This version
gives compilation support and partial support for browsing Modelica
package hierarchies and classes.

OpenModelica Development Environment (OMDev)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following mechanisms have been put in place to support OpenModelica
development.

-  Bugzilla support for OpenModelica bug tracking, accessible to
       anybody.

-  A system for automatic regression testing of the compiler and
       simulator, (+ other system parts) usually run at check in time.

-  Version handling is done using SVN, which is better than the
       previously used CVS system. For example, name change of modules
       is now possible within the version handling system.
