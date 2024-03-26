Flattening models to BaseModelica
=================================

BaseModelica
------------

BaseModelica is an intermediate format to describe hybrid (continuous
and discrete) systems with emphasis on defining the dynamic behavior of systems,
rather than their structure. It is meant to become part of the Modelica
standard, as a subset of the Modelica language that does not include
object-oriented features such as lookup, instantiation, inheritance,
connections, but rather gives a flat representation of a Modelica model
which only contains variable declarations, function declarations,
record declarations, equations, and initial equations.

The main aim of BaseModelica is to provide a much lower barrier of
entry to the Modelica world, since writing a BaseModelica compiler
or interpreter will be a much easier task than writing a full-fledged
Modelica compiler.

BaseModelica is currently described by the
`MCP 0031 draft <https://github.com/modelica/ModelicaSpecification/blob/MCP/0031/RationaleMCP/0031/ReadMe.md>`_ ,
and will eventually be incorporated in a future version of the Modelica Language
Specification.

Converting Modelica models in BaseModelica with OpenModelica
------------------------------------------------------------
The OpenModelica compiler front-end can flatten virtually 100% of Modelica models
that are fully compliant with the Modelica Language Specification, converting them
into a BaseModelica output. This provides a unique opportunity for organizations that
want to enter the Modelica ecosystem, as they can delegate the heavy-lifting of
flattening a Modelica model to the OpenModelica compiler (OMC), developing tools
that only need to be able to parse and compile (or interpret) BaseModelica
input.

Assume you have a package ``MyPackage`` contained in a file ``MyPackage.mo`` and you
want to get the BaseModelica flattened code of model ``MyPackage.Examples.MyModel``
in the MyModel.mo file. From the command line, this is accomplished by typing
  
``omc --BaseModelica -i=MyPackage.Examples.MyModel MyPackage.mo > MyModel.mo``

If the package ``MyPackage`` is installed with the Package Manager, you can type

``omc --BaseModelica -i=MyPackage.Examples.MyModel MyPackage > MyModel.mo``

If you want to use OMEdit for that, you can load ``MyPackage``, go to
*Tools | Options | Simulation*, add ``--BaseModelica`` to the 
*Additional Translation Flags* input field, open ``MyModel`` and click on the
Instantiate Model button, to get the BaseModelica flattened model in a separate
window. Don't forget to remove ``--BaseModelica`` from the simulation options
when you are done, otherwise regular simulations will be broken.

Array-preserving BaseModelica output
------------------------------------
The OMC front-end can flatten models without scalarizing them, i.e., keeping
arrays of variables together as first-class citizens and keeping array equations
together via for loops. This feature is essential to manage models with large
arrays efficiently.

From the command line, you can get array-preserving BaseModelica flat output by adding
some extra debug flags to the previous command line, e.g.,
  
``omc --BaseModelica -d=nonfScalarize,arrayConnect,combineSubscripts,evaluateAllParameters,vectorizeBindings -i=MyPackage.Examples.MyModel MyPackage > MyModel.mo``

or by adding them to the Additional Translation Flags option in OMEdit.

Last, but not least, if you have a model with a large number of instances of the
same class with the same modifier structure, the OMC front-end can automatically
collect them into a single array, which can then be flattened efficiently without
scalarization. To get that, replace the debug flags of the previous command line with

``-d=nonfScalarize,mergeComponents,combineSubscripts,evaluateAllParameters,vectorizeBindings``

In this case, you also get a ``MyModel_merged_table.json`` file in the working directory,
which lists the correspondences between the original scalar component names and the
elements of the automatically created arrays.
