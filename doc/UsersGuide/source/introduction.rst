Introduction
============

.. highlight:: modelica

The OpenModelica system described in this document has both short-term
and long-term goals:

-  The short-term goal is to develop an efficient interactive
   computational environment for the Modelica language, as well as a
   rather complete implementation of the language. It turns out that
   with support of appropriate tools and libraries, Modelica is very
   well suited as a computational language for development and
   execution of both low level and high level numerical algorithms,
   e.g. for control system design, solving nonlinear equation
   systems, or to develop optimization algorithms that are applied
   to complex applications.

-  The long-term goal is to have a complete reference implementation
   of the Modelica language, including simulation of equation based
   models and additional facilities in the programming environment,
   as well as convenient facilities for research and experimentation
   in language design or other research activities. However, our
   goal is not to reach the level of performance and quality
   provided by current commercial Modelica environments that can
   handle large models requiring advanced analysis and optimization
   by the Modelica compiler.

The long-term *research* related goals and issues of the OpenModelica
open source implementation of a Modelica environment include but are not
limited to the following:

-  Development of a *complete formal specification* of Modelica,
   including both static and dynamic semantics. Such a specification
   can be used to assist current and future Modelica implementers by
   providing a semantic reference, as a kind of reference
   implementation.

-  *Language design*, e.g. to further *extend the scope* of the
   language, e.g. for use in diagnosis, structural analysis, system
   identification, etc., as well as modeling problems that require
   extensions such as partial differential equations, enlarged scope
   for discrete modeling and simulation, etc.

-  *Language design* to *improve abstract properties* such as
   expressiveness, orthogonality, declarativity, reuse,
   configurability, architectural properties, etc.

-  *Improved implementation techniques*, e.g. to enhance the performance
   of compiled Modelica code by generating code for parallel
   hardware.

-  *Improved debugging* support for equation based languages such as
   Modelica, to make them even easier to use.

-  *Easy-to-use* specialized high-level (graphical) *user interfaces*
   for certain application domains.

-  *Visualization* and animation techniques for interpretation and
   presentation of results.

-  *Application usage* and model library development by researchers in
   various application areas.

The OpenModelica environment provides a test bench for language design
ideas that, if successful, can be submitted to the Modelica Association
for consideration regarding possible inclusion in the official Modelica
standard.

The current version of the OpenModelica environment allows most of the
expression, algorithm, and function parts of Modelica to be executed
interactively, as well as equation models and Modelica functions to be
compiled into efficient C code. The generated C code is combined with a
library of utility functions, a run-time library, and a numerical DAE
solver.

System Overview
---------------

The OpenModelica environment consists of several interconnected
subsystems, as depicted in :numref:`systemoverview`.

.. figure :: media/systemoverview.png
  :name: systemoverview
  :width: 100%

  The architecture of the OpenModelica environment.
  Arrows denote data and control flow.
  The interactive session handler receives commands and shows results from evaluating commands and expressions that are translated and executed.
  Several subsystems provide different forms of browsing and textual editing of Modelica code.
  The debugger currently provides debugging of an extended algorithmic subset of Modelica.

The following subsystems are currently integrated in the OpenModelica
environment:

-  *An interactive session handler*, that parses and interprets commands
   and Modelica expressions for evaluation, simulation, plotting,
   etc. The session handler also contains simple history facilities,
   and completion of file names and certain identifiers in commands.

-  *A Modelica compiler subsystem*, translating Modelica to C code, with
   a symbol table containing definitions of classes, functions, and
   variables. Such definitions can be predefined, user-defined, or
   obtained from libraries. The compiler also includes a Modelica
   interpreter for interactive usage and constant expression
   evaluation. The subsystem also includes facilities for building
   simulation executables linked with selected numerical ODE or DAE
   solvers.

