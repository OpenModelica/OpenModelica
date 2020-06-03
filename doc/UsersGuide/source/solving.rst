.. _solving :

Solving Modelica Models
=======================

.. TODO: Describe the Backend related modules.

.. _cruntime-integration-methods :

Integration Methods
-------------------

By default OpenModelica transforms a Modelica model into an ODE
representation to perform a simulation by using numerical integration
methods. This section contains additional information about the different
integration methods in OpenModelica. They can be selected by the method
parameter of the :ref:`simulate` command or the :ref:`-s simflag <simflag-s>`.

The different methods are also called solver and can be distinguished by
their characteristic:

- explicit vs. implicit
- order
- step size control
- multi step

A good introduction on this topic may be found in :cite:`Cellier:2006`
and a more mathematical approach can be found in :cite:`Hairer:1993`.

.. _dassl :

DASSL
~~~~~

DASSL is the default solver in OpenModelica, because of a severals reasons.
It is an implicit, higher order, multi-step solver with a step-size control
and with these properties it is quite stable for a wide range of models.
Furthermore it has a mature source code, which was originally developed
in the eighties an initial description may be found in :cite:`PetzoldDASSL:1982`.

This solver is based on backward differentiation formula (BDF), which is
a family of implicit methods for numerical integration. The used implementation
is called DASPK2.0 (see [#f3]_) and it is translated automatically to C
by f2c (see [#f4]_).

The following simulation flags can be used to adjust the behavior of the
solver for specific simulation problems:
:ref:`jacobian <simflag-jacobian>`,
:ref:`noRootFinding <simflag-norootfinding>`,
:ref:`noRestart <simflag-norestart>`,
:ref:`initialStepSize <simflag-initialstepsize>`,
:ref:`maxStepSize <simflag-maxstepsize>`,
:ref:`maxIntegrationOrder <simflag-maxintegrationorder>`,
:ref:`noEquidistantTimeGrid <simflag-noequidistanttimegrid>`.


.. _sundials_ida :

IDA
~~~

The IDA solver is part of a software family called sundials: SUite of
Nonlinear and DIfferential/ALgebraic equation Solvers :cite:`Hindmarsh:2005`.
The implementation is based on DASPK with an extended linear solver
interface, which includes an interface to the high performance sparse
linear solver KLU :cite:`Davis:2010`.

The simulation flags of :ref:`dassl` are also valid for the IDA
solver and furthermore it has the following IDA specific flags:
:ref:`idaLS <simflag-idaLS>`,
:ref:`idaMaxNonLinIters <simflag-idaMaxNonLinIters>`,
:ref:`idaMaxConvFails <simflag-idaMaxConvFails>`,
:ref:`idaNonLinConvCoef <simflag-idaNonLinConvCoef>`,
:ref:`idaMaxErrorTestFails <simflag-idaMaxErrorTestFails>`.


.. _sundials_cvode :

CVODE
~~~~~

The CVODE solver is part of sundials: SUite of Nonlinear and
DIfferential/ALgebraic equation Solvers :cite:`Hindmarsh:2005`.
CVODE solves initial value problems for ordinary differential equation (ODE)
systems with variable-order, variable-step multistep methods.

In OpenModelica, CVODE uses a combination of Backward Differentiation
Formulas (varying order 1 to 5) as linear multi-step method and a modified
Newton iteration with fixed Jacobian as non-linear solver per default.
This setting is advised for stiff problems which are very common for Modelica
models.
For non-stiff problems an combination of an Adams-Moulton formula (varying
order 1 to 12) as linear multi-step method together with a fixed-point
iteration as non-linear solver method can be choosen.

Both non-linear solver methods are internal functions of CVODE and use its
internal direct dense linear solver CVDense.
For the Jacobian of the ODE CVODE will use its internal dense difference
quotient approximation.

CVODE has the following solver specific flags:
:ref:`cvodeNonlinearSolverIteration <simflag-cvodeNonlinearSolverIteration>`,
:ref:`cvodeLinearMultistepMethod <simflag-cvodeLinearMultistepMethod>`.

Basic Explicit Solvers
~~~~~~~~~~~~~~~~~~~~~~

The basic explicit solvers are performing with a fixed step-size and
differ only in the integration order. The step-size is based on the
numberOfIntervals, the startTime and stopTime parameters in the
:ref:`simulate` command:
:math:`\mbox{stepSize} \approx \cfrac{\mbox{stopTime} - \mbox{startTime}}{\mbox{numberOfIntervals}}`

- euler - order 1
- heun - order 2
- rungekutta - order 4

Basic Implicit Solvers
~~~~~~~~~~~~~~~~~~~~~~

The basic implicit solvers are all based on the non-linear solver KINSOL
from the SUNDIALS suite. The underlining linear solver can be modified
with the simflag :ref:`-impRKLS <simflag-imprkls>`. The step-size is
determined as for the basic explicit solvers.

- impeuler  - order 1
- trapezoid - order 2
- imprungekutta - Based on Radau IIA and Lobatto IIIA defined by its
  Butcher tableau where the order can be adjusted by :ref:`-impRKorder <simflag-imprkorder>`.


Experimental Solvers
~~~~~~~~~~~~~~~~~~~~

The following solvers are marked as experimental, mostly because they
are till now not tested very well.

- cvode - experimental implementation of SUNDIALS CVODE solver - BDF or Adams-Moulton method - step size control, order 1-12
- rungekuttaSsc - Runge-Kutta based on Novikov (2016) - explicit, step-size control, order 4-5
- irksco - Own developed Runge-Kutta solver - implicit, step-size control, order 1-2
- symSolver - Symbolic inline solver (requires :ref:`--symSolver <omcflag-symSolver>`) - fixed step-size, order 1
- symSolverSsc - Symbolic implicit inline Euler with step-size control (requires :ref:`--symSolver<omcflag-symSolver>`) - step-size control, order 1-2
- qss - A QSS solver

DAE Mode Simulation
-------------------

Beside the default ODE simulation, OpenModelica is able to simulate models in
`DAE mode`. The `DAE mode` is enabled by the flag :ref:`--daeMode <omcflag-daeMode>`.
In general the whole equation system of a model is passed to the DAE integrator, 
including all algebraic loops. This reduces the amount of work that needs to be
done in the post optimization phase of the OpenModelica backend. 
Thus models with large algebraic loops might compile faster in `DAE mode`.

Once a model is compiled in `DAE mode` the simulation can be only performed 
with :ref:`SUNDIALS/IDA <sundials_ida>` integrator and with enabled 
:ref:`-daeMode <simflag-daeMode>` simulation flag. Both are enabled 
automatically by default, when a simulation run is started.


References
~~~~~~~~~~
.. bibliography:: openmodelica.bib extrarefs.bib
  :cited:
  :filter: docname in docnames

.. rubric:: Footnotes
.. [#f2] `Sundials Webpage <http://computation.llnl.gov/projects/sundials-suite-nonlinear-differential-algebraic-equation-solvers>`__
.. [#f3] `DASPK Webpage <https://cse.cs.ucsb.edu/software>`__
.. [#f4] `Cdaskr source <https://github.com/wibraun/Cdaskr>`__
