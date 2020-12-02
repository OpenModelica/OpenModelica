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
is called DASPK2.0 (see [#f1]_) and it is translated automatically to C
by f2c (see [#f2]_).

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


.. _initialization :

Initialization
--------------

To simulate an ODE representation of an Modelica model with one of the methods
shown in :ref:`cruntime-integration-methods` a valid initial state is needed.
Equations from an initial equation or initial algorithm block define a desired
initial system.

Choosing start values
~~~~~~~~~~~~~~~~~~~~~

Only non-linear iteration variables in non-linear strong components require
start values. All other start values will have no influence on convergence of
the initial system.

Use `-d=initialization` to show additional information from the initialization
process. In OMEdit Tools->Options->Simulation->OMCFlags, in OMNotebook call
setCommandLineOptions("-d=initialization")

.. figure :: media/piston.png

  piston.mo

.. omc-loadstring ::

  model piston
    Modelica.Mechanics.MultiBody.Parts.Fixed fixed1 annotation(
      Placement(visible = true, transformation(origin = {-80, 70}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Mechanics.MultiBody.Parts.Body body1(m = 1)  annotation(
      Placement(visible = true, transformation(origin = {30, 70}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Mechanics.MultiBody.Parts.FixedTranslation fixedTranslation1(r = {0.3, 0, 0})  annotation(
      Placement(visible = true, transformation(origin = {-10, 70}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Mechanics.MultiBody.Parts.FixedTranslation fixedTranslation2(r = {0.8, 0, 0})  annotation(
      Placement(visible = true, transformation(origin = {10, 20}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Modelica.Mechanics.MultiBody.Parts.Fixed fixed2(animation = false, r = {1.1, 0, 0})  annotation(
      Placement(visible = true, transformation(origin = {70, -60}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    Modelica.Mechanics.MultiBody.Parts.Body body2(m = 1)  annotation(
      Placement(visible = true, transformation(origin = {30, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    inner Modelica.Mechanics.MultiBody.World world annotation(
      Placement(visible = true, transformation(origin = {-70, -50}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Mechanics.MultiBody.Joints.Prismatic prismatic(animation = true)  annotation(
      Placement(visible = true, transformation(origin = {30, -60}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Mechanics.MultiBody.Joints.RevolutePlanarLoopConstraint revolutePlanar annotation(
      Placement(visible = true, transformation(origin = {-50, 70}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Mechanics.MultiBody.Joints.Revolute revolute1(a(fixed = false),phi(fixed = false), w(fixed = false))  annotation(
      Placement(visible = true, transformation(origin = {10, 48}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Modelica.Mechanics.MultiBody.Joints.Revolute revolute2 annotation(
      Placement(visible = true, transformation(origin = {10, -10}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  equation
    connect(prismatic.frame_b, fixed2.frame_b) annotation(
      Line(points = {{40, -60}, {60, -60}, {60, -60}, {60, -60}}, color = {95, 95, 95}));
    connect(fixed1.frame_b, revolutePlanar.frame_a) annotation(
      Line(points = {{-70, 70}, {-60, 70}, {-60, 70}, {-60, 70}}));
    connect(revolutePlanar.frame_b, fixedTranslation1.frame_a) annotation(
      Line(points = {{-40, 70}, {-20, 70}, {-20, 70}, {-20, 70}}, color = {95, 95, 95}));
    connect(fixedTranslation1.frame_b, revolute1.frame_a) annotation(
      Line(points = {{0, 70}, {10, 70}, {10, 58}, {10, 58}}, color = {95, 95, 95}));
    connect(revolute1.frame_b, fixedTranslation2.frame_a) annotation(
      Line(points = {{10, 38}, {10, 38}, {10, 30}, {10, 30}}, color = {95, 95, 95}));
    connect(revolute2.frame_b, prismatic.frame_a) annotation(
      Line(points = {{10, -20}, {10, -20}, {10, -60}, {20, -60}, {20, -60}}));
    connect(revolute2.frame_b, body2.frame_a) annotation(
      Line(points = {{10, -20}, {10, -20}, {10, -30}, {20, -30}, {20, -30}}, color = {95, 95, 95}));
    connect(revolute2.frame_a, fixedTranslation2.frame_b) annotation(
      Line(points = {{10, 0}, {10, 0}, {10, 10}, {10, 10}}, color = {95, 95, 95}));
    connect(fixedTranslation1.frame_b, body1.frame_a) annotation(
      Line(points = {{0, 70}, {18, 70}, {18, 70}, {20, 70}}));
  end piston;

.. omc-mos ::

  loadModel(Modelica);
  setCommandLineOptions("-d=initialization");
  buildModel(piston);

Note how OpenModelica will inform the user about relevant and irrelevant start
values for this model and for which variables a fixed default start value is
assumed.
The model has four joints but only one degree of freedom, so one of the joints
`revolutePlanar` or `prismatic` must be initialized.


So, initializing `phi` and `w` of `revolutePlanar` will give a sensible start
system.

.. omc-loadString ::

  model pistonInitialize
    extends piston(revolute1.phi.fixed = true, revolute1.phi.start = -1.221730476396031, revolute1.w.fixed = true, revolute1.w.start = 5);
  equation
  end pistonInitialize;

.. omc-mos ::

  setCommandLineOptions("-d=initialization");
  simulate(pistonInitialize, stopTime=2.0);


.. omc-gnuplot :: piston
  :caption: Vertical movement of mass body2.

  body2.frame_a.r_0[1]

Homotopy Method
~~~~~~~~~~~~~~~

For complex start conditions OpenModelica can have trouble finding a solution
for the initialization problem with the default Newton method.

Modelica offers the homotopy operator [#f3]_ to formulate *actual* and
*simplified* expression for equations, with homotopy parameter :math:`\lambda` going from 0 to 1:

.. math::

  actual \cdot \lambda + simplified \cdot (1-\lambda).

OpenModelica has different solvers available for non-linear systems.
Initializing with homotopy on the first try
is default if a homotopy operator is used. It can be switched off with
:ref:`noHomotopyOnFirstTry <simflag-noHomotopyOnFirstTry>`. For a general
overview see :cite:`sielemann2011robust`, for details on the implementation in
OpenModelica see :cite:`openmodelica.org:doc-extra:ochel2013initialization`.

The homotopy methods distinguish between local and global methods meaning, if
:math:`\lambda` affects the entire initialization system or only local
strong connected components.
In addition the homotopy methods can use equidistant :math:`\lambda` or and
adaptive :math:`\lambda` in [0,1].

**Default order of methods tried to solve initialization system**

If there is no homotopy in the model
  - Solve without homotopy method.

If there is homotopy in the model or solving without homotopy failed
  - Try global homotopy approach with equidistant :math:`\lambda`.

The default homotopy method will do three global equidistant steps from 0 to 1
to solve the initialization system.

Several compiler and simulation flags influence initialization with homotopy:
:ref:`--homotopyApproach <omcflag-homotopyApproach>`,
:ref:`-homAdaptBend <simflag-homAdaptBend>`,
:ref:`-homBacktraceStrategy <simflag-homBacktraceStrategy>`,
:ref:`-homHEps <simflag-homHEps>`,
:ref:`-homMaxLambdaSteps <simflag-homMaxLambdaSteps>`,
:ref:`-homMaxNewtonSteps <simflag-homMaxNewtonSteps>`,
:ref:`-homMaxTries <simflag-homMaxTries>`,
:ref:`-homNegStartDir <simflag-homNegStartDir>`,
:ref:`-homotopyOnFirstTry <simflag-homotopyOnFirstTry>`,
:ref:`-homTauDecFac <simflag-homTauDecFac>`,
:ref:`-homTauDecFacPredictor <simflag-homTauDecFacPredictor>`,
:ref:`-homTauIncFac <simflag-homTauIncFac>`,
:ref:`-homTauIncThreshold <simflag-homTauIncThreshold>`,
:ref:`-homTauMax <simflag-homTauMax>`,
:ref:`-homTauMin <simflag-homTauMin>`,
:ref:`-homTauStart <simflag-homTauStart>`,
:ref:`-ils <simflag-ils>`.


.. _cruntime-algebraic-solvers :

Algebraic Solvers
-----------------

If the ODE system contains equations that need to be solved together, so called
algebraic loops, OpenModelica can use a variety of different linear and non-linear
methods to solve the equation system during simulation.

For the C runtime the linear solver can be set with :ref:`-ls <simflag-ls>` and
the non-linear solver with :ref:`-nls <simflag-nls>`.
There are dense and sparse solver available.

**Linear solvers**
  - *default*    : Lapack with totalpivot as fallback :cite:`anderson1999lapack`
  - *lapack*     : Non-Sparse LU factorization using :cite:`anderson1999lapack`
  - *lis*        : Iterative linear solver :cite:`nishida2010experience`
  - *klu*        : Sparse LU factorization :cite:`natarajan2005klu`
  - *umfpack*    : Sparse unsymmetric multifrontal LU factorization :cite:`davis2004algorithm`
  - *totalpivot* : Total pivoting LU factorization for underdetermined systems

**Non-linear solvers**
 - *hybrid*     : Modified Powell hybrid method from MINPACK :cite:`dennis1996numerical`
 - *kinsol*     : Combination of Newton-Krylov, Picard and fixed-point solver :cite:`taylor1998user`
 - *newton*     : Newton-Raphson method :cite:`Cellier:2006`
 - *mixed*      : Homotopy with hybrid as fallback :cite:`keller1978global` :cite:`bachmann2015symbolical`
 - *homotopy*   : Damped Newton solver with fixed-point solver and Newton homotopy solver as fallbacks

In addition, there are further optional settings for the algebraic solvers available.
A few of them are listed in the following:

General:
:ref:`-nlsLS <simflag-nlsls>`

Newton:
:ref:`-newton <simflag-newton>`
:ref:`-newtonFTol <simflag-newtonFTol>`
:ref:`-newtonMaxStepFactor <simflag-newtonMaxStepFactor>`
:ref:`-newtonXTol <simflag-newtonXTol>`

Sparse solver:
:ref:`-nlssMinSize <simflag-nlssMinSize>`
:ref:`-nlssMaxDensity <simflag-nlssMaxDensity>`

Enable logging:
:ref:`-lv=LOG_LS <simflag-lv>`
:ref:`-lv=LOG_LS_V <simflag-lv>`
:ref:`-lv=LOG_NLS <simflag-lv>`
:ref:`-lv=LOG_NLS_V <simflag-lv>`

References
~~~~~~~~~~
.. bibliography:: openmodelica.bib extrarefs.bib
  :cited:
  :filter: docname in docnames

.. rubric:: Footnotes
.. [#f1] `DASPK Webpage <https://cse.cs.ucsb.edu/software>`__
.. [#f2] `Cdaskr source <https://github.com/wibraun/Cdaskr>`__
.. [#f3] `Modelica Association, Modelica® - A Unified Object-Oriented Language for Systems Modeling Language Specification - Version 3.4, 2017 - Section 3.7.2.4 <https://specification.modelica.org/maint/3.4/Ch3.html#homotopy>`__
