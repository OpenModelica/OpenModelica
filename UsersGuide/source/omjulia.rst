OMJulia – OpenModelica Julia Interface
======================================

OMJulia – the OpenModelica Julia API is a free, open source, highly
portable Julia based interactive session handler for Modelica
scripting. It provides the modeler with components for creating a
complete Modelica modeling, compilation and simulation environment based
on the latest OpenModelica library standard available. OMPython is
architectured to combine both the solving strategy and model building.
So domain experts (people writing the models) and computational
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
>>> omc.sendExpression("loadModel(Modelica)")
"True"
>>> omc.sendExpression("model a Real s; equation s=sin(10*time); end a;")
"{a}"
>>> omc.sendExpression("simulate(a)")
>>> omc.sendExpression("plot(s)")
"true"

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
>>> mod.ModelicaSystem("BouncingBall.mo","BouncingBall")

The object constructor requires a minimum of 2 input arguments which are strings, and third input argument which is optional .

- The first input argument must be a string with the file name of the Modelica code, with Modelica file extension ".mo".
  If the Modelica file is not in the current directory, then the file path must also be included.

- The second input argument must be a string with the name of the Modelica model
  including the namespace if the model is wrapped within a Modelica package.

- The third input argument (optional) is used to specify the list of dependent libraries 
  The argument can be passed as a string or array of strings e.g.,

>>> mod.ModelicaSystem("BouncingBall.mo","BouncingBall",["Modelica", "SystemDynamics"])


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

>>> mod.getQuantities() // method-1, list of all variables from xml file
[{"aliasvariable": None, "Name": "height", "Variability": "continuous", "Value": "1.0", "alias": "noAlias", "Changeable": "true", "Description": None}, {"aliasvariable": None, "Name": "c", "Variability": "parameter", "Value": "0.9", "alias": "noAlias", "Changeable": "true", "Description": None}]

>>> mod.getQuantities("height") // method-2, to query information about single quantity
[{"aliasvariable": None, "Name": "height", "Variability": "continuous", "Value": "1.0", "alias": "noAlias", "Changeable": "true", "Description": None}]

>>> mod.getQuantities(["c","radius"]) // method-3, to query information about list of quantity
[{"aliasvariable": None, "Name": "c", "Variability": "parameter", "Value": "0.9", "alias": "noAlias", "Changeable": "true", "Description": None}, {"aliasvariable": None, "Name": "radius", "Variability": "parameter", "Value": "0.1", "alias": "noAlias", "Changeable": "true", "Description": None}]

>>> mod.getContinuous() // method-1, list of continuous variable
{"velocity": "-1.825929609047952", "der(velocity)": "-9.8100000000000005", "der(height)": "-1.825929609047952", "height": "0.65907039052943617"}

>>> mod.getContinuous(["velocity","height"]) // method-2, get specific variable value information
["-1.825929609047952", "0.65907039052943617"]

>>> mod.getInputs()
{}

>>>  mod.getOutputs()
{}

>>> mod.getParameters()  // method-1
{"c": "0.9", "radius": "0.1"}

>>> mod.getParameters(["c","radius"]) // method-2
["0.9", "0.1"]

>>> mod.getSimulationOptions()  // method-1
{"stepSize": "0.002", "stopTime": "1.0", "tolerance": "1e-06", "startTime": "0.0", "solver": "dassl"}

>>> mod.getSimulationOptions(["stepSize","tolerance"]) // method-2
["0.002", "1e-06"]

>>> mod.getSolutions() // method-1 returns list of simulation variables for which results are available
["time", "height", ""velocity", "der(height)", "der(velocity)", "c", "radius"]

>>> mod.getSolutions(["time","height"])  // method-2, return list of array

>>> mod.showQuantities() // same as getQuantities() but returns the results in the form table 

Standard set methods
~~~~~~~~~~~~~~~~~~~~
- setInputs()
- setParameters()
- setSimulationOptions()

Two setting possibilities are accepted using setXXXs(),where "XXX" can be any of above functions.

- setXXX(S) where S is a string of names
- setXXX([S1,S2])  where S1 and S1 are array of string elements


Usage of setMethods
~~~~~~~~~~~~~~~~~~~

>>> mod.setInputs("cAi=1") // method-1

>>> mod.setInputs(["cAi=1","Ti=2"]) // method-2

>>> mod.setParameters("radius=14") // method-1

>>> mod.setParameters(["radius=14","c=0.5"]) // method-2 setting parameter value using array of string 

>>> mod.setSimulationOptions(["stopTime=2.0","tolerance=1e-08"])


Advanced Simulation
~~~~~~~~~~~~~~~~~~~
An example of how to do advanced simulation to set parameter values using set methods and finally simulate the  "BouncingBall.mo" model is given below . 

>>> mod.getParameters()
{"c": "0.9", "radius": "0.1"}

>>> mod.setParameters(["radius=14","c=0.5"]) 

To check whether new values are updated to model , we can again query the getParameters().

>>> mod.getParameters()
{"c": "0.5", "radius": "14"}

Similary we can also use setInputs() to set a value for the inputs during various time interval can also be done using the following.

>>> mod.setInputs("cAi=1")

And then finally we can simulate the model using.

>>> mod.simulate()

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

>>> mod.getLinearizationOptions()  // method-1
{"stepSize": "0.002", "stopTime": "1.0", "startTime": "0.0", "numberOfIntervals": "500.0", "tolerance": "1e-08"}

>>> mod.getLinearizationOptions(["startTime","stopTime"]) // method-2
["0.0", "1.0"]

>>> mod.setLinearizationOptions(["stopTime=2.0","tolerance=1e-06"])

>>> mod.linearize()  //returns a tuple of 2D arrays (matrices) A, B, C and D.

>>> mod.getLinearInputs()  //returns a list of strings of names of inputs used when forming matrices.

>>> mod.getLinearOutputs() //returns a list of strings of names of outputs used when forming matrices.

>>> mod.getLinearStates() // returns a list of strings of names of states used when forming matrices.


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

>>> (Sn, Sa) = mod.sensitivity(["UA","EdR"],["T","cA"],[1e-2,1e-4])


With the above list of API calls implemented, the users can have more control over the result types, returned as Julia data structures.
