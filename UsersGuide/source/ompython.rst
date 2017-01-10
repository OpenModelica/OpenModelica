OpenModelica Python Interface and PySimulator
=============================================

This chapter describes the OpenModelica Python integration facilities.

-  OMPython – the OpenModelica Python scripting interface, see :ref:`ompython`.

-  PySimulator – a Python package that provides simulation and post
       processing/analysis tools integrated with OpenModelica, see
       :ref:`pysimulator`.

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
OMPython v2.0 is not a standalone package, it depends upon the
OpenModelica installation.

OMPython v2.0 is implemented in Python using the OmniORB and OmniORBpy -
high performance CORBA ORBs for Python and it supports the Modelica
Standard Library version 3.2 that is included in starting with
OpenModelica 1.9.2.
It is now primarily available using the command :command:`pip install ompython`,
but it is also possible to run :command:`python setup.py install` manually
or use the version provided in the Windows installer.

Features of OMPython
~~~~~~~~~~~~~~~~~~~~

OMPython provides user friendly features like:

-  Interactive session handling, parsing, interpretation of commands and
       Modelica expressions for evaluation, simulation, plotting, etc.

-  Interface to the latest OpenModelica API calls.

-  Optimized parser results that give control over every element of the
       output.

-  Helper functions to allow manipulation on Nested dictionaries.

-  Easy access to the library and testing of OpenModelica commands.

Test Commands
~~~~~~~~~~~~~

To test the command outputs, simply create an OMCSession object by
importing from the OMPython library within Python interepreter. The
module allows you to interactively send commands to the OMC server and
display their output.

To get started, create an OMCSession object:

>>> from OMPython import OMCSession
>>> omc = OMCSession()

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
OMCSession from within the using program. Make use of the execute()
function of the OMPython library to send commands to the OMC server.

For example:

answer = OMPython.execute(cmd)

Full example:

.. code-block:: python

  # test.py
  from OMPython import OMCSession
  omc = OMCSession()
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

-  Initialize the CORBA communication.

-  Send commands to the Omc server via the CORBA interface.

-  Receive the string results.

-  Use the Parser module to format the results.

-  Return or display the results.

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
