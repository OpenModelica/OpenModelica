Functional Mock-up Interface - FMI
==================================

The `Functional Mock-up Interface (FMI) <http://www.fmi-standard.org>`_ Standard
for model exchange and co-simulation allows export, exchange and import of pre-compiled
models between different tools.
The FMI standard is Modelica independent, so import and export works both between
different Modelica or non-Modelica tools.

See also :ref:`OMSimulator documentation<omsimulator-documentation>`.

FMI Export
----------

To export a FMU use the OpenModelica command :ref:`buildModelFMU()<buildModelFMU>` from
the command line interface, OMShell, OMNotebook or MDT.
The FMU export command is also integrated in OMEdit.
Select `File > Export > FMU`. Or alternatively, right click a model to obtain the export
command.
The FMU package is generated in the current working directory of OMC or the directory set
in `OMEdit > Options > FMI > Move FMU`.
You can use the :ref:`cd()<cd>` command to see the current location.
The location of the generated FMU is printed in the Messages Browser of OMEdit or on the
command line.

You can set which version of FMI to export through OMEdit settings, see section
:ref:`omedit-options-fmi`.

.. figure :: media/fmiExport.png

  FMI Export.

To export the bouncing ball example to an FMU, use the following commands:

.. omc-mos ::
  :erroratend:

  loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/BouncingBall.mo")
  buildModelFMU(BouncingBall)

After the command execution is complete you will see that a file BouncingBall.fmu has been
created. Its contents varies depending on the target platform.
On the machine generating this documentation the contents in
:numref:`BouncingBall-FMU-contents` are generated (along with the C source code).

.. omc-mos ::
  :hidden:

  system("unzip -l BouncingBall.fmu | egrep -v 'sources|files' | tail -n+3 | grep -o '[A-Za-z._0-9/]*$' > BB.log")

.. literalinclude :: ../tmp/BB.log
  :name: BouncingBall-FMU-contents
  :caption: BouncingBall FMU contents

A log file for FMU creation is also generated named ModelName\_FMU.log.
If there are some errors while creating the FMU, they will be shown in the command line
window and logged in this log file as well.

By default an FMU that can be used for both Model Exchange and Co-Simulation is generated.
We support FMI 1.0 & FMI 2.0.4 for Model Exchange FMUs and FMI 2.0.4 for Co-Simulation
FMUs.

For the Co-Simulation FMU two integrator methods are available:

