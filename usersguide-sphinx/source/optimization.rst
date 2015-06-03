Optimization with OpenModelica
==============================

The following facilities for model-based optimization are provided with
OpenModelica:

-  Builtin dynamic optimization with OpenModelica and IpOpt using
       dynamic optimization, Section 6.1 This is the recommended way of
       performing dynamic optimization with OpenModelica.

-  Dynamic optimization with OpenModelica by automatic export of the
       problem to CasADi, Section 6.2. Use this if you want to employ
       the CasADi tool for dynamic optimization.

-  Classical parameter sweep based design optimization, Section 6.3. Use
       this if you have a static optimization problem.

Builtin Dynamic Optimization with OpenModelica and IpOpt
--------------------------------------------------------

*Note: this is a very short preliminary decription which soon will be
considerably improved.*

OpenModelica provides builtin dynamic optimization of models by using
the powerful symbolic machinery of the OpenModelica compiler for more
efficient and automatic solution of dynamic optimization problems.

The builtin dynamic optimization allows users to define optimal control
problems (OCP) using the Modelica language for the model and the
optimization language extension called Optimica (currently partially
supported) for the optimization part of the problem. This is used to
solve the underlying dynamic optimization model formulation using
collocation methods, using a single execution instead of multiple
simulations as in the parameter-sweep optimization described in Section
6.3.

For more detailed information regarding background and methods, see the
papers:

