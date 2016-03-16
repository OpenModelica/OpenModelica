Major OpenModelica Releases
^^^^^^^^^^^^^^^^^^^^^^^^^^^

This Appendix lists the most important OpenModelica releases and a brief
description of their contents. Right now the versions from 1.3.1 are described.

.. include :: tracreleases.inc

OpenModelica 1.8, November 2011
===============================

The OpenModelica 1.8 release contains OMC flattening improvements for
the Media library – it now flattens the whole library and simulates
about 20% of its example models. Moreover, about half of the Fluid
library models also flatten. This release also includes two new tool
functionalities – the FMI for model exchange import and export, and a
new efficient Eclipse-based debugger for Modelica/MetaModelica
algorithmic code.

OpenModelica Compiler (OMC)
---------------------------

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

OpenModelica Notebook (OMNotebook)
----------------------------------

No changes.

OpenModelica Shell (OMShell)
----------------------------

Small performance improvements.

OpenModelica Eclipse Plug-in (MDT)
----------------------------------

Small fixes and improvements. MDT now also includes a beta version of a
new Eclipse-based very efficient algorithmic code debugger for functions
in MetaModelica/Modelica.

OpenModelica Development Environment (OMDev)
--------------------------------------------

Third party binaries, including Qt libraries and executable Qt clients,
are now part of the OMDev package. Also, now uses GCC 4.4.0 instead of
the earlier GCC 3.4.5.

Graphic Editor OMEdit
---------------------

Bug fixes. Access to FMI Import/Export through a pull-down menu.
Improved configuration of library loading. A function to go to a
specific line number. A button to cancel an on-going simulation. Support
for some updated OMC API calls.

New OMOptim Optimization Subsystem
----------------------------------

Bug fixes, especially in the Linux version.

FMI Support
-----------

The Functional Mockup Interface FMI 1.0 for model exchange import and
export is supported by this release. The functionality is accessible via
API calls as well as via pull-down menu commands in OMEdit.

OpenModelica 1.7, April 2011
============================

The OpenModelica 1.7 release contains OMC flattening improvements for
the Media library, better and faster event handling and simulation, and
fast MetaModelica support in the compiler, enabling it to compiler
itself. This release also includes two interesting new tools – the
OMOptim optimization subsystem, and a new performance profiler for
equation-based Modelica models.

OpenModelica Compiler (OMC)
---------------------------

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
----------------------------------

Improved much faster and more stable 2D plotting through the new OMPlot
module. Plotting from binary .mat files. Better integration between
OMEdit and OMNotebook, copy/paste between them.

OpenModelica Shell (OMShell)
----------------------------

Same as previously, except the improved 2D plotting through OMPlot.

OpenModelica Eclipse Plug-in (MDT)
----------------------------------

Same as previously.

OpenModelica Development Environment (OMDev)
--------------------------------------------

No changes.

Graphic Editor OMEdit
---------------------

Several enhancements of OMEdit are included in this release. Support for
Icon editing is now available. There is also an improved much faster 2D
plotting through the new OMPlot module. Better integration between
OMEdit and OMNotebook, with copy/paste between them. Interactive on-line
simulation is available in an easy-to-use way.

New OMOptim Optimization Subsystem
----------------------------------

A new optimization subsystem called OMOptim has been added to
OpenModelica. Currently, parameter optimization using genetic algorithms
is supported in this version 0.9. Pareto front optimization is also
supported.

New Performance Profiler
------------------------

A new, low overhead, performance profiler for Modelica models has been
developed.

OpenModelica 1.6, November 2010
===============================

The OpenModelica 1.6 release primarily contains flattening, simulation,
and performance improvements regarding Modelica Standard Library 3.1
support, but also has an interesting new tool – the OMEdit graphic
connection editor, and a new educational material called DrControl, and
an improved ModelicaML UML/Modelica profile with better support for
modeling and requirement handling.

OpenModelica Compiler (OMC)
---------------------------

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
----------------------------------

A new DrControl electronic notebook for teaching control and modeling
with Modelica.

OpenModelica Shell (OMShell)
----------------------------

Same as previously.

OpenModelica Eclipse Plug-in (MDT)
----------------------------------

Same as previously.

OpenModelica Development Environment (OMDev)
--------------------------------------------

Several enhancements. Support for match-expressions in addition to
matchcontinue. Support for real if-then-else. Support for if-then
without else-branches. Modelica Development Tooling 0.7.7 with small
improvements such as more settings, improved error detection in console,
etc.

New Graphic Editor OMEdit
-------------------------

