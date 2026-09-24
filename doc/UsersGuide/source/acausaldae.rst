Acausal DAE Separate Compilation
================================

Overview
--------

OpenModelica can simulate a flowsheet model whose top-level components are
acausal DAE blocks by compiling each component *separately* and stitching the
compiled components together with the connection equations, instead of
flattening and compiling the whole model as a single monolithic system.

This is useful for large component-based models (for example fluid networks),
where it enables:

* **separate compilation** -- each component is translated to C code on its own
  and can be reused unchanged across models, and
* **incremental rebuilds** -- changing the way components are connected, or
  swapping one component, only requires regenerating the affected parts.

Each acausal connector variable (for example a fluid port's ``m_flow``, ``p``,
``h_outflow``, ``Xi_outflow``, a heat port's ``T``, ``Q_flow``, or a real
signal) is exposed by the per-component code as a placeholder DAE residual.
These placeholders are then replaced by the real Modelica connection equations
(flow conservation ``sum(m_flow) = 0`` and potential equality ``c_i.p =
c_ref.p``) so the assembled system is equivalent to the monolithic one.

The underlying per-component code generation is provided by the
``translateResidualsDAE`` scripting function.

Scripting API
-------------

Three scripting functions drive the flow, mirroring the
``translateModel`` / ``buildModel`` / ``simulate`` trio:

.. code-block:: modelica

  translateAcausalDAE(TopLevelModel)  // generate the combined DAE C code
  buildAcausalDAE(TopLevelModel)      // generate + build the executable
  simulateAcausalDAE(TopLevelModel)   // generate + build + run, returns SimulationResult

All three accept the same optional arguments as ``simulate`` (``startTime``,
``stopTime``, ``numberOfIntervals``, ``tolerance``, ``method``,
``fileNamePrefix``, ``options``, ``outputFormat``, ``variableFilter``,
``cflags``, ``simflags``); the combined system is always integrated with the
SUNDIALS IDA DAE solver.

``simulateAcausalDAE`` returns the same ``SimulationResult`` record as
``simulate``, so it can be used as a drop-in replacement.

Example
-------

.. code-block:: modelica

  loadFile("Example1Total.mo");
  simulateAcausalDAE(Example1_total);

What happens under the hood:

#. ``getModelInstance(TopLevelModel)`` is used to obtain the top-level
   components (with their modifications, including ``redeclare`` of the medium
   package) and the top-level connections. This resolves inheritance, so it
   works even when the model only ``extends`` another model.
#. For each top-level component a small wrapper model is synthesized and passed
   to ``translateResidualsDAE``, producing the per-component DAE residual C code
   (the per-component ``fileNamePrefix`` is the component's instance name).
#. The connection equations are written to ``_connect_<Model>.txt`` and the
   per-component code is combined into a single simulable system.
#. The combined system is built and run, and the result is returned.

Code reuse
----------

When ``translateAcausalDAE`` / ``buildAcausalDAE`` / ``simulateAcausalDAE`` is
called again, a component is *not* regenerated if its top-level model (class path
and modifications) and the OpenModelica version are unchanged. This information
is stored next to the generated C code in a small JSON sidecar
(``<component>_acausal_cache.json``); when it matches, the previously generated
component code is reused and only the connection/combination step is redone.

Result file
-----------

The combined model is integrated with SUNDIALS IDA and the trajectory is written
in both OpenModelica result formats, ``combined_res.mat`` and
``combined_res.csv``; ``simulateAcausalDAE`` returns the one selected by
``outputFormat`` (default ``mat``) in ``SimulationResult.resultFile``, so it can
be loaded, plotted or compared exactly like a normal ``simulate`` result. The
result variables use their real hierarchical names (for example ``res.m_flow``,
``sou.ports[1].m_flow``), so the result can be diffed against an ordinary
simulation:

.. code-block:: modelica

  simulateAcausalDAE(Example1_total);
  simulate(Example1_total, fileNamePrefix="ode");
  diffSimulationResults("combined_res.mat", "ode_res.mat", "diff");

Working directory
-----------------

The generated files are written to the current directory. If that directory is
not writable, a temporary directory is created and used instead.

Limitations
-----------

* The combined system is integrated with IDA; the ``method`` argument is
  accepted for compatibility but ignored.
* A component can only be separately compiled if ``translateResidualsDAE``
  succeeds for it; components for which DAE-mode index reduction fails cannot be
  used with this flow.
