Introduction
============

The |omlogo| system described in this document has both short-term
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

-  The longer-term goal is to have a complete reference implementation
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
subsystems, as depicted in Figure 1- 1 -1 below.

-

Figure 111. **The architecture** **of the OpenModelica environment.
Arrows denote data and control flow. The interactive session handler
receives commands and shows results from evaluating commands and
expressions that are translated and executed. Several subsystems provide
different forms of browsing and textual editing of Modelica code. The
debugger currently provides debugging of an extended algorithmic subset
of Modelica**

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
handler in the OpenModelica environment, called OMShell – the
OpenModelica Shell). Most of these examples are also available in the
OpenModelica notebook UsersGuideExamples.onb in the testmodels
(C:/OpenModelica/share/doc/omc/testmodels/) directory, see also Chapter
4.

Starting the Interactive Session
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Windows version which at installation is made available in the start
menu as OpenModelica->OpenModelica Shell which responds with an
interaction window:

We enter an assignment of a vector expression, created by the range
construction expression 1:12, to be stored in the variable x. The value
of the expression is returned.

>> x := 1:12

{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}

Using the Interactive Mode
~~~~~~~~~~~~~~~~~~~~~~~~~~

When running OMC in interactive mode (for instance using OMShell) one
can make use of some of the compiler debug trace flags defined in
section 2.1.2 in the System Documentation. Here we give a few example
sessions.

**Example Session 1**

OpenModelica 1.9.2

Copyright (c) OSMC 2002-2015

To get help on using OMShell and OpenModelica, type "help()" and press
enter.

**>>** model A Integer t = 1.5; end A; //The type is Integer but 1.5 is
of Real Type

{A}

**>>** instantiateModel(A)

"

Error: Type mismatch in modifier, expected type Integer, got modifier
=1.5 of type Real

Error: Error occured while flattening model A

**Example Session 2**

OpenModelica 1.9.2

Copyright (c) OSMC 2002-2014

To get help on using OMShell and OpenModelica, type "help()" and press
enter.

**>>** setDebugFlags("dump")

true

---DEBUG(dump)---

IEXP(Absyn.CALL(Absyn.CREF\_IDENT("setDebugFlags", []),
FUNCTIONARGS(Absyn.STRING("dump"), )))

---/DEBUG(dump)---

"

---DEBUG(dump)---

IEXP(Absyn.CALL(Absyn.CREF\_IDENT("getErrorString", []), FUNCTIONARGS(,
)))

---/DEBUG(dump)—

**>>** model B Integer k = 10; end B;

{B}

---DEBUG(dump)---

Absyn.PROGRAM([

Absyn.CLASS("B", false, false, false, Absyn.R\_MODEL,
Absyn.PARTS([Absyn.PUBLIC([Absyn.ELEMENTITEM(Absyn.ELEMENT(false, \_,
Absyn.UNSPECIFIED , "component", Absyn.COMPONENTS(Absyn.ATTR(false,
false, Absyn.VAR, Absyn.BIDIR,
[]),Integer,[Absyn.COMPONENTITEM(Absyn.COMPONENT("k",[],
SOME(Absyn.CLASSMOD([], SOME(Absyn.INTEGER(10))))), NONE())]),
Absyn.INFO("", false, 1, 9, 1, 23)), NONE))])], NONE()), Absyn.INFO("",
false, 1, 1, 1, 30))

],Absyn.TOP)

---/DEBUG(dump)---

"

---DEBUG(dump)---

IEXP(Absyn.CALL(Absyn.CREF\_IDENT("getErrorString", []), FUNCTIONARGS(,
)))

---/DEBUG(dump)—

**>>** instantiateModel(B)

"fclass B

Integer k = 10;

end B;

"

---DEBUG(dump)---

IEXP(Absyn.CALL(Absyn.CREF\_IDENT("instantiateModel", []),
FUNCTIONARGS(Absyn.CREF(Absyn.CREF\_IDENT("B", [])), )))

