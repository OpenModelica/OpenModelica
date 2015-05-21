# Linux/etc README for OpenModelica

## Debian/Ubuntu Compile Cheat Sheet (or read on for the full guide)

```bash
echo deb http://build.openmodelica.org/apt precise nightly | sudo tee -a /etc/apt/sources.list
echo deb-src http://build.openmodelica.org/apt precise nightly | sudo tee -a /etc/apt/sources.list
sudo apt-get update
sudo apt-get build-dep openmodelica
git clone --recursive https://openmodelica.org/git-readonly/OpenModelica.git OpenModelica
cd OpenModelica
autoconf
./configure --with-omniORB
make -j4
```

## How to compile on Linux/BSD (all from source)

```bash
autoconf
# Skip some pieces of software to ease installation and only compile the base omc executable
# If you have a working and compatible omc that is not on the PATH, you can use --with-omc=path/to/omc to speed up compilation
./configure --prefix=/usr/local --disable-modelica3d
make
sudo make install
```

But first you need to install dependencies:
- autoconf, automake, libtool, g++, gfortran (pretty standard compilers)
- boost (optional; used with configure --with-cppruntime)
- [clang](http://clang.llvm.org/), clang++ (optional, but *highly recommended*; if you use gcc instead, use gcc 4.4 or 4.9, not 4.5-4.8 as they are very slow)
- [cmake](http://www.cmake.org)
- hwloc (optional; queries the number of hardware CPU cores instead of logical CPU cores)
- Java JRE (JDK is option; compiles the Java CORBA interface)
- Lapack/BLAS
- libhdf5 (optional part of the [MSL](https://github.com/modelica/Modelica) tables library supported by few other Modelica tools, so it does not do much)
- libexpat (it's actually included in the FMIL sources which are included... but we do not compile those and it's better to use the OS-provided dynamically linked version)
- [lpsolve55](http://lpsolve.sourceforge.net)
- omniORB or mico (optional; CORBA is used by OMOptim, OMShell, and OMPython)
- [Sundials](http://www.llnl.gov/CASC/sundials/) (optional; adds more numerical solvers to the simulation runtime)

# Setting your environment for compiling OpenModelica
If you plan to use mico corba with OMC you need to:
- set the PATH to path/to/mico/bin (for the idl compiler and mico-cpp)
- set the LD_LIBRARY_PATH to path/to/installed/mico/lib (for mico libs)
- set the PATH (for executables: idl, mico-cpp and mico-config):
```bash
export PATH=${PATH}:/path/to/installed/mico/bin
```

## To Compile OpenModelica
Run:
```bash
autoconf
# One of the following configure lines
./configure --with-omniORB=/path/to/omniORB (if you want omc to use omniORB corba)
./configure --with-CORBA=/path/to/mico (if you want omc to use mico corba)
./configure --without-CORBA            (if you want omc to use sockets)
```
in the source directory.
Make sure that all makefiles are created.
Check carefully for error messages.
```bash
make
```
After the compilation the results are in the path/to/trunk/build.
To run the testsuite, you need to use the superproject [OpenModelica.git](https://github.com/OpenModelica/OpenModelica), or clone [OpenModelica-testsuite.git](https://github.com/OpenModelica/OpenModelica-testsuite) into the root directory under the name `testsuite`.
```
make -C testsuite omc-diff ReferenceFiles
cd testsuite/runtests && ./runtests.pl
```

If you run into problems read the GENERAL NOTES below and if that does not help, subscribe to the [OpenModelicaInterest list](https://www.openmodelica.org/index.php/home/mailing-list) and then sent us an email at [OpenModelicaInterest@ida.liu.se](mailto:OpenModelicaInterest@ida.liu.se).

## How to run

Here is a short example session.
This example uses [OMShell-terminal](https://github.com/OpenModelica/OMShell), but OMShell, mos-scripts, or OMNotebook work the same way.

```
$ cd trunk/build/bin
$ ./OMShell-terminal
OMShell Copyright 1997-2015, Open Source Modelica Consortium (OSMC)
Distributed under OMSC-PL and GPL, see www.openmodelica.org

To get help on using OMShell and OpenModelica, type "help()" and press enter
Started server using:omc +d=interactive > /tmp/omshell.log 2>&1 &
>>> loadModel(Modelica)
true
>>> getErrorString()
""
>> instantiateModel(Modelica.Electrical.Analog.Basic.Resistor)
"class Modelica.Electrical.Analog.Basic.Resistor \"Ideal linear electrical resistor\"
  Real v(quantity = \"ElectricPotential\", unit = \"V\") \"Voltage drop between the two pins (= p.v - n.v)\";
  Real i(quantity = \"ElectricCurrent\", unit = \"A\") \"Current flowing from pin p to pin n\";
  Real p.v(quantity = \"ElectricPotential\", unit = \"V\") \"Potential at the pin\";
  Real p.i(quantity = \"ElectricCurrent\", unit = \"A\") \"Current flowing into the pin\";
  Real n.v(quantity = \"ElectricPotential\", unit = \"V\") \"Potential at the pin\";
  Real n.i(quantity = \"ElectricCurrent\", unit = \"A\") \"Current flowing into the pin\";
  parameter Boolean useHeatPort = false \"=true, if HeatPort is enabled\";
  parameter Real T(quantity = \"ThermodynamicTemperature\", unit = \"K\", displayUnit = \"degC\", min = 0.0, start = 288.15, nominal = 300.0) = T_ref \"Fixed device temperature if useHeatPort = false\";
  Real LossPower(quantity = \"Power\", unit = \"W\") \"Loss power leaving component via HeatPort\";
  Real T_heatPort(quantity = \"ThermodynamicTemperature\", unit = \"K\", displayUnit = \"degC\", min = 0.0, start = 288.15, nominal = 300.0) \"Temperature of HeatPort\";
  parameter Real R(quantity = \"Resistance\", unit = \"Ohm\", start = 1.0) \"Resistance at temperature T_ref\";
  parameter Real T_ref(quantity = \"ThermodynamicTemperature\", unit = \"K\", displayUnit = \"degC\", min = 0.0, start = 288.15, nominal = 300.0) = 300.15 \"Reference temperature\";
  parameter Real alpha(quantity = \"LinearTemperatureCoefficient\", unit = \"1/K\") = 0.0 \"Temperature coefficient of resistance (R_actual = R*(1 + alpha*(T_heatPort - T_ref))\";
  Real R_actual(quantity = \"Resistance\", unit = \"Ohm\") \"Actual resistance = R*(1 + alpha*(T_heatPort - T_ref))\";
equation
  assert(1.0 + alpha * (T_heatPort - T_ref) >= 1e-15, \"Temperature outside scope of model!\");
  R_actual = R * (1.0 + alpha * (T_heatPort - T_ref));
  v = R_actual * i;
  LossPower = v * i;
  v = p.v - n.v;
  0.0 = p.i + n.i;
  i = p.i;
  T_heatPort = T;
  p.i = 0.0;
  n.i = 0.0;
end Modelica.Electrical.Analog.Basic.Resistor;
"
>> a:=1:5;
>> b:=3:8
{3,4,5,6,7,8}
>>> a*b

>>> getErrorString()
"[<interactive>:1:1-1:0:writable] Error: Incompatible argument types to operation scalar product in component <NO COMPONENT>, left type: Integer[5], right type: Integer[6]
[<interactive>:1:1-1:0:writable] Error: Incompatible argument types to operation scalar product in component <NO COMPONENT>, left type: Real[5], right type: Real[6]
[<interactive>:1:1-1:0:writable] Error: Cannot resolve type of expression a * b. The operands have types Integer[5], Integer[6] in component <NO COMPONENT>.
"
>> b:=3:7;
>> a*b
85
>>> listVariables()
{b, a}
>>
```

## CentOS 6 Hints (RPM, command-line only; for clients, add CORBA, readline)
```bash
yum install tar gcc-c++ autoconf sqlite-devel java expat-devel lpsolve-devel lapack-devel make patch gettext
```
also needs cmake > 2.8; not in default repos; try to install an [rpm manually if needed](http://dl.atrpms.net/el6-x86_64/atrpms/testing/cmake-2.8.8-4.el6.x86_64.rpm)
```bash
autoconf
./configure
make -j8
```
## GENERAL NOTES:
- Fedora Core 4 has a missing symlink. To fix it, in /usr/lib do:
```bash
ln -s libg2c.so.0 libg2c.so
```
Otherwise the testsuite will fail when generating simulation code.

- On some Linux systems when running simulate(Model, ...) the executable for the Model enters an infinite loop. To fix this, add -ffloat-store to CFLAGS

Last updated 2015-05-21. Much is still outdated.
