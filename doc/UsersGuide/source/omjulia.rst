OMJulia – OpenModelica Julia Scripting
======================================

OMJulia – the OpenModelica Julia API is a free, open source, 
highly portable Julia based interactive session handler for 
Julia scripting of OpenModelica API functionality. It provides the modeler
with components for creating a complete Julia-Modelica modeling, compilation 
and simulation environment based on the latest OpenModelica implementation 
and Modelica library standard available. OMJulia is architectured to 
combine both the solving strategy and model building.
Thus, domain experts (people writing the models) and computational
engineers (people writing the solver code) can work on one unified tool
that is industrially viable for optimization of Modelica models, while
offering a flexible platform for algorithm development and research.
OMJulia is not a standalone package, it depends upon the 
OpenModelica installation.

OMJulia is implemented in Julia and depends on
ZeroMQ - high performance asynchronous messaging library and it supports the Modelica
Standard Library version 3.2 that is included in starting with
OpenModelica 1.9.2.

To install OMJulia follow the instructions at https://github.com/OpenModelica/OMJulia.jl

Features of OMJulia
~~~~~~~~~~~~~~~~~~~
The OMJulia package contains the following features:

- Interactive session handling, parsing, interpretation of commands and
  Modelica expressions for evaluation, simulation, plotting, etc.
- Connect with the OpenModelica compiler through zmq sockets
- Able to interact with the OpenModelica compiler through the :ref:`available API <scripting-api>`
- Easy access to the Modelica Standard library.
- All the API calls are communicated with the help of the sendExpression method implemented in a Julia module
- The results are returned as strings

Test Commands
~~~~~~~~~~~~~

To get started, create an OMJulia session object:

>>> using OMJulia
>>> omc= OMJulia.OMCSession()
>>> sendExpression(omc,"loadModel(Modelica)")
true
>>> sendExpression(omc,"model a Real s; equation s=sin(10*time); end a;")
1-element Array{Symbol,1}:
 :a
>>> sendExpression(omc,"simulate(a)")
>>> sendExpression(omc,"plot(s)")
true

.. figure :: media/sineplot.png
  :name: sineplot

Advanced OMJulia Features
-------------------------
OMJulia package has advanced functionality for querying more information about the models
and simulate them. A list of new user friendly API functionality allows user to extract information about models using julia
objects. A list of API functionality is described below.

To get started, create a ModelicaSystem object:

>>> using OMJulia
>>> mod = OMJulia.OMCSession()
>>> ModelicaSystem(mod,"BouncingBall.mo","BouncingBall")

The object constructor requires a minimum of 2 input arguments which are strings, and third input argument which is optional .

- The first input argument must be a string with the file name of the Modelica code, with Modelica file extension ".mo".
  If the Modelica file is not in the current directory, then the file path must also be included.

- The second input argument must be a string with the name of the Modelica model
  including the namespace if the model is wrapped within a Modelica package.

- The third input argument (optional) is used to specify the list of dependent libraries or dependent Modelica files
  The argument can be passed as a string or array of strings e.g.,

>>> ModelicaSystem(mod,"BouncingBall.mo","BouncingBall",["Modelica", "SystemDynamics", "dcmotor.mo"])

-  The fourth input argument (optional), is a keyword argument which is used to set the command line options e.g.,

>>> ModelicaSystem(mod,"BouncingBall.mo","BouncingBall",["Modelica", "SystemDynamics", "dcmotor.mo"],commandLineOptions="-d=newInst")


WorkDirectory
~~~~~~~~~~~~~
For each OMJulia session a temporary work directory is created and the results are published in that working directory, Inorder to get the workdirectory the users can
use the following API

>>> getWorkDirectory(mod)
"C:/Users/arupa54/AppData/Local/Temp/jl_5pbewl"

BuildModel
~~~~~~~~~~
The buildModel API can be used after ModelicaSystem(), in case the model needs to be updated or additional simulationflags needs to be set using sendExpression()

>>> buildModel(mod)


Standard get methods
~~~~~~~~~~~~~~~~~~~~

- getQuantities()
- showQuantities()
- getContinuous()
- getInputs()
- getOutputs()
- getParameters()
- getSimulationOptions()
- getSolutions()

Three calling possibilities are accepted using getXXX() where "XXX" can be any of the above functions (eg:) getParameters().

-  getXXX() without input argument, returns a dictionary with names as keys and values as values.
-  getXXX(S), where S is a string of names.
-  getXXX(["S1","S2"]) where S1 and S1 are array of string elements

Usage of getMethods
~~~~~~~~~~~~~~~~~~~

>>> getQuantities(mod) // method-1, list of all variables from xml file
[{"aliasvariable": None, "Name": "height", "Variability": "continuous", "Value": "1.0", "alias": "noAlias", "Changeable": "true", "Description": None}, {"aliasvariable": None, "Name": "c", "Variability": "parameter", "Value": "0.9", "alias": "noAlias", "Changeable": "true", "Description": None}]

>>> getQuantities(mod,"height") // method-2, to query information about single quantity
[{"aliasvariable": None, "Name": "height", "Variability": "continuous", "Value": "1.0", "alias": "noAlias", "Changeable": "true", "Description": None}]

>>> getQuantities(mod,["c","radius"]) // method-3, to query information about list of quantity
[{"aliasvariable": None, "Name": "c", "Variability": "parameter", "Value": "0.9", "alias": "noAlias", "Changeable": "true", "Description": None}, {"aliasvariable": None, "Name": "radius", "Variability": "parameter", "Value": "0.1", "alias": "noAlias", "Changeable": "true", "Description": None}]