---/DEBUG(dump)---

"

---DEBUG(dump)---

IEXP(Absyn.CALL(Absyn.CREF\_IDENT("getErrorString", []), FUNCTIONARGS(,
)))

---/DEBUG(dump)—

**>>** simulate(B, startTime=0, stopTime=1, numberOfIntervals=500,
tolerance=1e-4)

record SimulationResult

resultFile = "B\_res.plt"

end SimulationResult;

---DEBUG(dump)---

#ifdef \_\_cplusplus

extern "C" {

#endif

#ifdef \_\_cplusplus

}

#endif

IEXP(Absyn.CALL(Absyn.CREF\_IDENT("simulate", []),
FUNCTIONARGS(Absyn.CREF(Absyn.CREF\_IDENT("B", [])), startTime =
Absyn.INTEGER(0), stopTime = Absyn.INTEGER(1), numberOfIntervals =
Absyn.INTEGER(500), tolerance = Absyn.REAL(0.0001))))

---/DEBUG(dump)---

"

---DEBUG(dump)---

IEXP(Absyn.CALL(Absyn.CREF\_IDENT("getErrorString", []), FUNCTIONARGS(,
)))

---/DEBUG(dump)--

**Example Session 3**

OpenModelica 1.9.2

Copyright (c) OSMC 2002-2014

To get help on using OMShell and OpenModelica, type "help()" and press
enter.

**>>** model C Integer a; Real b; equation der(a) = b; der(b) = 12.0;
end C;

{C}

**>>** instantiateModel(C)

"

Error: Illegal derivative. der(a) where a is of type Integer, which is
not a subtype of Real

Error: Wrong type or wrong number of arguments to der(a)'.

Error: Error occured while flattening model C

Error: Illegal derivative. der(a) where a is of type Integer, which is
not a subtype of Real

Error: Wrong type or wrong number of arguments to der(a)'.

Error: Error occured while flattening model C

Trying the Bubblesort Function
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Load the function bubblesort, either by using the pull-down menu
File->Load Model, or by explicitly giving the command:

>>
loadFile("C:/OpenModelica1.9.2/share/doc/omc/testmodels/bubblesort.mo")

true

The function bubblesort is called below to sort the vector x in
descending order. The sorted result is returned together with its type.
Note that the result vector is of type Real[:], instantiated as
Real[12], since this is the declared type of the function result. The
input Integer vector was automatically converted to a Real vector
according to the Modelica type coercion rules. The function is
automatically compiled when called if this has not been done before.

>> bubblesort(x)

{12.0,11.0,10.0,9.0,8.0,7.0,6.0,5.0,4.0,3.0,2.0,1.0}

Another call:

>> bubblesort({4,6,2,5,8})

{8.0,6.0,5.0,4.0,2.0}

It is also possible to give operating system commands via the system
utility function. A command is provided as a string argument. The
example below shows the system utility applied to the UNIX command cat,
which here outputs the contents of the file bubblesort.mo to the output
stream. However, the cat command does not boldface Modelica keywords –
this improvement has been done by hand for readability.

>> cd("C:/OpenModelica1.9.2/share/doc/omc/testmodels/")

>> system("cat bubblesort.mo")

**function** bubblesort

**input** Real[:] x;

**output** Real[size(x,1)] y;

**protected**

Real t;

**algorithm**

y := x;

**for** i **in** 1:size(x,1) **loop**

**for** j **in** 1:size(x,1) **loop**

**if** y[i] > y[j] **then**

t := y[i];

y[i] := y[j];

y[j] := t;

**end** **if**;

**end** **for**;

**end** **for**;

**end** bubblesort;

Trying the system and cd Commands
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Note: Under Windows the output emitted into stdout by system commands is
put into the winmosh console windows, not into the winmosh interaction
windows. Thus the text emitted by the above cat command would not be
returned. Only a success code (0 = success, 1 = failure) is returned to
the winmosh window. For example:

