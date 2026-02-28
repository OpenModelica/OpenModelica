OMPython - OpenModelica Python Interface
========================================

This chapter describes the OpenModelica Python integration facilities.

-  OMPython.om_session_* - the OpenModelica Python scripting interface, see :ref:`om_session`.
-  OMPython.modelica_system_* - enhanced OMPython scripting interface, see :ref:`modelica_system`.
-  OMPython.modelica_doe_* - running design of experiments (DOE) using OpenModelica, see :ref:`modelica_doe`

Besides these main parts, additional helper functionality exists:

-  OMPython.OMParser and OMPython.OMTypedParser - parser for OpenModelica return data, see :ref:`parser`
-  OMPython.model_execution - execute compiled models, see :ref:`model_execution`

Each of the main sections listed above is differentiated in

-  OMPython.*_abc - basic functionality which is used by the two available implementations
-  OMPython.*_omc - run OpenModelica based on an OMC server
-  OMPython.*_runner - run simulations using pre-compiled binaries

The following data is based on OMPython version v4.x.x (to be released); it contains a compatibility layer which
supports the main interface based on OMPython v4.0.0. During a transition period, both options will be available. The
main differences between both implementations as well as limitations of the compatibility layer are described in
:ref:`compatibility`.

.. _om_session:

OMPython.OMCSession - OpenModelica Python Interface
---------------------------------------------------

OMPython - OpenModelica Python API is a free, open source, highly
portable Python based interactive session handler for Modelica
scripting. It provides the modeler with components for creating a
complete Modelica modeling, compilation and simulation environment based
on the latest OpenModelica tools standard available. OMPython is
architectured to combine both the solving strategy and model building.
So domain experts (people writing the models) and computational
engineers (people writing the solver code) can work on one unified tool
that is industrially viable for optimization of Modelica models, while
offering a flexible platform for algorithm development and research.
OMPython is not a standalone package, it depends upon the
OpenModelica installation.

OMPython is implemented in Python and depends on ZeroMQ - high performance asynchronous
messaging library.

To install OMPython follow the instructions at https://github.com/OpenModelica/OMPython

Features of OMPython
~~~~~~~~~~~~~~~~~~~~

OMPython provides user friendly features like:

-  Interactive session handling, parsing, interpretation of commands and
   Modelica expressions for evaluation, simulation, plotting, etc.

-  Interface to the latest OpenModelica API calls. **depreciated**; see :ref:`compatibility`

-  Optimized parser results that give control over every element of the output.

-  Helper functions to allow manipulation on Nested dictionaries.

-  Easy access to the library and testing of OpenModelica commands.

-  Possibility to run DoEs (design of experiments) based on parameter variation of an existing model.

-  Run models in different environments like Linux, Windows, docker or WSL.

-  Run compiled models without any dependency on OMC / ZMQ.

Test Commands
~~~~~~~~~~~~~

OMPython provides a set of classes named OMCSession* that uses ZeroMQ to communicate with the OpenModelica Compiler
(OMC). The following options exist:

-  OMCSessionLocal

-  OMCSessionPort

-  OMCSessionDocker

-  OMCSessionContainer

-  OMCSessionWSL

The handling of any paths within the communication is covered by OMCPath class. It is an implementation base on pathlib
which uses OMC to run the different filesystem related commands. Therefore, it can be used also for remote / separated
systems like docker or WSL.

To test the command outputs, simply create an OMCSessionLocal object by
importing from the OMPython library within Python interpreter. The
module allows you to interactively send commands to the OMC server and
display their output.

To get started, create an OMCSessionLocal object:

>>> import OMPython
>>> omc = OMPython.OMCSessionZMQ()

.. omc-mos ::
  :ompython-output:
  :parsed:
  :clear:

  getVersion()
  cd()
  loadModel(Modelica)
  loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/BouncingBall.mo")
  instantiateModel(BouncingBall)

We get the name and other properties of a class:

.. omc-mos ::
  :ompython-output:
  :parsed:

  getClassNames()
  isPartial(BouncingBall)
  isPackage(BouncingBall)
  isModel(BouncingBall)
  checkModel(BouncingBall)
  getClassRestriction(BouncingBall)
  getClassInformation(BouncingBall)
  getConnectionCount(BouncingBall)
  getInheritanceCount(BouncingBall)
  getComponentModifierValue(BouncingBall,e)
  checkSettings()

The common combination of a simulation followed by getting a value and
doing a plot:

.. omc-mos ::
  :ompython-output:
  :parsed:

  simulate(BouncingBall, stopTime=3.0)
  val(h , 2.0)

Import As Library
^^^^^^^^^^^^^^^^^

To use the module from within another python program, simply import the selected OMCSession* class from within the
selected program.

For example:

.. code-block:: python

  # test.py
  import OMPython
  omc = OMPython.OMCSessionLocal()
  cmds = [
    'loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/BouncingBall.mo")',
    "simulate(BouncingBall)",
    "plot(h)",
    ]
  for cmd in cmds:
    answer = omc.sendExpression(cmd)
    print("\n{}:\n{}".format(cmd, answer))

