Interoperability – C and Python
===============================

Below is information and examples about the OpenModelica external C
interfaces, as well as examples of Python interoperability.

Calling External C functions
----------------------------

The following is a small example (ExternalLibraries.mo) to show the use
of external C functions:

**model** ExternalLibraries

Real x(start=1.0),y(start=2.0);

**equation**

**der**\ (x)=-ExternalFunc1(x);

**der**\ (y)=-ExternalFunc2(y);

**end** ExternalLibraries;

**function** ExternalFunc1

**input** Real x;

**output** Real y;

**external**

y=ExternalFunc1\_ext(x)
**annotation**\ (Library="libExternalFunc1\_ext.o",

Include="#include \\"ExternalFunc1\_ext.h\\"");

**end** ExternalFunc1;

**function** ExternalFunc2

**input** Real x;

**output** Real y;

**external** "C" **annotation**\ (Library="libExternalFunc2.a",

Include="#include \\"ExternalFunc2.h\\"");

**end** ExternalFunc2;

These C (.c) files and header files (.h) are needed:

/\* file: ExternalFunc1.c \*/

double ExternalFunc1\_ext(double x)

{

double res;

res = x+2.0\*x\*x;

return res;

}

/\* Header file ExternalFunc1\_ext.h for ExternalFunc1 function \*/

double ExternalFunc1\_ext(double);

/\* file: ExternalFunc2.c \*/

double ExternalFunc2(double x)

{

double res;

res = (x-1.0)\*(x+2.0);

return res;

}

/\* Header file ExternalFunc2.h for ExternalFunc2 \*/

double ExternalFunc2(double);

The following script file ExternalLibraries.mos will perform everything
that is needed, provided you have gcc installed in your path:

loadFile("ExternalLibraries.mo");

system("gcc -c -o libExternalFunc1\_ext.o ExternalFunc1.c");

system("gcc -c -o libExternalFunc2.a ExternalFunc2.c");

simulate(ExternalLibraries);

We run the script:

>> runScript("ExternalLibraries.mos");

and plot the results:

>> plot({x,y});

Calling Python Code
-------------------

This section describes a simple-minded approach to calling Python code
from OpenModelica. For a description of Python scripting with
OpenModelica, see Chapter 13.

The interaction with Python can be perfomed in four different ways
whereas one is illustrated below. Assume that we have the following
Modelica code (CalledbyPython.mo):

**model** CalledbyPython

Real x(start=1.0),y(start=2.0);

parameter Real b = 2.0;

**equation**

**der**\ (x) = -b\*y;

**der**\ (y) = x;

**end** CalledbyPython;

In the following Python (.py) files the above Modelica model is
simulated via the OpenModelica scripting interface.

# file: PythonCaller.py

#!/usr/bin/python

**import** sys,os

**global** newb = 0.5

os.chdir(r'C:\\Users\\Documents\\python')

execfile('CreateMosFile.py')

os.popen(r"C:\\OpenModelica1.4.5\\bin\\omc.exe
CalledbyPython.mos").read()

execfile('RetrResult.py')

# file: CreateMosFile.py

#!/usr/bin/python

mos\_file = open('CalledbyPython.mos',’w’,1)

mos\_file.write("loadFile(\\"CalledbyPython.mo\\");\\n")

mos\_file.write("setComponentModifierValue(CalledbyPython,b,$Code(="+str(newb)+")

    );\\n")

mos\_file.write("simulate(CalledbyPython,stopTime=10);\\n")

mos\_file.close()

# file: RetrResult.py

#!/usr/bin/python

**def** zeros(n): #

vec = [0.0]

**for** i **in** range(int(n)-1): vec = vec + [0.0]

**return** vec

res\_file = open("CalledbyPython\_res.plt",'r',1)

line = res\_file.readline()

size = int(res\_file.readline().split('=')[1])

time = zeros(size)

y = zeros(size)

**while** line != ['DataSet: time\\n']: line =
res\_file.readline().split(',')[0:1]

**for** j **in** range(int(size)):
time[j]=float(res\_file.readline().split(',')[0])

**while** line != ['DataSet: y\\n']:
line=res\_file.readline().split(',')[0:1]

**for** j **in** range(int(size)):
y[j]=float(res\_file.readline().split(',')[1])

res\_file.close()

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