>> system("dir")

0

>> system("Non-existing command")

1

Another built-in command is cd, the *change current directory* command.
The resulting current directory is returned as a string.

>> cd()

" C:/OpenModelica1.9.2/share/doc/omc/testmodels/"

>> cd("..")

" C:/OpenModelica1.9.2/share/doc/omc/"

>> cd("C:/OpenModelica1.9.2/share/doc/omc/testmodels/")

" C:/OpenModelica1.9.2/share/doc/omc/testmodels/"

Modelica Library and DCMotor Model
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We load a model, here the whole Modelica standard library, which also
can be done through the File->Load Modelica Library menu item:

>> loadModel(Modelica)

true

We also load a file containing the dcmotor model:

>> loadFile("C:/OpenModelica1.9.2/share/doc/omc/testmodels/dcmotor.mo")

true

It is simulated:

>> simulate(dcmotor,startTime=0.0,stopTime=10.0)

record

resultFile = "dcmotor\_res.plt"

end record

We list the source code of the model:

>> list(dcmotor)

"model dcmotor

Modelica.Electrical.Analog.Basic.Resistor r1(R=10);

Modelica.Electrical.Analog.Basic.Inductor i1;

Modelica.Electrical.Analog.Basic.EMF emf1;

Modelica.Mechanics.Rotational.Inertia load;

Modelica.Electrical.Analog.Basic.Ground g;

Modelica.Electrical.Analog.Sources.ConstantVoltage v;

equation

connect(v.p,r1.p);

connect(v.n,g.p);

connect(r1.n,i1.p);

connect(i1.n,emf1.p);

connect(emf1.n,g.p);

connect(emf1.flange\_b,load.flange\_a);

end dcmotor;

"

We test code instantiation of the model to flat code:

>> instantiateModel(dcmotor)

"fclass dcmotor

Real r1.v "Voltage drop between the two pins (= p.v - n.v)";

Real r1.i "Current flowing from pin p to pin n";

Real r1.p.v "Potential at the pin";

Real r1.p.i "Current flowing into the pin";

Real r1.n.v "Potential at the pin";

Real r1.n.i "Current flowing into the pin";

parameter Real r1.R = 10 "Resistance";

Real i1.v "Voltage drop between the two pins (= p.v - n.v)";

Real i1.i "Current flowing from pin p to pin n";

Real i1.p.v "Potential at the pin";

Real i1.p.i "Current flowing into the pin";

Real i1.n.v "Potential at the pin";

Real i1.n.i "Current flowing into the pin";

parameter Real i1.L = 1 "Inductance";

parameter Real emf1.k = 1 "Transformation coefficient";

Real emf1.v "Voltage drop between the two pins";

Real emf1.i "Current flowing from positive to negative pin";

Real emf1.w "Angular velocity of flange\_b";

Real emf1.p.v "Potential at the pin";

Real emf1.p.i "Current flowing into the pin";

Real emf1.n.v "Potential at the pin";

Real emf1.n.i "Current flowing into the pin";

Real emf1.flange\_b.phi "Absolute rotation angle of flange";

Real emf1.flange\_b.tau "Cut torque in the flange";

Real load.phi "Absolute rotation angle of component (= flange\_a.phi =
flange\_b.phi)";

Real load.flange\_a.phi "Absolute rotation angle of flange";

Real load.flange\_a.tau "Cut torque in the flange";

Real load.flange\_b.phi "Absolute rotation angle of flange";

Real load.flange\_b.tau "Cut torque in the flange";

parameter Real load.J = 1 "Moment of inertia";

Real load.w "Absolute angular velocity of component";

Real load.a "Absolute angular acceleration of component";

Real g.p.v "Potential at the pin";

Real g.p.i "Current flowing into the pin";

Real v.v "Voltage drop between the two pins (= p.v - n.v)";

