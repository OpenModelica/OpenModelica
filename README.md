# OMCompiler
The OpenModelica Compiler is the core of the OpenModelica project, which is an open-source Modelica-based modeling and simulation environment intended for industrial and academic usage.

## How to contribute to the OpenModelica Compiler

Contributions are primarily in the form of [pull requests](https://github.com/OpenModelica/OMCompiler/pulls).
Note that your contributions are assumed to follow the [contributior license agreement](https://openmodelica.org/osmc-pl/osmc-pl-1.2.txt) (which means the [Open Source Modelica Consortium](https://openmodelica.org) holds the copyright).

Commits that are pushed to this repository should pass the [test suite](https://github.com/OpenModelica/OpenModelica-testsuite), and @OpenModelica-Hudson makes sure this is true.
Developers should push their changes elsewhere and use the [OpenModelica hudson job](https://test.openmodelica.org/hudson/job/OpenModelica_TEST_PULL_REQUEST/build?delay=0sec) to trigger a build+push (it can build from a given URL+branch or a specific pull request, as desired).
It is recommended to use a feature branch for pull requests since hudson may rebase them, which in turn would make it harder to merge the changes.

## Building the OpenModelica Compiler

There are [Linux instructions](README.Linux.md) available.
