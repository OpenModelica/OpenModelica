Porting Modelica libraries to OpenModelica
===========

One of the goals of OpenModelica is to provide a full, no-compromise implementation
of the latest version of the
`Modelica Language Specification <https://specification.modelica.org>`_,
released by the non-profit `Modelica Association <https://www.modelica.org>`_.
This means that a main requirement for a Modelica library to work in
OpenModelica is to be fully compliant to the Language Specification.

Libraries and models developed with other Modelica tools may contain some code
which is not valid according to the current language specification, but still accepted
by that tool, e.g. to support legacy code of their customers. In order to use
those libraries and models in OpenModelica, one needs to make sure that such code
is replaced by a valid one. Note that getting rid of invalid Modelica code
does not make the library *only* usable in OpenModelica; to the contrary, doing that
is the best guarantee that the library will be usable *both* with the original
tool used for development *and* with OpenModelica, as well as with any other present
or future Modelica tool that follows the standard strictly.

The first recommendation is to use any flag or option of the tool that was
originally used to develop the library, that allows to check for strict compliance
to the language specification. For example, Dymola features a translation option
'Pedantic mode for checking Modelica semantics' that issues an error if
non-standard constructs are used.

For your convenience, here you can find a list of commonly reported issues.

Mapping of the library on the file system
-------

Packages can be mapped onto individual *.mo* files or onto hierarchical
directory structures on the file system, according to the rules set forth in
`Section 13.4 <https://specification.modelica.org/maint/3.5/packages.html#mapping-package-class-structures-to-a-hierarchical-file-system>`_.
of the language specification.
The file encoding must be UTF-8; the use of a BOM at the beginning of the file
is deprecated and preferably avoided. If there are non-ASCII characters
in the comments or in the documentation of your library, make sure that the
file is encoded as UTF-8.

If a directory-based representation is chosen, each *.mo* file must start with
a *within* clause, and each directory should contain a *package.order* file that lists
all the classes and constants defined as separate files in that directory.

When using revision control systems such as GIT or SVN, if the library is
stored in a directory structure, it is recommended to include the top-level
directory (that must have the same name as the top-level package) in the
repository itself, to avoid problems in case the repository is cloned locally
on a directory that doesn't have the right name.

The top-level directory name, or the single *.mo* file containing the entire
package, should be named exactly as the package (e.g. *Modelica*),
possibly followed by a space and by the version number (e.g. *Modelica 3.2.3*).

Modifiers for arrays
-------
According to the rules set forth in `Section 7.2.5 <https://specification.modelica.org/maint/3.5/inheritance-modification-and-redeclaration.html#modifiers-for-array-elements>`_
of the language specification, when instantiating arrays of components, modifier
values should be arrays of the same size of the component array, unless the *each*
prefix is introduced, in which case the scalar modifier values is applied to
all the elements of the array. Thus, if *MyComponent* has a Real parameter *p*,
these are all valid declarations

.. code-block:: modelica

  parameter Real q = {0, 1, 2};
  MyComponent ma[3](p = {10, 20, 30});
  MyComponent mb[3](p = q);
  MyComponent mb[3](each p = 10);

while these are not

.. code-block:: modelica

  parameter Real r = 4;
  MyComponent ma[3](p = r);
  MyComponent mb[3](p = 20);

In most cases, the problem is solved by simply adding the *each* keyword where
appropriate.

Access to conditional components
-------
According to `Section 4.4.5 <https://specification.modelica.org/maint/3.5/class-predefined-types-and-declarations.html#conditional-component-declaration>`_
of the language specification, "A component declared with a condition-attribute
can only be modified and/or used in connections". When dealing, e.g., with
conditional input connectors, one can use the following patterns:

.. code-block:: modelica

  model M
    parameter Boolean activateIn1 = true;
    parameter Boolean activateIn2 = true;
    Modelica.Blocks.Interfaces.RealInput u1_in if activateIn1;
    Modelica.Blocks.Interfaces.RealInput u2_in = u2 if activateIn2;
    Real u2 "internal variable corresponding to u2_in";
    Real y;
  protected
    Modelica.Blocks.Interfaces.RealInput u1 "internal connector corresponding to u1_in";
  equation
    y = u1 + u2;
    connect(u1_in, u1) "automatically disabled if u1_in is deactivated";
    if not activateIn1 then
      u1 = 0 "default value for protected connector value when u1_in is disabled";
    end if;
    if not activateIn2 then
      u2 = 0 "default value for u2 when u2_in is disabled";
    end if;
  end M;