Real v.i "Current flowing from pin p to pin n";

Real v.p.v "Potential at the pin";

Real v.p.i "Current flowing into the pin";

Real v.n.v "Potential at the pin";

Real v.n.i "Current flowing into the pin";

parameter Real v.V = 1 "Value of constant voltage";

equation

r1.R \* r1.i = r1.v;

r1.v = r1.p.v - r1.n.v;

0.0 = r1.p.i + r1.n.i;

r1.i = r1.p.i;

i1.L \* der(i1.i) = i1.v;

i1.v = i1.p.v - i1.n.v;

0.0 = i1.p.i + i1.n.i;

i1.i = i1.p.i;

emf1.v = emf1.p.v - emf1.n.v;

0.0 = emf1.p.i + emf1.n.i;

emf1.i = emf1.p.i;

emf1.w = der(emf1.flange\_b.phi);

emf1.k \* emf1.w = emf1.v;

emf1.flange\_b.tau = -(emf1.k \* emf1.i);

load.w = der(load.phi);

load.a = der(load.w);

load.J \* load.a = load.flange\_a.tau + load.flange\_b.tau;

load.flange\_a.phi = load.phi;

load.flange\_b.phi = load.phi;

g.p.v = 0.0;

v.v = v.V;

v.v = v.p.v - v.n.v;

0.0 = v.p.i + v.n.i;

v.i = v.p.i;

emf1.flange\_b.tau + load.flange\_a.tau = 0.0;

emf1.flange\_b.phi = load.flange\_a.phi;

emf1.n.i + v.n.i + g.p.i = 0.0;

emf1.n.v = v.n.v;

v.n.v = g.p.v;

i1.n.i + emf1.p.i = 0.0;

i1.n.v = emf1.p.v;

r1.n.i + i1.p.i = 0.0;

r1.n.v = i1.p.v;

v.p.i + r1.p.i = 0.0;

v.p.v = r1.p.v;

load.flange\_b.tau = 0.0;

end dcmotor;

"

We plot part of the simulated result:

>> plot({load.w,load.phi})

true

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

>>
loadFile("C:/OpenModelica1.9.2/share/doc/omc/testmodels/BouncingBall.mo")

true

>> list(BouncingBall)

.. code-block :: modelica

  model BouncingBall
    parameter Real e=0.7 "coefficient of restitution";
    parameter Real g=9.81 "gravity acceleration";
    Real h(start=1) "height of ball";
    Real v "velocity of ball";
    Boolean flying(start=true) "true, if ball is flying";
    Boolean impact;
    Real v_new;
  equation
    impact=h <= 0.0;
    der(v) = if flying then -g else 0;
    der(h) = v;
    when {h <= 0.0 and v <= 0.0,impact} then
      v_new = if edge(impact) then -e*pre(v) else 0;
      flying = v_new > 0;
      reinit(v, v_new);
    end when;
  end BouncingBall;

Instead of just giving a simulate and plot command, we perform a
runScript command on a .mos (Modelica script) file sim\_BouncingBall.mos
that contains these commands:

loadFile("BouncingBall.mo");

simulate(BouncingBall, stopTime=3.0);

plot({h,flying});

The runScript command:

>> runScript("sim\_BouncingBall.mos")

"true

record

resultFile = "BouncingBall\_res.plt"

end record

true

true"

>> **model** Switch

Real v;

Real i;

Real i1;

Real itot;

Boolean open;

**equation**

itot = i + i1;

**if** open **then**

v = 0;

**else**

i = 0;

**end** **if**;

1 - i1 = 0;

1 - v - i = 0;

open = time >= 0.5;

**end** Switch;

Ok

>> simulate(Switch, startTime=0, stopTime=1);

Retrieve the value of itot at time=0 using the
val(\ *variableName*,\ *time*) function:

>> val(itot,0)

1

Plot itot and open:

>> plot({itot,open})

true

