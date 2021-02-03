Porting Modelica libraries to OpenModelica
===========

One of the goals of OpenModelica is to provide a full, no-compromise implementation
of the latest specification of the Modelica language, released by the
non-profit Modelica Association, see the
`Modelica Language Specification <https://specification.modelica.org>`_. 
This means that a main requirement for a Modelica library to work in
OpenModelica is to be fully compliant to the Language Specification.

Libraries and models developed with other Modelica tools may contain some code
which is not valid according to the language specification, but still accepted
by that tool, e.g. to support legacy code of their customers. In order to use
those libraries and models in OpenModelica, one needs to make sure that there
are no such occurrencies. Note that getting rid of invalid Modelica code
does not make the library *only* usable in OpenModelica; to the contrary, doing that
is the best guarantee that the library will be usable both with the original
tool used for development and with OpenModelica, as well as with any other present
or future tool that follows the standard.

The first recommendation is to use any flag or option of the tool that was
originally used to develop the library, which checks for strict conformance
to the language specification. For example, Dymola features a translation option
'Pedantic mode for checking Modelica semantics' that issues an error if
non-standard constructs are used.

For your convenience, here you find a list of commonly reported issues.

Mapping of the library on the file system
-------

Packages can be mapped onto individual .mo files or onto hierarchical
directory structures on the file system, according to the rules set forth in
Section 13.4 of the language specification
`Section 13.4 <https://specification.modelica.org/maint/3.5/packages.html#mapping-package-class-structures-to-a-hierarchical-file-system>`_.
The file encoding must be UTF-8; the use of a BOM at the beginning of the file
is deprecated and preferably avoided. If you are using non-ASCII characters
in the comments or in the documentation, make sure you are not using any other
encoding.

If a directory-based representation is chosen, each .mo file must start with
a within clause, and each directory should contain a package.order that lists
all the classes and constants defined as separate files in that directory.

When using revision control systems such as GIT or SVN, if the library is
stored in a directory structure, it is recommended to include the top-level
directory (that must have the same name as the top-level package) in the
repository itself, to avoid problems in case the repository is cloned locally
on a directory that doesn't have the right name.

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
of the language specification, "A component declared with a condition-
attribute can only be modified and/or used in connections". Thus, the following
patterns are legal

.. code-block:: modelica

  Real y "Variable set by parameter or conditional input connector";
  parameter Boolean activateInput "Activate conditional input connector";
  parameter Boolean activatePin "Activate conditional pin connector";
  Modelica.Blocks.Interfaces.RealInput conditionalInput = y if activateInput;
  Modelica.Electrical.Analog.Interfaces.Pin pin if activatePin "Conditional pin connector";
  parameter Real y_default "Default value for y if not connected";
  parameter Real R "Resistance";
protected
  Modelica.Electrical.Analog.Interfaces.Pin pinInternal "Internal hidden pin connector";
equation
  if not activateInput then y = y_default;
  connect(pin, pinInternal) "Automatically removed if pin is disabled";
  if not activatePin then pinInternal.v = 0 "Default behaviour if pin is disabled";
  pinInternal.v = R*pinInternal.i "Some equation involving pin connector";

while the following ones are not

.. code-block:: modelica

  Real y "Variable set by parameter or conditional input connector";
  parameter Boolean activateInput "Activate conditional input connector";
  parameter Boolean activatePin "Activate conditional pin connector";
  Modelica.Blocks.Interfaces.RealInput conditionalInput if activate;
  Modelica.Electrical.Analog.Interfaces.Pin pin if conditionalPin "Conditional pin connector";
  parameter Real y_default "Default value for y if not connected";
  parameter Real R "Resistance";
equation
  if not activateInput then conditionalPin.y = y_default "Illegal, conditional components used outside connection";
  if not activatePin then pin.v = 0 "Illegal, conditional component used outside connection";
  pinInternal.v = R*pinInternal.i "Some equation involving pin connector";

You can make your library Modelica compliant by using the hidden connector
pattern (for physical connectors with flow variables), or by using binding
equations in conditional connector declarations (for input/output connectors).

Equality operator in algorithms
-------
The following code is illegal, because it uses the equality '=' operator, which
is reserved for equations, instead of the assignment operatore ':=' inside
an algorithm.

.. code-block:: modelica

  function f
    input Real x;
    input Real y = 0;
    output Real z;
  algorithm
    z = x + y;
  end f;

so, the OpenModelica parser does not accept it. Some tools automatically and silently
apply the correction to the code, please save it in its correct form to make
it usable with OpenModelica.

Public non-input non-output variables in functions
------
According to `Section 12.2 <https://specification.modelica.org/maint/3.5/functions.html#function-as-a-specialized-class>`_
of the language specification, only input and output formal parameters are
allowed in the function’s public variable section. Hence, the following function
declaration is not valid

.. code-block:: modelica

  function f
    input Real x;
    output Real y;
    Real z;
  algorithm 
    z := 2;
    y := x+z;
  end f;

and should be fixed by putting the variable *z* in the protected section

.. code-block:: modelica

  function f
    input Real x;
    output Real y;
    Real z;
  algorithm 
    z := 2;
    y := x+z;
  end f;

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
tool-specific functionality. Until this effort is undertaken, the
Modelica_LinearSystem2 library cannot be considered as a full-fledged
Modelica library, but only a Dymola-specific one.

