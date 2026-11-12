// Generated from fmi-settings.json. Do not edit. To update it, run in
// OMCompiler/Compiler/runtime/rust:
//   FMI_GUIDE_WRITE_TEXTS=1 cargo test -p openmodelica_fmi_guide
// lupdate reads the texts of the FMI settings guide from here.
#include <QtGlobal>

Q_DECL_UNUSED static const char *const fmiGuideTexts[] = {
  //: support level yes
  QT_TRANSLATE_NOOP("FMIGuide", "Supported"),
  //: support level experimental
  QT_TRANSLATE_NOOP("FMIGuide", "Experimental"),
  //: support level partial
  QT_TRANSLATE_NOOP("FMIGuide", "Limited"),
  //: support level planned
  QT_TRANSLATE_NOOP("FMIGuide", "Planned"),
  //: support level no
  QT_TRANSLATE_NOOP("FMIGuide", "Missing"),
  //: question group importer
  QT_TRANSLATE_NOOP("FMIGuide", "The importing tool"),
  //: question group system
  QT_TRANSLATE_NOOP("FMIGuide", "The system"),
  //: question group model
  QT_TRANSLATE_NOOP("FMIGuide", "The model"),
  //: question group use
  QT_TRANSLATE_NOOP("FMIGuide", "The use case"),
  //: question group accuracy
  QT_TRANSLATE_NOOP("FMIGuide", "Accuracy"),
  //: setting group interface
  QT_TRANSLATE_NOOP("FMIGuide", "Interface"),
  //: setting group solver
  QT_TRANSLATE_NOOP("FMIGuide", "Solver inside the FMU"),
  //: setting group coupling
  QT_TRANSLATE_NOOP("FMIGuide", "Coupling and events"),
  //: setting group packaging
  QT_TRANSLATE_NOOP("FMIGuide", "Packaging"),
  //: setting group features
  QT_TRANSLATE_NOOP("FMIGuide", "FMI 3.0 features"),
  //: question importerVersions
  QT_TRANSLATE_NOOP("FMIGuide", "Which FMI versions can the importing tool read?"),
  //: question importerVersions, help
  QT_TRANSLATE_NOOP("FMIGuide", "Select none if you do not know."),
  //: question importerVersions, answer 1.0
  QT_TRANSLATE_NOOP("FMIGuide", "FMI 1.0"),
  //: question importerVersions, answer 2.0
  QT_TRANSLATE_NOOP("FMIGuide", "FMI 2.0"),
  //: question importerVersions, answer 3.0
  QT_TRANSLATE_NOOP("FMIGuide", "FMI 3.0"),
  //: question importerKinds
  QT_TRANSLATE_NOOP("FMIGuide", "Which interface types can it run?"),
  //: question importerKinds, answer me
  QT_TRANSLATE_NOOP("FMIGuide", "Model Exchange"),
  //: question importerKinds, answer cs
  QT_TRANSLATE_NOOP("FMIGuide", "Co-Simulation"),
  //: question importerKinds, answer se
  QT_TRANSLATE_NOOP("FMIGuide", "Scheduled Execution"),
  //: question importerKinds, answer se, why it is off
  QT_TRANSLATE_NOOP("FMIGuide", "Scheduled Execution exists only in FMI 3.0."),
  //: question importerSolver
  QT_TRANSLATE_NOOP("FMIGuide", "How capable is the importing tool's own solver?"),
  //: question importerSolver, help
  QT_TRANSLATE_NOOP("FMIGuide", "With Model Exchange the importing tool integrates the model, so the result is only as good as its solver."),
  //: question importerSolver, why it is off
  QT_TRANSLATE_NOOP("FMIGuide", "Only matters when the importing tool can run Model Exchange."),
  //: question importerSolver, answer strong
  QT_TRANSLATE_NOOP("FMIGuide", "Variable step, implicit, locates events"),
  //: question importerSolver, answer strong, help
  QT_TRANSLATE_NOOP("FMIGuide", "For example CVODE, DASSL, Radau, ode15s."),
  //: question importerSolver, answer basic
  QT_TRANSLATE_NOOP("FMIGuide", "Fixed step or explicit only"),
  //: question importerSolver, answer basic, help
  QT_TRANSLATE_NOOP("FMIGuide", "For example Euler or Runge-Kutta 4."),
  //: question importerSolver, answer unknown
  QT_TRANSLATE_NOOP("FMIGuide", "Do not know"),
  //: question topology
  QT_TRANSLATE_NOOP("FMIGuide", "How is the FMU used?"),
  //: question topology, answer single
  QT_TRANSLATE_NOOP("FMIGuide", "One FMU on its own"),
  //: question topology, answer component
  QT_TRANSLATE_NOOP("FMIGuide", "One FMU inside a larger model"),
  //: question topology, answer component, help
  QT_TRANSLATE_NOOP("FMIGuide", "The rest of the model is native to the importing tool."),
  //: question topology, answer multi
  QT_TRANSLATE_NOOP("FMIGuide", "Several connected FMUs"),
  //: question coupling
  QT_TRANSLATE_NOOP("FMIGuide", "How tightly is it coupled to the rest?"),
  //: question coupling, help
  QT_TRANSLATE_NOOP("FMIGuide", "Tight: fast feedback, rigid mechanical or hydraulic connections, algebraic loops across the connection. Loose: signal flow, slow physical coupling."),
  //: question coupling, why it is off
  QT_TRANSLATE_NOOP("FMIGuide", "A single FMU has nothing to couple to."),
  //: question coupling, answer loose
  QT_TRANSLATE_NOOP("FMIGuide", "Loosely"),
  //: question coupling, answer tight
  QT_TRANSLATE_NOOP("FMIGuide", "Tightly"),
  //: question stiffSystem
  QT_TRANSLATE_NOOP("FMIGuide", "Is the whole coupled system stiff?"),
  //: question stiffSystem, help
  QT_TRANSLATE_NOOP("FMIGuide", "Stiff: time constants that differ by orders of magnitude, where the fast ones decay quickly."),
  //: question stiffSystem, why it is off
  QT_TRANSLATE_NOOP("FMIGuide", "For a single FMU, the question below about the model covers this."),
  //: question stiffSystem, answer no
  QT_TRANSLATE_NOOP("FMIGuide", "No"),
  //: question stiffSystem, answer yes
  QT_TRANSLATE_NOOP("FMIGuide", "Yes"),
  //: question master
  QT_TRANSLATE_NOOP("FMIGuide", "What does the co-simulation algorithm of the importing tool do?"),
  //: question master, why it is off
  QT_TRANSLATE_NOOP("FMIGuide", "Only matters for Co-Simulation of a coupled system."),
  //: question master, answer naive
  QT_TRANSLATE_NOOP("FMIGuide", "Holds the inputs, never repeats a step"),
  //: question master, answer advanced
  QT_TRANSLATE_NOOP("FMIGuide", "Extrapolates inputs or repeats steps"),
  //: question master, answer advanced, help
  QT_TRANSLATE_NOOP("FMIGuide", "Higher order or iterative co-simulation."),
  //: question commStep
  QT_TRANSLATE_NOOP("FMIGuide", "How long is a communication step compared with the dynamics of the model?"),
  //: question commStep, help
  QT_TRANSLATE_NOOP("FMIGuide", "The communication step is the interval at which the importing tool exchanges values with a Co-Simulation FMU. Between two of them the FMU is on its own."),
  //: question commStep, answer long
  QT_TRANSLATE_NOOP("FMIGuide", "Much longer"),
  //: question commStep, answer short
  QT_TRANSLATE_NOOP("FMIGuide", "About as long, or shorter"),
  //: question stiffModel
  QT_TRANSLATE_NOOP("FMIGuide", "Is this model stiff?"),
  //: question stiffModel, help
  QT_TRANSLATE_NOOP("FMIGuide", "Typical causes: electrical with thermal parts, hydraulics, fast controllers, chemical reactions."),
  //: question oscillatory
  QT_TRANSLATE_NOOP("FMIGuide", "Does the model oscillate with little damping?"),
  //: question oscillatory, help
  QT_TRANSLATE_NOOP("FMIGuide", "Mechanics and electric circuits often do."),
  //: question events
  QT_TRANSLATE_NOOP("FMIGuide", "Which events does the model have?"),
  //: question events, answer none
  QT_TRANSLATE_NOOP("FMIGuide", "None"),
  //: question events, answer none, help
  QT_TRANSLATE_NOOP("FMIGuide", "Purely continuous."),
  //: question events, answer time
  QT_TRANSLATE_NOOP("FMIGuide", "Time events only"),
  //: question events, answer time, help
  QT_TRANSLATE_NOOP("FMIGuide", "sample(), clocks, tables."),
  //: question events, answer state
  QT_TRANSLATE_NOOP("FMIGuide", "State events"),
  //: question events, answer state, help
  QT_TRANSLATE_NOOP("FMIGuide", "Switches, friction, impacts, limiters."),
  //: question modelSize
  QT_TRANSLATE_NOOP("FMIGuide", "How large is the model?"),
  //: question modelSize, answer small
  QT_TRANSLATE_NOOP("FMIGuide", "Up to some hundred states"),
  //: question modelSize, answer large
  QT_TRANSLATE_NOOP("FMIGuide", "Thousands of states"),
  //: question algebraicLoops
  QT_TRANSLATE_NOOP("FMIGuide", "Does the model have large systems of algebraic equations?"),
  //: question algebraicLoops, help
  QT_TRANSLATE_NOOP("FMIGuide", "Nonlinear loops with many unknowns, for example in power grids and fluid networks."),
  //: question realtime
  QT_TRANSLATE_NOOP("FMIGuide", "Does it run against the clock?"),
  //: question realtime, answer offline
  QT_TRANSLATE_NOOP("FMIGuide", "No, as fast as possible"),
  //: question realtime, answer interactive
  QT_TRANSLATE_NOOP("FMIGuide", "Interactive"),
  //: question realtime, answer interactive, help
  QT_TRANSLATE_NOOP("FMIGuide", "An operator or a 3D view follows the simulation. A late step is not a failure."),
  //: question realtime, answer hard
  QT_TRANSLATE_NOOP("FMIGuide", "Hard real time"),
  //: question realtime, answer hard, help
  QT_TRANSLATE_NOOP("FMIGuide", "Hardware in the loop. Every step has a deadline."),
  //: question tuneParameters
  QT_TRANSLATE_NOOP("FMIGuide", "Must parameters change after export?"),
  //: question tuneParameters, answer values
  QT_TRANSLATE_NOOP("FMIGuide", "Values, while it runs"),
  //: question tuneParameters, answer structure
  QT_TRANSLATE_NOOP("FMIGuide", "Also array sizes"),
  //: question gradients
  QT_TRANSLATE_NOOP("FMIGuide", "Does the importing tool need derivatives of the model?"),
  //: question gradients, answer forward
  QT_TRANSLATE_NOOP("FMIGuide", "Jacobians"),
  //: question gradients, answer forward, help
  QT_TRANSLATE_NOOP("FMIGuide", "Linearisation, an implicit solver, algebraic loops between FMUs."),
  //: question gradients, answer adjoint
  QT_TRANSLATE_NOOP("FMIGuide", "Gradients for many parameters"),
  //: question gradients, answer adjoint, help
  QT_TRANSLATE_NOOP("FMIGuide", "Optimisation, parameter estimation, machine learning."),
  //: question target
  QT_TRANSLATE_NOOP("FMIGuide", "Where does the FMU run?"),
  //: question target, answer same
  QT_TRANSLATE_NOOP("FMIGuide", "On this kind of computer"),
  //: question target, answer other
  QT_TRANSLATE_NOOP("FMIGuide", "Another operating system or CPU"),
  //: question target, answer embedded
  QT_TRANSLATE_NOOP("FMIGuide", "A target that compiles the FMU itself"),
  //: question target, answer embedded, help
  QT_TRANSLATE_NOOP("FMIGuide", "Real-time and embedded platforms."),
  //: question target, answer browser
  QT_TRANSLATE_NOOP("FMIGuide", "A web browser or sandbox"),
  //: question ip
  QT_TRANSLATE_NOOP("FMIGuide", "Must the inside of the model stay hidden?"),
  //: question solverPrecision
  QT_TRANSLATE_NOOP("FMIGuide", "How accurate must the solution be?"),
  //: question solverPrecision, answer low
  QT_TRANSLATE_NOOP("FMIGuide", "Trends"),
  //: question solverPrecision, answer low, help
  QT_TRANSLATE_NOOP("FMIGuide", "About 1e-3 relative error."),
  //: question solverPrecision, answer medium
  QT_TRANSLATE_NOOP("FMIGuide", "Engineering"),
  //: question solverPrecision, answer medium, help
  QT_TRANSLATE_NOOP("FMIGuide", "About 1e-6."),
  //: question solverPrecision, answer high
  QT_TRANSLATE_NOOP("FMIGuide", "Reference"),
  //: question solverPrecision, answer high, help
  QT_TRANSLATE_NOOP("FMIGuide", "1e-8 or better."),
  //: question eventPrecision
  QT_TRANSLATE_NOOP("FMIGuide", "How accurate must events be?"),
  //: question eventPrecision, why it is off
  QT_TRANSLATE_NOOP("FMIGuide", "The model has no events."),
  //: question eventPrecision, answer step
  QT_TRANSLATE_NOOP("FMIGuide", "The next communication point is enough"),
  //: question eventPrecision, answer located
  QT_TRANSLATE_NOOP("FMIGuide", "The FMU must find the event time"),
  //: question eventPrecision, answer sync
  QT_TRANSLATE_NOOP("FMIGuide", "Everything must stop at the event"),
  //: question eventPrecision, answer sync, help
  QT_TRANSLATE_NOOP("FMIGuide", "The other parts of the system react at the event time, not one step later."),
  //: question eventPrecision, answer sync, why it is off
  QT_TRANSLATE_NOOP("FMIGuide", "Only for a coupled system."),
  //: preset omsimulator
  QT_TRANSLATE_NOOP("FMIGuide", "OMSimulator"),
  //: preset fmpy
  QT_TRANSLATE_NOOP("FMIGuide", "FMPy"),
  //: preset simulink
  QT_TRANSLATE_NOOP("FMIGuide", "Simulink FMU block"),
  //: preset omc-import
  QT_TRANSLATE_NOOP("FMIGuide", "OpenModelica importFMU"),
  //: preset hil
  QT_TRANSLATE_NOOP("FMIGuide", "Typical real-time target"),
  //: setting interface
  QT_TRANSLATE_NOOP("FMIGuide", "Interface to use"),
  //: setting interface, help
  QT_TRANSLATE_NOOP("FMIGuide", "Who integrates: the importing tool (Model Exchange) or the FMU (Co-Simulation)."),
  //: setting fmiVersion
  QT_TRANSLATE_NOOP("FMIGuide", "FMI version"),
  //: setting fmiVersion, option 1.0, support
  QT_TRANSLATE_NOOP("FMIGuide", "Deprecated. Model Exchange only."),
  //: setting fmiType
  QT_TRANSLATE_NOOP("FMIGuide", "Interfaces in the FMU"),
  //: setting fmiType, option me_cs
  QT_TRANSLATE_NOOP("FMIGuide", "Model Exchange and Co-Simulation"),
  //: setting fmiType, option me_cs, why it is impossible
  QT_TRANSLATE_NOOP("FMIGuide", "OpenModelica exports FMI 1.0 as Model Exchange only."),
  //: setting fmiType, option se, why it is impossible
  QT_TRANSLATE_NOOP("FMIGuide", "FMI 3.0 only."),
  //: setting daeMode
  QT_TRANSLATE_NOOP("FMIGuide", "DAE mode"),
  //: setting daeMode, option off
  QT_TRANSLATE_NOOP("FMIGuide", "Off: explicit ODE"),
  //: setting daeMode, option off, help
  QT_TRANSLATE_NOOP("FMIGuide", "The FMU solves the algebraic equations each time it calculates the derivatives."),
  //: setting daeMode, option on
  QT_TRANSLATE_NOOP("FMIGuide", "On: residual form"),
  //: setting daeMode, option on, help
  QT_TRANSLATE_NOOP("FMIGuide", "The integrator solves the algebraic equations together with the states."),
  //: setting daeMode, option on, why it is impossible
  QT_TRANSLATE_NOOP("FMIGuide", "Needs Co-Simulation, or Model Exchange with FMI 3.0."),
  //: setting daeMode, option on, support
  QT_TRANSLATE_NOOP("FMIGuide", "Model Exchange uses the draft of the FMI-LS-DAE layered standard."),
  //: setting daeMode, option on, support
  QT_TRANSLATE_NOOP("FMIGuide", "With FMI 2.0 only the Co-Simulation part is exported."),
  //: setting csSolver
  QT_TRANSLATE_NOOP("FMIGuide", "Solver"),
  //: setting csSolver, option cvode
  QT_TRANSLATE_NOOP("FMIGuide", "CVODE"),
  //: setting csSolver, option cvode, help
  QT_TRANSLATE_NOOP("FMIGuide", "Implicit, variable step and order (BDF), with root finding for state events."),
  //: setting csSolver, option euler
  QT_TRANSLATE_NOOP("FMIGuide", "Explicit Euler"),
  //: setting csSolver, option dassl
  QT_TRANSLATE_NOOP("FMIGuide", "DASSL"),
  //: setting csSolver, option dassl, support
  QT_TRANSLATE_NOOP("FMIGuide", "WebAssembly FMUs only."),
  //: setting csSolver, option ida
  QT_TRANSLATE_NOOP("FMIGuide", "IDA"),
  //: setting csSolver, option ida, help
  QT_TRANSLATE_NOOP("FMIGuide", "Implicit, variable step and order (BDF) for the residual form."),
  //: setting csSolver, option ida, why it is impossible
  QT_TRANSLATE_NOOP("FMIGuide", "Only for DAE mode."),
  //: setting csSolver, option ida, how to select it
  QT_TRANSLATE_NOOP("FMIGuide", "Nothing to set. DAE mode selects it."),
  //: setting csSolver, option heun
  QT_TRANSLATE_NOOP("FMIGuide", "Heun, fixed step"),
  //: setting csSolver, option heun, help
  QT_TRANSLATE_NOOP("FMIGuide", "Explicit, second order."),
  //: setting csSolver, option heun, support
  QT_TRANSLATE_NOOP("FMIGuide", "Available for simulations (-s=heun), not inside FMUs."),
  //: setting csSolver, option rk4
  QT_TRANSLATE_NOOP("FMIGuide", "Explicit Runge-Kutta, fixed step"),
  //: setting csSolver, option rk4, support
  QT_TRANSLATE_NOOP("FMIGuide", "Available for simulations (-s=rungekutta), not inside FMUs."),
  //: setting csSolver, option impeuler
  QT_TRANSLATE_NOOP("FMIGuide", "Implicit Euler, fixed step"),
  //: setting csSolver, option impeuler, support
  QT_TRANSLATE_NOOP("FMIGuide", "Available for simulations (-s=impeuler), not inside FMUs."),
  //: setting csSolver, option rosenbrock
  QT_TRANSLATE_NOOP("FMIGuide", "Linearly implicit (Rosenbrock), fixed step"),
  //: setting csSolver, option rosenbrock, help
  QT_TRANSLATE_NOOP("FMIGuide", "One Jacobian factorisation per step and no Newton iteration, so the cost of a step is known in advance."),
  //: setting csSolver, option rosenbrock, support
  QT_TRANSLATE_NOOP("FMIGuide", "Not in OpenModelica."),
  //: setting csSolver, option esdirk
  QT_TRANSLATE_NOOP("FMIGuide", "ESDIRK, variable step (gbode)"),
  //: setting csSolver, option esdirk, help
  QT_TRANSLATE_NOOP("FMIGuide", "An implicit one-step method. It keeps its order across restarts."),
  //: setting csSolver, option esdirk, support
  QT_TRANSLATE_NOOP("FMIGuide", "Available for simulations (-s=gbode), not inside FMUs."),
  //: setting csStepping
  QT_TRANSLATE_NOOP("FMIGuide", "Internal step"),
  //: setting csStepping, option comm
  QT_TRANSLATE_NOOP("FMIGuide", "One solver step per communication step"),
  //: setting csStepping, option substep
  QT_TRANSLATE_NOOP("FMIGuide", "Several solver steps per communication step"),
  //: setting csStepping, option substep, support
  QT_TRANSLATE_NOOP("FMIGuide", "WebAssembly FMUs step on the output interval of the model. FMUs built from C code take one Euler step per communication step."),
  //: setting tolerance
  QT_TRANSLATE_NOOP("FMIGuide", "Solver tolerance"),
  //: setting tolerance, option 1e-6
  QT_TRANSLATE_NOOP("FMIGuide", "1e-6"),
  //: setting tolerance, option 1e-6, how to select it
  QT_TRANSLATE_NOOP("FMIGuide", "The importing tool can override it."),
  //: setting tolerance, option 1e-4
  QT_TRANSLATE_NOOP("FMIGuide", "1e-4"),
  //: setting tolerance, option 1e-4, how to select it
  QT_TRANSLATE_NOOP("FMIGuide", "Set annotation(experiment(Tolerance = 1e-4)) in the model. The importing tool can override it."),
  //: setting tolerance, option 1e-8
  QT_TRANSLATE_NOOP("FMIGuide", "1e-8"),
  //: setting tolerance, option 1e-8, how to select it
  QT_TRANSLATE_NOOP("FMIGuide", "Set annotation(experiment(Tolerance = 1e-8)) in the model. The importing tool can override it."),
  //: setting eventHandling
  QT_TRANSLATE_NOOP("FMIGuide", "Events during a step"),
  //: setting eventHandling, option internal
  QT_TRANSLATE_NOOP("FMIGuide", "Handled inside the FMU"),
  //: setting eventHandling, option internal, help
  QT_TRANSLATE_NOOP("FMIGuide", "The FMU finds the event, handles it and continues to the end of the step. The rest of the system sees the result at the next communication point."),
  //: setting eventHandling, option internal, how to select it
  QT_TRANSLATE_NOOP("FMIGuide", "Nothing to set."),
  //: setting eventHandling, option eventMode
  QT_TRANSLATE_NOOP("FMIGuide", "Event Mode with early return"),
  //: setting eventHandling, option eventMode, help
  QT_TRANSLATE_NOOP("FMIGuide", "The step returns at the event time, so that the importing tool can update every part."),
  //: setting eventHandling, option eventMode, how to select it
  QT_TRANSLATE_NOOP("FMIGuide", "Nothing to set at export. The importing tool turns it on with eventModeUsed and earlyReturnAllowed."),
  //: setting eventIterations
  QT_TRANSLATE_NOOP("FMIGuide", "Limit of event iterations"),
  //: setting eventIterations, option default
  QT_TRANSLATE_NOOP("FMIGuide", "At most 20 per event"),
  //: setting eventIterations, option default, help
  QT_TRANSLATE_NOOP("FMIGuide", "The FMU stops with an error when an event needs more."),
  //: setting eventIterations, option limited
  QT_TRANSLATE_NOOP("FMIGuide", "A lower limit, set at export"),
  //: setting eventIterations, option limited, support
  QT_TRANSLATE_NOOP("FMIGuide", "The simulation flag -mei sets the limit. An FMU does not read it."),
  //: setting inputHandling
  QT_TRANSLATE_NOOP("FMIGuide", "Inputs between communication points"),
  //: setting inputHandling, option hold
  QT_TRANSLATE_NOOP("FMIGuide", "Held constant"),
  //: setting inputHandling, option smooth
  QT_TRANSLATE_NOOP("FMIGuide", "Smoothed inside the FMU"),
  //: setting inputHandling, option smooth, help
  QT_TRANSLATE_NOOP("FMIGuide", "The FMU spreads a change of an input over the step, so that its solver sees no jump."),
  //: setting inputHandling, option interpolate
  QT_TRANSLATE_NOOP("FMIGuide", "Input derivatives"),
  //: setting inputHandling, option interpolate, why it is impossible
  QT_TRANSLATE_NOOP("FMIGuide", "FMI 2.0 only. FMI 3.0 uses Intermediate Update for this."),
  //: setting inputHandling, option interpolate, how to select it
  QT_TRANSLATE_NOOP("FMIGuide", "Nothing to set at export. The importing tool must call fmi2SetRealInputDerivatives."),
  //: setting inputHandling, option intermediate
  QT_TRANSLATE_NOOP("FMIGuide", "Intermediate Update"),
  //: setting inputHandling, option intermediate, help
  QT_TRANSLATE_NOOP("FMIGuide", "The importing tool reads outputs and sets inputs at the internal steps of the solver."),
  //: setting fmuState
  QT_TRANSLATE_NOOP("FMIGuide", "Saving the FMU state"),
  //: setting fmuState, option none
  QT_TRANSLATE_NOOP("FMIGuide", "Not needed"),
  //: setting fmuState, option getset
  QT_TRANSLATE_NOOP("FMIGuide", "Get and set"),
  //: setting fmuState, option getset, why it is impossible
  QT_TRANSLATE_NOOP("FMIGuide", "Not in FMI 1.0."),
  //: setting fmuState, option getset, how to select it
  QT_TRANSLATE_NOOP("FMIGuide", "Always exported. Nothing to set."),
  //: setting fmuState, option serialize
  QT_TRANSLATE_NOOP("FMIGuide", "Serialize"),
  //: setting fmuState, option serialize, how to select it
  QT_TRANSLATE_NOOP("FMIGuide", "Always exported for FMI 3.0. Nothing to set."),
  //: setting fmuState, option serialize, support
  QT_TRANSLATE_NOOP("FMIGuide", "OpenModelica serializes the state only for FMI 3.0."),
  //: setting derivatives
  QT_TRANSLATE_NOOP("FMIGuide", "Partial derivatives"),
  //: setting derivatives, option directional
  QT_TRANSLATE_NOOP("FMIGuide", "Directional derivatives"),
  //: setting derivatives, option directional, support
  QT_TRANSLATE_NOOP("FMIGuide", "The Co-Simulation part of an FMI 2.0 FMU also needs -d=fmuExperimental."),
  //: setting derivatives, option adjoint
  QT_TRANSLATE_NOOP("FMIGuide", "Adjoint derivatives"),
  //: setting derivatives, option adjoint, support
  QT_TRANSLATE_NOOP("FMIGuide", "In development."),
  //: setting platforms
  QT_TRANSLATE_NOOP("FMIGuide", "Binaries"),
  //: setting platforms, option static
  QT_TRANSLATE_NOOP("FMIGuide", "This platform, statically linked"),
  //: setting platforms, option dynamic
  QT_TRANSLATE_NOOP("FMIGuide", "This platform, dynamically linked"),
  //: setting platforms, option cross
  QT_TRANSLATE_NOOP("FMIGuide", "Cross-compiled with Docker"),
  //: setting platforms, option cross, how to select it
  QT_TRANSLATE_NOOP("FMIGuide", "Replace the host triple by the one of the target."),
  //: setting platforms, option source
  QT_TRANSLATE_NOOP("FMIGuide", "No binaries, source code only"),
  //: setting platforms, option source, how to select it
  QT_TRANSLATE_NOOP("FMIGuide", "OpenModelica does not zip the FMU in this case. Pack it with the create_fmu target of the CMake project in sources/."),
  //: setting platforms, option wasm
  QT_TRANSLATE_NOOP("FMIGuide", "WebAssembly"),
  //: setting platforms, option wasm, why it is impossible
  QT_TRANSLATE_NOOP("FMIGuide", "Not for FMI 1.0."),
  //: setting platforms, option wasm, support
  QT_TRANSLATE_NOOP("FMIGuide", "Needs the omc built from the Rust port."),
  //: setting fmiSources
  QT_TRANSLATE_NOOP("FMIGuide", "Source code in the FMU"),
  //: setting fmiSources, option slim
  QT_TRANSLATE_NOOP("FMIGuide", "The sources it was built from"),
  //: setting fmiSources, option full
  QT_TRANSLATE_NOOP("FMIGuide", "Sources and all their dependencies"),
  //: setting fmiSources, option full, support
  QT_TRANSLATE_NOOP("FMIGuide", "Differs from slim only with --simCodeTarget=C+Rust."),
  //: setting fmiFilter
  QT_TRANSLATE_NOOP("FMIGuide", "Variables in modelDescription.xml"),
  //: setting fmiFilter, option protected
  QT_TRANSLATE_NOOP("FMIGuide", "Public variables"),
  //: setting fmiFilter, option internal
  QT_TRANSLATE_NOOP("FMIGuide", "Public and protected variables"),
  //: setting fmiFilter, option none
  QT_TRANSLATE_NOOP("FMIGuide", "Everything, also generated variables"),
  //: setting fmiFilter, option blackBox
  QT_TRANSLATE_NOOP("FMIGuide", "Only the interface"),
  //: setting runtimeDepends
  QT_TRANSLATE_NOOP("FMIGuide", "Libraries copied into the FMU"),
  //: setting runtimeDepends, option modelica
  QT_TRANSLATE_NOOP("FMIGuide", "Libraries the model uses"),
  //: setting runtimeDepends, option all
  QT_TRANSLATE_NOOP("FMIGuide", "Also system libraries"),
  //: setting tunable
  QT_TRANSLATE_NOOP("FMIGuide", "Parameters after export"),
  //: setting tunable, option literal
  QT_TRANSLATE_NOOP("FMIGuide", "Parameters with a literal value are tunable"),
  //: setting tunable, option none
  QT_TRANSLATE_NOOP("FMIGuide", "All parameters fixed"),
  //: setting tunable, option structural
  QT_TRANSLATE_NOOP("FMIGuide", "Structural parameters"),
  //: setting tunable, option structural, help
  QT_TRANSLATE_NOOP("FMIGuide", "The importing tool changes array sizes in Configuration Mode."),
  //: setting tunable, option structural, support
  QT_TRANSLATE_NOOP("FMIGuide", "Array sizes are fixed at export."),
  //: setting clocks
  QT_TRANSLATE_NOOP("FMIGuide", "Clocks"),
  //: setting clocks, option off
  QT_TRANSLATE_NOOP("FMIGuide", "Not exported"),
  //: setting clocks, option on
  QT_TRANSLATE_NOOP("FMIGuide", "Exported"),
  //: setting terminals
  QT_TRANSLATE_NOOP("FMIGuide", "Terminals"),
  //: setting terminals, option on
  QT_TRANSLATE_NOOP("FMIGuide", "Terminals from the connectors of the model"),
  //: setting terminals, option on, how to select it
  QT_TRANSLATE_NOOP("FMIGuide", "Nothing to set. Written to terminalsAndIcons.xml when the model has connectors at the top level."),
  //: setting xcp
  QT_TRANSLATE_NOOP("FMIGuide", "Calibration on the target (FMI-LS-XCP)"),
  //: setting xcp, option on
  QT_TRANSLATE_NOOP("FMIGuide", "XCP description in the FMU"),
  //: setting xcp, option on, why it is impossible
  QT_TRANSLATE_NOOP("FMIGuide", "A layered standard on FMI 3.0."),
  //: setting xcp, option on, support
  QT_TRANSLATE_NOOP("FMIGuide", "Not planned."),
  //: rule importer-lacks-me, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The importing tool cannot run Model Exchange."),
  //: rule importer-lacks-cs, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The importing tool cannot run Co-Simulation."),
  //: rule se-only-when-supported, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Few tools run Scheduled Execution. Use it only when the importing tool is known to."),
  //: rule single-fmu-self-contained, reason
  QT_TRANSLATE_NOOP("FMIGuide", "An FMU with its own solver gives the same result in every tool."),
  //: rule strong-importer-solver, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The solver of the importing tool controls the error of the whole model and locates the events itself."),
  //: rule basic-importer-solver, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A solver inside the FMU is better than a fixed-step or explicit solver in the importing tool."),
  //: rule stiff-model-basic-importer, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A stiff model needs an implicit solver, which the importing tool does not have."),
  //: rule tight-coupling-one-solver, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Tightly coupled parts need one solver for the whole system. Co-Simulation exchanges values only at communication points, which limits stability and accuracy."),
  //: rule stiff-system-one-solver, reason
  QT_TRANSLATE_NOOP("FMIGuide", "With Model Exchange one implicit solver sees the stiffness of the whole system. Co-Simulation needs very small communication steps instead."),
  //: rule loose-coupling-own-solvers, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Loosely coupled parts can each run their own solver and step size."),
  //: rule fast-dynamics-stay-inside, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Co-Simulation keeps the fast dynamics inside this FMU, so the rest of the system can take large steps."),
  //: rule synchronised-events-need-importer, reason
  QT_TRANSLATE_NOOP("FMIGuide", "With Model Exchange the importing tool locates every event and updates all parts at that time."),
  //: rule system-wide-error-control, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Error control over a coupled system needs one solver."),
  //: rule hard-realtime-own-solver, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A real-time target calls one function per sample. The FMU must bring a solver with a known cost per step."),
  //: rule interactive-even-step-cost, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A solver inside the FMU gives an even cost per step, which keeps an interactive simulation smooth."),
  //: rule scheduled-execution-for-rtos, reason
  QT_TRANSLATE_NOOP("FMIGuide", "With Scheduled Execution the real-time scheduler runs each clocked part of the model as its own task."),
  //: rule derivative-tools-use-me, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Tools that linearise or optimise work on the state derivatives, which only Model Exchange exposes."),
  //: rule importer-lacks-fmi1, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The importing tool does not read FMI 1.0."),
  //: rule importer-lacks-fmi2, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The importing tool does not read FMI 2.0."),
  //: rule importer-lacks-fmi3, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The importing tool does not read FMI 3.0."),
  //: rule fmi1-deprecated, reason
  QT_TRANSLATE_NOOP("FMIGuide", "FMI 1.0 export is deprecated in OpenModelica."),
  //: rule fmi3-experimental, reason
  QT_TRANSLATE_NOOP("FMIGuide", "FMI 3.0 export is experimental in OpenModelica."),
  //: rule synchronised-events-in-cs-need-fmi3, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Only FMI 3.0 Co-Simulation can stop a step at an event and tell the importing tool."),
  //: rule adjoint-needs-fmi3, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Adjoint derivatives are defined only in FMI 3.0."),
  //: rule array-sizes-need-fmi3, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Structural parameters are defined only in FMI 3.0."),
  //: rule tight-cs-better-in-fmi3, reason
  QT_TRANSLATE_NOOP("FMIGuide", "With FMI 3.0 Intermediate Update the master exchanges values inside a communication step."),
  //: rule coupled-samplers-fmi3, reason
  QT_TRANSLATE_NOOP("FMIGuide", "FMI 3.0 clocks let the importing tool keep sampled parts in step."),
  //: rule wasm-not-fmi1, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A WebAssembly FMU cannot be FMI 1.0."),
  //: rule type-follows-me, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The importing tool uses the Model Exchange part."),
  //: rule type-follows-cs, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The importing tool uses the Co-Simulation part."),
  //: rule type-follows-se, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The importing tool uses Scheduled Execution."),
  //: rule type-not-se, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Scheduled Execution was not selected as the interface."),
  //: rule unknown-importer-both-interfaces, reason
  QT_TRANSLATE_NOOP("FMIGuide", "With both interfaces the FMU works whichever one the importing tool supports."),
  //: rule algebraic-loops-dae-mode, reason
  QT_TRANSLATE_NOOP("FMIGuide", "In DAE mode the integrator solves the algebraic equations together with the states. Otherwise a nonlinear solver runs inside every calculation of the derivatives."),
  //: rule large-loops-dae-mode, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The integrator uses one sparse Jacobian for the whole model, which scales to large models."),
  //: rule hard-realtime-no-dae-mode, reason
  QT_TRANSLATE_NOOP("FMIGuide", "DAE mode integrates with IDA, a variable-step method with no upper limit for the time of a step."),
  //: rule me-dae-mode-needs-importer, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Only an importing tool that knows the FMI-LS-DAE draft can integrate the residual form of a Model Exchange FMU."),
  //: rule stiff-needs-implicit, reason
  QT_TRANSLATE_NOOP("FMIGuide", "An explicit method is stable only with steps below the fastest time constant of a stiff model."),
  //: rule nonstiff-explicit-is-cheaper, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A model that is not stiff does not need the cost of an implicit method."),
  //: rule unknown-stiffness-robust, reason
  QT_TRANSLATE_NOOP("FMIGuide", "An implicit variable-step method works whether the model is stiff or not."),
  //: rule offline-error-control, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Without a deadline, a variable-step method chooses the step that the tolerance needs."),
  //: rule low-precision-first-order, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A first-order method is enough to see trends."),
  //: rule medium-precision-higher-order, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A method of higher order reaches engineering accuracy with fewer steps."),
  //: rule high-precision-error-control, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Only a variable-step method with error control can keep a tight tolerance."),
  //: rule hard-realtime-bounded-step, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A real-time step must end within a known time. Step-size control and Newton iterations have no upper limit."),
  //: rule interactive-fixed-step, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A fixed step gives an even cost per step."),
  //: rule events-restart-multistep, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A multistep method such as BDF restarts at order one after every event. A one-step method keeps its order."),
  //: rule oscillations-need-higher-order, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Explicit Euler adds energy to an oscillation with little damping at every step, and implicit Euler removes it. A method of second or higher order keeps the energy much better."),
  //: rule long-steps-need-step-control, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Between two communication points the FMU is on its own. With long steps it needs a solver that chooses its own step."),
  //: rule short-steps-restart-bdf, reason
  QT_TRANSLATE_NOOP("FMIGuide", "With short communication steps a BDF solver starts again at low order at every step. A one-step method does not pay for the restart."),
  //: rule inputs-restart-multistep, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Inputs change at every communication point, which makes a multistep method restart often."),
  //: rule dae-mode-uses-ida, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Only IDA integrates the residual form."),
  //: rule substeps-for-accuracy, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A smaller internal step lowers the error without a smaller communication step."),
  //: rule long-steps-substeps, reason
  QT_TRANSLATE_NOOP("FMIGuide", "One solver step per long communication step is too coarse."),
  //: rule substeps-for-stability, reason
  QT_TRANSLATE_NOOP("FMIGuide", "An explicit method needs steps below the fastest time constant to stay stable."),
  //: rule tolerance-for-trends, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A coarse tolerance is enough to see trends and takes fewer steps."),
  //: rule tolerance-for-reference, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Reference results need a tight tolerance."),
  //: rule synchronised-events-event-mode, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Event Mode stops the step at the event, so that the other parts react at the event time."),
  //: rule realtime-limit-event-iterations, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Each event iteration calculates the whole model again. A lower limit shortens the longest step."),
  //: rule tight-coupling-input-extrapolation, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Held inputs are up to one communication step old, which makes tight coupling unstable."),
  //: rule naive-master-smooth-inputs, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A master that holds the inputs gives the FMU a jump at every communication point. Smoothing inside the FMU hides the jump from the solver."),
  //: rule advanced-master-needs-support, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A master can extrapolate inputs or repeat a step only when the FMU offers it."),
  //: rule precision-input-extrapolation, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Held inputs add an error of first order in the communication step."),
  //: rule stiff-system-input-extrapolation, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A stiff coupled system reacts strongly to input values that are out of date."),
  //: rule rollback-for-repeated-steps, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A master that repeats a step, to iterate or to change the step size, must reset the FMU to the start of the step."),
  //: rule snapshots-for-operator, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A saved state lets an operator go back, or continue in a later session."),
  //: rule jacobians-requested, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Directional derivatives give the importing tool exact Jacobians."),
  //: rule gradients-requested, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Adjoint derivatives give the gradient for all parameters in one pass. Directional derivatives need one pass per parameter."),
  //: rule implicit-importer-solver-needs-jacobian, reason
  QT_TRANSLATE_NOOP("FMIGuide", "An implicit solver in the importing tool needs the Jacobian. Without directional derivatives it estimates it by finite differences."),
  //: rule master-needs-interface-jacobian, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Interface Jacobians let the master solve algebraic loops between FMUs."),
  //: rule large-me-needs-jacobian, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Finite differences cost one model evaluation per state, which is slow for a large model."),
  //: rule other-platform-cross-compile, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A binary for this computer does not run on the target."),
  //: rule target-compiles-sources, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The target platform compiles the FMU from source code with its own toolchain."),
  //: rule browser-needs-wasm, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A browser or sandbox cannot load native code."),
  //: rule hidden-model-no-sources, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Source code shows the equations of the model."),
  //: rule hidden-model-on-target, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Without source code, the FMU must carry a binary built for the target."),
  //: rule source-only-needs-sources, reason
  QT_TRANSLATE_NOOP("FMIGuide", "An FMU without binaries and without sources is empty."),
  //: rule hidden-model-black-box, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The names and values of internal variables show how the model is built."),
  //: rule cross-compile-all-libraries, reason
  QT_TRANSLATE_NOOP("FMIGuide", "System libraries differ between versions of an operating system."),
  //: rule tune-values, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The importing tool can set a tunable parameter between steps. The FMU calculates the dependent parameters again."),
  //: rule tune-array-sizes, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Only structural parameters can change array sizes after export."),
  //: rule fixed-when-hidden, reason
  QT_TRANSLATE_NOOP("FMIGuide", "The receiver of the FMU cannot change a fixed parameter after initialization."),
  //: rule se-needs-clocks, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Scheduled Execution is driven by clocks."),
  //: rule clocks-for-coupled-samplers, reason
  QT_TRANSLATE_NOOP("FMIGuide", "With exported clocks the importing tool activates the sampled parts of all FMUs at the same instant."),
  //: rule clocks-for-realtime, reason
  QT_TRANSLATE_NOOP("FMIGuide", "A real-time scheduler can tick the clocks of the model directly."),
  //: rule terminals-for-many-fmus, reason
  QT_TRANSLATE_NOOP("FMIGuide", "Terminals group the signals of a connector, so that FMUs are connected connector by connector and not signal by signal."),
  //: rule calibrate-on-target, reason
  QT_TRANSLATE_NOOP("FMIGuide", "XCP lets standard calibration tools measure and tune the model while it runs on the target."),
  //: rule advice-use-me-part, tip
  QT_TRANSLATE_NOOP("FMIGuide", "The FMU carries both interfaces. Select Model Exchange in the importing tool if it has it."),
  //: rule advice-coupling-unknown, tip
  QT_TRANSLATE_NOOP("FMIGuide", "Find out how tightly the parts are coupled. It is the main reason to choose Model Exchange over Co-Simulation."),
  //: rule advice-stiffness-unknown, tip
  QT_TRANSLATE_NOOP("FMIGuide", "To find out if the model is stiff, simulate it in OpenModelica with -s=euler or -s=rungekutta. If it needs a much smaller step than the accuracy asks for, it is stiff."),
  //: rule advice-omsimulator, tip
  QT_TRANSLATE_NOOP("FMIGuide", "OMSimulator connects and simulates several FMUs. Model Exchange FMUs go into a strongly coupled system, Co-Simulation FMUs into a weakly coupled one."),
  //: rule advice-cut-at-decoupling, tip
  QT_TRANSLATE_NOOP("FMIGuide", "Cut the system where the physics decouples it, and use as few FMUs as the task allows."),
  //: rule advice-energy-at-the-cut, tip
  QT_TRANSLATE_NOOP("FMIGuide", "A cut through a stiff connection adds or removes energy at every communication step. A transmission line (TLM) connection, or a master that corrects the energy error, keeps it stable."),
  //: rule warn-euler-oscillation, warning
  QT_TRANSLATE_NOOP("FMIGuide", "Explicit Euler makes an oscillation with little damping grow. Use a step much shorter than its period, and check the amplitude over a long run."),
  //: rule advice-euler-step, tip
  QT_TRANSLATE_NOOP("FMIGuide", "Explicit Euler takes one step per communication step. Choose the communication step from the fastest dynamics of the model, not from how often you need output."),
  //: rule advice-fmi3-test, tip
  QT_TRANSLATE_NOOP("FMIGuide", "FMI 3.0 export is experimental. Test the FMU in the importing tool before you rely on it."),
  //: rule warn-tight-cs, warning
  QT_TRANSLATE_NOOP("FMIGuide", "Tight coupling through Co-Simulation: use a communication step well below the fastest coupled time constant, and a master that can repeat steps."),
  //: rule warn-stiff-system-cs, warning
  QT_TRANSLATE_NOOP("FMIGuide", "A stiff coupled system in Co-Simulation is stable only with small communication steps, however good the solvers inside the FMUs are."),
  //: rule warn-fmi2-cs-events, warning
  QT_TRANSLATE_NOOP("FMIGuide", "FMI 2.0 Co-Simulation cannot report an event to the importing tool. The other parts see it at the next communication point. Choose a communication step as small as the event accuracy needs."),
  //: rule warn-me-stiff-basic-solver, warning
  QT_TRANSLATE_NOOP("FMIGuide", "Model Exchange with a stiff model needs an implicit solver in the importing tool."),
  //: rule warn-realtime-variable-step, warning
  QT_TRANSLATE_NOOP("FMIGuide", "A variable-step solver has no upper limit for the time of a step. Measure the longest step on the target and leave a margin."),
  //: rule warn-realtime-events, warning
  QT_TRANSLATE_NOOP("FMIGuide", "A step with an event takes longer: the FMU finds the time of the event and then iterates, up to 20 times. Measure the longest step on the target with all events active."),
  //: rule warn-realtime-me, warning
  QT_TRANSLATE_NOOP("FMIGuide", "With Model Exchange the real-time behaviour depends on the fixed-step solver of the importing tool. Check how it handles events."),
};