where conditional components are only used in connect equations. The following
patterns instead are not legal:

.. code-block:: modelica

  model M
    parameter Boolean activateIn1 = true;
    parameter Boolean activateIn2 = true;
    Modelica.Blocks.Interfaces.RealInput u1_in if activateIn1;
    Modelica.Blocks.Interfaces.RealInput u2_in if activateIn2;
    Real u1 "internal variable corresponding to u1_in";
    Real u2 "internal variable corresponding to u2_in";
    Real y;
  equation
    if activateIn1 then
      u1 = u1_in "invalid: uses conditional u1_in outside connect equations";
    end if;
    if activateIn2 then
      u2 = u2_in "invalid: uses conditional u1_in outside connect equations";
    end if;
    y = u1 + u2;
  end M;

because those components are also used in other
equations. The fact that those equations are conditional and are not activated
when the corresponding conditional components are also not activated is
irrelevant, according to the language specification.

Access to classes defined in partial packages
-------
Consider the following example package

.. code-block:: modelica

  package TestPartialPackage
    partial package PartialPackage
      function f
        input Real x;
        output Real y;
      algorithm
        y := 2*x;
      end f;
    end PartialPackage;

    package RegularPackage
      extends PartialPackage;
      model A
        Real x = time;
      end A;
    end RegularPackage;

    model M1
      package P = PartialPackage;
      Real x = P.f(time);
    end M1;

    model M2
      extends M1(redeclare package P = RegularPackage);
    end M2;

    model M3
      encapsulated package LocalPackage
        import TestPartialPackage.PartialPackage;
        extends PartialPackage;
      end LocalPackage;
      package P = LocalPackage;
      Real x = P.f(time);
    end M3;
  end TestPartialPackage;

Model *M1* references a class (a function, in this case) from a partial
package. This is perfectly fine if one wants to write a generic model, which
is then specialized by redeclaring the package to a non-partial one, as in
*M2*. However, *M1* cannot be compiled for simulation, since, according to
`Section 5.3.2 <https://specification.modelica.org/maint/3.5/scoping-name-lookup-and-flattening.html#composite-name-lookup>`_
of the language specification, the classes that are looked inside during
lookup shall not be partial in a simulation model.

This problem can be fixed by accessing that class (the function *f*, in this case)
from a non-final package that extends the partial one, either by redeclaring
the partial package to a non-partial one, as in *M2*, or by locally defining
a non-partial package that extends from the partial one, as in *M3*. The latter
option is of course viable only if the class being accessed is in itself not a partial
or somehow incomplete one.

This issue is often encountered in models using *Modelica.Media*, that sometimes
use some class definitions (e.g. unit types) from partial packages such as
*Modelica.Media.Interfaces.PartialMedium*. The fix in most cases is just to
use the same definition from the actual replaceable *Medium* package defined
in the model, which will eventually be redeclared to a non-partial one
in the simulation model.


Equality operator in algorithms
-------
The following code is illegal, because it uses the equality '=' operator, which
is reserved for equations, instead of the assignment operator ':=' inside
an algorithm:

.. code-block:: modelica

  function f
    input Real x;
    input Real y = 0;
    output Real z;
  algorithm
    z = x + y;
  end f;

so, the OpenModelica parser does not accept it. The correct code is:

.. code-block:: modelica

  function f
    input Real x;
    input Real y = 0;
    output Real z;
  algorithm
    z := x + y;
  end f;

Some tools automatically and silently apply the correction to the code, please
save it in its correct form to make it usable with OpenModelica.

Also note that binding *equations* with '=' sign are instead required for
default values of function inputs.

Public non-input non-output variables in functions
------
According to `Section 12.2 <https://specification.modelica.org/maint/3.5/functions.html#function-as-a-specialized-class>`_
of the language specification, only input and output formal parameters are
allowed in the function’s public variable section. Hence, the following function
declaration is not valid:

.. code-block:: modelica

  function f
    input Real x;
    output Real y;
    Real z;
  algorithm
    z := 2;
    y := x+z;
  end f;

and should be fixed by putting the variable *z* in the protected section:

.. code-block:: modelica

  function f
    input Real x;
    output Real y;
  protected
    Real z;
  algorithm
    z := 2;
    y := x+z;
  end f;

Subscripting of expressions
------
There is a proposal of allowing expression subscripting, e.g.

