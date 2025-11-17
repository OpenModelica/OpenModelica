.. _solving :

Solving Modelica Models
=======================

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

- Method
- Explicit vs. implicit
- Suitability for stiff systems
- Usage of sparse methods to solver underlying equation systems
- Integration order
- Step size control: Fixed vs. adaptive

+----------+---------+------+------------+----------+----------+-----------+
| Solver   | Method  | Type | System     | Sparsity | Order    | Step Size |
+==========+=========+======+============+==========+==========+===========+
| `DASSL`_ | BDF     | imp. | stiff      | sparse / | adaptive | adaptive  |
|          |         |      |            | dense    | 1-5      |           |
+----------+---------+------+------------+----------+----------+-----------+
| `IDA`_   | BDF     | imp. | stiff      | sparse / | adaptive | adaptive  |
|          |         |      |            | dense    | 1-5      |           |
+----------+---------+------+------------+----------+----------+-----------+
| `CVODE`_ | Adams-  | imp. | non-stiff  | dense    | adaptive | adaptive  |
|          | Moulton |      |            |          | 1-12     |           |
+----------+---------+------+------------+----------+----------+-----------+
| `CVODE`_ | BDF     | imp. | stiff      | dense    | adaptive | adaptive  |
|          |         |      |            |          | 1-5      |           |
+----------+---------+------+------------+----------+----------+-----------+
| `GBODE`_ | RK      | exp. | non-stiff  | sparse / | 1-14     | adaptive  |
|          |         |      |            | dense    |          |           |
+----------+---------+------+------------+----------+----------+-----------+
| `GBODE`_ | RK      | imp. | stiff      | sparse / | 1-12     | adaptive  |
|          |         |      |            | dense    |          |           |
+----------+---------+------+------------+----------+----------+-----------+
| `GBODE`_ | RK      | imp. | multi-rate | sparse / | 1-14     | adaptive  |
|          |         |      |            | dense    |          |           |
+----------+---------+------+------------+----------+----------+-----------+
| `Euler`_ | Euler   | exp. | non-stiff  | dense    | 1        | fixed     |
+----------+---------+------+------------+----------+----------+-----------+

A good introduction on this topic may be found in :cite:`Cellier:2006`
and a more mathematical approach can be found in :cite:`Hairer:1993`.

.. _dassl :

DASSL
~~~~~

DASSL is the default solver in OpenModelica, because of a severals reasons. It
is an implicit, higher order, multi-step solver with a step-size control and
with these properties it is quite stable for a wide range of models. Furthermore
it has a mature source code, which was originally developed in the eighties an
initial description may be found in :cite:`PetzoldDASSL:1982`.