We note that the variable open switches from false (0) to true (1),
causing itot to increase from 1.0 to 2.0.

Clear All Models
~~~~~~~~~~~~~~~~

Now, first clear all loaded libraries and models:

>> clear()

true

List the loaded models – nothing left:

>> list()

""

VanDerPol Model and Parametric Plot
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We load another model, the VanDerPol model (or via the menu File->Load
Model):

>>
loadFile("C:/OpenModelica1.9.2/share/doc/omc/testmodels/VanDerPol.mo"))

true

It is simulated:

>> simulate(VanDerPol)

record

resultFile = "VanDerPol\_res.plt"

end record

It is plotted:

plotParametric(x,y);

Perform code instantiation to flat form of the VanDerPol model:

>> instantiateModel(VanDerPol)

"fclass VanDerPol

Real x(start=1.0);

Real y(start=1.0);

parameter Real lambda = 0.3;

equation

der(x) = y;

der(y) = -x + lambda \* (1.0 - x \* x) \* y;

end VanDerPol;

"

Using Japanese or Chinese Characters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Japenese, Chinese, and other kinds of UniCode characters can be used
within quoted (single quote) identifiers, see for example the variable
name to the right in the plot below:

|image0|

Scripting with For-Loops, While-Loops, and If-Statements
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A simple summing integer loop (using multi-line input without evaluation
at each line into OMShell requires copy-paste as one operation from
another document):

>> k := 0;

**for** i **in** 1:1000 **loop**

k := k + i;

**end** **for**;

>> k

500500

A nested loop summing reals and integers::

>> g := 0.0;

h := 5;

**for** i **in** {23.0,77.12,88.23} **loop**

**for** j **in** i:0.5:(i+1) **loop**

g := g + j;

g := g + h / 2;

**end** **for**;

h := h + g;

**end** **for**;

By putting two (or more) variables or assignment statements separated by
semicolon(s), ending with a variable, one can observe more than one
variable value:

>> h;g

1997.45

1479.09

A for-loop with vector traversal and concatenation of string elements:

>> i:="";

lst := {"Here ", "are ","some ","strings."};

s := "";

**for** i **in** lst **loop**

s := s + i;

**end** **for**;

>> s

"Here are some strings."

Normal while-loop with concatenation of 10 "abc " strings:

>> s:="";

i:=1;

**while** i<=10 **loop**

s:="abc "+s;

i:=i+1;

**end** **while**;

>> s

"abc abc abc abc abc abc abc abc abc abc "

A simple if-statement. By putting the variable last, after the
semicolon, its value is returned after evaluation:

>> **if** 5>2 **then** a := 77; **end** **if**; a

77

An if-then-else statement with elseif:

>> **if** false **then**

a := 5;

**elseif** a > 50 **then**

b:= "test"; a:= 100;

**else**

a:=34;

**end** **if**;

Take a look at the variables a and b:

>> a;b

100

"test"

Variables, Functions, and Types of Variables
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Assign a vector to a variable:

>> a:=1:5

{1,2,3,4,5}

Type in a function:

>> function MySqr input Real x; output Real y; algorithm y:=x\*x; end
MySqr;

Ok

Call the function:

>> b:=MySqr(2)

4.0

Look at the value of variable a:

>> a

{1,2,3,4,5}

Look at the type of a:

>> typeOf(a)

"Integer[]"

Retrieve the type of b:

>> typeOf(b)

"Real"

What is the type of MySqr? Cannot currently be handled.

>> typeOf(MySqr)

Error evaluating expr.

List the available variables:

>> listVariables()

{currentSimulationResult, a, b}

Clear again:

>> clear()

true

Getting Information about Error Cause
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Call the function getErrorString() in order to get more information
about the error cause after a simulation failure:

>> getErrorString()

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

simulate(... , outputFormat="mat")

simulate(... , outputFormat="csv")

simulate(... , outputFormat="plt")

