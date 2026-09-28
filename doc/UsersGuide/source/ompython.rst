OMPython - OpenModelica Python Interface
========================================

OMPython - OpenModelica Python API is a free, open source, highly
portable Python based interactive session handler for Modelica
scripting. It provides the modeler with components for creating a
complete Modelica modeling, compilation and simulation environment based
on the latest OpenModelica tools standard available. OMPython is
architectured to combine both the solving strategy and model building.
So domain experts (people writing the models) and computational
engineers (people writing the solver code) can work on one unified tool
that is industrially viable for optimization of Modelica models, while
offering a flexible platform for algorithm development and research.

OMPython is implemented in Python and depends on ZeroMQ - high performance asynchronous
messaging library.

To install OMPython follow the instructions at https://github.com/OpenModelica/OMPython

Features of OMPython
--------------------

OMPython provides user friendly features like:

-  Interactive session handling, parsing, interpretation of commands and
   Modelica expressions for evaluation, simulation, plotting, etc.

-  Optimized parser results that give control over every element of the output.

-  Helper functions to allow manipulation on Nested dictionaries.

-  Easy access to the library and testing of OpenModelica commands.

-  Possibility to run DoEs (design of experiments) based on parameter variation of an existing model.

-  Run models in different environments like Linux, Windows, docker or WSL.

-  Run compiled models without any dependency on OMC / ZMQ.

The classes which talk to OMC depend on an OpenModelica installation, because they start or connect to an
OMC server. The classes which only run already compiled models - :code:`OMSessionRunner`,
:code:`ModelicaSystemRunner` and :code:`OMPython.model_execution` - do not, and are therefore usable on
machines without OpenModelica.

-  **OMPython.om_session_*** - the session classes, see :ref:`om_session`.
-  **OMPython.modelica_system_*** - the modelica system classes, see :ref:`modelica_system`.
-  **OMPython.modelica_doe_*** - design of experiments (DOE), see :ref:`modelica_doe`

Besides these main parts, additional helper functionality exists:

-  **OMPython.OMParser** and **OMPython.OMTypedParser** - parser for OpenModelica return data, see :ref:`parser`
-  **OMPython.model_execution** - execute compiled models, see :ref:`model_execution`

Each of the main sections listed above is differentiated in

-  **OMPython.*_abc** - abstract base classes holding the basic functionality which is shared by the two
   available implementations
-  **OMPython.*_omc** - run OpenModelica based on an OMC server
-  **OMPython.*_runner** - run simulations using pre-compiled binaries

The two available implementations mentioned above are **OMPython.*_omc**, which drives a full OpenModelica
installation by sending commands to an OMC server, and **OMPython.*_runner**, which only executes a
previously compiled model executable and therefore runs without OMC / ZeroMQ.

The following documentation is based on current OMPython version, which contains a compatibility layer supporting the
main interface of OMPython v4.0.0. During a transition period, both options are available. The main
differences between both interfaces as well as the limitations of the compatibility layer are described in
:ref:`compatibility`.

.. _om_session:

Session Classes
---------------

OMPython provides a set of classes named :code:`OMCSession*`. All of them use ZeroMQ to
communicate with the OpenModelica Compiler (OMC) and they all offer the same interface, see
:ref:`om_session_api`. The following options exist:

-  :code:`OMCSessionLocal(timeout=None, omhome=None)` - the default; it starts an :code:`omc` server as a
   child process of the current Python process. :code:`omhome` is the OpenModelica installation directory,
   i.e. the directory which contains :code:`bin/omc`. If it is not given, the installation is looked up in
   the :code:`OPENMODELICAHOME` environment variable, and then via the :code:`omc` command in
   :code:`PATH`.

   .. code-block:: python

     import OMPython
     # the installation is looked up in $OPENMODELICAHOME and then in $PATH
     omc = OMPython.OMCSessionLocal()
     # or select the installation explicitly; a longer timeout for slow operations
     omc = OMPython.OMCSessionLocal(omhome="/opt/openmodelica", timeout=600)

-  :code:`OMCSessionPort(omc_port, timeout=None)` - connects to an already running OMC server.
   :code:`omc_port` is the connection string which the server reports, for example :code:`tcp://127.0.0.1:41613`.

   .. code-block:: python

     import OMPython
     # start the server separately, e.g. in another terminal:
     #   omc --interactive=zmq
     #   port   ->  "tcp://127.0.0.1:41613"
     omc = OMPython.OMCSessionPort(omc_port="tcp://127.0.0.1:41613")
     print(omc.get_port())
     print(omc.sendExpression("getVersion()"))

-  :code:`OMCSessionDocker(timeout=None, docker=None, dockerExtraArgs=None, dockerOpenModelicaPath="omc", dockerNetwork=None, port=None)`
   - runs the OMC server in a Docker container. :code:`docker` is the image to use,
   :code:`dockerOpenModelicaPath` the path of :code:`omc` within the image and :code:`port` the port to
   connect to. The container is started by OMPython and removed again when the session ends. This is the
   recommended way to get a reproducible compiler environment, independent of the Python installation.

   .. code-block:: python

     import OMPython
     omc = OMPython.OMCSessionDocker(docker="openmodelica/openmodelica:v1.27.0-ompython")
     print(omc.sendExpression("getVersion()"))
     print(omc.get_docker_container_id())

-  :code:`OMCSessionDockerContainer(timeout=None, dockerContainer=None, dockerExtraArgs=None, dockerOpenModelicaPath="omc", dockerNetwork=None, port=None)`
   - runs the OMC server in an already existing Docker container which is identified by
   :code:`dockerContainer`, i.e. by its container ID. In contrast to :code:`OMCSessionDocker`, the
   container is not removed when the session is closed.

   .. code-block:: python

     import OMPython
     # a long living container, e.g. started via "docker run -d <image> sleep infinity"
     container_id = "b1e4e6a0f7c2"

     omc = OMPython.OMCSessionDockerContainer(dockerContainer=container_id)
     print(omc.sendExpression("getVersion()"))
     print(omc.get_docker_container_id())

     # alternatively, reuse the container of an OMCSessionDocker instance
     omc_docker = OMPython.OMCSessionDocker(docker="openmodelica/openmodelica:v1.27.0-ompython")
     omc_inner = OMPython.OMCSessionDockerContainer(dockerContainer=omc_docker.get_docker_container_id())
     print(omc_inner.sendExpression("getVersion()"))

   Each session starts its own :code:`omc` server inside the given container, so several sessions can work
   with the same container without interfering. The container survives the session, which makes this the
   session of choice for repeated runs against a fixed compiler environment.

-  :code:`OMCSessionWSL(timeout=None, wsl_omc="omc", wsl_distribution=None, wsl_user=None)` - runs the
   OMC server within the Windows Subsystem for Linux. The distribution and the user can be selected;
   :code:`wsl_omc` is the path of :code:`omc` within the WSL environment.

   .. code-block:: python

     import OMPython
     omc = OMPython.OMCSessionWSL()
     print(omc.sendExpression("getVersion()"))

-  :code:`OMSessionRunner(ompath_runner=OMPathRunnerLocal, timeout=None, version="1.27.0", cmd_prefix=None, model_execution_local=True)`
   - the runner session described in :ref:`modelica_system_runner`; it runs a pre-compiled model
   executable directly, without using OMC at all. :code:`ompath_runner` selects how the paths are
   resolved, either locally (:code:`OMPathRunnerLocal`) or via a remote shell
   (:code:`OMPathRunnerBash`), and :code:`cmd_prefix` is the command prefix needed to enter that
   environment.

   .. code-block:: python

     import OMPython

     # a model executable which runs on the local machine
     runner = OMPython.OMSessionRunner(version="1.27.0")
     mod = OMPython.ModelicaSystemRunner(session=runner, work_directory="/path/to/build_dir")
     mod.setup(model_name="BouncingBall")
     mod.simulate()

     # a model executable which runs inside a Docker container; the command prefix is taken
     # from the Docker session which built the model
     docker_omc = OMPython.OMCSessionDocker(docker="openmodelica/openmodelica:v1.27.0-ompython")
     runner = OMPython.OMSessionRunner(
         version=docker_omc.get_version(),
         cmd_prefix=docker_omc.model_execution_prefix(cwd="/path/to/build_dir"),
         ompath_runner=OMPython.OMPathRunnerBash,
         model_execution_local=False,
     )
     mod = OMPython.ModelicaSystemRunner(session=runner, work_directory="/path/to/build_dir")

   Since no compiler is involved, the version passed to the constructor is only reported by
   :code:`get_version()`; it does not have to match any real OMC server.