Implementation
~~~~~~~~~~~~~~

Client Implementation
^^^^^^^^^^^^^^^^^^^^^

The OpenModelica Python API Interface - OMPython, attempts to mimic the
OMShell's style of operations.

OMPython is designed to,

-  Initialize the ZeroMQ communication.

-  Send commands to the OMC server via the ZeroMQ interface.

-  Receive the string results.

-  Use the Parser module to format the results.

-  Return or display the results.

The main function to execute commands (like in OMShell) would be:

.. code-block:: python

  # test.py
  import OMPython
  omc = OMPython.OMCSessionLocal()
  cmds = [
    "getVersion()",
    ]
  for cmd in cmds:
    answer = omc.sendExpression(cmd)
    print("\n{}:\n{}".format(cmd, answer))

.. _modelica_system :

OMPython.ModelicaSystem - Enhanced OMPython Features
----------------------------------------------------
The ModelicaSystem class adds more functionality to OMPython. It provides methods to querying information about the
models, to modify data (parameters, inputs, ...) and to simulate them. The corresponding API is described below.

To get started, create a ModelicaSystem object:

>>> import OMPython
>>> mod = OMPython.ModelicaSystemOMC()

The constructor for an ModelicaSystemOMC object creates an OMCSessionLocal by default. If this is not desired or
additional configuration is needed, several options exist:

-  Via the argument command_line_options (optional), additional command line options for OMC can be defined:

>>> mod = OMPython.ModelicaSystemOMC(command_line_options="-d=newInst")

-  TODO: work_directory, omhome, session

After a ModelicaSystem object is created, the model can be defined:

>>> model_path = mod.get_session().sendExpression("getInstallationDirectoryPath()") + "/share/doc/omc/testmodels/"
>>> mod.model(model_name="BouncingBall", model_file=ModelicaSystem(model_path + "BouncingBall.mo"))

The class method model() allows several arguments:

-  model_name - The model name (as string). If the model is wrapped within a Modelica package, the namespace must also
   be included.

-  model_file - The path where to find the model file (as string or pathlib.Path object). The file should use the
   Modelica file extension ".mo". If the Modelica file is not in the current directory of Python, then the file path
   must also be included.

-  libraries - A third input argument (optional) is used to specify the list of dependent libraries or dependent
   Modelica files. Here, it is possible to just provide the library name or a tuple of library name and version:

>>> mod.model(model_name="BouncingBall", model_file=ModelicaSystem(model_path + "BouncingBall.mo"), libraries=["Modelica"])
>>> mod.model(model_name="BouncingBall", model_file=ModelicaSystem(model_path + "BouncingBall.mo"), libraries=[("Modelica","3.2.3"), "PowerSystems"])

-  variable_filter - Optional string which sets a filter for the output variables. It is defined as a regular
   expression. Only variables fully matching the regexp will be stored in the result file. Leaving it unspecified is
   equivalent to ".*".

-  build - Optional boolean controlling whether the model should be built when constructor is called. If False, the
   constructor simply loads the model without compiling.

BuildModel
~~~~~~~~~~
The buildModel API can either directly be executed on model definition (see above) or be called separately, in case the
model needs to be updated or additional simulation options needs to be set using sendExpression()

>>> mod.buildModel()

Standard get methods
~~~~~~~~~~~~~~~~~~~~

- getContinuous() [*] - possibility to use getContinuousInitial() or getContinuousFinal() for the defined cases
- getInputs() [*]
- getLinearInputs()
- getLinearisationOptions() [*]
- getLinearOutputs()
- getLinearStates()
- getOptimisationOptions() [*]
- getOutputs() [*] - possibility to use getContinuousInitial() or getContinuousFinal() for the defined cases
- getParameters() [*]
- getQuantities() [*]
- getSimulationOptions() [*]
- getSolutions()

Three calling possibilities are accepted by the marked get*() functions like getParameters():

-  get*() without input argument - returns a dictionary with names as keys and values as values.

-  get*(S), where S is a string of names - returns the value for S.

-  get*(["S1", "S2", ...]) where S1 and S1 define a list of string elements - returns a list of values matching the
   requested parameters

[TODO point]

Usage of getMethods
~~~~~~~~~~~~~~~~~~~

>>> mod.getQuantities() // method-1, list of all variables from xml file
[{'aliasvariable': None, 'Name': 'height', 'Variability': 'continuous', 'Value': '1.0', 'alias': 'noAlias', 'Changeable': 'true', 'Description': None}, {'aliasvariable': None, 'Name': 'c', 'Variability': 'parameter', 'Value': '0.9', 'alias': 'noAlias', 'Changeable': 'true', 'Description': None}]

>>> mod.getQuantities("height") // method-2, to query information about single quantity
[{'aliasvariable': None, 'Name': 'height', 'Variability': 'continuous', 'Value': '1.0', 'alias': 'noAlias', 'Changeable': 'true', 'Description': None}]