simulate(... , outputFormat="empty")

It is also possible to specify which variables should be present in the
result-file. This is done by using `POSIX Extended Regular
Expressions <<http://en.wikipedia.org/wiki/Regular_expression>>`_.
The given expression must match the full variable name
(^ and $ symbols are automatically added to the given regular
expression).

// Default, match everything

simulate(... , variableFilter=".\*")

// match indices of variable myVar that only contain the numbers using
combinations

// of the letters 1 through 3

simulate(... , variableFilter="myVar\\\\[[1-3]\*\\\\]")

// match x or y or z

simulate(... , variableFilter="x\|y\|z")

Using External Functions
~~~~~~~~~~~~~~~~~~~~~~~~

See Chapter 12 for more information about calling functions in other
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

omc +d=openmp model.mo

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

package Modelica

annotation(uses(Complex(version="1.0"),
ModelicaServices(version="1.1")))

end Modelica;

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

>>loadFile("C:/OpenModelica1.9.2/share/doc/omc/testmodels/BouncingBall.mo")

true

>>list(BouncingBall)

"model BouncingBall

parameter Real e=0.7 "coefficient of restitution";

parameter Real g=9.81 "gravity acceleration";

Real h(start=1) "height of ball";

Real v "velocity of ball";

Boolean flying(start=true) "true, if ball is flying";

Boolean impact;

Real v\_new;

equation

impact=h <= 0.0;

der(v)=if flying then -g else 0;

der(h)=v;

when {h <= 0.0 and v <= 0.0,impact} then

v\_new=if edge(impact) then -e\*pre(v) else 0;

flying=v\_new > 0;

reinit(v, v\_new);

end when;

end BouncingBall;

"

Different kinds of calls with returned results:

>>getClassRestriction(BouncingBall)

"model"

>>getClassInformation(BouncingBall)

{"model","","",{false,false,false},{"writable",1,1,18,17}}

>>isFunction(BouncingBall)

false

>>existClass(BouncingBall)

true

>>getComponents(BouncingBall)

{{Real,e,"coefficient of restitution", "public", false, false, false,

"parameter", "none", "unspecified"},

{Real,g,"gravity acceleration",

"public", false, false, false, "parameter", "none", "unspecified"},

{Real,h,"height of ball", "public", false, false, false,

"unspecified", "none", "unspecified"},

{Real,v,"velocity of ball",

"public", false, false, false, "unspecified", "none", "unspecified"},

{Boolean,flying,"true, if ball is flying", "public", false, false,

false, "unspecified", "none", "unspecified"},

{Boolean,impact,"",

"public", false, false, false, "unspecified", "none", "unspecified"},

{Real,v\_new,"", "public", false, false, false, "unspecified", "none",

"unspecified"}}

>>getConnectionCount(BouncingBall)

0

>>getInheritanceCount(BouncingBall)

0

>>getComponentModifierValue(BouncingBall,e)

0.7

>>getComponentModifierNames(BouncingBall,e)

{}

>>getClassRestriction(BouncingBall)

"model"

>>getVersion() // Version of the currently running OMC

"1.9.2"

Quit OpenModelica
~~~~~~~~~~~~~~~~~

Leave and quit OpenModelica:

>> quit()

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

$ cat daequery.mos

loadFile("BouncingBall.mo");

exportDAEtoMatlab(BouncingBall);

readFile("BouncingBall\_imatrix.m");

$ omc daequery.mos

true

"The equation system was dumped to Matlab file:BouncingBall\_imatrix.m"

"

% Incidence Matrix

% ====================================

% number of rows: 6

IM={[3,-6],[1,{'if', 'true','==' {3},{},}],[2,{'if', 'edge(impact)'
{3},{5},}],[4,2],[5,{'if', 'true','==' {4},{},}],[6,-5]};

VL = {'foo','v\_new','impact','flying','v','h'};