.. code-block:: modelica

  model M
    Real x[3];
    Real y[3];
    Real z;
  equation
    z = (x.*y)[2];
    ...
  end M;

This construct is already accepted by some Modelica tools, but is not yet
included in the current Modelica specification 3.5, nor even in the current working
draft of 3.6, so it is not currently supported by OpenModelica.

Incomplete specification of initial conditions
------
The simulation of Modelica models of dynamical systems requires the tool to
determine a consistent initial solution for the simulation to start. To do so,
the system equations are augmented by adding one initial condition for each
continuous state variable (after index reduction) and one initial condition for
each discrete state variable. Then, the augmented system is solved upon
initialization.

These initial conditions can be formulated by adding
a *start = <expression>* and a *fixed = true* attribute to those variables, e.g.

.. code-block:: modelica

  parameter Real x_start = 10;
  parameter Real v_start = 2.5;
  Real x(start = x_start, fixed = true);
  discrete Real v(start = v_start, fixed = true);
  Integer i(start = 2, fixed = true);

or by adding initial equations, e.g.:

.. code-block:: modelica

    parameter Real x_start = 10;
    parameter Real v_start = 2.5;
    Real x;
    discrete Real v;
    Integer i;
    Real y(start = 3.5);
  initial equation
    x = x_start;
    v = v_start;
    i = 2;
    der(y) = 0;

Note that in the latter case, the start attribute on *y* is not used directly
to set the initial value of that variable, but only potentially used as initial
guess for the solution of the initialization problem, that may require using
an iterative nonlinear solver. Also note that sets of initial equations are
often added to the models taken from reusable component libraries
by selecting certain component parameters, such as *initOpt* or similar.

If the number of initial conditions matches the number of continuous and
discrete states, then the initialization problem is well-defined. Although
this is per se not a guarantee that all tools will be able to solve it and find
the same solution, this is for sure a prerequisite for across-tool portability.

Conversely, if the number of initial conditions is less than the number of
states, the tool has to add some initial equations, using some heuristics
to change the fixed attribute of some variables from false to true. Consider
for example the following model:

.. code-block:: modelica

  model M
    Real x;
    Real y(start = 1);
    Real z(start = 2);
  equation
    der(x) = y + z;
    y = 2*x;
    z = 10*x + 1;
  end M;

This model has one state variable *x*, no variables with *fixed = true*
attributes and no initial equation, so there is one missing initial condition.
One tool could choose to add the *fixed = true* attribute to the state variable
*x*, fixing it to the default value of zero of its *start* attribute. Or, it
could decide to give more priority to variables that have an explicitly modified
*start* attribute, hence fix the initial value of *y* to 1, or the initial value
of *z* to 2. Three completely different simulations would ensue.

The Modelica Language Specification,
`Section 8.6 <https://specification.modelica.org/maint/3.5/equations.html#initialization-initial-equation-and-initial-algorithm>`_
does not prescribe or recommend any specific choice criterion in this case.
Hence, different tools, or even different versions of the same tool, could add
different initial conditions, leading to completely different simulations.
In order to avoid any ambiguity and achieve good portability, it is thus
recommended to make sure that the initial conditions of all simulation model
are well-specified.

A model with not enough initial conditions causes the OMC to issue the
following translation warning: "The initial conditions are not fully specified".
By activating the Tools | Options | Simulation | Show additional information from
the initialization process option, or the *-d=initialization* compiler flag,
one can get an explicit list of the additional equations that OpenModelica
automatically adds to get a fully specified initialization problem, which may be
helpful to figure out which initial conditions are missing. In this case, we
recommend to amend the source code of the model by adding suitable extra initial
conditions, until that warning message no longer appears.

Modelica_LinearSystems2 Library
------
The Modelica_LinearSystem2 library was originally developed in Dymola
with a plan of eventually making it part of the Modelica Standard Library
(thus the underscore in the library name). The library is based on several
functions, e.g. *readStringMatrix()*, *simulateModel()*, *linearizeModel()*
that are built-in Dymola functions but are not part of the Modelica Standard
Library.

In principle, these functions could be standardized and become part of
the ModelicaServices library, which collects standardized interfaces to
tool-specific functionality; then, OpenModelica could easily implement them
based on its internal functionality. However, until this effort is undertaken,
the Modelica_LinearSystem2 library cannot be considered as a full-fledged
Modelica library, but only a Dymola-specific one.

If you are interested in using this library in OpenModelica and are willing to
contribute to get it supported, please contact the development team, e.g. by
opening an ticket on the issue tracker.