-  *An execution and run-time module*. This module currently executes
   compiled binary code from translated expressions and functions,
   as well as simulation code from equation based models, linked
   with numerical solvers. In the near future event handling
   facilities will be included for the discrete and hybrid parts of
   the Modelica language.

-  *Eclipse plugin editor/browser*. The Eclipse plugin called MDT
   (Modelica Development Tooling) provides file and class hierarchy
   browsing and text editing capabilities, rather analogous to
   previously described Emacs editor/browser. Some syntax
   highlighting facilities are also included. The Eclipse framework
   has the advantage of making it easier to add future extensions
   such as refactoring and cross referencing support.

-  *OMNotebook DrModelica model editor*. This subsystem provides a
   lightweight notebook editor, compared to the more advanced
   Mathematica notebooks available in MathModelica. This basic
   functionality still allows essentially the whole DrModelica
   tutorial to be handled. Hierarchical text documents with chapters
   and sections can be represented and edited, including basic
   formatting. Cells can contain ordinary text or Modelica models
   and expressions, which can be evaluated and simulated. However,
   no mathematical typesetting facilities are yet available in the
   cells of this notebook editor.

-  *Graphical model editor/browser OMEdit*. This is a graphical
   connection editor, for component based model design by connecting
   instances of Modelica classes, and browsing Modelica model
   libraries for reading and picking component models. The graphical
   model editor also includes a textual editor for editing model
   class definitions, and a window for interactive Modelica command
   evaluation.

-  *Optimization subsystem OMOptim*. This is an optimization subsystem
   for OpenModelica, currently for design optimization choosing an
   optimal set of design parameters for a model. The current version
   has a graphical user interface, provides genetic optimization
   algorithms and Pareto front optimization, works integrated with
   the simulators and automatically accesses variables and design
   parameters from the Modelica model.

-  *Dynamic Optimization subsystem*. This is dynamic optimization using
   collocation methods, for Modelica models extended with
   optimization specifications with goal functions and additional
   constraints. This subsystem is integrated with in the
   OpenModelica compiler.

-  *Modelica equation model debugger*. The equation model debugger shows
   the location of an error in the model equation source code. It
   keeps track of the symbolic transformations done by the compiler
   on the way from equations to low-level generated C code, and also
   explains which transformations have been done.

-  *Modelica algorithmic code debugger*. The algorithmic code Modelica
   debugger provides debugging for an extended algorithmic subset of
   Modelica, excluding equation-based models and some other
   features, but including some meta-programming and model
   transformation extensions to Modelica. This is a conventional
   full-feature debugger, using Eclipse for displaying the source
   code during stepping, setting breakpoints, etc. Various
   back-trace and inspection commands are available. The debugger
   also includes a data-view browser for browsing hierarchical data
   such as tree- or list structures in extended Modelica.

Interactive Session with Examples
---------------------------------

The following is an interactive session using the interactive session
handler in the OpenModelica environment, called OMShell - the
OpenModelica Shell. Most of these examples are also available in the
:ref:`omnotebook` UsersGuideExamples.onb as well as the testmodels in:

.. omc-mos ::

  getInstallationDirectoryPath() + "/share/doc/omc/testmodels/"

The following commands were run using OpenModelica version:

.. omc-mos::

  getVersion()

Starting the Interactive Session
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Under Windows, go to the Start Menu and run OpenModelica->OpenModelica Shell
which responds with an interaction window.

Under Linux, run ``OMShell-terminal`` to start the interactive session at the prompt.

We enter an assignment of a vector expression, created by the range
construction expression 1:12, to be stored in the variable x. The value
of the expression is returned.

.. omc-mos::

   x := 1:12

Using the Interactive Mode
~~~~~~~~~~~~~~~~~~~~~~~~~~

When running OMC in interactive mode (for instance using OMShell) one
can make load classes and execute commands.
Here we give a few example sessions.

Example Session 1
^^^^^^^^^^^^^^^^^

.. omc-mos::

  model A Integer t = 1.5; end A; //The type is Integer but 1.5 is of Real Type
  instantiateModel(A)