EqStr = {'impact = h <= 0.0;','foo = if impact then 1 else 2;','when {h
<= 0.0 AND v <= 0.0,impact} then v\_new = if edge(impact) then (-e) \*
pre(v) else 0.0; end when;','when {h <= 0.0 AND v <= 0.0,impact} then
flying = v\_new > 0.0; end when;','der(v) = if flying then -g else
0.0;','der(h) = v;'};

OldEqStr={'fclass BouncingBall','parameter Real e = 0.7 "coefficient of
restitution";','parameter Real g = 9.81 "gravity acceleration";','Real
h(start = 1.0) "height of ball";','Real v "velocity of ball";','Boolean
flying(start = true) "true, if ball is flying";','Boolean impact;','Real
v\_new;','Integer foo;','equation',' impact = h <= 0.0;',' foo = if
impact then 1 else 2;',' der(v) = if flying then -g else 0.0;',' der(h)
= v;',' when {h <= 0.0 AND v <= 0.0,impact} then',' v\_new = if
edge(impact) then (-e) \* pre(v) else 0.0;',' flying = v\_new > 0.0;','
reinit(v,v\_new);',' end when;','end BouncingBall;',''};"

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
  available (see chapter 1.2.14).

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

The OpenModelica compiler can also be used from command line, in Windows
cmd.exe.

**Example Session 1 – obtaining information about command line
parameters**

| C:\\dev> C:\\OpenModelica1.9.2 \\bin\\omc -h
| OpenModelica Compiler 1.9.2
| Copyright © 2015 Open Source Modelica Consortium (OSMC)
| Distributed under OMSC-PL and GPL, see https://www.openmodelica.org/
| Usage: omc [Options] (Model.mo \| Script.mos) [Libraries \| .mo-files]
| ...

**Example Session 2 - create an TestModel.mo file and run omc on it**

| C:\\dev> echo model TestModel parameter Real x = 1; end TestModel; >
  TestModel.mo
| C:\\dev> C:\\OpenModelica1.9.2 \\bin\\omc TestModel.mo
| class TestModel
|  parameter Real x = 1.0;
| end TestModel;
| C:\\dev>

**Example Session 3 - create an script.mos file and run omc on it**

| Create a file script.mos using your editor containing these commands:
| // start script.mos
| loadModel(Modelica); getErrorString();
| simulate(Modelica.Mechanics.MultiBody.Examples.Elementary.Pendulum);
  getErrorString();
| // end script.mos
| C:\\dev> notepad script.mos
| C:\\dev> C:\\OpenModelica1.9.2 \\bin\\omc script.mos
| true
| ""
| record SimulationResult
|  resultFile =
  "C:/dev/Modelica.Mechanics.MultiBody.Examples.Elementary.Pendulum\_res.mat",
|  simulationOptions = "startTime = 0.0, stopTime = 5.0,
  numberOfIntervals = 500, tolerance = 1e-006, method = 'dassl',
  fileNamePrefix =
  'Modelica.Mechanics.MultiBody.Examples.Elementary.Pendulum', options =
  '', outputFormat = 'mat', variableFilter = '.\*', cflags = '',
  simflags = ''",
|  messages = "",
|  timeFrontend = 1.245787339209033,
|  timeBackend = 20.51007138993843,
|  timeSimCode = 0.1510248469321959,
|  timeTemplates = 0.5052317333954395,
|  timeCompile = 5.128213942691722,
|  timeSimulation = 0.4049189573103951,
|  timeTotal = 27.9458487395605
| end SimulationResult;
| ""

In order to obtain more information from the compiler one can use the
command line options **+showErrorMessages +d=failtrace** when running
the compiler:

C:\\dev> C:\\OpenModelica1.9.2 \\bin\\omc +showErrorMessages
+d=failtrace script.mos

.. |omlogo| image:: logo.*
  :alt: OpenModelica logotype
  :height: 14pt
.. |image0| image:: media/image7.png