>>> mod.getQuantities(["c","radius"]) // method-3, to query information about list of quantity
[{'aliasvariable': None, 'Name': 'c', 'Variability': 'parameter', 'Value': '0.9', 'alias': 'noAlias', 'Changeable': 'true', 'Description': None}, {'aliasvariable': None, 'Name': 'radius', 'Variability': 'parameter', 'Value': '0.1', 'alias': 'noAlias', 'Changeable': 'true', 'Description': None}]

>>> mod.getContinuous() // method-1, list of continuous variable
{'velocity': -1.825929609047952, 'der(velocity)': -9.8100000000000005, 'der(height)': -1.825929609047952, 'height': 0.65907039052943617}

>>> mod.getContinuous(["velocity","height"]) // method-2, get specific variable value information
(-1.825929609047952, 0.65907039052943617)

>>> mod.getInputs()
{}

>>>  mod.getOutputs()
{}

>>> mod.getParameters()  // method-1
{'c': 0.9, 'radius': 0.1}

>>> mod.getParameters(["c","radius"]) // method-2
[0.9, 0.1]

>>> mod.getSimulationOptions()  // method-1
{'stepSize': 0.002, 'stopTime': 1.0, 'tolerance': 1e-06, 'startTime': 0.0, 'solver': 'dassl'}

>>> mod.getSimulationOptions(["stepSize","tolerance"]) // method-2
[0.002, 1e-06]

The getSolution method can be used in two different ways.
 #. using default result filename
 #. use the result filenames provided by user

This provides a way to compare simulation results and perform regression testing

>>> mod.getSolutions() // method-1 returns list of simulation variables for which results are available
['time', 'height', 'velocity', 'der(height)', 'der(velocity)', 'c', 'radius']

>>> mod.getSolutions(["time","height"])  // return list of numpy arrays

>>> mod.getSolutions(resultfile="c:/tmpbouncingBall.mat") // method-2 returns list of simulation variables for which results are available , the resulfile location is provided by user

>>> mod.getSolutions(["time","height"],resultfile="c:/tmpbouncingBall.mat") // return list of array


Standard set methods
~~~~~~~~~~~~~~~~~~~~
- setInputs()
- setParameters()
- setSimulationOptions()

Two setting possibilities are accepted using setXXXs(),where "XXX" can be any of above functions.

- setXXX("Name=value") string of keyword assignments
- setXXX(["Name1=value1","Name2=value2","Name3=value3"])  list of string of keyword assignments

Usage of setMethods
~~~~~~~~~~~~~~~~~~~

>>> mod.setInputs(["cAi=1","Ti=2"]) // method-2

>>> mod.setParameters("radius=14") // method-1 setting parameter value

>>> mod.setParameters(["radius=14","c=0.5"]) // method-2 setting parameter value using second option

>>> mod.setSimulationOptions(["stopTime=2.0","tolerance=1e-08"]) // method-2


Simulation
~~~~~~~~~~
An example of how to get parameter names and change the value of parameters using set methods and finally simulate the  "BouncingBall.mo" model is given below.

>>>  mod.getParameters()
{'c': 0.9, 'radius': 0.1}

>>>  mod.setParameters(["radius=14","c=0.5"]) //setting parameter value

To check whether new values are updated to model , we can again query the getParameters().

>>> mod.getParameters()
{'c': 0.5, 'radius': 14}

The model can be simulated using the `simulate` API in the following ways,
  #.  without any arguments
  #.  resultfile (keyword argument) - (only filename is allowed and not the location)
  #.  simargs (keyword argument) - runtime simulationflags supported by OpenModelica

>>> mod.simulate() // method-1 default result file name will be used
>>> mod.simulate(resultfile="tmpbouncingBall.mat")  // method-2 resultfile name provided by users
>>> mod.simulate(simargs={"noEventEmit": None, "noRestart": None, "override": {"e": 0.3, "g": 10}}) // method-3 simulationflags provided by users


Linearization
~~~~~~~~~~~~~
The following methods are proposed for linearization.

- linearize()
- getLinearizationOptions()
- setLinearizationOptions()
- getLinearInputs()
- getLinearOutputs()
- getLinearStates()

Usage of Linearization methods
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

>>> mod.getLinearizationOptions()  // method-1
{'simflags': ' ', 'stepSize': 0.002, 'stopTime': 1.0, 'startTime': 0.0, 'numberOfIntervals': 500.0, 'tolerance': 1e-08}

>>> mod.getLinearizationOptions("startTime","stopTime") // method-2
[0.0, 1.0]

>>> mod.setLinearizationOptions(["stopTime=2.0","tolerance=1e-06"])

>>> mod.linearize()  //returns a tuple of 2D numpy arrays (matrices) A, B, C and D.

>>> mod.getLinearInputs()  //returns a list of strings of names of inputs used when forming matrices.

>>> mod.getLinearOutputs() //returns a list of strings of names of outputs used when forming matrices

>>> mod.getLinearStates() // returns a list of strings of names of states used when forming matrices.


.. _modelica_doe:

more text

.. _model_execution:

more text

.. _parser:

more text

.. _compatibility:

more text

.. omc-reset ::