-  Bernhard Bachmann, Lennart Ochel, Vitalij Ruge, Mahder Gebremedhin,
       Peter Fritzson, Vaheed Nezhadali, Lars Eriksson, Martin
       Sivertsson. Parallel Multiple-Shooting and Collocation
       Optimization with OpenModelica. In Proceedings of the 9th
       International Modelica Conference (Modelica'2012), Munich,
       Germany, Sept.3-5, 2012.

-  Vitalij Ruge, Willi Braun, Bernhard Bachmann, Andrea Walther and
       Kshitij Kulshreshtha. Efficient Implementation of Collocation
       Methods for Optimization using OpenModelica and ADOL–C. In
       Proceedings of the 10th International Modelica Conference
       (Modelica'2014), Munich, Germany, March.10-12, 2014.

|image26|

Figure 642: **OMNotebook screenshot for dynamic optimization.**

Compiling the Modelica code
---------------------------

Before starting the optimization the model should be symbolically
instantiated by the compiler in order to get a single flat system of
equations. The model variables should also be scalarized. The compiler
frontend performs this, including syntax checking, semantics and type
checking, simplification and constant evaluation etc. are applied. Then
the complete flattened model can be used for initialization, simulation
and last but not least for model-based dynamic optimization.

The OpenModelica command optimize(ModelName) from OMShell, OMNotebook or
MDT runs immediately the optimization. The generated result file can be
read in and visualized with OMEdit or within OMNotebook.

// name: BatchReactor.mos

setCommandLineOptions("+g=Optimica");

getErrorString();

loadFile("BatchReactor.mo");

getErrorString();

optimize(nmpcBatchReactor, numberOfIntervals=16, stopTime=1,
tolerance=1e-8);

getErrorString();

An Example
----------

In this section, a simple optimal control problem will be solved. When
formulating the optimization problems, models are expressed in the
Modelica language and optimization specifications. The optimization
language specification allows users to formulate dynamic optimization
problems to be solved by a numerical algorithm. It includes several
constructs including a new specialized class optimization, a constraint
section, startTime, finalTime etc. See the optimal control problem for
batch reactor model below.

**optimization** BatchReactor(objective=-x2(finalTime),

startTime = 0, finalTime =1)

Real x1(start =1, fixed=true, min=0, max=1);

Real x2(start =0, fixed=true, min=0, max=1);

**input** Real u(min=0, max=5);

**equation**

**der**\ (x1) = -(u+u^2/2)\*x1;

**der**\ (x2) = u\*x1;

**end** BatchReactor;

Create a new file named BatchReactor.mo and save it in you working
directory. Notice that this model contains both the dynamic system to be
optimized and the optimization specification.

Once we have formulated the undelying optimal control problems, we can
run the optimization by using OMShell, OMNotebook , MDT, OMEdit or
command line terminals similar as described in Figure 6 -42.

The control and state trajectories of the optimization results are shown
in Figure 6 -43.

|image27|

|image28|

Figure 643: **Optimization results for Batch Reactor model – state and
control variables.**

Different Options for the Optimizer IPOPT
-----------------------------------------

Compiler options

+-----------------------+-------------------------+-------------------------+
| numberOfIntervals     |                         | collocation intervals   |
+-----------------------+-------------------------+-------------------------+
| startTime, stopTime   |                         | time horizon            |
+-----------------------+-------------------------+-------------------------+
| tolerance = 1e-8      | e.g. 1e-8               | solver tolerance        |
+-----------------------+-------------------------+-------------------------+
| simflags              | all run/debug options   |
+-----------------------+-------------------------+-------------------------+

Run/debug options

+---------------------+------------------+-----------------------------------------+
| -lv                 | LOG\_IPOPT       | console output                          |
+---------------------+------------------+-----------------------------------------+
| -ipopt\_hesse       | CONST,BFGS,NUM   | hessian approximation                   |
+---------------------+------------------+-----------------------------------------+
| -ipopt\_max\_iter   | number e.g. 10   | maximal number of iteration for ipopt   |
+---------------------+------------------+-----------------------------------------+
| externalInput.csv   |                  | input guess                             |
+---------------------+------------------+-----------------------------------------+

Figure 644: **Compiler options for IpOpt.**

Dynamic Optimization with OpenModelica and CasADi
-------------------------------------------------

OpenModelica coupling with CasADi supports dynamic optimization of
models by OpenModelica exporting the optimization problem to CasADi
which performs the optimization. In order to convey the dynamic system
model information between Modelica and CasADi, we use an XML-based model
exchange format for differential-algebraic equations (DAE). OpenModelica
supports export of models written in Modelica and the Optimization
language extension using this XML format, while CasADi supports import
of models represented in this format. This allows users to define
optimal control problems (OCP) using Modelica and Optimization language
specifications, and solve the underlying model formulation using a range
of optimization methods, including direct collocation and direct
multiple shooting.

Compiling the Modelica code
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Before exporting a model to XML, the model should be symbolically
instantiated by the compiler in order to get a single flat system of
equations. The model variables should also be scalarized. The compiler
frontend performs this, including syntax checking, semantics and type
checking, simplification and constant evaluation etc. are applied. Then
the complete flattened model is exported to XML code. The exported XML
document can then be imported to CasADi for model-based dynamic
optimization.

The OpenModelica command translateModelXML(ModelName) from OMShell,
OMNotebook or MDT exports the XML. The export XML command is also
integrated with OMEdit. Select XML > Export XML the XML document is
generated in the current directory of omc. You can use the cd() command
to see the current location. After the command execution is complete you
will see that a file ModelName.xml has been exported. As depicted in
Figure 6 -45, we first changed the current directory to
C:/OpenModelica1.9.2/bin, and then we loaded a Modelica file with
BatchReactor example model and finally exported an XML for it using the
translateModelXML call.

Assuming that the model is defined in the modelName.mo, the model can
also be exported to an XML code using the following steps from the
terminal window:

-  Go to the path where your model file found(C:/<%path to modelName .mo
   file%>).

-  Go to omc path (<%path to omc%>/omc) and write the flag +s
   +g=Optimica +simCodeTarget=XML <%your.mo file name%>.mo>

|image29|

Figure 645: **OMShell screenshot for exporting an XML.**

An example
~~~~~~~~~~

In this section, a simple optimal control problem will be solved. When
formulating the optimization problems, models are expressed in the
Modelica language and optimization specifications. The optimization
language specification allows users to formulate dynamic optimization
problems to be solved by a numerical algorithm. It includes several
constructs including a new specialized class optimization, a constraint
section, startTime, finalTime etc. See the optimal control problem for
batch reactor model below.

**optimization** BatchReactor(objective=-x2(finalTime),

startTime = 0, finalTime =1)

Real x1(start =1, fixed=true, min=0, max=1);

Real x2(start =0, fixed=true, min=0, max=1);

input Real u(min=0, max=5);

**equation**

der(x1) = -(u+u^2/2)\*x1;

der(x2) = u\*x1;

**end** BatchReactor;

Create a new file named BatchReactor.mo and save it in you working
directory. Notice that this model contains both the dynamic system to be
optimized and the optimization specification.

One we have formulated the undelying optimal control problems, we can
export the XML by using OMShell, OMNotebook , MDT, OMEdit or command
line terminals which are described in Section 6.2.4 .

To export XML using terminals as depicted in Figure 6 -46, we first
changed the current directory to C:/TestCases, and run command
../Dev/OpenModleica/build/bin omc +s +g=Optimica +simCodeTarget=XML
BatchReactor.mo. This will generate an XML file under C:/TestCases
directory named BatchReactor.xml shown in Section 6.2.3 that contains a
symbolic representation of the optimal control problem and can be
inspected in a standard XML editor.

|image30|

Figure 646: **Terminal screenshot for exporting an XML.**

Generated XML for Example
~~~~~~~~~~~~~~~~~~~~~~~~~

<?xml version="1.0" encoding="UTF-8"?>

<OpenModelicaModelDescription

xmlns:exp="https://svn.jmodelica.org/trunk/XML/daeExpressions.xsd"

xmlns:equ="https://svn.jmodelica.org/trunk/XML/daeEquations.xsd"

xmlns:fun="https://svn.jmodelica.org/trunk/XML/daeFunctions.xsd"

xmlns:opt="https://svn.jmodelica.org/trunk/XML/daeOptimization.xsd"

xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"

fmiVersion="1.0"

modelName="BatchReactor"

modelIdentifier="BatchReactor"

guid="{d06ca497-3a14-4c61-ab0a-ee9f3edfca73}"

generationDateAndTime="2012-05-18T17:47:35"

variableNamingConvention="Structured"

numberOfContinuousStates="2"

numberOfEventIndicators="0">

<VendorAnnotations>

<Tool name="OpenModelica Compiler 1.8.1+ (r11925)">

</Tool>

</VendorAnnotations>

<ModelVariables>

<ScalarVariable name="finalTime" valueReference="0"

variability="parameter" causality="internal" alias="noAlias">

<Real relativeQuantity="false" start="1.0" free="false"

initialGuess="0.0" />

<QualifiedName>

<exp:QualifiedNamePart name="finalTime"/>

</QualifiedName>

<isLinear>true</isLinear>

<isLinearTimedVariables>

<TimePoint index="0" isLinear="true"/>

</isLinearTimedVariables>

<VariableCategory>independentParameter</VariableCategory>

</ScalarVariable>

<ScalarVariable name="startTime" valueReference="1"

variability="parameter" causality="internal" alias="noAlias">

<Real relativeQuantity="false" start="0.0" free="false"

initialGuess="0.0" />

<QualifiedName>

<exp:QualifiedNamePart name="startTime"/>

</QualifiedName>

<isLinear>true</isLinear>

<isLinearTimedVariables>

<TimePoint index="0" isLinear="true"/>

</isLinearTimedVariables>

<VariableCategory>independentParameter</VariableCategory>

</ScalarVariable>

<ScalarVariable name="x1" valueReference="2" variability="continuous"

causality="internal" alias="noAlias">

<Real relativeQuantity="false" min="0.0" max="1.0" start="1.0"

fixed="true" />

<QualifiedName>

<exp:QualifiedNamePart name="x1"/>

</QualifiedName>

<VariableCategory>state</VariableCategory>

</ScalarVariable>

<ScalarVariable name="x2" valueReference="3"

variability="continuous" causality="internal" alias="noAlias">

<Real relativeQuantity="false" min="0.0" max="1.0" start="0.0"

fixed="true" />

<QualifiedName>

<exp:QualifiedNamePart name="x2"/>

</QualifiedName>

<VariableCategory>state</VariableCategory>

</ScalarVariable>

<ScalarVariable name="der(x1)" valueReference="4"

variability="continuous" causality="internal" alias="noAlias">

<Real relativeQuantity="false" />

<QualifiedName>

<exp:QualifiedNamePart name="x1"/>

</QualifiedName>

<VariableCategory>derivative</VariableCategory>

</ScalarVariable>

<ScalarVariable name="der(x2)" valueReference="5"

variability="continuous" causality="internal" alias="noAlias">

<Real relativeQuantity="false" />

<QualifiedName>

<exp:QualifiedNamePart name="x2"/>

</QualifiedName>

<VariableCategory>derivative</VariableCategory>

</ScalarVariable>

<ScalarVariable name="u" valueReference="6"

variability="continuous" causality="input" alias="noAlias">

<Real relativeQuantity="false" min="0.0" max="5.0"/>

<QualifiedName>

<exp:QualifiedNamePart name="u"/>

</QualifiedName>

<VariableCategory>algebraic</VariableCategory>

</ScalarVariable>

</ModelVariables>

<equ:BindingEquations>

<equ:BindingEquation>

<equ:Parameter>

<exp:QualifiedNamePart name="startTime"/>

</equ:Parameter>

<equ:BindingExp>

<exp:IntegerLiteral>0</exp:IntegerLiteral>

</equ:BindingExp>

</equ:BindingEquation>

<equ:BindingEquation>

<equ:Parameter>

<exp:QualifiedNamePart name="finalTime"/>

</equ:Parameter>

<equ:BindingExp>

<exp:IntegerLiteral>1</exp:IntegerLiteral>

</equ:BindingExp>

</equ:BindingEquation>

</equ:BindingEquations>

<equ:DynamicEquations>

<equ:Equation>

<exp:Sub>

<exp:Der>

<exp:Identifier>

<exp:QualifiedNamePart name="x2"/>

</exp:Identifier>

</exp:Der>

<exp:Mul>

<exp:Identifier>

<exp:QualifiedNamePart name="u"/>

</exp:Identifier>

<exp:Identifier>

<exp:QualifiedNamePart name="x1"/>

</exp:Identifier>

</exp:Mul>

</exp:Sub>

</equ:Equation>

<equ:Equation>

<exp:Sub>

<exp:Der>

<exp:Identifier>

<exp:QualifiedNamePart name="x1"/>

</exp:Identifier>

</exp:Der>

<exp:Mul>

<exp:Sub>

<exp:Div>

<exp:Neg>

<exp:Pow>

<exp:Identifier>

<exp:QualifiedNamePart name="u"/>

</exp:Identifier>

<exp:RealLiteral>2.0</exp:RealLiteral>

</exp:Pow>

</exp:Neg>

<exp:RealLiteral>2.0</exp:RealLiteral>

</exp:Div>

<exp:Identifier>

<exp:QualifiedNamePart name="u"/>

</exp:Identifier>

</exp:Sub>

<exp:Identifier>

<exp:QualifiedNamePart name="x1"/>

</exp:Identifier>

</exp:Mul>

</exp:Sub>

</equ:Equation>

</equ:DynamicEquations>

<equ:InitialEquations>

<equ:Equation>

<exp:Sub>

<exp:Identifier>

<exp:QualifiedNamePart name="x1"/>

</exp:Identifier>

<exp:RealLiteral>1.0</exp:RealLiteral>

</exp:Sub>

</equ:Equation>

<equ:Equation>

<exp:Sub>

<exp:Identifier>

<exp:QualifiedNamePart name="x2"/>

</exp:Identifier>

<exp:RealLiteral>0.0</exp:RealLiteral>

</exp:Sub>

</equ:Equation>

</equ:InitialEquations>

<opt:Optimization>

<opt:ObjectiveFunction>

<exp:Neg>

<exp:TimedVariable timePointIndex = "0" >

<exp:Identifier>

<exp:QualifiedNamePart name="x2"/>

</exp:Identifier>

</exp:TimedVariable>

</exp:Neg>

</opt:ObjectiveFunction>

<opt:IntervalStartTime>

<opt:Value>0.0</opt:Value>

<opt:Free>false</opt:Free>

<opt:InitialGuess>0.0</opt:InitialGuess>

</opt:IntervalStartTime>

<opt:IntervalFinalTime>

<opt:Value>1.0</opt:Value>

<opt:Free>false</opt:Free>

<opt:InitialGuess>1.0</opt:InitialGuess>

</opt:IntervalFinalTime>

<opt:TimePoints>

<opt:TimePoint index = "0" value = "1.0">

<opt:QualifiedName>

<exp:QualifiedNamePart name="x2"/>

</opt:QualifiedName>

</opt:TimePoint>

</opt:TimePoints>

<opt:Constraints>

</opt:Constraints>

</opt:Optimization>

<fun:FunctionsList>

</fun:FunctionsList>

</OpenModelicaModelDescription>

XML Import to CasADi via OpenModelica Python Script
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The symbolic optimal control problem representation (or just model
description) contained in BatchReactor.xml can be imported into CasADi
in the form of the SymbolicOCP class via OpenModelica python script.

The SymbolicOCP class contains symbolic representation of the optimal
control problem designed to be general and allow manipulation. For a
more detailed description of this class and its functionalities, we
refer to the API documentation of CasADi.

The following step compiles the model to an XML format, imports to
CasADi and solves an optimization problem in windows PowerShell:

1. Create a new file named BatchReactor.mo and save it in you working
   directory.

    E.g. C:\\OpenModelica1.9.2\\share\\casadi\\testmodel

1. Perform compilation and generate the XML file

   a. Go to your working directory

    E.g. cd C:\\OpenModelica1.9.2\\share\\casadi\\testmodel

a. Go to omc path from working directory and run the following command

    E.g. ..\\..\\..\\bin\\omc +s +g=Optimica +simCodeTarget=XML
    BatchReactor.mo

3. Run defaultStart.py python script from OpenModelica optimization
directory

E.g. Python.exe ..\\share\\casadi\\scripts defaultStart.py
BatchReactor.xml

The control and state trajectories of the optimization results are shown
in Figure 6 -47.

|image31|

|image32|

Figure 647: **Optimization results for Batch Reactor model – state and
control variables.**

Parameter Sweep Optimization using OMOptim
------------------------------------------

OMOptim is a tool for parameter sweep design optimization of Modelica
models. By optimization, one should understand a procedure which
minimizes/maximizes one or more objective functions by adjusting one or
more parameters. This is done by the optimization algorithm performing a
parameter swep, i.e., systematically adjusting values of selected
parameters and running a number of simulations for different parameter
combinations to find a parameter setting that gives an optimal value of
the goal function.

OMOptim 0.9 contains meta-heuristic optimization algorithms which allow
optimizing all sorts of models with following functionalities:

-  One or several objectives optimized simultaneously

-  One or several parameters (integer or real variables)

However, the user must be aware of the large number of simulations an
optimization might require.

Preparing the Model
~~~~~~~~~~~~~~~~~~~

Before launching OMOptim, one must prepare the model in order to
optimize it.

Parameters
^^^^^^^^^^

An optimization parameter is picked up from all model variables. The
choice of parameters can be done using the OMOptim interface.

For all intended parameters, please note that:

-  The corresponding variable is **constant** during all simulations.
       The OMOptim optimization in version 0.9 only concerns static
       parameters’ optimization *i.e.* values found for these parameters
       will be constant during all simulation time.

-  The corresponding variable should play an **input** role in the model
       *i.e.* its modification influences model simulation results.

Constraints
^^^^^^^^^^^

If some constraints should be respected during optimization, they must
be defined in the Modelica model itself.

For instance, if mechanical stress must be less than 5 N.m\ :sup:`-2`,
one should write in the model:

assert( mechanicalStress < 5, “Mechanical stress too high”);

If during simulation, the variable *mechanicalStress* exceeds 5
N.m\ :sup:`-2`, the simulation will stop and be considered as a failure.

Objectives
^^^^^^^^^^

As parameters, objectives are picked up from model variables.
Objectives’ values are considered by the optimizer at the *final time*.

Set problem in OMOptim
~~~~~~~~~~~~~~~~~~~~~~

Launch OMOptim
^^^^^^^^^^^^^^

OMOptim can be launched using the executable placed in
OpenModelicaInstallationDirectory/bin/ OMOptim/OMOptim.exe. Alternately,
choose OpenModelica > OMOptim from the start menu.

Create a new project
^^^^^^^^^^^^^^^^^^^^

To create a new project, click on menu File -> New project

Then set a name to the project and save it in a dedicated folder. The
created file created has a .min extension. It will contain information
regarding model, problems, and results loaded.

Load models
^^^^^^^^^^^

First, you need to load the model(s) you want to optimize. To do so,
click on *Add .mo* button on main window or select menu *Model -> Load
Mo file…*

When selecting a model, the file will be loaded in OpenModelica which
runs in the background.

While OpenModelica is loading the model, you could have a frozen
interface. This is due to multi-threading limitation but the delay
should be short (few seconds).

You can load as many models as you want.

If an error occurs (indicated in log window), this might be because:

-  Dependencies have not been loaded before (e.g. modelica library)

-  Model use syntax incompatible with OpenModelica.

**Dependencies**

OMOptim should detect dependencies and load corresponding files.
However, it some errors occur, please load by yourself dependencies. You
can also load Modelica library using Model->Load Modelica library.

When the model correctly loaded, you should see a window similar to
Figure 6 -48.

|image33|

Figure 648. **OMOptim window after having loaded model.**

Create a new optimization problem
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Problem->Add Problem->Optimization

A dialog should appear. Select the model you want to optimize. Only
Model can be selected (no Package, Component, Block…).

A new form will be displayed. This form has two tabs. One is called
Variables, the other is called Optimization.

|image34| Figure 649. **Forms for defining a new optimization problem.**

**List of Variables is Empty**

If variables are not displayed, right click on model name in model
hierarchy, and select *Read variables*.

|image35|

Figure 650. **Selecting read variables, set parameters, and selecting
simulator.**

Select Optimized Variables
^^^^^^^^^^^^^^^^^^^^^^^^^^

To set optimization, we first have to define the variables the optimizer
will consider as free *i.e.* those that it should find best values of.
To do this, select in the left list, the variables concerned. Then, add
them to *Optimized variables* by clicking on corresponding button
(|image36|).

For each variable, you must set minimum and maximum values it can take.
This can be done in the *Optimized variables* table.

Select objectives
^^^^^^^^^^^^^^^^^

Objectives correspond to the final values of chosen variables. To select
these last, select in left list variables concerned and click |image37|
button of *Optimization objectives* table.

For each objective, you must:

-  Set minimum and maximum values it can take. If a configuration does
       not respect these values, this configuration won’t be considered.
       You also can set minimum and maximum equals to “-“ : it will then

-  Define whether objective should be minimized or maximized.

This can be done in the *Optimized variables* table.

Select and configure algorithm
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

After having selected variables and objectives, you should now select
and configure optimization algorithm. To do this, click on
*Optimization* tab.

Here, you can select optimization algorithm you want to use. In version
0.9, OMOptim offers three different genetic algorithms. Let’s for
example choose SPEA2Adapt which is an auto-adaptative genetic algorithm.

By clicking on *parameters*\ … button, a dialog is opened allowing
defining parameters. These are:

-  *Population size*: this is the number of configurations kept after a
       generation. If it is set to 50, your final result can’t contain
       more than 50 different points.

-  *Off spring rate*: this is the number of children per adult obtained
       after combination process. If it is set to 3, each generation
       will contain 150 individual (considering population size is 50).

-  *Max generations*: this number defines the number of generations
       after which optimization should stop. In our case, each
       generation corresponds to 150 simulations. Note that you can
       still stop optimization while it is running by clicking on *stop*
       button (which will appear once optimization is launched).
       Therefore, you can set a really high number and still stop
       optimization when you want without losing results obtained until
       there.

-  *Save frequency*: during optimization, best configurations can be
       regularly saved. It allows to analyze evolution of best
       configurations but also to restart an optimization from
       previously obtained results. A Save Frequency parameter set to 3
       means that after three generations, a file is automatically
       created containing best configurations. These files are named
       iteraion1.sav, iteration2.sav and are store in *Temp* directory,
       and moved to *SolvedProblems* directory when optimization is
       finished.

-  *ReinitStdDev*: this is a specific parameter of EAAdapt1. It defines
       whether standard deviation of variables should be reinitialized.
       It is used only if you start optimization from previously
       obtained configurations (using *Use start file* option). Setting
       it to yes (1) will, in most of cases, lead to a spread research
       of optimized configurations, forgetting parameters’ variations’
       reduction obtained in previous optimization.

**Use start file**

As indicated before, it is possible to pursue an optimization finished
or stopped. To do this, you must enable *Use start file* option and
select file from which optimization should be started. This file is an
*iteration\_.sav* file created in previous optimization. It is stored in
corresponding *SolvedProblems* folder (*iteration10.sav* corresponds to
the tenth generation of previous optimization).

***Note that this functionality can only work with same variables and
objectives*.** However, minimum, maximum of variables and objectives can
be changed before pursuing an optimization.

Launch
^^^^^^

You can now launch Optimization by clicking *Launch* button.

Stopping Optimization
^^^^^^^^^^^^^^^^^^^^^

Optimization will be stopped when the generation counter will reach the
generation number defined in parameters. However, you can still stop the
optimization while it is running without loosing obtained results. To do
this, click on *Stop* button. Note that this will not immediately stop
optimization: it will first finish the current generation.

This stop function is especially useful when optimum points do not vary
any more between generations. This can be easily observed since at each
generation, the optimum objectives values and corresponding parameters
are displayed in log window.

Results
~~~~~~~

The result tab appear when the optimization is finished. It consists of
two parts: a table where variables are displayed and a plot region.

Obtaining all Variable Values
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

During optimization, the values of optimized variables and objectives
are memorized. The others are not. To get these last, you must
recomputed corresponding points. To achieve this, select one or several
points in point’s list region and click on *recompute*.

For each point, it will simulate model setting input parameters to point
corresponding values. All values of this point (including those which
are not optimization parameters neither objectives).

Window Regions in OMOptim GUI
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

|image38|

Figure 651. **Window regions in OMOptim GUI.**

.. |image26| image:: media/image52.png
.. |image27| image:: media/image53.png
.. |image28| image:: media/image54.png
.. |image29| image:: media/image55.png
.. |image30| image:: media/image56.png
.. |image31| image:: media/image57.png
.. |image32| image:: media/image58.png
.. |image33| image:: media/image59.png
.. |image34| image:: media/image60.png
.. |image35| image:: media/image61.png
.. |image36| image:: media/image62.png
.. |image37| image:: media/image63.png
.. |image38| image:: media/image64.png