* Forward Euler [default]
* SUNDIALS CVODE (see [#f1]_)

Forward Euler uses root finding, which does an Euler step of ``communicationStepSize``
in ``fmi2DoStep``. Events are checked for before and after the call to
``fmi2GetDerivatives``.

If CVODE is chosen as integrator the FMU should also include runtime dependencies
(:ref:`--fmuRuntimeDepends=modelica<omcflag-fmuRuntimeDepends>`) to copy all used dynamic
libraries into the generated FMU to make it exchangeable.

To export a Co-Simulation FMU with CVODE for the bouncing ball example use the
following commands:

.. omc-mos ::
  :erroratend:

  loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/BouncingBall.mo")
  setCommandLineOptions("--fmiFlags=s:cvode")
  buildModelFMU(BouncingBall, version = "2.0", fmuType="cs")


The FMU BouncingBall.fmu will have a new file BouncingBall_flags.json in its resources
directory. By manually changing its content users can change the solver method without
recompiling the FMU.

The BouncingBall_flags.json for this example is displayed in
:numref:`BouncingBall-FMI-flags`.

.. omc-mos ::
  :hidden:

  system("unzip -cqq BouncingBall.fmu resources/BouncingBall_flags.json > BouncingBall_flags.json")

.. literalinclude :: ../tmp/BouncingBall_flags.json
  :name: BouncingBall-FMI-flags
  :caption: BouncingBall FMI flags


Compilation Process
~~~~~~~~~~~~~~~~~~~

OpenModelica can export FMUs that are compiled with CMake (default) or Makefiles. CMake
version v3.21 or newer is recommended, minimum CMake version is v3.5.

The Makefile FMU export will be removed in a future version of OpenModelica.
Set compiler flag :ref:`--fmuCMakeBuild=false<omcflag-fmuCMakeBuild>` to use the
Makefiles export.

The FMU contains a CMakeLists.txt file in the sources directory that can be used to
re-compile the FMU for a different host and is also used to cross compile for different
platforms.

The CMake compilation accepts the following settings:

* ``BUILD_SHARED_LIBS``:
  Boolean value to switch between dynamic and statically linked binaries.

  * ``ON`` (default): Compile DLL/Shared Object binary object.

  * ``OFF``: Compile static binary object.

* ``FMI_INTERFACE_HEADER_FILES_DIRECTORY``:
  String value specifying path to FMI header files containing ``fmi2Functions.h``,
  ``fmi2FunctionTypes.h`` and ``fmi2TypesPlatforms.h``.

  * Defaults to a location inside the OpenModelica installation directory, which was used
    to create the FMU. They need to be version 2.0.4 from the FMI Standard.

* ``RUNTIME_DEPENDENCIES_LEVEL``:
  String value to specify runtime dependencies set.

  * ``none``: Adds no runtime dependencies to FMU. The FMU can't be used on a system if it
    doesn't provided all needed dependencies.

  * ``modelica`` (default): Add Modelica runtime dependencies to FMU, e.g. a external C
    library used from a Modelica function. Needs CMake version v3.21 or newer.

  * ``all``: Add system and Modelica runtime dependencies. Needs CMake version v3.21 or
    newer.

  CMake install TARGETS RUNTIME_DEPENDENCIES is not supported when cross compiling.
  Use ``none`` when cross compiling FMUs.

* ``NEED_CVODE``:
  Boolean value to integrate CVODE integrator into CoSimulation FMU.

  * ``ON``: Link to SUNDIALS CVODE. If CVODE is not in a default location
    ``CVODE_DIRECTORY`` needs to be set.
    Its also recommended to use ``RUNTIME_DEPENDENCIES_LEVEL=modelica`` or higher to add
    SUNDIALS runtime dependencies into the FMU.

  * ``OFF`` (default): Don't link to SUNDIALS CVODE.

* ``CVODE_DIRECTORY``:
  String value with location of libraries ``sundials_cvode`` and ``sundials_nvecserial``
  with SUNDIALS version 5.4.0.

  * Defaults to a location inside the OpenModelica installation directory, which was
    used to create the FMU.


Then use CMake to configure, build and install the FMU.
To repack the FMU after installation use custom target ``create_fmu``.

For example to re-compile the FMU with cmake and runtime dependencies use:

.. code-block:: bash

    $ unzip BouncingBall.fmu -d BouncingBall_FMU
    $ cd BouncingBall_FMU/sources
    $ cmake -S . -B build_cmake \
      -D RUNTIME_DEPENDENCIES_LEVEL=modelica \
      -D CMAKE_C_COMPILER=clang -D CMAKE_CXX_COMPILER=clang++
    $ cmake --build build_cmake --target create_fmu --parallel

.. _fmitlm-export-options :

Platforms
~~~~~~~~~

The ``platforms`` setting specifies for what target system the FMU is compiled:

* Empty: Create a Source-Code-only FMU.

* ``native``:  Create a FMU compiled for the exporting system.

* ``<cpu>-<vendor>-<os>`` host triple: OpenModelica searches for programs in PATH matching
  pattern ``<cpu>-<vendor>-<os>cc`` to compile.
  E.g. ``x86_64-linux-gnu`` for a 64 bit Linux OS or ``i686-w64-mingw32`` for a 32 bit
  Windows OS using MINGW.

* ``<cpu>-<vendor>-<os> docker run ghcr.io/openmodelica/crossbuild:v1.26.0-dev`` Host triple with
  Docker image provided by OpenModelica: OpenModelica will use Docker image
  `ghcr.io/openmodelica/crossbuild:v1.26.0-dev <https://github.com/OpenModelica/openmodelica-crossbuild>`_
  to cross compile. The image provides compiler toolchain files to
  cross compile with CMake for the following host triples:

    * ``i686-linux-gnu``
    * ``x86_64-linux-gnu``
    * ``aarch64-linux-gnu``
    * ``arm-linux-gnueabi``
    * ``arm-linux-gnueabihf``
    * ``i686-w64-mingw32``
    * ``x86_64-w64-mingw32``

  OpenModelica will add a matching ``CMAKE_TOOLCHAIN_FILE`` to the compilation
  process.

  If your model depends on external C libraries cross compilation can be
  difficult. Providing pre-compiled static libraries can be necessary.
  Installing runtime dependencies using CMake isn't supported when
  cross-compiling.

* ``<cpu>-<vendor>-<os> docker run <image>`` Host triple with Docker image:
  OpenModelica will use the specified Docker image to cross compile for given host triple.
  Because privilege escalation is very easy to achieve with Docker OMEdit adds
  ``--pull=never`` to the Docker calls for the ``multiarch/crossbuild`` images. Only use
  this option if you understand the security risks associated with Docker images from
  unknown sources.
  E.g. ``x86_64-linux-gnu docker run --pull=never multiarch/crossbuild`` to cross compile
  for a 64 bit Linux OS.
  Because system libraries can be different for different versions of the same operating
  system, it is advised to use :ref:`--fmuRuntimeDepends=all<omcflag-fmuRuntimeDepends>`.


.. _fmi-import :

FMI Import - SSP
----------------

If you want to simulate a single, stand-alone FMU, or possibly a connection
of several FMUs, the recommended tool to do that is OMSimulator, see the
:ref:`OMSimulator documentation<omsimulator-documentation>` and
:ref:`omedit-graphical-modelling` for further information.

FMI Import - Non-Standard Modelica Model
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FMI Import allows to use an FMU, generated according to the FMI for Model
Exchange 2.0 standard, as a component in a Modelica model. This can be
useful if the FMU describes the behavior of a component or sub-system in a
structured Modelica model, which is not easily turned into a pure FMI-based
model that can be handled by OMSimulator.

FMI is a computational description of a dynamic model, while a Modelica model is
a declarative description; this means that not all conceivable FMUs can be successfully
imported as Modelica models. Also, the current implementation of FMU import in
OpenModelica is still somewhat experimental and not guaranteed to work in all
cases. However, if the FMU-ME you want to import was exported from a Modelica model
and only represents continuous time dynamic behavior, it should work without problems
when imported as a Modelica block.

Please also note that the current implementation of FMI Import in OpenModelica
is based on a built-in wrapper that uses a `reinit()` statement in an algorithm
section. This is not allowed by the Modelica Language Specification, so it is
necessary to set the compiler to accept this non-standard construct by setting
the :ref:`--allowNonStandardModelica=reinitInAlgorithms<omcflag-allowNonStandardModelica>`
compiler flag.
In OMEdit, you can set this option by activating the *Enable FMU Import* checkbox in the
*Tools | Options | Simulation | Translation Flags* tab. This will generate a warning during
compilation, as there is no guarantee that the imported model using this feature
can be ported to other Modelica tools; if you want to use a model that contains
imported FMUs in another Modelica tool, you should rely on the other tool's import
feature to generate the Modelica blocks corresponding to the FMUs.

After setting the :ref:`--allowNonStandardModelica<omcflag-allowNonStandardModelica>`
flag, to import the FMU package use the OpenModelica command importFMU,

.. omc-mos ::
  :parsed:

  list(OpenModelica.Scripting.importFMU, interfaceOnly=true);

The command could be used from command line interface, OMShell,
OMNotebook or MDT. The importFMU command is also integrated with OMEdit
through the `File > Import > FMU` dialog: the FMU package is extracted in the directory
specified by workdir, or in the current directory of omc if not specified, see
`Tools > Open Working Directory`.

The imported FMU is then loaded in the Libraries Browser and can be used as any
other regular Modelica block.

.. rubric:: Footnotes
.. [#f1] `Sundials Webpage <http://computation.llnl.gov/projects/sundials-suite-nonlinear-differential-algebraic-equation-solvers>`__