A new improved open source graphic model connection editor called
OMEdit, supporting 3.1 graphical annotations, which makes it possible to
move models back and forth to other tools without problems. The editor
has been implemented by students at Linköping University and is based on
the C++ Qt library.

OpenModelica 1.5, July 2010
===========================

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
---------------------------

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
----------------------------------

Improvements in platform availability.

-  Support for 64-bit Linux.

-  Support for Windows 7.

-  Better support for MacOS, including 64-bit OSX.

OpenModelica Shell (OMShell)
----------------------------

Same as previously.

OpenModelica Eclipse Plug-in (MDT)
----------------------------------

Minor bug fixes.

OpenModelica Development Environment (OMDev)
--------------------------------------------

Minor bug fixes.

OpenModelica 1.4.5, January 2009
================================

This release has several improvements, especially platform availability,
less compiler memory usage, and supporting more aspects of Modelica 3.0.

OpenModelica Compiler (OMC)
---------------------------

This release includes small improvements and some bugfixes of the
OpenModelica Compiler (OMC):

-  Less memory consumption and better memory management over time. This
   also includes a better API supporting automatic memory management
   when calling C functions from within the compiler.

-  Modelica 3.0 parsing support.

-  Export of DAE to XML and MATLAB.

-  Support for several platforms Linux, MacOS, Windows (2000, Xp, Vista).

-  Support for record and strings as function arguments.

-  Many bug fixes.

-  (Not part of OMC): Additional free graphic editor SimForge can be
   used with OpenModelica.

OpenModelica Notebook (OMNotebook)
----------------------------------

A number of improvements, primarily in the plotting functionality and
platform availability.

-  A number of improvements in the plotting functionality: scalable
   plots, zooming, logarithmic plots, grids, etc.

-  Programmable plotting accessible through a Modelica API.

-  Simple 3D visualization.

-  Support for several platforms Linux, MacOS, Windows (2000, Xp,
   Vista).

OpenModelica Shell (OMShell)
----------------------------

Same as previously.

OpenModelica Eclipse Plug-in (MDT)
----------------------------------

Minor bug fixes.

OpenModelica Development Environment (OMDev)
--------------------------------------------

Same as previously.

OpenModelica 1.4.4, Feb 2008
============================

This release is primarily a bug fix release, except for a preliminary
version of new plotting functionality available both from the OMNotebook
and separately through a Modelica API. This is also the first release
under the open source license OSMC-PL (Open Source Modelica Consortium
Public License), with support from the recently created Open Source
Modelica Consortium. An integrated version handler, bug-, and issue
tracker has also been added.

OpenModelica Compiler (OMC)
---------------------------

This release includes small improvements and some bugfixes of the
OpenModelica Compiler (OMC):

-  Better support for if-equations, also inside when.

-  Better support for calling functions in parameter expressions and
   interactively through dynamic loading of functions.

-  Less memory consumtion during compilation and interactive evaluation.

-  A number of bug-fixes.

OpenModelica Notebook (OMNotebook)
----------------------------------

Test release of improvements, primarily in the plotting functionality
and platform availability.

-  Preliminary version of improvements in the plotting functionality:
   scalable plots, zooming, logarithmic plots, grids, etc.,
   currently available in a preliminary version through the plot2
   function.

-  Programmable plotting accessible through a Modelica API.

OpenModelica Shell (OMShell)
----------------------------

Same as previously.

OpenModelica Eclipse Plug-in (MDT)
----------------------------------

This release includes minor bugfixes of MDT and the associated
MetaModelica debugger.

OpenModelica Development Environment (OMDev)
--------------------------------------------

Extended test suite with a better structure. Version handling, bug
tracking, issue tracking, etc. now available under the integrated
Codebeamer

OpenModelica 1.4.3, June 2007
=============================

This release has a number of significant improvements of the OMC
compiler, OMNotebook, the MDT plugin and the OMDev. Increased platform
availability now also for Linux and Macintosh, in addition to Windows.
OMShell is the same as previously, but now ported to Linux and Mac.

OpenModelica Compiler (OMC)
---------------------------

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

OpenModelica Notebook (OMNotebook)
----------------------------------

A number of improvements, primarily in the platform availability.

-  Available on the Linux and Macintosh platforms, in addition to
   Windows.

-  Fixed cell copying bugs, plotting of derivatives now works, etc.

OpenModelica Shell (OMShell)
----------------------------

Now available also on the Macintosh platform.

OpenModelica Eclipse Plug-in (MDT)
----------------------------------

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
--------------------------------------------

Increased compilation speed for MetaModelica. Better if-expression
support in MetaModelica.