This solver is based on backward differentiation formula (BDF), which is
a family of implicit methods for numerical integration. The used implementation
is called DASPK2.0 (see [#f1]_) and it is translated automatically to C
by f2c (see [#f2]_).

Internal non-linear and linear equation systems are solved using dense methods.
If the target model is known to have a sparse structure one of the sparse
solvers might be a better alternative.

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

The IDA solver is part of a software family called sundials: SUite of Nonlinear
and DIfferential/ALgebraic equation Solvers :cite:`Hindmarsh:2005`. The
implementation is based on DASPK with an extended linear solver interface, which
includes an interface to the high performance sparse non-lineaer solver KINSOL
:cite:`Hindmarsh:2005` and linear solver KLU :cite:`Davis:2010`.

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
iteration as non-linear solver method can be chosen.

Both non-linear solver methods are internal functions of CVODE and use its
internal direct dense linear solver CVDense.
For the Jacobian of the ODE CVODE will use its internal dense difference
quotient approximation.

CVODE has the following solver specific flags:
:ref:`cvodeNonlinearSolverIteration <simflag-cvodeNonlinearSolverIteration>`,
:ref:`cvodeLinearMultistepMethod <simflag-cvodeLinearMultistepMethod>`.

GBODE
~~~~~

GBODE stands for Generic Bi-rate ordinary differential equation (ODE) solver
and is a generic implementation for any Runge-Kutta (RK) scheme
:cite:`Hairer2000`. In GBODE there are already many different implicit and
explicit RK methods (e.g. SDIRK, ESDIRK, Gauss, Radau, Lobatto, Fehlberg,
DOPRI45, Merson) with different approximation order configurable and ready to
use. New RK schemes can easily be added, if the corresponding Butcher tableau
is available. By default the solver runs in single-rate mode using the
embedded RK scheme ESDIRK4 :cite:`KENNEDY2019221` with variable-step-size
control and efficient event handling.

The bi-rate mode can be utilized using the simulation flag
:ref:`gbratio <simflag-gbratio>`. This flag determines the percentage of fast
states with respect to all states. These states will then be automatically
detected during integration based on the estimated approximation error and
afterwards refined using an appropriate inner step-size control and
interpolated values of the slow states.

The solver utilizes by default the sparsity pattern of the ODE Jacobian and
solves the corresponding non-linear system in case of an implicit chosen RK
scheme using sparse solver KINSOL.

GBODE is highly configurable and the following simulation flags can be used to
adjust the behavior of the solver for specific simulation problems:
:ref:`gbratio <simflag-gbratio>`,
:ref:`gbm <simflag-gbm>`,
:ref:`gbctrl <simflag-gbctrl>`,
:ref:`gbnls <simflag-gbnls>`,
:ref:`gbint <simflag-gbint>`,
:ref:`gberr <simflag-gberr>`,
:ref:`gbfm <simflag-gbm>`,
:ref:`gbfctrl <simflag-gbctrl>`,
:ref:`gbfnls <simflag-gbnls>`,
:ref:`gbfint <simflag-gbint>`,
:ref:`gbferr <simflag-gbferr>`.

.. _euler :

Basic Explicit Solvers
~~~~~~~~~~~~~~~~~~~~~~

The basic explicit solvers Euler uses a fixed step-size based on the
``numberOfIntervals``, the ``startTime`` and ``stopTime`` parameters in the
:ref:`simulate` command:
:math:`\mbox{stepSize} \approx \cfrac{\mbox{stopTime} - \mbox{startTime}}{\mbox{numberOfIntervals}}`

- euler - Explicit Euler, fixed step size, order 1

Deprecated Solvers
~~~~~~~~~~~~~~~~~~~~

The following solvers are deprecated and will be removed in a future version of
OpenModelica:

- rungekutta - Classic Runge-Kutta method RK4, explicit, fixed step-size, oder 4

.. code-block::

  old: -s=rungekutta
  new: -s=gbode -gbm=rungekutta -gbctrl=const

- symSolver - Symbolic inline solver
  (requires :ref:`--symSolver <omcflag-symSolver>`) - fixed step-size, order 1
- symSolverSsc - Symbolic implicit inline Euler with step-size control
  (requires :ref:`--symSolver<omcflag-symSolver>`) - step-size control, order 1-2
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

Importing initial values from previous simulations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
In many use cases it is useful to import initial values from previous simulations, possibly obtained with
another Modelica tool, which are saved in a .mat file. There are two different options to do that.

Using previous simulation results as start values for the initial equations
***************************************************************************

The first option is to solve the initial equations specified by the Modelica model, using the previous simulation results as
initial guesses for the iterative solvers, in case they are needed. This can be very helpful in case the initialization problem involves the
solution of large nonlinear systems of equations by means of iterative algorithms, whose convergence is sensitive to the selected
initial guess.

Importing a previously found solution allows the OpenModelica solver to pick very good initial guesses for the
unknowns of the iterative solvers, thus achieving convergence with a few iterations. Since the initial equations
are solved in the process, the values of all variables and derivatives, as well as of all parameters with `fixed = false` attribute,
are re-computed and fully consistent with the selected initial conditions, even in case the previously saved simulation results
refer to a slightly different model configuration. Note that parameters with `fixed = true` will also get their values from the
imported .mat file, so if you want to change them you need to edit the .mat file accordingly.

This option is activated by selecting the simulation result file name in the OMEdit
*Simulation Setup | Simulation Flag | Equation System Initialization File* input field, or by setting the additional simulation flag
:ref:`-iif=resultfile.mat <simflag-iif>`. By activating the checkbox *Save simulation flags inside the model i.e., __OpenModelica_simulationFlags annotation*,
a custom annotation *__OpenModelica_simulationFlags(iif="filename.mat")* is added to the model, so this setting is saved with the model and is reused
when loading the model again later on. It is also possible to specify at which point in time of the saved simulation results the initial values
should be picked, by means of the *Simulation Setup | Simulation Flags | Equation System Initialization Time* input field, or by setting
the simulation flag :ref:`-iit=initialTimeValue <simflag-iit>`.

Using previous simulation results to directly initialize a simulation
*********************************************************************

The second option is to skip the solution of the initial equations entirely, directly starting the simulation
with the imported start values. In this case, the initial equations of the model are ignored, and the initial values of
all parameters and state variables are directly set to the values loaded from the .mat file. This option is useful
to restart a simulation from the final state of a previous one, ignoring whatever initial conditions are declared in the
Modelica model by either fixed = true attributes or initial equations.

Note that state variables and parameters will be directly initialized to the imported values, while algebraic variables
will be recomputed with the regular simulation equations, on the basis of the imported initial state and parameter values.
The values of algebraic variables in the imported file will only be used to initialize iteration variables, in case this
computation involves nonlinear implicit equations and iterative solvers, otherwise they will be ignored.

To activate this second option, set *Simulation Setup | Simulation Flag | Initialization Method* to *none* in OMEdit,
or set the simulation flag :ref:`-iim=none <simflag-iim>`. Also in this case, activating the checkbox *Save simulation
flags inside model, i.e. __OpenModelica_simulationFlags annotation* saves this option in an
*__OpenModelica_simulationFlags(iim=none)* annotation, so it is retained for future simulations of the same model.

Beware of missing variables in the simulation result file
*********************************************************

When importing simulation results to initialize a new simulation, bear in mind that, by default, protected and hidden variables
are *not saved* to the .mat file, so they will be missing when importing the simulation results for initialization. This is
particularly dangerous when the imported values are used directly, as unsaved protected or hidden variables will not be
initialized and will retain their default zero value, which is likely to cause numerical problems such as division by zero
when the simulation is started.

To avoid this problem, make sure you also save protected and hidden variables in the simulation result file, by setting the
corresponding checkboxes in the *Simulation Setup | Output* tab of OMEdit, or by setting the simulation flags
:ref:`-emit_protected <simflag-emit-protected>` and :ref:`-ignoreHideResult <simflag-ignorehideresult>`.

Example of use
**************

The following minimal working example demonstrates the use of the initial value import feature. You can create a new package
`ImportInitialValues` in OMEdit, copy and paste its code from here, and then run the different models in it.

.. code-block:: modelica

  package ImportInitialValues "Test cases for importing initial values in OpenModelica"
    partial model Base "The mother of all models"
      Real v1, v2, x;
      parameter Real p1;
      parameter Real p2 = 2*p1;
      final Real p3 = 3*p1;
    end Base;

    model ResultFileGenerator "Dummy model for generating the initial.mat file"
      extends Base(p1 = 7, p2 = 10);
    equation
      v1 = 2.8;
      v2 = 10;
      der(x) = 0;
    initial equation
      x = 4;
    annotation(
      experiment(StopTime = 1),
      __OpenModelica_simulationFlags(r = "../initial.mat"));
    end ResultFileGenerator;

    model M "Relies on Modelica code only for initialization"
      extends Base(
        v1(start = 14),
        p1 = 1, p2 = 1);
    equation
      (v1 - 3)*(v1 + 10)*(v1 - 15) = 0;
      v2 = time;
      der(x) = -x;
    initial equation
      x = 6;
    end M;

    model M2 "Imports parameters and initial guesses only, solve initial equations"
      extends M;
    annotation(__OpenModelica_simulationFlags(iif = "../initial.mat"));
    end M2;

    model M3 "import parameters, initial guesses and initial states, skip initial equations"
      extends M;
    annotation(__OpenModelica_simulationFlags(iim = "none", iif = "../initial.mat"));
    end M3;
  end ImportInitialValues;

Running the `ResultFileGenerator` model creates an `initial.mat` file with some initial values in the root OMEdit working directory:
`p1 = 7`, `p2 = 10`, `p3 = 21`, `v1 = 2.8`, `v2 = 10`, `x = 4`, `der(x) = 0`. Note that the default directory when running simulations
in OMEdit is a sub-directory named as the full model pathname, located in the working directory, so it is necessary to go up one
directory to access the root working directory.

When running model `M`, the simulation process only relies on the initial and guess values provided by the Modelica source code. Regarding the
parameter values, `p1 = 1`, `p2 = 1`, `p3 = 3*p1 = 3`; regarding `v1`, the implicit cubic equation is solved iteratively using the start value
14 as an initial guess, thus converging to the nearest solution `v1 = 15`. The other variable `v2` can be computed explicitly, so there is no
need of any guess value for it. Finally, the initial value of the state variable is set to `x = 6` by the initial equations.

When running model `M2`, the values of the `initial.mat` file are imported to provide values for non-final parameters and guess values for the initial
equations, which are solved starting from there. Hence, the imported parameter values p1 = 7 and p2 = 10 override the model's binding equations,
that would set both to 1; on the other hand, the final parameter p3 is computed based on the final binding equation to `p3 = p1*3 = 21`. Regarding
`v1`, the iterative solver converges to the solution closest to the imported start value of 2.8, i.e. `v1 = 3`, while `v2` is computed explicitly,
so it doesn't depend on the imported start value, which is ignored. The initial value of the state `x = 6` is obtained by solving the initial equation,
which is explicit and thus ignores the imported guess value `x = 4`.

Finally, when running model `M3`, parameters are handled like in the previous case, as well as the algebraic variables `v1` and `v2`. However,
in this case the solution of the initial equations is skipped, so the state variable gets its initial value `x = 4` straight from the imported `initial.mat` file.


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
overview see :cite:`sielemann2011robust`, :cite:`sielemann2012PhD`, for details on the implementation in
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

Tearing
-------

The size of linear and nonlinear equation systems can be substantially reduced by
means of the Tearing method. Consider a system of :math:`N` equations. The Tearing method requires
to pick :math:`M << N` variables :math:`x_t` as *tearing* or *iteration* variables, so that
assuming their values are known, :math:`N - M` *torn* equations can be solved explicitly for the
remaining :math:`N - M` *torn* variables, by sorting them appropriately. Then, the remaining
M equations are put in *residual* form :math:`f(x_t) = 0`, where the residuals can ultimately be
computed by explicit computations as a function of the tearing variables :math:`x_t` only. 
The result is thus an equivalent implicit system of :math:`M << N` equations in the :math:`M`
tearing variables, with an explicit procedure to compute the residual function :math:`f(x_t)`.
The Jacobian of that function, which is required by the Newton method, can then be obtained
by either symbolic or numerical differentiation techniques.

The Tearing method has three main advantages:

- the size of the Jacobian matrix to be factorized in order to solve it is greatly reduced;
- for nonlinear systems solved by iterative methods like Newton-Raphson, it is only necessary
  to give initial guess values to the much smaller set of variables :math:`x_t`;
- the method allows to solve mixed systems containing Real and discrete (Boolean or Integer)
  variables and equations by means of standard nonlinear equation solvers, as long as the
  discrete variables are selected as torn variables and the resulting residual equations have 
  a continuous dependency on the Real tearing variables.
  
OpenModelica implements some heuristic algorithms to automatically choose the set of
tearing variables. The tearing algorithm can be selected with the compiler flags:
:ref:`--tearingMethod <omcflag-tearingMethod>`,
:ref:`--tearingHeuristic <omcflag-tearingHeuristic>`.
Since the tearing algorithms can be very time-consuming for large systems, they are automatically
disabled for systems above a certain size, see
:ref:`--maxSizeLinearTearing <omcflag-maxSizeLinearTearing>`,
:ref:`--maxSizeNonlinearTearing <omcflag-maxSizeNonlinearTearing>`.

As of Modelica 3.6, there is no standardized way to influence the choice of tearing variables. OpenModelica
provides a custom `__OpenModelica_tearingSelect` annotation that can be added to variable declarations to
influence the choice of tearing variables:
	
.. code-block:: modelica
Real x annotation(__OpenModelica_tearingSelect = TearingSelect.always);
Real y annotation(__OpenModelica_tearingSelect = TearingSelect.prefer);
Real z annotation(__OpenModelica_tearingSelect = TearingSelect.default);
Real v annotation(__OpenModelica_tearingSelect = TearingSelect.avoid);
Real w annotation(__OpenModelica_tearingSelect = TearingSelect.never);

This feature is currently experimental. There is discussion going on within the MAP-Lang group of the
Modelica Association to standardize features for the selection of tearing variables and residual
equations.

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
