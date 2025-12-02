OMMatlab - OpenModelica Matlab Interface
========================================

OMMatlab - the OpenModelica Matlab API is a free, open source, highly
portable Matlab-based interactive session handler for Modelica
scripting. It provides the modeler with components for creating a
complete Modelica modeling, compilation and simulation environment based
on the latest OpenModelica library standard available. OMMatlab is
architectured to combine both the solving strategy and model building.
So domain experts (people writing the models) and computational
engineers (people writing the solver code) can work on one unified tool
that is industrially viable for optimization of Modelica models, while
offering a flexible platform for algorithm development and research.
OMMatlab is not a standalone package, it depends upon the
OpenModelica installation.

OMMatlab is implemented in Matlab and depends on
ZeroMQ - high performance asynchronous
messaging library and it supports the Modelica
Standard Library version 3.2 that is included in starting with
OpenModelica 1.9.2.


To install OMMatlab follow the instructions at https://github.com/OpenModelica/OMMatlab


Features of OMMatlab
~~~~~~~~~~~~~~~~~~~~
The OMMatlab package contains the following features:

- Import the OMMatlab package in Matlab
- Connect with the OpenModelica compiler through zmq sockets
- Able to interact with the OpenModelica compiler through the :ref:`available API <scripting-api>`
- All the API calls are communicated with the help of the sendExpression method implemented in a Matlab pacakge
- The results are returned as strings

Test Commands
~~~~~~~~~~~~~

To get started, create a OMMatlab session object:

>>> import OMMatlab.*
>>> omc= OMMatlab()
>>> omc.sendExpression("getVersion()")
'v1.13.0-dev-531-gde26b558a (64-bit)'
>>> omc.sendExpression("loadModel(Modelica)")
'true'
>>> omc.sendExpression("model a Real s; equation s=sin(10*time); end a;")
'{a}'
>>> omc.sendExpression("simulate(a)")
>>> omc.sendExpression("plot(s)")
'true'

.. figure :: media/sineplot.png
  :name: sineplot


Advanced OMMatlab Features
--------------------------
OMMatlab package has advanced functionality for querying more information about the models
and simulate them. A list of new user friendly API functionality allows user to extract information about models using matlab
objects. A list of API functionality is described below.

To get started, create a ModelicaSystem object:

>>> import OMMatlab.*
>>> omc= OMMatlab()
>>> omc.ModelicaSystem("BouncingBall.mo","BouncingBall")

The object constructor requires a minimum of 2 input arguments which are strings, and third input argument which is optional .

- The first input argument must be a string with the file name of the Modelica code, with Modelica file extension ".mo".
  If the Modelica file is not in the current directory, then the file path must also be included.

- The second input argument must be a string with the name of the Modelica model
  including the namespace if the model is wrapped within a Modelica package.

- The third input argument (optional) is used to specify the list of dependent libraries or dependent Modelica files
  The argument can be passed as a string or array of strings e.g.,

>>> omc.ModelicaSystem("BouncingBall.mo","BouncingBall",["Modelica", "SystemDynamics", "dcmotor.mo"])

-  The fourth input argument (optional), which is used to set the command line options e.g.,

>>> omc.ModelicaSystem("BouncingBall.mo","BouncingBall",["Modelica", "SystemDynamics", "dcmotor.mo"],"-d=newInst")

Matlab does not support keyword arguments, and hence inorder to skip an argument, empty list should be used "[]" e.g.,

>>> omc.ModelicaSystem("BouncingBall.mo","BouncingBall",[],"-d=newInst")


WorkDirectory
~~~~~~~~~~~~~
For each Matlab session a temporary work directory is created and the results are published in that working directory, Inorder to get the workdirectory the users can
use the following API

>>> omc.getWorkDirectory()
'C:/Users/arupa54/AppData/Local/Temp/tp7dd648e5_5de6_4f66_b3d6_90bce1fe1d58'

BuildModel
~~~~~~~~~~
The buildModel API can be used after ModelicaSystem(), in case the model needs to be updated or additional simulationflags needs to be set using sendExpression()

>>> omc.buildModel()

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
>>> omc.getQuantities() // method-1, list of all variables from xml file
+----------+------------+-------------------------+--------------+------------+-----------+---------------+-------+
| name     | changeable | description             | variability  | causality  | alias     | aliasVariable | value |
+----------+------------+-------------------------+--------------+------------+-----------+---------------+-------+
| 'h'      | 'true'     | 'height of ball'        | 'continuous' | 'internal' | 'noAlias' | ''            | '1.0' |
+----------+------------+-------------------------+--------------+------------+-----------+---------------+-------+
| 'v'      | 'true'     | 'velocity of ball'      | 'continuous' | 'internal' | 'noAlias' | ''            | ''    |
+----------+------------+-------------------------+--------------+------------+-----------+---------------+-------+
| 'der(h)' | 'false'    | 'der(height of ball)'   | 'continuous' | 'internal' | 'noAlias' | ''            | ''    |
+----------+------------+-------------------------+--------------+------------+-----------+---------------+-------+
| 'der(v)' | 'false'    | 'der(velocity of ball)' | 'continuous' | 'internal' | 'noAlias' | ''            | ''    |
+----------+------------+-------------------------+--------------+------------+-----------+---------------+-------+