>>> getContinuous(mod) // method-1, list of continuous variable
{"velocity": "-1.825929609047952", "der(velocity)": "-9.8100000000000005", "der(height)": "-1.825929609047952", "height": "0.65907039052943617"}

>>> getContinuous(mod,["velocity","height"]) // method-2, get specific variable value information
["-1.825929609047952", "0.65907039052943617"]

>>> getInputs(mod)
{}

>>> getOutputs(mod)
{}

>>> getParameters(mod)  // method-1
{"c": "0.9", "radius": "0.1"}

>>> getParameters(mod,["c","radius"]) // method-2
["0.9", "0.1"]

>>> getSimulationOptions(mod)  // method-1
{"stepSize": "0.002", "stopTime": "1.0", "tolerance": "1e-06", "startTime": "0.0", "solver": "dassl"}

>>> getSimulationOptions(mod,["stepSize","tolerance"]) // method-2
["0.002", "1e-06"]

The getSolution method can be used in two different ways.
 #. using default result filename
 #. use the result filenames provided by user

This provides a way to compare simulation results and perform regression testing

>>> getSolutions(mod) // method-1 returns list of simulation variables for which results are available
["time", "height", ""velocity", "der(height)", "der(velocity)", "c", "radius"]

>>> getSolutions(mod,["time","height"])  // return list of array

>>> getSolutions(mod,resultfile="c:/tmpbouncingBall.mat") // method-2 returns list of simulation variables for which results are available , the resulfile location is provided by user
["time", "height", ""velocity", "der(height)", "der(velocity)", "c", "radius"]

>>> getSolutions(mod,["time","h"],resultfile="c:/tmpbouncingBall.mat") // return list of array

>>> showQuantities(mod) // same as getQuantities() but returns the results in the form table

Standard set methods
~~~~~~~~~~~~~~~~~~~~
- setInputs()
- setParameters()
- setSimulationOptions()

Two setting possibilities are accepted using setXXXs(),where "XXX" can be any of above functions.

- setXXX("Name=value") string of keyword assignments
- setXXX(["Name1=value1","Name2=value2","Name3=value3"])  array of string of keyword assignments


Usage of setMethods
~~~~~~~~~~~~~~~~~~~

>>> setInputs(mod,"cAi=1") // method-1

>>> setInputs(mod,["cAi=1","Ti=2"]) // method-2

>>> setParameters(mod,"radius=14") // method-1

>>> setParameters(mod,["radius=14","c=0.5"]) // method-2 setting parameter value using array of string

>>> setSimulationOptions(mod,["stopTime=2.0","tolerance=1e-08"])


Advanced Simulation
~~~~~~~~~~~~~~~~~~~
An example of how to do advanced simulation to set parameter values using set methods and finally simulate the  "BouncingBall.mo" model is given below . 

>>> getParameters(mod)
{"c": "0.9", "radius": "0.1"}

>>> setParameters(mod,["radius=14","c=0.5"])

To check whether new values are updated to model , we can again query the getParameters().

>>> getParameters(mod)
{"c": "0.5", "radius": "14"}

Similary we can also use setInputs() to set a value for the inputs during various time interval can also be done using the following.

>>> setInputs(mod,"cAi=1")

The model can be simulated using the `simulate` API in the following ways,
  #. without any arguments
  #. resultfile (keyword argument) - (only filename is allowed and not the location)
  #. simflags (keyword argument) - runtime simulationflags supported by OpenModelica

>>> simulate(mod) // method-1 default result file name will be used
>>> simulate(mod,resultfile="tmpbouncingBall.mat") // method-2 resultfile name provided by users
>>> simulate(mod,simflags="-noEventEmit -noRestart -override=e=0.3,g=9.71") // method-3 simulationflags provided by users


Linearization
~~~~~~~~~~~~~
The following methods are available for linearization of a modelica model

- linearize()
- getLinearizationOptions()
- setLinearizationOptions()
- getLinearInputs()
- getLinearOutputs()
- getLinearStates()

Usage of Linearization methods
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

>>> getLinearizationOptions(mod)  // method-1
{"stepSize": "0.002", "stopTime": "1.0", "startTime": "0.0", "numberOfIntervals": "500.0", "tolerance": "1e-08"}

>>> getLinearizationOptions(mod,["startTime","stopTime"]) // method-2
["0.0", "1.0"]

>>> setLinearizationOptions(mod,["stopTime=2.0","tolerance=1e-06"])

>>> linearize(mod)  //returns a list 2D arrays (matrices) A, B, C and D.

>>> getLinearInputs(mod)  //returns a list of strings of names of inputs used when forming matrices.

>>> getLinearOutputs(mod) //returns a list of strings of names of outputs used when forming matrices.

>>> getLinearStates(mod) // returns a list of strings of names of states used when forming matrices.


Sensitivity Analysis
~~~~~~~~~~~~~~~~~~~~

A Method for computing numeric sensitivity of modelica model is available .
  
- (res1,res2) = sensitivity(arg1,arg2,arg3)

The constructor requires a minimum of 3 input arguments .

- arg1: Array of strings of Modelica Parameter names
- arg2: Array of strings of Modelica Variable names
- arg3: Array of float Excitations of parameters; defaults to scalar 1e-2

The results contains the following .

- res1: Vector of Sensitivity names.
- res2: Array of sensitivies: vector of elements per parameter, each element containing time series per variable.

Usage 
~~~~~

>>> (Sn, Sa) = sensitivity(mod,["UA","EdR"],["T","cA"],[1e-2,1e-4])


With the above list of API calls implemented, the users can have more control over the result types, returned as Julia data structures.