OpenModelica 1.4.2, October 2006
================================

This release has improvements and bug fixes of the OMC compiler,
OMNotebook, the MDT plugin and the OMDev. OMShell is the same as
previously.

OpenModelica Compiler (OMC)
---------------------------

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
----------------------------------

Search and replace functions have been added. The DrModelica tutorial
(all files) has been updated, obsolete sections removed, and models
which are not supported by the current implementation marked clearly.
Automatic recognition of the .onb suffix (e.g. when double-clicking) in
Windows makes it even more convenient to use.

OpenModelica Eclipse Plug-in (MDT)
----------------------------------

Two major improvements are added in this release:

-  Browsing and code completion works both for standard Modelica and for
   MetaModelica.

-  The debugger for algorithmic code is now available and operational in
   Eclipse for debugging of MetaModelica programs.

OpenModelica Development Environment (OMDev)
--------------------------------------------

Mostly the same as previously.

OpenModelica 1.4.1, June 2006
=============================

This release has only improvements and bug fixes of the OMC compiler,
the MDT plugin and the OMDev components. The OMShell and OMNotebook are
the same.

OpenModelica Compiler (OMC)
---------------------------

This release includes further improvements of the OpenModelica Compiler
(OMC):

-  Support for external objects.

-  OMC now reports the version number (via command line switches or
   CORBA API getVersion()).

-  Implemented caching for faster instantiation of large models.

-  Many bug fixes.

OpenModelica Eclipse Plug-in (MDT)
----------------------------------

Improvements of the error reporting when building the OMC compiler. The
errors are now added to the problems view. The latest MDT release is
version 0.6.6 (2006-06-06).

OpenModelica Development Environment (OMDev)
--------------------------------------------

Small fixes in the MetaModelica compiler. MetaModelica Users Guide is
now part of the OMDev release. The latest OMDev was release in
2006-06-06.

OpenModelica 1.4.0, May 2006
============================

This release has a number of improvements described below. The most
significant change is probably that OMC has now been translated to an
extended subset of Modelica (MetaModelica), and that all development of
the compiler is now done in this version..

OpenModelica Compiler (OMC)
---------------------------

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
----------------------------

Essentially the same OMShell as in 1.3.1. One difference is that now all
error messages are sent to the command window instead of to a separate
log window.

OpenModelica Notebook (OMNotebook)
----------------------------------

Many significant improvements and bug fixes. This version supports
graphic plots within the cells in the notebook. Improved cell handling
and Modelica code syntax highlighting. Command completion of the most
common OMC commands is now supported. The notebook has been used in
several courses.

OpenModelica Eclipse Plug-in (MDT)
----------------------------------

This is the first really useful version of MDT. Full browsing of
Modelica code, e.g. the MSL 2.2, is now supported. (MetaModelica
browsing is not yet fully supported). Full support for automatic
indentation of Modelica code, including the MetaModelica extensions.
Many bug fixes. The Eclipse plug-in is now in use for OpenModelica
development at PELAB and MathCore Engineering AB since approximately one
month.

OpenModelica Development Environment (OMDev)
--------------------------------------------

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

.. _openmodelica_1.3.1 :

OpenModelica 1.3.1, November 2005
=================================

This release has several important highlights.

This is also the *first* release for which the New BSD (Berkeley)
open-source license applies to the source code, including the whole
compiler and run-time system. This makes is possible to use OpenModelica
for both academic and commercial purposes without restrictions.

OpenModelica Compiler (OMC)
---------------------------

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
----------------------------

An improved window-based interactive command shell, now including
command completion and better editing and font size support.

OpenModelica Notebook (OMNotebook)
----------------------------------

A free implementation of an OpenModelica notebook (OMNotebook), for
electronic books with course material, including the DrModelica
interactive course material. It is possible to simulate and plot from
this notebook.

OpenModelica Eclipse Plug-in (MDT)
----------------------------------

An early alpha version of the first Eclipse plug-in (called MDT for
Modelica Development Tooling) for Modelica Development. This version
gives compilation support and partial support for browsing Modelica
package hierarchies and classes.

OpenModelica Development Environment (OMDev)
--------------------------------------------

The following mechanisms have been put in place to support OpenModelica
development.

-  Bugzilla support for OpenModelica bug tracking, accessible to
   anybody.

-  A system for automatic regression testing of the compiler and
   simulator, (+ other system parts) usually run at check in time.

-  Version handling is done using SVN, which is better than the
   previously used CVS system. For example, name change of modules
   is now possible within the version handling system.
