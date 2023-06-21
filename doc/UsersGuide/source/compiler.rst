.. _openmodelcia-compiler :

OpenModelica Compiler
=====================

The OpenModelica Compiler (OMC) consists of a frontend, backend, code generation and the
runtimes.


#. **Lexical Analysis**

   Keywords, operators and identifiers are extracted from the model.

#. **Parsing**

   An abstract syntax tree represented in Meta-Modelica is created from the operators and
   identifiers.

#. **Semantic Analysis**

   The abstract syntax tree gets tested for semantic errors.

#. **Intermediate Representation**

   Translation of the abstract syntax tree to an intermediate representation called SCode
   in MetaModelica.
   This is further processed by the frontend producing DAE intermediate representation
   code.

#. **Symbolic Optimization Backend**

   The intermediate representation gets optimized and preprocessed.

#. **Code Generation**

   Executable code gets generated from the low level intermediate representation.

For more details see :cite:`openmodelica.org:fritzson:mic:2020`.
A full list of compiler flags can be found in :ref:`openmodelica-compiler-flags`.


.. TODO: Describe the Frontend related modules.

.. _frontend-modules :

Frontend Modules
----------------

.. _backend-modules :

Backend Modules
---------------

#. **Pre-Optimization**

   - Partitioning
   - Alias removal

#. **Causalization**

   - Matching
   - Sorting
   - Index reduction

#. **Post-Optimization**

   - Tearing
   - Jacobian

.. _backend-modules-backend-info :

Backend DAE Info
~~~~~~~~~~~~~~~~

With compiler debug flag :ref:`backenddaeinfo <omcflag-debug-backenddaeinfo>` it is
possible to get additional information from the Backend modules.

  - Number of equations / variables
  - Number of states
  - Information about initialization and simulation system

    - Equation types
    - Equation system details (linear and non-linear)

The output of `backenddaeinfo` can be expanded by using additional compiler debug flags
:ref:`stateselection <omcflag-debug-stateselection>` and
:ref:`discreteinfo <omcflag-debug-discreteinfo>`.

**Example**

.. omc-mos::

  loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/BouncingBall.mo")
  setCommandLineOptions("-d=backenddaeinfo,stateselection,discreteinfo")
  translateModel(BouncingBall)

.. _code-generation :

Code generation
---------------

From the low level intermediate representation from the backend code will be generated.
The default code generation target is C and offers the largest model coverage.
An alternative is the C++ (`Cpp`) which can produce significant faster executables in some
cases.

The target language can be changed with compiler flag
:ref:`--simCodeTarget<omcflag-simCodeTarget>`.

Depending on the target the compiler will write code and compile everything into a single
simulation executable.

.. _simulation-runtimes :

Simulation Runtimes
-------------------

The generated code is linked with the appropriate runtime.

.. _c-runtime :

C Runtime
~~~~~~~~~

In :ref:`solving` the methods implemented in the C runtime are described.
In :ref:`cruntime-simflags` the runtime flags are documented.

.. TODO: Describe the C ++Runtimes
.. _cpp-runtime :

C++ Runtime
~~~~~~~~~~~

Solver methods and runtime flags are currently undocumented.
Refer to the source code 

References
~~~~~~~~~~
.. bibliography:: openmodelica.bib extrarefs.bib
  :cited:
  :filter: docname in docnames