All sessions accept a :code:`timeout` argument; see :ref:`om_session_api`.

The handling of any paths within the communication is covered by the :code:`OMCPath` class. It is an
implementation based on :code:`pathlib` which uses OMC to run the different filesystem related
commands. Therefore, it can be used also for remote / separated systems like docker or WSL. Because
all paths are resolved by OMC and not by the local Python process, a path created via
:code:`omc.omcpath(...)` always refers to the file system seen by OMC, which is not necessarily the
file system of the Python process. See :ref:`omc_path` for details.

To test the command outputs, simply create an :code:`OMCSessionLocal` object by importing from the
OMPython library within the Python interpreter. The module allows you to interactively send commands
to the OMC server and display their output.

To get started, create an :code:`OMCSessionLocal` object:

>>> import OMPython
>>> omc = OMPython.OMCSessionLocal()

.. omc-mos ::
  :ompython-output:
  :parsed:
  :clear:

  getVersion()
  cd()
  loadModel(Modelica)
  loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/BouncingBall.mo")
  instantiateModel(BouncingBall)

We get the name and other properties of a class:

.. omc-mos ::
  :ompython-output:
  :parsed:

  getClassNames()
  isPartial(BouncingBall)
  isPackage(BouncingBall)
  isModel(BouncingBall)
  checkModel(BouncingBall)
  getClassRestriction(BouncingBall)
  getClassInformation(BouncingBall)
  getConnectionCount(BouncingBall)
  getInheritanceCount(BouncingBall)
  getComponentModifierValue(BouncingBall,e)
  checkSettings()

The common combination of a simulation followed by getting a value and
doing a plot:

.. omc-mos ::
  :ompython-output:
  :parsed:

  simulate(BouncingBall, stopTime=3.0)
  val(h , 2.0)

Import As Library
^^^^^^^^^^^^^^^^^

To use the module from within another python program, simply import the selected :code:`OMCSession*`
class from within the selected program.

For example:

.. code-block:: python

  # test.py
  import OMPython
  omc = OMPython.OMCSessionLocal()
  cmds = [
    'loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/BouncingBall.mo")',
    "simulate(BouncingBall)",
    "plot(h)",
    ]
  for cmd in cmds:
    answer = omc.sendExpression(cmd)
    print("\n{}:\n{}".format(cmd, answer))

.. _om_session_api:

Session API
~~~~~~~~~~~

All :code:`OMCSession*` classes derive from :code:`OMCSessionABC` and share the same interface. The
following methods are available on every OMC based session.

:code:`sendExpression(expr, parsed=True, raise_on_error=True)` is the central method. It sends
:code:`expr` to the OMC server and returns the result, converted into a Python object by the parser
described in :ref:`parser`. Some typical usages are:

.. code-block:: python

  omc.sendExpression("getVersion()")
  omc.sendExpression("getClassNames()")

The :code:`parsed` argument controls whether the returned string is run through the parser. Set it to
:code:`False` whenever you need the exact string that OMC produced, for example when you want to
post-process the output yourself. The two calls which return free text which cannot be parsed,
:code:`getErrorString()` and :code:`getMessagesStringInternal()`, always return the raw string and log
a warning if :code:`parsed=True` was requested. :code:`quit()` closes the connection and returns
:code:`None`; it is called automatically when the session object is deleted.

By default, :code:`sendExpression()` raises an :code:`OMSessionException` if OMC emitted an
:code:`error`-level diagnostic during the call. Some OMC API calls, notably :code:`buildModel`, can
emit error-level diagnostics which are recoverable and do not actually prevent the call from
succeeding. If your code has its own, more precise way of verifying success - for example by checking
that the expected files were created - pass :code:`raise_on_error=False` to log those messages
instead of raising an exception:

.. code-block:: python

  try:
    omc.sendExpression("loadModel(Modelica)")
  except OMPython.OMSessionException as ex:
    print("Modelica could not be loaded:", ex)

The remaining session methods are:

-  :code:`get_version()` returns the version of the connected OMC server as a string.

-  :code:`set_timeout(timeout=None)` sets the timeout which is used when waiting for an answer of the
   OMC server or for the model executable, and returns the timeout which was in effect before the
   call. The value of zero or less raises an :code:`OMSessionException`.
   Passing :code:`None` changes nothing, which makes :code:`set_timeout()` a getter.

-  :code:`set_workdir(workdir)` changes the working directory of the OMC server, i.e. the directory
   subsequent relative paths are resolved against. It is a no-op for :code:`OMSessionRunner`.

-  :code:`omcpath(*path)` creates an :code:`OMCPath` object, see :ref:`omc_path`.

-  :code:`omcpath_tempdir(tempdir_base=None)` creates a uniquely named temporary directory as
   :code:`OMCPath`. If :code:`tempdir_base` is given, the directory is created inside that directory.
   This is how :code:`ModelicaSystem` obtains its private build directory.

-  :code:`get_cmd_prefix()` returns the command prefix needed to run commands in the environment
   which is defined by the session.

-  :code:`escape_str(value)` escapes a string so that it can be embedded into an OMC expression: all
   backslashes and double quotes are escaped. Use it whenever you interpolate user data into a command.

In addition, the OMC based sessions provide :code:`get_port()` which returns the ZeroMQ address of the
OMC server and :code:`get_log()` which returns the content of the OMC server log file, and the Docker
based sessions provide :code:`get_server_address()` and :code:`get_docker_container_id()`.
:code:`OMSessionRunner` provides none of them, and its :code:`sendExpression()` always raises an
:code:`OMSessionException`.

.. _omc_path:

File and directory access
~~~~~~~~~~~~~~~~~~~~~~~~~

The :code:`OMCPath` class gives you a :code:`pathlib`-like interface to the file system which OMC
sees. This is important when OMC does not run on the local machine, e.g. inside a Docker container
or in WSL - in that case the Python process and OMC do not share a file system, and a plain
:code:`pathlib.Path` would silently operate on the wrong files.

Paths are always created via the session they belong to, so that the correct backend is used:

.. code-block:: python

  import OMPython
  omc = OMPython.OMCSessionDocker(docker="openmodelica/openmodelica:v1.27.0-ompython")
  mo_file = omc.omcpath("/work") / "BouncingBall.mo"
  mo_file.write_text('model BouncingBall end BouncingBall;')
  print(mo_file.is_file())
  print(mo_file.read_text())
  print(mo_file.size())

The following methods are available. They all have the same names and semantics as their
:code:`pathlib.Path` counterparts:

-  :code:`is_file()` and :code:`is_dir()` check the type of the path.

-  :code:`exists()` is a shorthand for :code:`is_file() or is_dir()`.

-  :code:`is_absolute()` checks whether the path is absolute. Windows and POSIX conventions are
   distinguished based on the environment defined by the session.

-  :code:`read_text()` and :code:`write_text(data)` read and write the file content. Both are always
   UTF-8 encoded; the other arguments of the :code:`pathlib` methods are ignored.

-  :code:`mkdir()` creates a directory. An existing directory raises a :code:`FileExistsError` unless
   :code:`exist_ok=True` is given.

-  :code:`unlink()` deletes the file or the empty directory. A path which does not exist raises a
   :code:`FileNotFoundError` unless :code:`missing_ok=True` is given.

-  :code:`resolve()` and :code:`absolute()` convert a relative path into an absolute one. The path has
   to exist, because OMC can only resolve existing paths.

-  :code:`cwd()` returns the current working directory of OMC.

-  :code:`size()` returns the file size in bytes. It raises an :code:`OMSessionException` if the path
   is not a file.

-  :code:`get_session()` returns the session this path belongs to.

The path arithmetic of :code:`pathlib` - the :code:`/` operator, :code:`.parent`, :code:`.name`,
:code:`.stem`, :code:`.suffix` and :code:`.as_posix()` - is inherited unchanged and needs no OMC call.

.. _modelica_system:

