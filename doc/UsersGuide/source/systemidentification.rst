System Identification
=====================

`System Identification (OMSysIdent) <https://github.com/OpenModelica/OMSysident>`_
is part of the OpenModelica tool suite, but not bundled together with the main
OpenModelica distribution and thus must be fetched separately from its project site.

*OMSysIdent* is a module for the parameter estimation for linear and nonlinear
parametric dynamic models (wrapped as FMUs) on top of the :doc:`omsimulator` API.
It uses the Ceres solver (http://ceres-solver.org/) for the optimization task.
The module provides a *Python scripting API* as well as an *C API*.

.. note::
  Notice that this module was previously part of OMSimulator. It has been extracted
  out of the OMSimulator project and reorganized as a separate project in September 2020.
  As of 2020-10-07 the project is working on Linux but some more efforts are needed
  for migrating the Windows build and make the build and usage of the module
  more convenient.

Version: `a65a0ed <https://github.com/OpenModelica/OMSysIdent/tree/a65a0edc3bdeebb1341fb3af8d3f100a4c86507a>`_

Examples
########

There are examples in the testsuite which use the scripting API, as well as
examples which directly use the C API.

Below is a basic example from the testsuite (`HelloWorld_cs_Fit.py`) which
uses the Python scripting API. It determines the parameters for the following
"hello world" style Modelica model:

.. code-block:: Modelica

  model HelloWorld
    parameter Real a = -1;
    parameter Real x_start = 1;
    Real x(start=x_start, fixed=true);
  equation
    der(x) = a*x;
  end HelloWorld;

The goal is to estimate the value of the coefficent `a` and the initial value
`x_start` of the state variable `x`. Instead of real measurements, the script
simply uses simulation data generated from the `HelloWorld` examples as
measurement data. The array `data_time` contains the time instants at which a
sample is taken and the array `data_x` contains the value of `x` that
corresponds to the respective time instant.

The estimation parameters are defined by calls to function
`simodel.addParameter(..)` in which the name of the parameter and a first guess
for the parameter's value is stated.

.. code-block:: python
  :caption: HelloWorld_cs_Fit.py
  :name: HelloWorld_cs_Fit-python

  from OMSimulator import OMSimulator
  from OMSysIdent import OMSysIdent
  import numpy as np

  oms = OMSimulator()

  oms.setLogFile("HelloWorld_cs_Fit_py.log")
  oms.setTempDirectory("./HelloWorld_cs_Fit_py/")
  oms.newModel("HelloWorld_cs_Fit")
  oms.addSystem("HelloWorld_cs_Fit.root", oms.system_wc)
  # oms.setTolerance("HelloWorld_cs_Fit.root", 1e-5)

  # add FMU
  oms.addSubModel("HelloWorld_cs_Fit.root.HelloWorld", "../resources/HelloWorld.fmu")

  # create simodel for model
  simodel = OMSysIdent("HelloWorld_cs_Fit")
  # simodel.describe()

  # Data generated from simulating HelloWorld.mo for 1.0s with Euler and 0.1s step size
  kNumSeries = 1
  kNumObservations = 11
  data_time = np.array([0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1])
  inputvars = []
  measurementvars = ["root.HelloWorld.x"]
  data_x = np.array([1, 0.9, 0.8100000000000001, 0.7290000000000001, 0.6561, 0.5904900000000001, 0.5314410000000001, 0.4782969000000001, 0.43046721, 0.387420489, 0.3486784401])

  simodel.initialize(kNumSeries, data_time, inputvars, measurementvars)
  # simodel.describe()

  simodel.addParameter("root.HelloWorld.x_start", 0.5)
  simodel.addParameter("root.HelloWorld.a", -0.5)
  simodel.addMeasurement(0, "root.HelloWorld.x", data_x)
  # simodel.describe()

  simodel.setOptions_max_num_iterations(25)
  simodel.solve("BriefReport")

  status, state = simodel.getState()
  # print('status: {0}; state: {1}').format(OMSysIdent.status_str(status), OMSysIdent.omsi_simodelstate_str(state))

  status, startvalue1, estimatedvalue1 = simodel.getParameter("root.HelloWorld.a")
  status, startvalue2, estimatedvalue2 = simodel.getParameter("root.HelloWorld.x_start")
  # print('HelloWorld.a startvalue1: {0}; estimatedvalue1: {1}'.format(startvalue1, estimatedvalue1))
  # print('HelloWorld.x_start startvalue2: {0}; estimatedvalue2: {1}'.format(startvalue2, estimatedvalue2))
  is_OK1 = estimatedvalue1 > -1.1 and estimatedvalue1 < -0.9
  is_OK2 = estimatedvalue2 > 0.9 and estimatedvalue2 < 1.1
  print('HelloWorld.a estimation is OK: {0}'.format(is_OK1))
  print('HelloWorld.x_start estimation is OK: {0}'.format(is_OK2))

  # del simodel
  oms.terminate("HelloWorld_cs_Fit")
  oms.delete("HelloWorld_cs_Fit")

Running the script generates the following console output:

.. code-block:: none

  iter      cost      cost_change  |gradient|   |step|    tr_ratio  tr_radius  ls_iter  iter_time  total_time
   0  4.069192e-01    0.00e+00    2.20e+00   0.00e+00   0.00e+00  1.00e+04        0    7.91e-03    7.93e-03
   1  4.463938e-02    3.62e-01    4.35e-01   9.43e-01   8.91e-01  1.92e+04        1    7.36e-03    1.53e-02
   2  7.231043e-04    4.39e-02    5.16e-02   3.52e-01   9.85e-01  5.75e+04        1    7.26e-03    2.26e-02
   3  1.046555e-07    7.23e-04    4.74e-04   4.40e-02   1.00e+00  1.73e+05        1    7.31e-03    3.00e-02
   4  2.192358e-15    1.05e-07    5.77e-08   6.05e-04   1.00e+00  5.18e+05        1    7.15e-03    3.71e-02
   5  7.377320e-26    2.19e-15    2.05e-13   9.59e-08   1.00e+00  1.55e+06        1    7.42e-03    4.46e-02
  Ceres Solver Report: Iterations: 6, Initial cost: 4.069192e-01, Final cost: 7.377320e-26, Termination: CONVERGENCE

  =====================================
  Total duration for parameter estimation: 44msec.
  Result of parameter estimation (check 'Termination' status above whether solver converged):

  HelloWorld_cs_Fit.root.HelloWorld.a(start=-0.5, *estimate*=-1)
  HelloWorld_cs_Fit.root.HelloWorld.x_start(start=0.5, *estimate*=1)

  =====================================
  HelloWorld.a estimation is OK: True
  HelloWorld.x_start estimation is OK: True
  info:    Logging information has been saved to "HelloWorld_cs_Fit_py.log"

Python and C API
################

addInput
--------

Add input values for external model inputs.

If there are several measurement series, all series need to be conducted
with the same external inputs!


Python
^^^^^^

Args:
  :var: (str) Name of variable..
  :values: (np.array) Array of input values for respective time instants in `simodel.initialize()`.

Returns:
  :status: (int) The C-API status code (`oms_status_enu_t`).

.. code-block:: python

  status = simodel.addInput(var, values)


C
^

.. code-block:: c

  oms_status_enu_t omsi_addInput(void* simodel, const char* var, const double* values, size_t nValues);


addMeasurement
--------------

Add measurement values for a fitting variable.

Python
^^^^^^

Args:
  :iSeries: (int) Index of measurement series.
  :var: (str) Name of variable..
  :values: (np.array) Array of measured values for respective time instants in `simodel.initialize()`.

Returns:
  :status: (int) The C-API status code (`oms_status_enu_t`).

.. code-block:: python

  status = simodel.addMeasurement(iSeries, var, values)

C
^

.. code-block:: c

  oms_status_enu_t omsi_addMeasurement(void* simodel, size_t iSeries, const char* var, const double* values, size_t nValues);


addParameter
------------

Add parameter that should be estimated.

PYTHON
^^^^^^

Args:
  :var: (str) Name of parameter.
  :startvalue: (float) Start value of parameter.

Returns:
  :status: (int) The C-API status code (`oms_status_enu_t`).

.. code-block:: python

  status = simodel.addParameter(var, startvalue)

C
^

.. code-block:: c

  oms_status_enu_t omsi_addParameter(void* simodel, size_t iSeries, const char* var, const double* values, size_t nValues);


describe
--------

Print summary of SysIdent model.

PYTHON
^^^^^^

.. code-block:: python

  status = simodel.describe()

C
^

.. code-block:: c

  oms_status_enu_t omsi_describe(void* simodel);


freeSysIdentModel
-----------------

Unloads a model.

PYTHON
^^^^^^

Not available in Python. Related external C function called by class destructor.


C
^

.. code-block:: c

  void omsi_freeSysIdentModel(void* simodel);


getParameter
------------

Get parameter that should be estimated.

PYTHON
^^^^^^

Args:
  :var: (str) Name of parameter.

Returns:
  :status: (int) The C-API status code (`oms_status_enu_t`).
  :startvalue: (float) Start value of parameter.
  :estimatedvalue: (float) Estimated value of parameter.

.. code-block:: python

  status, startvalue, estimatedvalue = simodel.getParameter(var)

C
^

.. code-block:: c

  oms_status_enu_t omsi_getParameter(void* simodel, const char* var, double* startvalue, double* estimatedvalue);


getState
--------

Get state of SysIdent model object.

PYTHON
^^^^^^

Returns:
  :status: (int) The C-API status code (`oms_status_enu_t`).
  :state: (int) State of SysIdent model (`omsi_simodelstate_t`).

.. code-block:: python

  status, state = simodel.getState()

C
^

.. code-block:: c

  oms_status_enu_t omsi_getState(void* simodel, omsi_simodelstate_t* state);


initialize
----------

This function initializes a given composite model. After this call, the model is in simulation mode.

PYTHON
^^^^^^

Args:
  :nSeries: (int) Number of measurement series.
  :time: (numpy.array) Array of measurement/input time instants.
  :inputvars: (list of str) List of names of input variables (empty list if none).
  :measurementvars: (list of str) List of names of observed measurement variables.

Returns:
  :status: (int) The C-API status code (`oms_status_enu_t`).

.. code-block:: python

  status = simodel.initalize(nSeries, time, inputvars, measurementvars)

C
^

.. code-block:: c

  oms_status_enu_t omsi_initialize(void* simodel, size_t nSeries, const double* time, size_t nTime, char const* const* inputvars, size_t nInputvars, char const* const* measurementvars, size_t nMeasurementvars);


newSysIdentModel
----------------

Creates an empty model for parameter estimation.

PYTHON
^^^^^^

The corresponding Python function is the class constructor.

Args:
  :ident: (str) Name of the model instance.

Returns:
  :simodel: SysIdent model instance.

.. code-block:: python

  simodel = OMSysIdent(ident)

C
^

.. code-block:: c

  void* omsi_newSysIdentModel(const char* ident);


oms_status_str
--------------

Mapping of enum C-API status code (oms_status_enu_t) to string.

The C enum is reproduced below for convenience.

.. code-block:: c

  typedef enum {
    oms_status_ok,
    oms_status_warning,
    oms_status_discard,
    oms_status_error,
    oms_status_fatal,
    oms_status_pending
  } oms_status_enu_t;

PYTHON
^^^^^^

Args:
  :status: (int) The C-API status code.

Returns:
  :status_str: (str) String representation of status code.

The range of values of :code:`status` corresponds to the C enum (by implicit conversion).
This is a static Python method (:code:`@staticmethod`).

.. code-block:: python

  status_str = oms_status_str(status)

C
^

Not available.


omsi_simodelstate_str
---------------------

Mapping of enum C-API state code (omsi_simodelstate_t) to string.

The C enum is reproduced below for convenience.

.. code-block:: c

  typedef enum {
    omsi_simodelstate_constructed,    //!< After omsi_newSysIdentModel
    omsi_simodelstate_initialized,    //!< After omsi_initialize
    omsi_simodelstate_convergence,    //!< After omsi_solve if Ceres minimizer returned with ceres::TerminationType::CONVERGENCE
    omsi_simodelstate_no_convergence, //!< After omsi_solve if Ceres minimizer returned with ceres::TerminationType::NO_CONVERGENCE
    omsi_simodelstate_failure         //!< After omsi_solve if Ceres minimizer returned with ceres::TerminationType::FAILURE
  } omsi_simodelstate_t;

PYTHON
^^^^^^

Args:
    :state: (int) State of SysIdent model.

Returns:
    :simodelstate_str: (str) String representation of state code.

The range of values of :code:`state` corresponds to the C enum (by implicit conversion).
This is a static Python method (:code:`@staticmethod`).

.. code-block:: python

  simodelstate_str = omsi_simodelstate_str(state)

C
^

Not available.


setOptions_max_num_iterations
-----------------------------

Set Ceres solver option `Solver::Options::max_num_iterations`.

PYTHON
^^^^^^

Args:
  :max_num_iterations: (int) Maximum number of iterations for which the solver should run (default: 25).

Returns:
  :status: (int) The C-API status code (`oms_status_enu_t`).

.. code-block:: python

  status = simodel.setOptions_max_num_iterations(max_num_iterations)

C
^

.. code-block:: c

  oms_status_enu_t omsi_setOptions_max_num_iterations(void* simodel, size_t max_num_iterations);


solve
-----

Solve parameter estimation problem.

PYTHON
^^^^^^

Args:
  :reporttype: (str) Print report and progress information after call to Ceres solver.
               Supported report types: `"", "BriefReport", "FullReport"`, where `""` denotes no output.

Returns:
  :status: (int) The C-API status code (`oms_status_enu_t`).

.. code-block:: python

  status = simodel.solve(reporttype)

C
^

.. code-block:: c

  oms_status_enu_t omsi_solve(void* simodel, const char* reporttype);