Example Session 2
^^^^^^^^^^^^^^^^^

If you do not see the error-message when running the example, use the command :code:`getErrorString()`.

.. omc-loadstring ::

  model C
    Integer a;
    Real b;
  equation
    der(a) = b; // der(a) is illegal since a is not a Real number
    der(b) = 12.0;
  end C;

.. omc-mos ::

  instantiateModel(C)

Trying the Bubblesort Function
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Load the function bubblesort, either by using the pull-down menu
File->Load Model, or by explicitly giving the command:

.. omc-mos::

  loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/bubblesort.mo")

The function bubblesort is called below to sort the vector x in
descending order. The sorted result is returned together with its type.
Note that the result vector is of type Real[:], instantiated as
Real[12], since this is the declared type of the function result. The
input Integer vector was automatically converted to a Real vector
according to the Modelica type coercion rules. The function is
automatically compiled when called if this has not been done before.

.. omc-mos::

  bubblesort(x)

Another call:

.. omc-mos::

  bubblesort({4,6,2,5,8})

Trying the system and cd Commands
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

It is also possible to give operating system commands via the system
utility function. A command is provided as a string argument. The
example below shows the system utility applied to the UNIX command cat,
which here outputs the contents of the file bubblesort.mo to the output
stream when running omc from the command-line.

.. omc-mos::

  system("cat '"+getInstallationDirectoryPath()+"/share/doc/omc/testmodels/bubblesort.mo' > bubblesort.mo")

.. literalinclude :: ../tmp/bubblesort.mo
  :language: modelica

Note: The output emitted into stdout by system commands is put into
log-files when running the CORBA-based clients, not into the visible GUI
windows. Thus the text emitted by the above cat command would not be
returned, which is why it is redirected to another file.

A better way to read the content of files would be the readFile command:

.. omc-mos::
  :parsed:

  readFile("bubblesort.mo")

The system command only returns a success code (0 = success).

.. omc-mos::

  system("dir")
  system("Non-existing command")

Another built-in command is cd, the *change current directory* command.
The resulting current directory is returned as a string.

