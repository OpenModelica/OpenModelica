OpenModelica Python Interface and PySimulator
=============================================

This chapter describes the OpenModelica Python integration facilities.

-  OMPython – the OpenModelica Python scripting interface, see :ref:`ompython`.
-  EnhancedOMPython - Enhanced OMPython scripting interface, see :ref:`enhancedompython`.
-  PySimulator – a Python package that provides simulation and post
   processing/analysis tools integrated with OpenModelica, see :ref:`pysimulator`.

.. _ompython:

OMPython – OpenModelica Python Interface
----------------------------------------

OMPython – OpenModelica Python API is a free, open source, highly
portable Python based interactive session handler for Modelica
scripting. It provides the modeler with components for creating a
complete Modelica modeling, compilation and simulation environment based
on the latest OpenModelica library standard available. OMPython is
architectured to combine both the solving strategy and model building.
So domain experts (people writing the models) and computational
engineers (people writing the solver code) can work on one unified tool
that is industrially viable for optimization of Modelica models, while
offering a flexible platform for algorithm development and research.
OMPython is not a standalone package, it depends upon the
OpenModelica installation.

OMPython is implemented in Python and depends either on
the OmniORB and OmniORBpy - high performance CORBA ORBs for Python
or ZeroMQ - high performance asynchronous
messaging library and it supports the Modelica
Standard Library version 3.2 that is included in starting with
OpenModelica 1.9.2.

To install OMPython follow the instructions at https://github.com/OpenModelica/OMPython

Features of OMPython
~~~~~~~~~~~~~~~~~~~~

OMPython provides user friendly features like:

-  Interactive session handling, parsing, interpretation of commands and
   Modelica expressions for evaluation, simulation, plotting, etc.

-  Interface to the latest OpenModelica API calls.

-  Optimized parser results that give control over every element of the output.

-  Helper functions to allow manipulation on Nested dictionaries.

-  Easy access to the library and testing of OpenModelica commands.

Test Commands
~~~~~~~~~~~~~

OMPython provides two classes for communicating with OpenModelica i.e.,
OMCSession and OMCSessionZMQ. Both classes have the same interface,
the only difference is that OMCSession uses omniORB and OMCSessionZMQ
uses ZeroMQ. All the examples listed down uses OMCSessionZMQ but if you
want to test OMCSession simply replace OMCSessionZMQ with OMCSession. We
recommend to use OMCSessionZMQ.

To test the command outputs, simply create an OMCSessionZMQ object by
importing from the OMPython library within Python interepreter. The
module allows you to interactively send commands to the OMC server and
display their output.

To get started, create an OMCSessionZMQ object:

>>> from OMPython import OMCSessionZMQ
>>> omc = OMCSessionZMQ()

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

To use the module from within another python program, simply import
OMCSessionZMQ from within the using program.

For example:

.. code-block:: python

  # test.py
  from OMPython import OMCSessionZMQ
  omc = OMCSessionZMQ()
  cmds = [
    "loadModel(Modelica)",
    "model test end test;",
    'loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/BouncingBall.mo")',
    "getIconAnnotation(Modelica.Electrical.Analog.Basic.Resistor)",
    "getElementsInfo(Modelica.Electrical.Analog.Basic.Resistor)",
    "simulate(BouncingBall)",
    "plot(h)"
    ]
  for cmd in cmds:
    answer = omc.sendExpression(cmd)
    print("\n{}:\n{}".format(cmd, answer))

Implementation
~~~~~~~~~~~~~~

Client Implementation
^^^^^^^^^^^^^^^^^^^^^

The OpenModelica Python API Interface – OMPython, attempts to mimic the
OMShell's style of operations.

OMPython is designed to,

-  Initialize the CORBA/ZeroMQ communication.

-  Send commands to the OMC server via the CORBA/ZeroMQ interface.

-  Receive the string results.

-  Use the Parser module to format the results.

-  Return or display the results.

.. _enhancedompython :

Enhanced OMPython Features
--------------------------
Some more improvements are added to OMPython functionality for querying more information about the models
and simulate them. A list of new user friendly API functionality allows user to extract information about models using python
objects. A list of API functionality is described below.

To get started, create a ModelicaSystem object:

>>> from OMPython import ModelicaSystem
>>> mod=ModelicaSystem("BouncingBall.mo","BouncingBall")

