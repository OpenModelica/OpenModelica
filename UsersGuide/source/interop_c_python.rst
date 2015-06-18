.. _interop-c :

Interoperability – C and Python
===============================

Below is information and examples about the OpenModelica external C
interfaces, as well as examples of Python interoperability.

Calling External C functions
----------------------------

The following is a small example (ExternalLibraries.mo) to show the use
of external C functions:

.. omc-loadstring ::

  model ExternalLibraries

    function ExternalFunc1
      input Real x;
      output Real y;
    external y=ExternalFunc1_ext(x) annotation(Library="ExternalFunc1.o", LibraryDirectory="modelica://ExternalLibraries", Include="#include \"ExternalFunc1.h\"");
    end ExternalFunc1;

    function ExternalFunc2
      input Real x;
      output Real y;
    external "C" annotation(Library="ExternalFunc2", LibraryDirectory="modelica://ExternalLibraries");
    end ExternalFunc2;

    Real x(start=1.0, fixed=true), y(start=2.0, fixed=true);
  equation
    der(x)=-ExternalFunc1(x);
    der(y)=-ExternalFunc2(y);
  end ExternalLibraries;

These C (.c) files and header files (.h) are needed (note that the headers are not needed since OpenModelica will generate the correct definition if it is not present; using the headers it is possible to write C-code directly in the Modelica source code or declare non-standard calling conventions):

.. literalinclude :: ExternalFunc1.c
  :caption: ExternalFunc1.c
  :language: c

.. literalinclude :: ExternalFunc1.h
  :caption: ExternalFunc1.h
  :language: c

.. literalinclude :: ExternalFunc2.c
  :caption: ExternalFunc2.c
  :language: c

The following script file ExternalLibraries.mos will perform everything
that is needed, provided you have gcc installed in your path:

.. omc-mos ::
  :hidden:

  system("cp ../source/ExternalFunc1.c ../source/ExternalFunc1.h ../source/ExternalFunc2.c .")

.. omc-mos ::
  :erroratend:

  system(getCompiler() + " -c -o ExternalFunc1.o ExternalFunc1.c")
  system(getCompiler() + " -c -o ExternalFunc2.o ExternalFunc2.c")
  system("ar rcs libExternalFunc2.a ExternalFunc2.o")
  simulate(ExternalLibraries)

And plot the results:

.. omc-gnuplot :: externallibraries

  x
  y

Calling external Python Code from a Modelica model
--------------------------------------------------

The following calls external Python code through a very simplistic
external function (no data is retrieved from the Python code).
By making it a dynamically linked library, you might get the code to
work without changing the linker settings.

.. omc-loadstring ::

  function pyRunString
    input String s;
  external "C" annotation(Include="
  #include <Python.h>

  void pyRunString(const char *str)
  {
    Py_SetProgramName(\"pyRunString\");  /* optional but recommended */
    Py_Initialize();
    PyRun_SimpleString(str);
    Py_Finalize();
  }
  ");
  end pyRunString;

  model CallExternalPython
  algorithm
    pyRunString("
  print 'Python says: simulation time',"+String(time)+"
  ");
  end CallExternalPython;

.. omc-mos ::
  :erroratend:

  system("python-config --cflags > pycflags")
  system("python-config --ldflags > pyldflags")
  pycflags := stringReplace(readFile("pycflags"),"\n","");
  pyldflags := stringReplace(readFile("pyldflags"),"\n","");
  setCFlags(getCFlags()+pycflags)
  setLinkerFlags(getLinkerFlags()+pyldflags)
  simulate(CallExternalPython, stopTime=2)

Calling OpenModelica from Python Code
-------------------------------------

This section describes a simple-minded approach to calling Python code
from OpenModelica. For a description of Python scripting with
OpenModelica, see :ref:`ompython`.

The interaction with Python can be perfomed in four different ways
whereas one is illustrated below. Assume that we have the following
Modelica code:

.. code-block :: modelica
  :caption: CalledbyPython.mo

  model CalledbyPython
    Real x(start=1.0), y(start=2.0);
    parameter Real b = 2.0;
  equation
    der(x) = -b*y;
    der(y) = x;
  end CalledbyPython;

In the following Python (.py) files the above Modelica model is
simulated via the OpenModelica scripting interface:

.. code-block :: python
  :caption: PythonCaller.py

  #!/usr/bin/python
  import sys,os
  global newb = 0.5
  execfile('CreateMosFile.py')
  os.popen(r"omc CalledbyPython.mos").read()
  execfile('RetrResult.py')

.. code-block :: python
  :caption: CreateMosFile.py

  #!/usr/bin/python
  mos_file = open('CalledbyPython.mos','w', 1)
  mos_file.write('loadFile("CalledbyPython.mo");\n')
  mos_file.write('setComponentModifierValue(CalledbyPython,b,$Code(="+str(newb)+"));\n')
  mos_file.write('simulate(CalledbyPython,stopTime=10);\n')
  mos_file.close()

.. code-block :: python
  :caption: RetrResult.py

  #!/usr/bin/python
  def zeros(n): #
    vec = [0.0]
    for i in range(int(n)-1): vec = vec + [0.0]
    return vec
  res_file = open("CalledbyPython_res.plt",'r',1)
  line = res_file.readline()
  size = int(res_file.readline().split('=')[1])
  time = zeros(size)
  y = zeros(size)
  while line != ['DataSet: time\\n']:
    line = res_file.readline().split(',')[0:1]
  for j in range(int(size)):
    time[j]=float(res\_file.readline().split(',')[0])
  while line != ['DataSet: y\\n']:
    line=res_file.readline().split(',')[0:1]
  for j in range(int(size)):
    y[j]=float(res\_file.readline().split(',')[1])
  res_file.close()

A second option of simulating the above Modelica model is to use the
command buildModel instead of the simulate command and setting the
parameter value in the initial parameter file, CalledbyPython\_init.txt
instead of using the command setComponentModifierValue. Then the file
CalledbyPython.exe is just executed.

The third option is to use the Corba interface for invoking the compiler
and then just use the scripting interface to send commands to the
compiler via this interface.

The fourth variant is to use external function calls to directly
communicate with the executing simulation process.

.. omc-reset ::
