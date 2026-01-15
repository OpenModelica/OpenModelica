# OpenModelica [![License: OSMC-PL](https://img.shields.io/badge/license-OSMC--PL-lightgrey.svg)](OSMC-License.txt)

[OpenModelica](https://openmodelica.org) is an open-source Modelica-based modeling and
simulation environment intended for industrial and academic usage.

## OpenModelica User's Guide

The [User's Guide](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/) is
automatically generated from the documentation repository.

## OpenModelica environment

The [OpenModelica Compiler](OMCompiler/) is the core of the OpenModelica project.
[OMEdit](OMEdit/README.md) is the graphical user interface on top of the compiler.
[OMSimulator](OMSimulator/README.md) is a capable FMI and SSP-based Co-Simulation environment,
available as a standalone version or integrated in OMEdit.
In addition there are interactive environments
[OMNotebook](OMNotebook/README.md), [OMPlot](OMPlot/README.md) and [OMShell](OMShell/README.md)
interaction with the OMCompiler as well as various other tools:
[OMOptim](OMOptim/README.md), [OMParser](OMParser/README.md),
[OMSense_Qt](OMSens_Qt/README.md).

## Working with the repository

OpenModelica.git is a superproject. Clone the project using one of:

```bash
# Faster pulling by using openmodelica.org read-only mirror (low latency in Europe; very important when updating all submodules)
# Replace the openmodelica.org pull URL with https://github.com/OpenModelica/OpenModelica.git if you want to pull directly from github
# The default choice is to push to your fork on github.com (SSH). Replace MY_FORK with OpenModelica to push directly to the OpenModelica repositories (if you have access)
MY_FORK=<MyGitHubUserName>
git clone --recurse-submodules https://openmodelica.org/git-readonly/OpenModelica.git
cd OpenModelica
git remote set-url --push origin git@github.com:$MY_FORK/OpenModelica.git
git submodule foreach --recursive 'git remote set-url --push origin `git config --get remote.origin.url | sed s,^.*/,git@github.com:'$MY_FORK'/,`'
```

If you are a developer and want to update your local git repository to the latest
developments or latest heads, use:

```bash
# After cloning
cd OpenModelica
git checkout master
git pull
# To checkout the latest master on each submodule run
# you will need to merge each submodule, but your changes will remain
git submodule foreach --recursive "git checkout master && git pull"

# Running master on all submodules might lead to build errors
# so use this to make sure you force all submodules to the commits
# from the OpenModelica glue project which are properly tested
git submodule update --force --init --recursive
```

In order to push to the repository, you will push to your own fork of OpenModelica.git,
etc. You will need to create a fork of each repository that you want to push to (by
clicking the Fork button in the GitHub web interface).

If you do not checkout the repositories for some GUI clients (such as OMOptim.git), these
directories will be ignored by autoconf and skipped during compilation.

To checkout a specific version of OpenModelica, say tag v1.16.2 do:
```bash
git clone --recurse-submodules https://github.com/OpenModelica/OpenModelica.git
cd OpenModelica
git checkout v1.16.2
git submodule update --force --init --recursive
```

If you have issues building you can try to clean and reset the repository using:

```bash
git clean -fdx
git submodule foreach --recursive git clean -fdx
git reset --hard
git submodule foreach --recursive git reset --hard
git submodule update --init --recursive
```

To check your working copy status and the hashes of the submodules, use:

```bash
git status
git submodule status --recursive
```

### To checkout a minimal version of OpenModelica

```bash
git clone https://openmodelica.org/git-readonly/OpenModelica.git OpenModelica-minimal
cd OpenModelica-minimal
git submodule update --init --recursive libraries
```

## Build OpenModelica

* [Linux/WSL/OSX Instructions](OMCompiler/README.Linux.md)
* [Windows Instructions](OMCompiler/README.Windows.md)

We automatically generate nightly builds for
[Windows](https://openmodelica.org/download/download-windows/) and for various flavours of
[Linux](https://openmodelica.org/download/download-linux/). You can download and install
them directly if you just want to run the latest development version of OpenModelica without
the effort of compiling the sources yourself.

## How to run

Here is a short example session.
This example uses [OMShell-terminal](OMShell), but OMShell, mos-scripts, or OMNotebook
work the same way.

```
$ cd trunk/build/bin
$ ./OMShell-terminal
OMShell Copyright 1997-2015, Open Source Modelica Consortium (OSMC)
Distributed under OMSC-PL and GPL, see www.openmodelica.org

To get help on using OMShell and OpenModelica, type "help()" and press enter
Started server using:omc -d=interactive > /tmp/omshell.log 2>&1 &
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

## How to contribute to the OpenModelica Compiler

The long-term development of OpenModelica is supported by a non-profit organization - the
[Open Source Modelica Consortium (OSMC)](https://openmodelica.org/home/consortium/).

See [CONTRIBUTING.md](CONTRIBUTING.md) on how to contribute to the development.
If you encounter any bugs, feel free to open a ticket about it.
For general questions regarding OpenModelica there is a
[discussions section](https://github.com/OpenModelica/OpenModelica/discussions) available.

## License

See [OSMC-License.txt](OSMC-License.txt).

## How to cite

See the [CITATIONS](CITATION.cff) file for information on how to cite OpenModelica in
any publications reporting work done using OpenModelica.
For a complete list of all publications related to OpenModelica see
[doc/bibliography/openmodelica.bib](./doc/bibliography/openmodelica.bib).

------------
Last updated: 2023-06-21