.. omc-mos::

  dir:=cd()
  cd("source")
  cd(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/")
  cd(dir)

Modelica Library and DCMotor Model
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We load a model, here the whole Modelica standard library, which also
can be done through the File->Load Modelica Library menu item:

.. omc-mos::

  loadModel(Modelica, {"3.2.3"})

We also load a file containing the dcmotor model:

.. omc-mos::

  loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/dcmotor.mo")

It is simulated:

.. omc-mos::

  simulate(dcmotor, startTime=0.0, stopTime=10.0)

We list the source code of the model:

.. omc-mos::
  :parsed:

  list(dcmotor)

We test code instantiation of the model to flat code:

.. omc-mos::
  :parsed:

  instantiateModel(dcmotor)

We plot part of the simulated result:

.. omc-gnuplot :: dcmotor
  :caption: Rotation and rotational velocity of the DC motor

  load.w
  load.phi

The val() function
~~~~~~~~~~~~~~~~~~

The val(\ *variableName*,\ *time*) scription function can be used to
retrieve the interpolated value of a simulation result variable at a
certain point in the simulation time, see usage in the BouncingBall
simulation below.

BouncingBall and Switch Models
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We load and simulate the BouncingBall example containing when-equations
and if-expressions (the Modelica keywords have been bold-faced by hand
for better readability):

.. omc-mos ::

  loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/BouncingBall.mo")

.. omc-mos ::
  :parsed:

  list(BouncingBall)

Instead of just giving a simulate and plot command, we perform a
runScript command on a .mos (Modelica script) file sim\_BouncingBall.mos
that contains these commands:

.. omc-mos ::
  :clear:
  :combine-lines: 5,6
  :erroratend:

  writeFile("sim_BouncingBall.mos", "
    loadFile(getInstallationDirectoryPath() + \"/share/doc/omc/testmodels/BouncingBall.mo\");
    simulate(BouncingBall, stopTime=3.0);
    /* plot({h,flying}); */
  ")
  runScript("sim_BouncingBall.mos")


.. omc-loadstring ::

  model Switch
    Real v;
    Real i;
    Real i1;
    Real itot;
    Boolean open;
  equation
    itot = i + i1;
    if open then
      v = 0;
    else
      i = 0;
    end if;
    1 - i1 = 0;
    1 - v - i = 0;
    open = time >= 0.5;
  end Switch;


.. omc-mos ::

  simulate(Switch, startTime=0, stopTime=1)

Retrieve the value of itot at time=0 using the
val(variableName, time) function:

.. omc-mos ::

  val(itot,0)

Plot itot and open:

.. omc-gnuplot :: switch
  :caption: Plot when the switch opens

  itot
  open

We note that the variable open switches from false (0) to true (1),
causing itot to increase from 1.0 to 2.0.

Clear All Models
~~~~~~~~~~~~~~~~

Now, first clear all loaded libraries and models:

.. omc-mos ::

  clear()

List the loaded models - nothing left:

.. omc-mos ::

  list()

.. _intro-vanderpol :

VanDerPol Model and Parametric Plot
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We load another model, the VanDerPol model (or via the menu File->Load
Model):

.. omc-mos ::

  loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/VanDerPol.mo")

It is simulated:

.. omc-mos ::

  simulate(VanDerPol, stopTime=80)

It is plotted:

.. omc-gnuplot :: VanDerPol
  :caption: VanDerPol plotParametric(x,y)
  :parametric:

  x
  y

Perform code instantiation to flat form of the VanDerPol model:

.. omc-mos ::
  :parsed:

  instantiateModel(VanDerPol)

Using Japanese or Chinese Characters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Japenese, Chinese, and other kinds of UniCode characters can be used
within quoted (single quote) identifiers, see for example the variable
name to the right in the plot below:

.. image :: media/bb-japanese.png

Scripting with For-Loops, While-Loops, and If-Statements
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A simple summing integer loop (using multi-line input without evaluation
at each line into OMShell requires copy-paste as one operation from
another document):

.. omc-mos ::
  :combine-lines: 1,4,5

  k := 0;
  for i in 1:1000 loop
    k := k + i;
  end for;
  k

A nested loop summing reals and integers:

.. omc-mos ::
  :combine-lines: 1,2,9

  g := 0.0;
  h := 5;
  for i in {23.0,77.12,88.23} loop
    for j in i:0.5:(i+1) loop
      g := g + j;
      g := g + h / 2;
    end for;
    h := h + g;
  end for;

By putting two (or more) variables or assignment statements separated by
semicolon(s), ending with a variable, one can observe more than one
variable value:

.. omc-mos ::

  h; g

A for-loop with vector traversal and concatenation of string elements:

.. omc-mos ::
  :combine-lines: 1,2,3,6,7

  i:="";
  lst := {"Here ", "are ","some ","strings."};
  s := "";
  for i in lst loop
    s := s + i;
  end for;
  s

Normal while-loop with concatenation of 10 "abc " strings:

.. omc-mos ::
  :combine-lines: 1,2,6,7

  s:="";
  i:=1;
  while i<=10 loop
    s:="abc "+s;
    i:=i+1;
  end while;
  s

A simple if-statement. By putting the variable last, after the
semicolon, its value is returned after evaluation:

.. omc-mos ::

  if 5>2 then a := 77; end if; a

An if-then-else statement with elseif:

.. omc-mos ::
  :combine-lines: 7

  if false then
    a := 5;
  elseif a > 50 then
    b:= "test"; a:= 100;
  else
    a:=34;
  end if;

Take a look at the variables a and b:

.. omc-mos ::

  a;b

Variables, Functions, and Types of Variables
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Assign a vector to a variable:

.. omc-mos ::

  a:=1:5

Type in a function:

.. omc-loadstring ::

  function mySqr
    input Real x;
    output Real y;
  algorithm
    y:=x*x;
  end mySqr;

Call the function:

.. omc-mos ::

  b:=mySqr(2)

Look at the value of variable a:

.. omc-mos ::

  a

Look at the type of a:

.. omc-mos ::

  typeOf(a)

Retrieve the type of b:

.. omc-mos ::

  typeOf(b)

What is the type of mySqr? Cannot currently be handled.

.. omc-mos ::

  typeOf(mySqr)

List the available variables:

.. omc-mos ::

  listVariables()

Clear again:

.. omc-mos ::

  clear()

Getting Information about Error Cause
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Call the function getErrorString() in order to get more information
about the error cause after a simulation failure:

.. omc-mos ::

  getErrorString()

.. _alternative-output-formats :

Alternative Simulation Output Formats
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

There are several output format possibilities, with mat being the
default. plt and mat are the only formats that allow you to use the
val() or plot() functions after a simulation. Compared to the speed of
plt, mat is roughly 5 times for small files, and scales better for
larger files due to being a binary format. The csv format is roughly
twice as fast as plt on data-heavy simulations. The plt format allocates
all output data in RAM during simulation, which means that simulations
may fail due applications only being able to address 4GB of memory on
32-bit platforms. Empty does no output at all and should be by far the
fastest. The csv and plt formats are suitable when using an external
scripts or tools like gnuplot to generate plots or process data. The mat
format can be post-processed in `MATLAB <http://www.mathworks.com/products/matlab>`_
or `Octave <http://www.gnu.org/software/octave/>`_.

>>> simulate(... , outputFormat="mat")
>>> simulate(... , outputFormat="csv")
>>> simulate(... , outputFormat="plt")
>>> simulate(... , outputFormat="empty")

It is also possible to specify which variables should be present in the
result-file. This is done by using `POSIX Extended Regular Expressions <http://en.wikipedia.org/wiki/Regular_expression>`_.
The given expression must match the full variable name
(^ and $ symbols are automatically added to the given regular
expression).

// Default, match everything

>>> simulate(... , variableFilter=".*")

// match indices of variable myVar that only contain the numbers using
combinations

// of the letters 1 through 3

>>> simulate(... , variableFilter="myVar\\\[[1-3]*\\\]")

// match x or y or z

>>> simulate(... , variableFilter="x|y|z")

Using External Functions
~~~~~~~~~~~~~~~~~~~~~~~~

See Chapter :ref:`interop-c` for more information about calling functions in other
programming languages.

Using Parallel Simulation via OpenMP Multi-Core Support
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Faster simulations on multi-core computers can be obtained by using a
new OpenModelica feature that automatically partitions the system of
equations and schedules the parts for execution on different cores using
shared-memory OpenMP based execution. The speedup obtained is dependent
on the model structure, whether the system of equations can be
partitioned well. This version in the current OpenModelica release is an
experimental version without load balancing. The following command, not
yet available from the OpenModelica GUI, will run a parallel simulation
on a model:

>>> omc -d=openmp model.mo

Loading Specific Library Version
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

There exist many different versiosn of Modelica libraries which are not
compatible. It is possible to keep multiple versions of the same library
stored in the directory given by calling getModelicaPath(). By calling
loadModel(Modelica,{"3.2"}), OpenModelica will search for a directory
called "Modelica 3.2" or a file called "Modelica 3.2.mo". It is possible
to give several library versions to search for, giving preference for a
pre-release version of a library if it is installed. If the searched
version is "default", the priority is: no version name (Modelica), main
release version (Modelica 3.1), pre-release version (Modelica 3.1Beta 1)
and unordered versions (Modelica Special Release).

The loadModel command will also look at the uses annotation of the
top-level class after it has been loaded. Given the following package,
Complex 1.0 and ModelicaServices 1.1 will also be loaded into the AST
automatically.

.. omc-loadstring ::

  package Modelica
    annotation(uses(Complex(version="1.0"),
    ModelicaServices(version="1.1")));
  end Modelica;

.. omc-mos ::

  clear()

Packages will also be loaded if a model has a uses-annotation:

.. omc-loadstring ::

  model M
    annotation(uses(Modelica(version="3.2.1")));
  end M;

.. omc-mos ::
  :parsed:

  instantiateModel(M)

Packages will also be loaded by looking at the first identifier in the path:

.. omc-mos ::
  :parsed:
  :clear:

  instantiateModel(Modelica.Electrical.Analog.Basic.Ground)

Calling the Model Query and Manipulation API
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In the OpenModelica System Documentation, an external API (application
programming interface) is described which returns information about
models and/or allows manipulation of models. Calls to these functions
can be done interactively as below, but more typically by program
clients to the OpenModelica Compiler (OMC) server. Current examples of
such clients are the OpenModelica MDT Eclipse plugin, OMNotebook, the
OMEdit graphic model editor, etc. This API is untyped for performance
reasons, i.e., no type checking and minimal error checking is done on
the calls. The results of a call is returned as a text string in
Modelica syntax form, which the client has to parse. An example parser
in C++ is available in the OMNotebook source code, whereas another
example parser in Java is available in the MDT Eclipse plugin.

Below we show a few calls on the previously simulated BouncingBall
model. The full documentation on this API is available in the system
documentation. First we load and list the model again to show its
structure:

.. omc-mos ::
  :clear:
  :parsed:

  loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/BouncingBall.mo");
  list(BouncingBall)

Different kinds of calls with returned results:

.. omc-mos ::
  :erroratend:

  getClassRestriction(BouncingBall)
  getClassInformation(BouncingBall)
  isFunction(BouncingBall)
  existClass(BouncingBall)
  getComponents(BouncingBall)
  getConnectionCount(BouncingBall)
  getInheritanceCount(BouncingBall)
  getComponentModifierValue(BouncingBall,e)
  getComponentModifierNames(BouncingBall,"e")
  getClassRestriction(BouncingBall)
  getVersion() // Version of the currently running OMC

Quit OpenModelica
~~~~~~~~~~~~~~~~~

Leave and quit OpenModelica:

>>> quit()

Dump XML Representation
~~~~~~~~~~~~~~~~~~~~~~~

The command dumpXMLDAE dumps an XML representation of a model, according
to several optional parameters.

dumpXMLDAE(\ *modelname*\ [,asInSimulationCode=<Boolean>]
[,filePrefix=<String>] [,storeInTemp=<Boolean>] [,addMathMLCode
=<Boolean>])

This command dumps the mathematical representation of a model using an
XML representation, with optional parameters. In particular,
asInSimulationCode defines where to stop in the translation process
(before dumping the model), the other options are relative to the file
storage: filePrefix for specifying a different name and storeInTemp to
use the temporary directory. The optional parameter addMathMLCode gives
the possibility to don't print the MathML code within the xml file, to
make it more readable. Usage is trivial, just:
addMathMLCode=\ *true/false* (default value is false).

Dump Matlab Representation
~~~~~~~~~~~~~~~~~~~~~~~~~~

The command export dumps an XML representation of a model, according to
several optional parameters.

exportDAEtoMatlab(\ *modelname*);

This command dumps the mathematical representation of a model using a
Matlab representation. Example:

.. omc-mos ::

  loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/BouncingBall.mo")
  exportDAEtoMatlab(BouncingBall)

.. literalinclude :: ../tmp/BouncingBall_imatrix.m
  :language: matlab

Summary of Commands for the Interactive Session Handler
-------------------------------------------------------

The following is the complete list of commands currently available in
the interactive session hander.

simulate(\ *modelname*) Translate a model named *modelname* and simulate
it.

| simulate(\ *modelname*\ [,startTime=<*Real*\ >][,stopTime=<*Real*\ >][,numberOfIntervals
| =<*Integer*\ >][,outputInterval=<*Real*\ >][,method=<*String*\ >]
| [,tolerance=<*Real*\ >][,fixedStepSize=<*Real*\ >]
| [,outputFormat=<*String*\ >]) Translate and simulate a model, with
  optional start time, stop time, and optional number of simulation
  intervals or steps for which the simulation results will be computed.
  More intervals will give higher time resolution, but occupy more space
  and take longer to compute. The default number of intervals is 500. It
  is possible to choose solving method, default is “dassl”, “euler” and
  “rungekutta” are also available. Output format “mat” is default. “plt”
  and “mat” (MATLAB) are the only ones that work with the val() command,
  “csv” (comma separated values) and “empty” (no output) are also
  available (see section :ref:`alternative-output-formats`).

plot(\ *vars*) Plot the variables given as a vector or a scalar, e.g.
plot({x1,x2}) or plot(x1).

plotParametric(\ *var1*, *var2*) Plot var2 relative to var1 from the
most recently simulated model, e.g. plotParametric(x,y).

cd() Return the current directory.

cd(\ *dir*) Change directory to the directory given as string.

clear() Clear all loaded definitions.

clearVariables() Clear all defined variables.

dumpXMLDAE(\ *modelname*, ...) Dumps an XML representation of a model,
according to several optional parameters.

exportDAEtoMatlab(\ *name*) Dumps a Matlab representation of a model.

instantiateModel(\ *modelname*)Performs code instantiation of a
model/class and return a string containing the flat class definition.

list() Return a string containing all loaded class definitions.

list(\ *modelname*) Return a string containing the class definition of
the named class.

listVariables() Return a vector of the names of the currently defined
variables.

loadModel(\ *classname*) Load model or package of name *classname* from
the path indicated by the environment variable OPENMODELICALIBRARY.

loadFile(\ *str*) Load Modelica file (.mo) with name given as string
argument *str*.

readFile(\ *str*) Load file given as string *str* and return a string
containing the file content.

runScript(\ *str*) Execute script file with file name given as string
argument *str*.

system(\ *str*) Execute *str* as a system(shell) command in the
operating system; return integer success value. Output into stdout from
a shell command is put into the console window.

timing(\ *expr*) Evaluate expression *expr* and return the number of
seconds (elapsed time) the evaluation took.

typeOf(\ *variable*) Return the type of the *variable* as a string.

saveModel(\ *str*,\ *modelname*) Save the model/class with name
*modelname* in the file given by the string argument *str*.

val(\ *variable,timePoint*) Return the (interpolated) value of the
*variable* at time *timePoint*.

help() Print this helptext (returned as a string).

quit() Leave and quit the OpenModelica environment

Running the compiler from command line
--------------------------------------

The OpenModelica compiler can also be used from command line, in Windows cmd.exe or a Unix shell.
The following examples assume omc is on the PATH; if it is not, you can run :code:`C:\\OpenModelica 1.16.0\\build\\bin\\omc.exe` or similar (depending on where you installed OpenModelica).

Example Session 1 - obtaining information about command line parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. command-output :: omc --help
  :ellipsis: 6,-2

Example Session 2 - create an TestModel.mo file and run omc on it
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. literalinclude:: TestModel.mo
  :language: modelica

.. command-output :: omc TestModel.mo

Example Session 3 - create a mos-script and run omc on it
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. literalinclude:: TestScript.mos
  :language: modelica

.. command-output :: omc TestScript.mos

In order to obtain more information from the compiler one can use the
command line options **--showErrorMessages -d=failtrace** when running
the compiler:

.. command-output :: omc --showErrorMessages -d=failtrace TestScript.mos
  :ellipsis: 4,-4