Modelica System Classes
-----------------------

The ModelicaSystem class adds more functionality to OMPython. It provides methods to query information
about models, to modify data (parameters, inputs, ...) and to simulate them. The corresponding API is
described below.

Two implementations are available:

-  :code:`ModelicaSystemOMC` compiles the model with OMC and can therefore do everything the
   OpenModelica compiler can do. This is the default choice and the one described below.

-  :code:`ModelicaSystemRunner` only runs an already compiled model executable. It needs no OMC at
   runtime, see :ref:`modelica_system_runner`.

To get started, create a ModelicaSystem object:

>>> import OMPython
>>> mod = OMPython.ModelicaSystemOMC()

The constructor for a :code:`ModelicaSystemOMC` object creates an :code:`OMCSessionLocal` by default.
If this is not desired or additional configuration is needed, several options exist:

-  :code:`command_line_options` (optional) - a list of additional command line options for OMC. The
   list elements are provided to OMC via :code:`setCommandLineOptions()`. If the option is set, the
   default command line options of OMC are overridden; pass an empty list to disable all of them.
   The default of OMPython itself sets :code:`--linearizationDumpLanguage=python` and
   :code:`--generateSymbolicLinearization`, which make :code:`linearize()` fast and let the model
   executable be reused for a linearization:

-  :code:`work_directory` (optional) - the directory which is used for the model build and for
   temporary files such as the model executable and the result file. If it is not given, a unique
   temporary directory is created for the instance, see :ref:`modelica_system_workdir`.

-  :code:`omhome` (optional) - the OpenModelica installation directory, i.e. the directory which
   contains :code:`bin/omc`. It is only used when the session is created, so it has no effect in
   combination with :code:`session`. If it is not given, the directory is taken from the
   :code:`OPENMODELICAHOME` environment variable, and otherwise derived from the :code:`omc` command
   in :code:`PATH`.

-  :code:`session` (optional) - an existing session to use. This is the way to combine
   :code:`ModelicaSystem` with a Docker, WSL or port based session:

>>> docker_omc = OMPython.OMCSessionDocker(docker="openmodelica/openmodelica:v1.27.0-ompython")
>>> mod = OMPython.ModelicaSystemOMC(session=docker_omc)

After a ModelicaSystem object is created, the model can be defined:

>>> model_path = mod.get_session().sendExpression("getInstallationDirectoryPath()") + "/share/doc/omc/testmodels/"
>>> mod.model(model_name="BouncingBall", model_file=model_path + "BouncingBall.mo")

The class method :code:`model()` allows several arguments:

-  :code:`model_name` - The model name (as string). If the model is wrapped within a Modelica
   package, the namespace must also be included, e.g. :code:`"MyPackage.BouncingBall"`.

-  :code:`model_file` - the path where to find the model file, either absolute or relative to the
   current working directory. The file should use the Modelica file extension ".mo". Because the path
   is resolved by OMC, a relative path refers to the working directory of the session, not to the
   working directory of the Python process.

-  :code:`libraries` - A third input argument (optional) is used to specify the list of dependent
   libraries or dependent Modelica files. Here, it is possible to just provide the library name or a
   tuple of library name and version. The libraries are loaded before the model itself is loaded:

>>> mod.model(model_name="BouncingBall", model_file=model_path + "BouncingBall.mo", libraries=["Modelica"])
>>> mod.model(model_name="BouncingBall", model_file=model_path + "BouncingBall.mo", libraries=[("Modelica","3.2.3"), "PowerSystems"])

-  :code:`variable_filter` - Optional string which sets a filter for the output variables. It is
   defined as a regular expression. Only variables fully matching the regexp will be stored in the
   result file. Leaving it unspecified is equivalent to ".*". A filter can also be changed later
   using :code:`set_variable_filter()`.

-  :code:`build` - Optional boolean controlling whether the model should be built when
   :code:`model()` is called. If False, the model is only loaded and :code:`buildModel()` has to be
   called before the model can be simulated.

Build Model
~~~~~~~~~~~

The :code:`buildModel()` API can either directly be executed on model definition (see above) or be
called separately.

>>> mod.buildModel()

It accepts an optional :code:`variableFilter` argument which sets the regular expression filter for
the variables to be stored in the result file; without it the filter of :code:`model()` or
:code:`set_variable_filter()` is used, and if that is unset as well then :code:`".*"`.
:code:`buildModel()` translates the changes which were applied via :code:`sendExpression()` - for
example a changed parameter of the model - into a new build, and afterwards verifies that the model
executable and the initialization file were really produced. If you only change parameters, input
values or simulation options, you do not need to rebuild the model; just call :code:`simulate()`
again.

The following methods give direct access to the underlying OMC session, and to the identity of the
model which is currently defined:

-  :code:`get_session()` returns the session which is used by this instance.

-  :code:`get_model_name()` returns the name of the model which was defined via :code:`model()`.

-  :code:`sendExpression(expr, parsed=True, raise_on_error=True)` is a wrapper for
   :code:`OMCSession*.sendExpression()`.

-  :code:`set_command_line_options(command_line_option)` sets a command line option for OMC via
   :code:`setCommandLineOptions()`. Call :code:`buildModel()` afterwards for it to take effect.

.. _modelica_system_workdir:

The work directory
~~~~~~~~~~~~~~~~~~

Every :code:`ModelicaSystem` instance owns a work directory. The model is built in that directory and
all files which are produced by the instance - the model executable, the generated C code, the
simulation result file and the input CSV file - are placed there.

-  :code:`getWorkDirectory()` returns the directory as an :code:`OMCPath` object.

-  :code:`setWorkDirectory(work_directory=None)` changes the work directory. If called without
   argument, a new unique temporary directory is created.

.. code-block:: python

  mod = OMPython.ModelicaSystemOMC(work_directory="/tmp/my_build_dir")
  mod.model(model_name="BouncingBall", model_file="BouncingBall.mo")
  print(mod.getWorkDirectory())

Because the work directory is unique per instance, one :code:`ModelicaSystem` instance corresponds
to one model build. If you need several independent simulations of the same model, create one
instance per simulation.

Standard get methods
~~~~~~~~~~~~~~~~~~~~

The following methods read values from the currently defined model:

-  :code:`getQuantities(names=None)` - a list of dictionaries describing every variable of the model.

-  :code:`getParameters(names=None)` - the parameter values.

-  :code:`getInputs(names=None)` - the input signal values.

-  :code:`getContinuous(names=None)` - the values of the continuous signals.

-  :code:`getContinuousInitial(names=None)` and :code:`getContinuousFinal(names=None)` - the values of
   the continuous signals before and after the simulation.

-  :code:`getOutputs(names=None)` - the values of the outputs.

-  :code:`getOutputsInitial(names=None)` and :code:`getOutputsFinal(names=None)` - the values of the
   outputs before and after the simulation.

-  :code:`getSimulationOptions(names=None)`, :code:`getLinearizationOptions(names=None)` and
   :code:`getOptimizationOptions(names=None)` - the options of the respective simulation mode.

-  :code:`getLinearInputs()`, :code:`getLinearOutputs()` and :code:`getLinearStates()` - plain lists of
   the variable names which are used for linearization. These take no argument at all.

-  :code:`getSolutions(varList=None, resultfile=None)` - the simulation results, see below.

All of them except the three linearization name lists and :code:`getSolutions()` accept the same three
forms of the :code:`names` argument:

-  :code:`getParameters()` - no argument; returns a dictionary which maps names to values.

-  :code:`getParameters("c")` - a single name; returns a list with the one value.

-  :code:`getParameters(["c", "radius"])` - a list of names; returns a list of values in the order in
   which the names were requested.

The name has to exist, otherwise a :code:`KeyError` is raised. The one exception is a list of
names, where a name which does not exist is silently skipped. The type of the returned values
depends on the method:

-  :code:`getParameters()`, :code:`getSimulationOptions()`, :code:`getLinearizationOptions()` and
   :code:`getOptimizationOptions()` always return strings, because a parameter or an option value can be
   an arbitrary Modelica expression which has not been evaluated yet. Note that even numerical option
   values such as :code:`tolerance` are strings. Use :code:`float()` if you need a number.