The object constructor requires a minimum of 2 input arguments which are strings, and may need a third string input argument.

- The first input argument must be a string with the file name of the Modelica code, with Modelica file extension ".mo".
  If the Modelica file is not in the current directory of Python, then the file path must also be included.

-  The second input argument must be a string with the name of the Modelica model
   including the namespace if the model is wrapped within a Modelica package.

-  A third input argument is used if the Modelica model builds on other Modelica code, e.g. the Modelica Standard Library.

-  By default ModelicaSystem uses OMCSessionZMQ but if you want to use OMCSession
   then pass the argument `useCorba=True` to the constructor.

Standard get methods
~~~~~~~~~~~~~~~~~~~~

- getQuantities()
- getContinuous()
- getInputs()
- getOutputs()
- getParameters()
- getSimulationOptions()
- getSolutions()


Two calling possibilities are accepted using getXXX() where "XXX" can be any of the above functions (eg:) getParameters().

-  getXXX() without input argument, returns a dictionary with names as keys and values as values.
-  getXXX(S), where S is a sequence of strings of names, returns a tuple of values for the specified names.

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

>>> mod.getContinuous("velocity","height") // method-2, get specific variable value information
(-1.825929609047952, 0.65907039052943617)

>>> mod.getInputs()
{}

>>>  mod.getOutputs()
{}

>>> mod.getParameters()  // method-1
{'c': 0.9, 'radius': 0.1}

>>> mod.getParameters("c","radius") // method-2
(0.9, 0.1)

>>> mod.getSimulationOptions()  // method-1
{'stepSize': 0.002, 'stopTime': 1.0, 'tolerance': 1e-06, 'startTime': 0.0, 'solver': 'dassl'}

>>> mod.getSimulationOptions("stepSize","tolerance") // method-2
(0.002, 1e-06)

>>> mod.getSolutions() // method-1 returns list of simulation variables for which results are available
['time', 'height', 'velocity', 'der(height)', 'der(velocity)', 'c', 'radius']

>>> mod.getSolutions("time","height")  // method-2, return list of numpy arrays

Standard set methods
~~~~~~~~~~~~~~~~~~~~
- setInputs()
- setParameters()
- setSimulationOptions()

Two calling possibilities are accepted using setXXXs(),where "XXX" can be any of above functions.

- setXXX(k) with K being a sequence of keyword assignments (e.g.) (name = value).
- setXXX(D) with D being a dictionary with quantity names as keywords and values.

Usage of setMethods
~~~~~~~~~~~~~~~~~~~

>>> mod.setInputs(cAi=1,Ti=2)

>>> mod.setParameters(radius=14,c=0.5) // method-1 setting parameter value

>>> mod.setParameters(**{"radius":14,"c":0.5}) // method-2 setting parameter value using second option

>>> mod.setSimulationOptions(stopTime=2.0,tolerance=1e-08)


Simulation
~~~~~~~~~~
An example of how to get parameter names and change the value of parameters using set methods and finally simulate the  "BouncingBall.mo" model is given below.

>>>  mod.getParameters()
{'c': 0.9, 'radius': 0.1}

>>>  mod.setParameters(radius=14,c=0.5) //setting parameter value using first option

To check whether new values are updated to model , we can again query the getParameters().

>>> mod.getParameters()
{'c': 0.5, 'radius': 14}

And then finally we can simulate the model using.

>>> mod.simulate()

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
(0.0, 1.0)

>>> mod.setLinearizationOptions(stopTime=2.0,tolerance=1e-06)

>>> mod.linearize()  //returns a tuple of 2D numpy arrays (matrices) A, B, C and D.

>>> mod.getLinearInputs()  //returns a list of strings of names of inputs used when forming matrices.

>>> mod.getLinearOutputs() //returns a list of strings of names of outputs used when forming matrices

>>> mod.getLinearStates() // returns a list of strings of names of states used when forming matrices.


.. _pysimulator :

PySimulator
-----------

PySimulator provides a graphical user interface for performing analyses
and simulating different model types (currently Functional Mockup Units
and Modelica Models are supported), plotting result variables and
applying simulation result analysis tools like Fast Fourier Transform.

.. figure >> media/pysimulator.png

  PySimulator screenshot.

Read more about the PySimulator at https://github.com/PySimulator/PySimulator.

.. omc-reset ::