>>> omc.getQuantities("h") // method-2, to query information about single quantity
+----------+------------+-------------------------+--------------+------------+-----------+---------------+-------+
| name     | changeable | description             | variability  | causality  | alias     | aliasVariable | value |
+----------+------------+-------------------------+--------------+------------+-----------+---------------+-------+
| 'h'      | 'true'     | 'height of ball'        | 'continuous' | 'internal' | 'noAlias' | ''            | '1.0' |
+----------+------------+-------------------------+--------------+------------+-----------+---------------+-------+

>>> omc.getQuantities(["h","v"]) // method-3, to query information about list of quantity
+----------+------------+-------------------------+--------------+------------+-----------+---------------+-------+
| name     | changeable | description             | variability  | causality  | alias     | aliasVariable | value |
+----------+------------+-------------------------+--------------+------------+-----------+---------------+-------+
| 'h'      | 'true'     | 'height of ball'        | 'continuous' | 'internal' | 'noAlias' | ''            | '1.0' |
+----------+------------+-------------------------+--------------+------------+-----------+---------------+-------+
| 'v'      | 'true'     | 'velocity of ball'      | 'continuous' | 'internal' | 'noAlias' | ''            | ''    |
+----------+------------+-------------------------+--------------+------------+-----------+---------------+-------+

>>> omc.getContinuous() // method-1, returns struct of continuous variable
struct with fields:
  h     : '1.0'
  v     : ''
  der_h_: ''
  der_v_: ''

>>> omc.getContinuous(["h","v"])   // method-2, returns string array
"1.0"    ""

>>> omc.getInputs()
struct with no fields

>>> omc.getOutputs()
struct with no fields

>>> omc.getParameters()  // method-1
struct with fields:
	e: '0.7'
	g: '9.810000000000001'

>>> omc.getParameters(["c","radius"]) // method-2
"0.7"  "9.810000000000001"

>>> omc.getSimulationOptions()  // method-1
struct with fields:
	startTime: '0'
	 stopTime: '1'
	 stepSize: '0.002'
	tolerance: '1e-006'
	   solver: 'dassl'

>>> omc.getSimulationOptions(["stepSize","tolerance"]) // method-2
"0.002", "1e-006"

The getSolution method can be used in two different ways.
 #. using default result filename
 #. use the result filenames provided by user

This provides a way to compare simulation results and perform regression testing

>>> omc.getSolutions() // method-1 returns string arrays of simulation variables for which results are available, the default result filename is taken
"time", "height", ""velocity", "der(height)", "der(velocity)", "c", "radius"

>>> omc.getSolutions(["time","h"])  // return list of cell arrays
1×2 cell array
{1×506 double}    {1×506 double}

>>> omc.getSolutions([],"c:/tmpbouncingBall.mat") // method-2 returns string arrays of simulation variables for which results are available , the resulfile location is provided by user
"time", "height", "velocity", "der(height)", "der(velocity)", "c", "radius"

>>> omc.getSolutions(["time","h"],"c:/tmpbouncingBall.mat") // return list of cell arrays
1×2 cell array
{1×506 double}    {1×506 double}


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

>>> omc.setInputs("cAi=1") // method-1

>>> omc.setInputs(["cAi=1","Ti=2"]) // method-2

>>> omc.setParameters("e=14") // method-1

>>> omc.setParameters(["e=14","g=10.8"]) // method-2 setting parameter value using array of string

>>> omc.setSimulationOptions(["stopTime=2.0","tolerance=1e-08"])

Advanced Simulation
~~~~~~~~~~~~~~~~~~~
An example of how to do advanced simulation to set parameter values using set methods and finally simulate the  "BouncingBall.mo" model is given below .

>>> omc.getParameters()
struct with fields:
	e: '0.7'
	g: '9.810000000000001'

>>> omc.setParameters(["e=0.9","g=9.83"])

To check whether new values are updated to model , we can again query the getParameters().

>>> omc.getParameters()
struct with fields:
    e: "0.9"
    g: "9.83"

Similary we can also use setInputs() to set a value for the inputs during various time interval can also be done using the following.

>>> omc.setInputs("cAi=1")

The model can be simulated using the `simulate` API in the following ways,
  #. without any arguments
  #. resultfile names provided by user (only filename is allowed and not the location)
  #. simflags - runtime simulationflags supported by OpenModelica

>>> omc.simulate() // method-1 default result file name will be used
>>> omc.simulate("tmpbouncingBall.mat") // method-2 resultfile name provided by users
>>> omc.simulate([],"-noEventEmit -noRestart -override=e=0.3,g=9.71") // method-3 simulationflags provided by users, since matlab does not support keyword argument we skip argument1 result file with empty list

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

>>> omc.getLinearizationOptions()  // method-1

>>> omc.getLinearizationOptions(["startTime","stopTime"]) // method-2
"0.0", "1.0"

>>> omc.setLinearizationOptions(["stopTime=2.0","tolerance=1e-08"])

>>> omc.linearize()  //returns a list 2D arrays (matrices) A, B, C and D.

>>> omc.getLinearInputs()  //returns a list of strings of names of inputs used when forming matrices.

>>> omc.getLinearOutputs() //returns a list of strings of names of outputs used when forming matrices.

>>> omc.getLinearStates() // returns a list of strings of names of states used when forming matrices.