-  :code:`getQuantities()` returns one dictionary per requested variable, with the keys :code:`alias`,
   :code:`aliasvariable`, :code:`causality`, :code:`changeable`, :code:`description`, :code:`max`,
   :code:`min`, :code:`name`, :code:`start`, :code:`unit` and :code:`variability`.

-  :code:`getInputs()` returns the :code:`start` attribute of the input as a string while the model has
   not been changed, and a list of :code:`(time, value)` tuples after :code:`setInputs()` was called.

-  :code:`getContinuous()`, :code:`getOutputs()` and their :code:`Initial`/:code:`Final` variants return
   :code:`numpy.float64` values, or :code:`None` for a variable which has no start value, for example a
   derivative such as :code:`der(height)`.

Note the difference between the initial and the final variants: before a simulation, :code:`getContinuous()`
and :code:`getOutputs()` return the initial values, after a simulation the values at :code:`stopTime`. The
explicit variants only ever return the initial respectively the final values, and the final ones raise a
:code:`ModelicaSystemError` if no simulation was run.

Usage of getMethods
~~~~~~~~~~~~~~~~~~~

The examples below show a BouncingBall model, once defined and built but not yet simulated, and once
after :code:`simulate()` was called.

.. code-block:: python

  >>> mod.getQuantities()
  [{'alias': 'noAlias', 'aliasvariable': None, 'causality': 'local',
    'changeable': 'true', 'description': None, 'max': None, 'min': None,
    'name': 'height', 'start': '1.0', 'unit': None, 'variability': 'continuous'},
   # ...

  >>> mod.getQuantities("height")
  [{'alias': 'noAlias', 'aliasvariable': None, 'causality': 'local',
    'changeable': 'true', 'description': None, 'max': None, 'min': None,
    'name': 'height', 'start': '1.0', 'unit': None, 'variability': 'continuous'}]

  >>> mod.getQuantities(["c", "radius"])
  [{'alias': 'noAlias', ..., 'name': 'c', 'start': '0.9', ..., 'variability': 'parameter'},
   {'alias': 'noAlias', ..., 'name': 'radius', 'start': '0.1', ..., 'variability': 'parameter'}]

  >>> mod.getParameters()
  {'c': '0.9', 'radius': '0.1'}

  >>> mod.getParameters(["c", "radius"])
  ['0.9', '0.1']

  >>> mod.getContinuous()
  {'height': 1.0, 'der(height)': None, 'velocity': 0.0, 'der(velocity)': None}

  >>> mod.getContinuous(["velocity", "height"])
  [0.0, 1.0]

  >>> mod.getInputs()
  {}

  >>> mod.getOutputs()
  {}

  >>> mod.getSimulationOptions()
  {'startTime': '0.0', 'stopTime': '2.0', 'stepSize': '0.002', 'tolerance': '1e-06',
   'solver': 'dassl', 'outputFormat': 'mat'}

  >>> mod.getSimulationOptions(["stepSize", "tolerance"])
  ['0.002', '1e-06']

An empty dictionary here is correct: :code:`BouncingBall` has no inputs and no outputs, because
:code:`height` has the causality :code:`local`. Use :code:`getQuantities("height")` to see the
causality of a variable, and :code:`getContinuous()` for its value.

After a simulation, :code:`getContinuous()` and :code:`getOutputs()` return the values at
:code:`stopTime`:

.. code-block:: python

  >>> mod.simulate()
  >>> mod.getContinuous()
  {'height': 0.6590703905294362, 'der(height)': -1.825929609047952,
   'velocity': -1.825929609047952, 'der(velocity)': -9.81}

  >>> mod.getContinuousFinal("height")
  [0.6590703905294362]

The :code:`getSolutions()` method can be used in two different ways:

-  Without a :code:`varList` it returns the names of the variables for which results are available.

-  With a :code:`varList` it returns the data itself, as a two dimensional :code:`numpy` array with one
   row per variable and one column per time point.

If no :code:`resultfile` is given, the result file of the last :code:`simulate()` call is used. This
makes it possible to read results of an earlier simulation, and to compare simulations and perform
regression testing:

.. code-block:: python

  >>> mod.getSolutions()
  ('time', 'height', 'velocity', 'der(height)', 'der(velocity)', 'c', 'radius')

  >>> mod.getSolutions(["time", "height"])
  array([[0.000e+00, 5.000e-04, 1.000e-03, ..., 2.000e+00],
         [1.000e+00, 9.999e-01, 9.997e-01, ..., 6.591e-01]])

  >>> mod.getSolutions(["time", "height"], resultfile="/tmp/other_run.mat")

The method :code:`plot(plotdata, resultfile=None)` passes the given expression to the plotting facility
of OMC, for example :code:`mod.plot("height")`. Because OMC itself creates the plot, it only works if
the session is an :code:`OMCSessionLocal`; Docker and WSL sessions have no access to a display.

Standard set methods
~~~~~~~~~~~~~~~~~~~~

The following methods change the values of the currently defined model:

- :code:`setParameters()` sets the values of model parameters.

- :code:`setContinuous()` sets the initial values of continuous variables.

- :code:`setSimulationOptions()`, :code:`setLinearizationOptions()` and
  :code:`setOptimizationOptions()` set the options of the respective simulation mode.

- :code:`setInputs()` sets the time based input signals of the model, see below.

All of them take keyword arguments, i.e. the values are provided as a dictionary, and return
:code:`True` if the values were accepted. A name which does not exist, or which belongs to a different
kind of variable, raises a :code:`ModelicaSystemError`. The values are stored as strings, because a
Modelica parameter can be an arbitrary expression which has not been evaluated yet:

.. code-block:: python

  mod.setParameters(radius=14)
  mod.setParameters(radius=14, c=0.5)
  mod.setParameters(**{"radius": 14, "c": 0.5})

Additionally, the following helper methods are available:

- :code:`isParameterChangeable(name)` returns whether the parameter can be changed without
  recompiling the model, i.e. whether its :code:`changeable` attribute is not :code:`false`. A parameter
  is not changeable if it is structural, final, protected, evaluated or has a non-constant binding.

- :code:`set_variable_filter(variable_filter=None, escape=False)` sets the regular expression which
  selects the variables to be stored in the result file. With :code:`escape=True` all regular
  expression special characters in the filter are escaped, so that a literal string can be used. An
  invalid regular expression raises a :code:`ModelicaSystemError`, and :code:`None` removes the filter.

- :code:`toInputs(data)` converts a dictionary of lists - as returned by
  :code:`pandas.DataFrame.to_dict(orient='list')` - into the input format used by
  :code:`setInputs()`. The dictionary must contain a :code:`time` key.

- :code:`setInputsCSV(csvfile)` reads the time based input data from a CSV file. The file has to
  contain a header row, the first column is used as time, and the header of the remaining columns
  defines the input names. Note that this file is read by the local Python process, so the path has to
  be a local path even if the session itself is a Docker, WSL or port based one. The method returns
  :code:`None`.

Usage of setMethods
~~~~~~~~~~~~~~~~~~~

.. code-block:: python

  >>> mod.setInputs(cAi=1, Ti=2)            # set constant input signals

  >>> mod.setParameters(radius=14)           # set one parameter

  >>> mod.setParameters(radius=14, c=0.5)    # set several parameters at once

  >>> mod.setContinuous(height=2.0)          # set an initial value of a continuous variable

  >>> mod.setSimulationOptions(stopTime=2.0, tolerance=1e-08)

The input signals are the one exception to the "value as string" rule of the other set methods. A
value may be given as a single number, which is then held constant over the whole simulation, or as
a list of (time, value) tuples, which defines a piecewise linear signal. The time values have to be in
increasing order and must not be smaller than :code:`startTime`:

.. code-block:: python

  >>> mod.setSimulationOptions(startTime=0.0, stopTime=2.0)
  >>> mod.setInputs(u=[(0.0, 0.0), (1.0, 1.0), (2.0, 0.5)])
  >>> mod.setInputs(u=0.5)                   # constant over [0.0, 2.0]

Simulation
~~~~~~~~~~

An example of how to get parameter names and change the value of parameters using set methods and
finally simulate the "BouncingBall.mo" model is given below.

.. code-block:: python

  >>> mod.getParameters()
  {'c': '0.9', 'radius': '0.1'}

  >>> mod.setParameters(radius=14, c=0.5)

To check whether new values are updated to the model, we can again query getParameters().

.. code-block:: python

  >>> mod.getParameters()
  {'c': '0.5', 'radius': '14'}

Note that the values are strings, so the order of the dictionary is not sorted and the values have to
be compared as strings.

The model can be simulated using the :code:`simulate` API in the following ways:

-  without any arguments,

-  with a :code:`resultfile` keyword argument,

-  with a :code:`simargs` keyword argument, i.e. runtime simulation flags supported by OpenModelica.

.. code-block:: python

  >>> mod.simulate()      # default result file name will be used
  >>> mod.simulate(resultfile="tmpbouncingBall.mat")
  >>> mod.simulate(simargs={"noEventEmit": None, "noRestart": None, "override": {"e": 0.3, "g": 10}})

All changes which were made via the set methods - parameters, continuous values, simulation options
and inputs - are passed to the model executable as command line arguments when :code:`simulate()`
is called. :code:`override` is a special key: it takes a dictionary of variable names and values
which is translated into the corresponding :code:`-override` runtime flag. Setting an override value
to :code:`None` removes it again. The remaining keys of :code:`simargs` are the runtime flags of the
compiled model, where a key without value (:code:`None`) becomes a flag and a key with a value
becomes :code:`-key=value`.

Note that the :code:`simargs` dictionary is passed on unchanged, i.e. it is not validated against
the model. An unknown key results in an error from the model executable, which OMPython reports as
a :code:`ModelicaSystemError`.

:code:`simulate()` returns nothing on success. The result file is available in the work directory
under the name :code:`<model_name>_res.mat`, unless a :code:`resultfile` was given.

If you only need the command line of a simulation - for example to run it later, on a different
machine, or in parallel - use :code:`simulate_cmd()` instead of :code:`simulate()`. It applies all
pending changes and returns a :code:`ModelExecutionConfig` object, see :ref:`model_execution`, which
can be turned into a runnable command:

.. code-block:: python

  from OMPython import ModelExecutionConfig

  cmd = mod.simulate_cmd(result_file=mod.getWorkDirectory() / "MyRes.mat",
                         simargs={"noRestart": None})
  execution = cmd.definition()   # -> ModelExecutionRun
  print(" ".join(execution.get_cmd()))
  returncode = execution.run()    # run the simulation

:code:`simulate_cmd()` is the basis of the DoE functionality, see :ref:`modelica_doe`.

Linearization
~~~~~~~~~~~~~

The following methods are used for linearization.

- linearize()
- getLinearizationOptions()
- setLinearizationOptions()
- getLinearInputs()
- getLinearOutputs()
- getLinearStates()

.. code-block:: python

  >>> mod.getLinearizationOptions()
  {'startTime': '0.0', 'stopTime': '1.0', 'stepSize': '0.002', 'tolerance': '1e-08'}

  >>> mod.getLinearizationOptions(["startTime", "stopTime"])
  ['0.0', '1.0']

  >>> mod.setLinearizationOptions(stopTime=2.0, tolerance=1e-06)

  >>> mod.linearize()      # returns a LinearizationResult object

  >>> mod.getLinearInputs()    # list of the input names used when forming the matrices
  ['u']

  >>> mod.getLinearOutputs()   # list of the output names used when forming the matrices
  ['y']

  >>> mod.getLinearStates()    # list of the state names used when forming the matrices
  ['x']

:code:`linearize()` accepts an optional :code:`lintime` argument to override the :code:`stopTime`
of the linearization, and an optional :code:`simargs` argument to pass runtime flags such as an
input file:

.. code-block:: python

  mod.linearize(lintime=2.0)
  mod.linearize(simargs={"csvInput": "my_input.csv"})

The returned :code:`LinearizationResult` can be used in three ways, depending on how much
information you need:

.. code-block:: python

  # (a) unpack just the matrices
  A, B, C, D = mod.linearize()

  # (b) access all attributes by name
  result = mod.linearize()
  print(result.A, result.B, result.C, result.D)
  print(result.n, result.m, result.p)          # number of states, inputs, outputs
  print(result.x0, result.u0)                  # fixed point and the input at the fixed point
  print(result.stateVars, result.inputVars, result.outputVars)

  # (c) index access, for backwards compatibility with the tuple which linearize() returned before
  A = mod.linearize()[0]

Optimization
~~~~~~~~~~~~

Besides simulating and linearizing a model, :code:`ModelicaSystemOMC` can also run a
model-based optimization. The optimization problem is defined in the model itself via an
:code:`optimize` algorithm annotation; :code:`ModelicaSystem` only controls the simulation options of
that run.

.. code-block:: python

  >>> mod.getOptimizationOptions()
  {'startTime': '0.0', 'stopTime': '1.0', 'numberOfIntervals': '500',
   'stepSize': '0.002', 'tolerance': '1e-08'}

  >>> mod.setOptimizationOptions(stopTime=2.0, numberOfIntervals=1000)

  >>> mod.optimize()

:code:`optimize()` returns a dictionary. Besides the path to the result file, it contains the
options which were used and the time which was spent in the different compilation and simulation
phases:

.. code-block:: python

  result = mod.optimize()
  print(result['resultFile'])
  print(result['simulationOptions'])  # -> startTime = 0.0, stopTime = 1.0, ...
  print(result['timeFrontend'], result['timeTotal'])

Note that :code:`optimize()` sets the compiler flag :code:`-g=Optimica` via
:code:`set_command_line_options()` in order to generate the simulation code of the optimization
problem. The flag stays set, so a model which was optimized once keeps the Optimica backend for all
following :code:`buildModel()` calls of the same instance.

Reading the result file works in the same way as after a simulation:

.. code-block:: python

  mod.getSolutions(resultfile=result['resultFile'])
  mod.getSolutions("y", resultfile=result['resultFile'])

Plotting
~~~~~~~~

:code:`plot(plotdata, resultfile=None)` forwards the plot to the OMC :code:`plot()` API call and
displays the result in the plot window of the OMC installation:

.. code-block:: python

  mod.plot("height")

Because the plot is rendered by OMC, which needs access to a local display, :code:`plot()` only
works for a local session. It is not available when the session runs OMC in Docker or in WSL. To
plot results in that case, read them with :code:`getSolutions()` and plot them with the plotting
library of your choice.

.. _modelica_system_runner:

Running a pre-compiled model
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If the model has already been compiled elsewhere and you only want to run the resulting executable -
for example on a machine without an OpenModelica installation, inside a CI job, or in a container
image which only contains the model binary - use :code:`ModelicaSystemRunner`. It does not need an
OMC server and does not use ZeroMQ.

.. code-block:: python

  import OMPython

  mod = OMPython.ModelicaSystemRunner(work_directory="/path/to/build_dir")
  mod.setup(model_name="BouncingBall", variable_filter=".*")
  mod.setParameters(radius=14, c=0.5)
  mod.setSimulationOptions(stopTime=2.0)
  mod.simulate()
  print(mod.getWorkDirectory() / "BouncingBall_res.mat")

:code:`setup()` replaces :code:`model()` because there is nothing to load or to compile. It expects
the files which OMC produced for the model to be present in the work directory, which must be
passed via the :code:`work_directory` argument of the constructor:

-  the model executable, either as :code:`<model_name>` or :code:`<model_name>.exe`. On Windows an
   additional :code:`<model_name>.bat` file is expected; OMPython reads the library path from it.

-  the model initialization file :code:`<model_name>_init.xml`, which provides the model structure.
   The quantities of the model - and therefore all get methods - are read from this file.

The constructor also accepts a :code:`session` argument, but it has to be an :code:`OMSessionRunner`;
any other session raises a :code:`ModelicaSystemError`, because running a model executable does not
need a compiler.

All get and set methods, :code:`simulate()`, :code:`simulate_cmd()` and :code:`linearize()` behave as
described above. The methods which need OMC are not available on this class, because they are defined
in :code:`ModelicaSystemOMC` only. This affects:

An :code:`ModelicaSystemRunner` instance cannot be reused for a second model; a second call of
:code:`setup()` raises a :code:`ModelicaSystemError`, so create a new instance instead.

.. _modelica_doe:

Design of Experiments
---------------------

A design of experiments (DoE) is a systematic way of running a model many times with different
parameter values, and of collecting the results. :code:`ModelicaDoE` takes a model which was defined
with :code:`ModelicaSystem` and expands a dictionary of parameter value lists into all combinations
of these values, runs the corresponding simulations, and reports which results are available where.

Two implementations are available, matching the two :code:`ModelicaSystem` implementations:

-  :code:`ModelicaDoEOMC` for a model defined by :code:`ModelicaSystemOMC`.

-  :code:`ModelicaDoERunner` for a model defined by :code:`ModelicaSystemRunner`.

The difference matters for the *structural* parameters, see below.

The following example defines a small model, varies four parameters and runs the resulting eight
simulations:

.. code-block:: python

  import OMPython
  import pathlib

  mypath = pathlib.Path('.')

  model = mypath / "M.mo"
  model.write_text(
      "model M\n"
      "  parameter Integer p=1;\n"
      "  parameter Integer q=1;\n"
      "  parameter Real a = -1;\n"
      "  parameter Real b = -1;\n"
      "  Real x[p];\n"
      "  Real y[q];\n"
      "equation\n"
      "  der(x) = a * fill(1.0, p);\n"
      "  der(y) = b * fill(1.0, q);\n"
      "end M;\n"
  )

  param = {
      # structural
      'p': [1, 2],
      'q': [3, 4],
      # non-structural
      'a': [5, 6],
      'b': [7, 8],
  }

  resdir = mypath / 'DoE'
  resdir.mkdir(exist_ok=True)

  mod = OMPython.ModelicaSystemOMC()
  mod.model(model_name="M", model_file=model.as_posix())
  doe_mod = OMPython.ModelicaDoEOMC(
      mod=mod,
      parameters=param,
      resultpath=resdir,
      simargs={"override": {'stopTime': 1.0}},
  )
  doe_mod.prepare()
  doe_def = doe_mod.get_doe_definition()
  doe_mod.simulate()
  doe_sol = doe_mod.get_doe_solutions()

The constructor of :code:`ModelicaDoEOMC` takes the following arguments:

-  :code:`mod` - the :code:`ModelicaSystemOMC` instance which holds the model. The type is checked, so
   a :code:`ModelicaSystemRunner` has to be combined with :code:`ModelicaDoERunner`.

-  :code:`parameters` - a dictionary which maps a parameter name to a list of values to be used for
   that parameter. All combinations of the lists are simulated, so the example above defines
   2x2x2x2 = 8 simulations. A name which does not exist in the model raises an error in
   :code:`prepare()`.

-  :code:`resultpath` - the directory in which the result files are stored. It has to exist already,
   because it is resolved but not created; otherwise a :code:`ModelicaSystemError` is raised. The
   default is a temporary directory.

-  :code:`simargs` - the runtime flags which are used for every simulation, in the same format as
   the :code:`simargs` argument of :code:`simulate()`.

Two further methods complete the interface: :code:`get_session()` returns the session in use and
:code:`get_resultpath()` returns the directory the results are written to. :code:`get_doe_command()`
returns the prepared simulations as a dictionary which maps each result file name to a
:code:`ModelExecutionRun` object, which is useful to run the DoE somewhere else; :code:`simulate()`
simply runs these commands in parallel.

The workflow always consists of the same four steps.

**1. prepare()** evaluates the parameters and builds the list of simulations. It returns the number
of simulations which were defined. This is the step which distinguishes the two implementations:

-  A *structural* parameter - for example an array size - changes the equations of the model, so
   the model has to be recompiled for every value it takes. :code:`prepare()` therefore creates one
   build per combination of the structural parameters.

-  A *non-structural* parameter - for example a resistance or a spring constant - does not change
   the equations. All of its values can be passed to the same model executable at runtime.

The two kinds are told apart with :code:`isParameterChangeable()`, so the classification is derived
from the model and not from the names in the :code:`parameters` dictionary.

For :code:`ModelicaDoEOMC` the structural parameters are handled by sending
:code:`setParameterValue()` to OMC and rebuilding the model for every combination, which is why a
DoE on structural parameters is comparatively slow. Note that :code:`prepare()` changes the work
directory of the :code:`ModelicaSystem` instance to the per-combination build directory, so do not
reuse that instance for something else afterwards.

:code:`ModelicaDoERunner` cannot recompile at all, so it can only vary non-structural parameters;
passing a structural parameter raises a :code:`ModelicaSystemError`.

**2. get_doe_definition()** returns the DoE as a dictionary, where each key is a result file name
and the value is a dictionary of the simulation settings, including the structural and non-structural
parameter values of that run. The three fixed keys of that dictionary are
:code:`DICT_ID_STRUCTURE`, :code:`DICT_ID_NON_STRUCTURE` and :code:`DICT_RESULT_AVAILABLE`; the last
one is set to :code:`True` by :code:`simulate()` for every run which produced a result file. The data
converts directly to a pandas dataframe:

.. code-block:: python

  import pandas as pd

  doe_df = pd.DataFrame.from_dict(data=doe_mod.get_doe_definition(), orient='index')
  print(doe_df)

**3. simulate(num_workers=3)** runs the simulations which were defined by :code:`prepare()`, using
the given number of worker threads. It returns :code:`True` if all simulations finished
successfully, and :code:`False` otherwise, so a partial failure does not abort your script. The
number of workers is a pure performance setting; increase it to use more CPU cores, and set it to
:code:`1` for a deterministic, easy to debug run. A simulation which fails is logged as a warning, so
enable the :code:`OMPython.modelica_doe_abc` logger to see the details. Calling :code:`simulate()`
without a preceding :code:`prepare()` raises a :code:`ModelicaSystemError`.

**4. get_doe_solutions(var_list=None)** is only available on :code:`ModelicaDoEOMC`, because it needs
OMC to read the result files. It returns a dictionary which maps each result file name to a
dictionary with the keys :code:`'msg'` and :code:`'data'`; the :code:`'data'` entry contains one numpy
array per variable. A run whose result file is missing or unreadable is reported in :code:`'msg'`
with an empty :code:`'data'` dictionary instead of raising, so a single failed simulation does not
cost you all results:

.. code-block:: python

  doe_sol = doe_mod.get_doe_solutions()
  # {'DOE_000000000_000000000.mat': {'msg': 'Simulation available',
  #                                 'data': {'time': array([...]), 'x': array([...])}},
  #  ...}

  doe_sol = doe_mod.get_doe_solutions(["time", "x"])   # restrict the variables

The underlying function :code:`OMPython.modelica_doe_omc.doe_get_solutions()` can also be called
directly, which is useful if the DoE definition is stored somewhere else. The data converts to a
pandas dataframe per run:

.. code-block:: python

  import pandas as pd

  for name, run in doe_sol.items():
      run['df'] = pd.DataFrame.from_dict(data=run['data']) if run['data'] else None

.. _model_execution:

Execute Compiled Models
-----------------------

Everything OMPython does with a simulation boils down to running the model executable. The module
:code:`OMPython.model_execution` implements this step, independently of OMC, and is therefore usable
on its own. It is the layer below :code:`ModelicaSystem.simulate()`, and it is what makes it
possible to run a model executable which lives in a different environment than the Python process.

ModelExecutionConfig
~~~~~~~~~~~~~~~~~~~~

:code:`ModelExecutionConfig` collects everything which is needed to run a compiled model: the
directory the model was built in, the command prefix needed to reach that environment, the model
name, and the command line arguments. Because the arguments are stored separately from the
environment, the same configuration can be inspected, modified and executed independently.

.. code-block:: python

  from OMPython import ModelExecutionConfig

  cmd = ModelExecutionConfig(
      runpath="/tmp/tmpxxxx",
      cmd_prefix=[],          # e.g. ['docker', 'exec', '--user', '1000', '<container_id>']
      cmd_local=True,         # is the environment the local one?
      cmd_windows=False,      # is the environment a Windows one?
      model_name="BouncingBall",
      timeout=300.0,          # optional, default is 300 s
  )

:code:`runpath`, :code:`cmd_prefix` and :code:`model_name` are required; :code:`model_name` is needed
because it determines the name of the executable and of the Windows batch file. Note that
:code:`runpath` has to be the path as seen from within the environment, so for a Docker or WSL
environment it is the path inside the container, not a local path.

The arguments are managed with four methods:

-  :code:`arg_set(key, val=None)` sets one argument. A value of :code:`None` results in a plain flag
   :code:`-key`; any other value results in :code:`-key=value`. Setting a key which is already set
   replaces the value and logs a warning.

-  :code:`arg_get(key)` returns the value of one argument, or :code:`None` if it is not set.

-  :code:`args_set(args)` sets several arguments at once from a dictionary. This is the same format
   as the :code:`simargs` argument of :code:`simulate()`.

-  :code:`get_cmd_args()` returns the resulting argument list as a list of strings, sorted by
   argument name.

The :code:`override` key is treated specially: its value is a dictionary of variable names and
values which is sorted by name and joined into the single :code:`-override=name=value,name=value`
argument that the model executable expects. Values are converted to their Modelica representation,
so Python :code:`True` becomes :code:`true` and numbers are formatted accordingly.

.. code-block:: python

  cmd.arg_set("noRestart", None)
  cmd.arg_set("r", "MyRes.mat")
  cmd.arg_set("override", {"e": 0.3, "g": 10, "s": "false"})
  cmd.get_cmd_args()
  # ['-noRestart', '-override=e=0.3,g=10,s=false', '-r=MyRes.mat']

.. code-block:: python

  cmd.args_set({"noEventEmit": None, "override": {"e": 0.3}})
  print(cmd.arg_get("noEventEmit"))  # -> None (a flag has no value)

:code:`definition()` freezes the configuration into a :code:`ModelExecutionRun` object, which is
what finally knows about the model executable and the command line to run.

ModelExecutionRun
~~~~~~~~~~~~~~~~~

:code:`ModelExecutionRun` is a data class holding the resolved command line:

- :code:`cmd_path` - the directory the model was built in, as seen by the environment.

- :code:`cmd_model_name` - the name of the model.

- :code:`cmd_prefix` - the command prefix needed to re-enter the environment, e.g. for Docker.

- :code:`cmd_model_executable` - the full path of the executable, including the :code:`.exe`
   suffix on Windows.

- :code:`cmd_args` - the command line arguments.

- :code:`cmd_result_file` - the result file of the run. If no :code:`-r` argument was set, it
   defaults to :code:`<model_name>.mat` in the build directory.

- :code:`cmd_timeout` - the timeout for the run, in seconds.

- :code:`cmd_library_path` - an additional library search path, which is only needed for a local
   Windows environment. OMPython derives it from the generated :code:`*.bat` file.

- :code:`cmd_cwd_local` - the working directory to use on the local system. This is only set when
   the environment is the local one, because in Docker or WSL the local directory has no meaning.

The two methods of this class are:

-  :code:`get_cmd()` returns the complete command line as a list of strings: prefix, executable and
   arguments. This is the form expected by :code:`subprocess.run()`, and it is a convenient way to
   log, print or verify the command which is executed.

-  :code:`run()` executes the command and returns its return code. The standard output of the
   executable is logged, an error on standard error or a non-zero exit status raises a
   :code:`ModelExecutionException`, and a run which exceeds :code:`cmd_timeout` also raises a
   :code:`ModelExecutionException`.

.. code-block:: python

  execution = cmd.definition()
  print(" ".join(execution.get_cmd()))
  execution.run()

Because this layer only starts a process, it imposes no restrictions on the model. You can use it to
run models that OMPython did not build, and to run a model in a Docker container or in WSL by
passing the corresponding :code:`cmd_prefix`.

.. _parser:

Parsers - Parsing OMC Return Data
---------------------------------

The OMC server answers every request with a string. OMPython converts that string into a Python
object before handing it to you, and this conversion is done by the parsers of this section. You
can also use them directly, for example to post-process a raw OMC answer.

:code:`sendExpression(expr, parsed=True)` first tries the typed parser and, if that fails, falls back
to the basic parser. So the default gives you the most detailed result which the two parsers can
produce, and only a string which neither of them understands is returned unchanged. With
:code:`parsed=False` the unmodified OMC answer is returned.

OMParser - the basic parser
~~~~~~~~~~~~~~~~~~~~~~~~~~~

:code:`OMParser.om_parser_basic(string)` converts the most common Modelica literals into Python
values:

- Integers, floating point numbers and numbers in scientific notation become :code:`int` and
  :code:`float`.

- :code:`true` and :code:`false` become :code:`True` and :code:`False`.

- Sets in the form :code:`{1,2,3}` become :code:`{'SET1': {'Set1': [1, 2, 3]}}`. The wrapper keys
  :code:`SET1` and :code:`Set1` reflect the "set" semantics of the Modelica notation.

- Strings are returned **including** their quotes.

- Anything the parser does not understand is returned unchanged as a string. It never raises.

.. code-block:: python

  from OMPython.OMParser import om_parser_basic

  om_parser_basic("1")        # -> 1
  om_parser_basic("1.0e-3")   # -> 0.001
  om_parser_basic("true")     # -> True
  om_parser_basic("{1,2,3}")  # -> {'SET1': {'Set1': [1, 2, 3]}}
  om_parser_basic('"abc"')    # -> '"abc"'
  om_parser_basic("1,2,3")    # -> '1,2,3'   (unchanged, not an error)

Besides :code:`om_parser_basic()`, the module provides the helper functions which the parser is
built from, such as :code:`typeCheck()`, :code:`bool_from_string()` and :code:`formatSimRes()`.
They are useful if you need to post-process an OMC result in the same way as OMPython does.

OMTypedParser - the typed parser
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:code:`OMTypedParser.om_parser_typed(string)` is built with the :code:`pyparsing` library and
converts a wider range of Modelica values, using a strict grammar:

- Integers, floating point numbers and booleans as above.

- Strings **without** their quotes, so :code:`"abc"` becomes :code:`abc`.

- Tuples, i.e. both the array form :code:`{1,2}` and the tuple form :code:`(1,2)`, become a Python
  :code:`tuple`.

- Array dimensions may be given as an expression, so :code:`{1+1, 2*3}` becomes :code:`(2, 6)`.

- Modelica records of the form :code:`record R a=1, b="x" end R;` become a Python :code:`dict`.

- :code:`SOME(x)` is unwrapped to :code:`x`, and :code:`NONE()` becomes :code:`None`. Note that the
  parentheses are part of the syntax: a bare :code:`NONE` is returned as the string :code:`'NONE'`.

- The empty string and the empty tuple :code:`()` are recognized as :code:`None` and :code:`()`.

- Anything the grammar does not match raises a :code:`pyparsing.ParseException`.

.. code-block:: python

  from OMPython.OMTypedParser import om_parser_typed

  om_parser_typed("1")                 # -> 1
  om_parser_typed('"abc"')             # -> 'abc'   (no quotes!)
  om_parser_typed("{1,2,3}")           # -> (1, 2, 3)
  om_parser_typed("{1+1, 2*3}")        # -> (2, 6)
  om_parser_typed('record R a=1 end R;')  # -> {'a': 1}
  om_parser_typed("SOME(1.0)")         # -> 1.0
  om_parser_typed("NONE()")            # -> None
  om_parser_typed("NONE")              # -> 'NONE'  (the string, not None!)
  om_parser_typed("Modelica.Blocks")  # -> 'Modelica.Blocks'
  om_parser_typed("1,2,3")             # -> raises ParseException
  om_parser_typed("Modelica.Units.SI.Frequency(1.0)")  # -> raises ParseException

Choosing a parser
~~~~~~~~~~~~~~~~~

The two parsers differ in a way that matters when you post-process OMC answers:

-  Use :code:`om_parser_basic()` when you want a result which never fails and where keeping the
   exact text of everything unrecognised is more useful than rejecting it.

-  Use :code:`om_parser_typed()` when you want real Python types - in particular unquoted strings
   and tuples instead of the nested :code:`SET1` dictionaries - and you are prepared to handle a
   parse error.

The parsers are a moving target: :code:`sendExpression()` currently uses the typed parser for its
default path, and the session classes are being moved to it. As a consequence, the exact type of a
value returned by :code:`sendExpression()` is an implementation detail. If your code depends on a
specific type, ask for it explicitly rather than relying on the default:

.. code-block:: python

  omc.sendExpression("getVersion()", parsed=False)             # exact string from OMC
  om_parser_typed(omc.sendExpression("getVersion()", parsed=False))

.. _compatibility:

Compatibility with OMPython v4.0.0
----------------------------------

The data above describes the current OMPython interface, which reorganized the API of OMPython
v4.0.0. During a transition period both interfaces are available: the new one documented in this
chapter, and a compatibility layer which keeps the old class and method names working.

Every compatibility class issues a :code:`DeprecationWarning` when it is instantiated, and it will
be removed in a future version. Existing scripts therefore keep running, but the warnings point out
what to change. The warning is only shown by default if warnings are enabled for
:code:`DeprecationWarning`, which Python hides outside of :code:`__main__`; run your script with
:code:`python -W default::DeprecationWarning` to see them.

The following table lists the v4.0.0 names and their replacements.

+-----------------------------------+------------------------------------------------------+
| OMPython v4.0.0                   | OMPython current                                     |
+===================================+======================================================+
| :code:`OMCSessionZMQ`             | :code:`OMCSessionLocal`                              |
+-----------------------------------+------------------------------------------------------+
| :code:`OMCProcessLocal`           | :code:`OMCSessionLocal`                              |
+-----------------------------------+------------------------------------------------------+
| :code:`OMCProcessPort`            | :code:`OMCSessionPort`                               |
+-----------------------------------+------------------------------------------------------+
| :code:`OMCProcessDocker`          | :code:`OMCSessionDocker`                             |
+-----------------------------------+------------------------------------------------------+
| :code:`OMCProcessDockerContainer` | :code:`OMCSessionDockerContainer`                    |
+-----------------------------------+------------------------------------------------------+
| :code:`OMCProcessWSL`             | :code:`OMCSessionWSL`                                |
+-----------------------------------+------------------------------------------------------+
| :code:`OMCSessionCmd`             | :code:`OMCSession*.sendExpression()`                 |
+-----------------------------------+------------------------------------------------------+
| :code:`OMCSessionException`       | :code:`OMSessionException`                           |
+-----------------------------------+------------------------------------------------------+
| :code:`ModelicaSystem`            | :code:`ModelicaSystemOMC`                            |
+-----------------------------------+------------------------------------------------------+
| :code:`ModelicaSystemCmd`         | :code:`ModelicaSystem.simulate_cmd()`                |
+-----------------------------------+------------------------------------------------------+
| :code:`ModelicaSystemDoE`         | :code:`ModelicaDoEOMC` / :code:`ModelicaDoERunner`   |
+-----------------------------------+------------------------------------------------------+
| :code:`parse_simflags`            | the :code:`simargs` dictionary of :code:`simulate()` |
+-----------------------------------+------------------------------------------------------+

All of these names are still re-exported from the package root, so :code:`OMPython.OMCSessionZMQ` and
friends keep working. Only :code:`ModelicaSystemCmd` has to be imported from its module:

.. code-block:: python

  from OMPython.ModelicaSystem import ModelicaSystemCmd

Note that :code:`OMPython.OMCSessionException` still refers to the compatibility subclass, while the
exception which the current code raises is :code:`OMPython.OMSessionException`. Change your
:code:`except` clauses accordingly, otherwise they will not catch anything:

.. code-block:: python

  # OMPython v4.0.0
  try:
      omc.sendExpression("getVersion()")
  except OMPython.OMCSessionException:
      pass

  # current
  try:
      omc.sendExpression("getVersion()")
  except OMPython.OMSessionException:
      pass

The most important changes to be aware of are the following.

Sessions and the :code:`omc_process` argument
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The v4.0.0 code passed the OMC process definition as :code:`omc_process`, and
:code:`OMCSessionZMQ` was the one class which combined the session and the process. Both are now the
same object, and the argument is called :code:`session`:

.. code-block:: python

  # OMPython v4.0.0
  omc = OMPython.OMCSessionZMQ(omc_process=OMPython.OMCProcessDocker())

  # current
  omc = OMPython.OMCSessionDocker(docker="openmodelica/openmodelica:v1.27.0-ompython")

The constructor argument :code:`OMCSessionZMQ.omc_process` and the parameter of the same name in the
compatibility class :code:`ModelicaSystem` are still accepted; :code:`ModelicaSystemOMC` only takes
:code:`session`.

Defining a model
~~~~~~~~~~~~~~~~

In v4.0.0 the model was passed to the constructor of :code:`ModelicaSystem` as
:code:`fileName` and :code:`modelName`. It is now defined by a separate :code:`model()` call, which
also makes it possible to load libraries first:

.. code-block:: python

  # OMPython v4.0.0
  mod = OMPython.ModelicaSystem("BouncingBall.mo", "BouncingBall", lmodel=["Modelica"])

  # current
  mod = OMPython.ModelicaSystemOMC()
  mod.model(model_name="BouncingBall", model_file="BouncingBall.mo", libraries=["Modelica"])

The constructor keywords :code:`fileName`, :code:`modelName`, :code:`lmodel`,
:code:`commandLineOptions`, :code:`variableFilter` and :code:`customBuildDirectory` are still
accepted, and map to :code:`model_file`, :code:`model_name`, :code:`libraries`,
:code:`command_line_options`, :code:`variable_filter` and :code:`work_directory` respectively.

Setting values
~~~~~~~~~~~~~~

The v4.0.0 set methods took either a single :code:`"name=value"` string or a list of such strings.
They now take keyword arguments, which removes the need to escape the values and gives a proper
error message on typos:

.. code-block:: python

  # OMPython v4.0.0
  mod.setParameters(["radius=14", "c=0.5"])

  # current
  mod.setParameters(radius=14, c=0.5)

The string form still works on the compatibility class and issues a :code:`DeprecationWarning`. The
difference is not only cosmetic: the v4.0.0 form had to split the string on :code:`=`, which made a
value containing :code:`=` impossible and silently dropped everything after a second :code:`=`. It
also removed all spaces from the string, so a value like :code:`"a + b"` was mangled into
:code:`"a+b"`. The current implementation keeps a value as it was given and reports a space in a key
or value as an error, and it names an unknown key in the error message instead of doing nothing.

Runtime flags
~~~~~~~~~~~~~

:code:`simflags` was a single string holding the runtime flags of the model executable, which had to
be quoted and escaped by hand. :code:`simargs` is a dictionary which is translated into the correct
command line, including the special handling of the :code:`override` flag:

.. code-block:: python

  # OMPython v4.0.0
  mod.simulate(simflags="-noEventEmit -noRestart -override=e=0.3,g=9.71")

  # current
  mod.simulate(simargs={"noEventEmit": None, "noRestart": None, "override": {"e": 0.3, "g": 9.71}})

The :code:`simflags` argument is still accepted by the compatibility class, in :code:`simulate()`,
:code:`simulate_cmd()` and :code:`linearize()`. :code:`parse_simflags()` is available as well, but
there is no need for it any more.

Linearization results
~~~~~~~~~~~~~~~~~~~~~

:code:`linearize()` used to return the list :code:`[A, B, C, D]`. It now returns a
:code:`LinearizationResult` object which carries the matrices together with the dimensions and the
variable names. Unpacking and indexing still work, so most existing code continues to run:

.. code-block:: python

  A, B, C, D = mod.linearize()      # still works
  A = mod.linearize()[0]            # still works
  result = mod.linearize()          # new
  print(result.n, result.stateVars)

Limitations of the compatibility layer
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The compatibility layer covers the naming and the call signatures, not the behaviour:

-  The work directory and the result file are unique per instance in the current version, so an
   instance cannot be reused for a second model build.

-  Setting a structural parameter via :code:`setParameters()` raises a :code:`ModelicaSystemError`
   in the current version, because the model would have to be recompiled. Use
   :code:`sendExpression()` followed by :code:`buildModel()` to change such a parameter.

-  The compatibility classes only wrap the constructors and the methods which changed their
   signature. Attributes of the v4.0.0 objects, for example the :code:`omc_process` attribute of
   :code:`OMCSessionZMQ`, are not guaranteed to stay available; use :code:`get_session()`.

-  Only the new classes are documented and tested. Behaviour which is only reachable through the
   compatibility layer may change without further notice.

.. omc-reset ::
