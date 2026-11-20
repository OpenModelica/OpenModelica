.. _parmodauto :

Automatic Parallelization of Simulations
========================================

OpenModelica can automatically parallelize the simulation of a model over the
available CPU cores. The feature is enabled by building the model with the
``--parmodauto`` compiler flag:

.. code-block:: modelica

  setCommandLineOptions("--parmodauto");
  loadModel(Modelica);
  buildModel(Modelica.Fluid.Examples.BranchingDynamicPipes, fileNamePrefix="m");

With ``--parmodauto`` the compiler emits, alongside the usual simulation code, a
description of the model's equation **task graph** (which equation depends on
which). At run time the executable reads that description, groups the tasks into
**clusters**, builds a task graph over the clusters and executes it in parallel
with `oneTBB <https://github.com/oneapi-src/oneTBB>`_.

How the tasks are grouped into clusters — the *clustering* — determines how well
the work balances across the cores. The runtime ships several clustering
strategies, and it can also **export** the task graph and clustering to JSON and
**import** a clustering produced by an external tool. This makes it possible to
develop and tune clustering/scheduling outside of the C++ runtime, for example
with graph-visualization tools or with an optimizer, and then feed the result
back into the simulation.

Run-time flags
--------------

The following simulation-executable flags control the clustering and the
JSON export/import. They are passed to the generated executable (e.g. via
``simulate(M, simflags="...")`` or on the command line).

.. code-block:: none

  -parmodScheduler=flow|level          select the scheduler (default: flow)
  -parmodClustering=NAME               select the clustering strategy
                                       (default, fixed_width_min_height,
                                       merge_across_levels, none)
  -parmodClustersPerLevel=INT          max clusters per level for the default clustering

  -parmodExportTaskGraph=FILE          export the final task graph + clustering as JSON
  -parmodDumpStages=PREFIX             export one JSON snapshot before and after every
                                       clustering optimization (PREFIX.00.initial.json,
                                       PREFIX.01.<opt>.json, ...)
  -parmodImportClustering=FILE         use the clustering from FILE instead of computing one

The clustering strategies are:

``default``
  Merge a task with its only parent and its siblings up to a cost limit, then
  merge the clusters of every level into a limited number of clusters of about
  the same measured cost.

``fixed_width_min_height``
  Put the tasks of every level into as many lanes as there are threads and
  move tasks between the lanes of a level to make the longest path shorter.

``merge_across_levels``
  Merge clusters that depend on each other, also when they are on different
  levels. A cluster is merged with one of its neighbours as long as the number
  of clusters it exchanges values with is not below its number of equations. A
  merge that closes a cycle in the cluster graph is not done. This strategy uses
  the structure of the task graph only, so the clusters are the same in every
  run.

``none``
  One cluster per equation.

Importing a clustering aborts the simulation (with an error) if the file
references an unknown or duplicated equation, or if the requested clustering
would form a cycle in the contracted task graph.

JSON format
-----------

Everything is keyed by the **stable equation index** (``eq``), which is
independent of the internal graph ordering:

.. code-block:: json

  {
    "name": "ModelName",
    "num_threads": 8,
    "tasks":        [ {"eq": 42, "level": 3, "cost": 2.0, "out_degree": 2} ],
    "dependencies": [ [11, 42] ],
    "clusters":     [ {"eqs": [42, 43], "lane": 1} ],
    "stage": 1, "stage_name": "cluster_merge_common"
  }

* ``level`` is the dependency depth (level 1 runs first), ``cost`` is the runtime's
  per-task cost estimate, and ``out_degree`` is the task's number of successors.
* ``lane`` is the hardware lane (core) ``0 .. num_threads-1`` assigned by
  lane-based clustering, or ``-1`` when the active clustering does not assign
  lanes.
* ``stage`` / ``stage_name`` appear only in ``-parmodDumpStages`` snapshots.
* For **import**, only ``{ "clusters": [ {"eqs": [...]}, ... ] }`` is required;
  equations not listed become singleton clusters.

External tools
--------------

OpenModelica ships a small toolchain (installed under
``share/omc/scripts/``) that consumes and produces this JSON. Each tool reads any
export or ``-parmodDumpStages`` snapshot.

``parmod_graph_to_graphml.py`` *(Python, standard library only)*
  Convert an export to `GraphML <http://graphml.graphdrawing.org/>`_ for general
  graph tools (yEd, Gephi, NetworkX):

  .. code-block:: bash

    python3 parmod_graph_to_graphml.py taskgraph.json                  # tasks, colored by cluster
    python3 parmod_graph_to_graphml.py --mode clusters taskgraph.json  # contracted cluster graph
    python3 parmod_graph_to_graphml.py --yed -o g.graphml taskgraph.json   # yEd, pre-laid-out

  Views (``--mode``): ``tasks`` (default), ``clusters``, ``lanes``, ``both``.

``parmod_graph_plot.jl`` *(Julia, GraphPlot.jl)*
  Render an export to SVG (default) or PNG, laid out left-to-right by level and
  colored by cluster:

  .. code-block:: bash

    julia parmod_graph_plot.jl taskgraph.json
    julia parmod_graph_plot.jl --mode lanes --png taskgraph.json

  Dependencies: ``JSON, Graphs, GraphPlot, Colors, Compose`` (and ``Cairo,
  Fontconfig`` for ``--png``). Best for small/medium graphs; for very large graphs
  prefer the GraphML route.

``parmod_optimize_clustering.jl`` *(Julia, MetaheuristicsAlgorithms.jl)*
  Optimize the clustering with a metaheuristic and write it back in the import
  format. The objective is the graph **height**: levels execute sequentially while
  the lanes within a level execute in parallel, so a level costs as much as its
  busiest lane and the height is the sum of those over all levels. Minimizing it
  balances each level's work across the ``K`` lanes (the *fixed-width / minimum
  height* goal). Clusters are keyed by ``(level, lane)`` so the result is always
  acyclic and safe to import.

  .. code-block:: bash

    julia parmod_optimize_clustering.jl taskgraph.json                      # GWO, K = num_threads
    julia parmod_optimize_clustering.jl --algorithm AEO --cores 8 --iters 500 taskgraph.json
    julia parmod_optimize_clustering.jl --run --exe ./m taskgraph.json      # optimize, then simulate

  With ``--objective merge_across_levels`` the script searches the clustering of
  the ``merge_across_levels`` strategy instead. The runtime merges the clusters
  in one fixed order; here every dependency has a priority, the merges are tried
  by decreasing priority, and the metaheuristic searches the priorities for the
  clustering with the shortest estimated evaluation time. A merge that closes a
  cycle is not done, so the result is safe to import.

  The time is estimated with a lower bound (``--estimate bound``, the default):
  the longest path of cluster costs, or the total cost divided by ``K`` when
  that is longer. ``--estimate schedule`` is a simulated evaluation instead:
  ``K`` threads take the clusters that are ready, and a cluster takes its cost
  plus an overhead for the cluster and one for every cluster it sends values to
  (``--cluster-overhead``, ``--edge-overhead``, in the unit of the task costs;
  the defaults were fitted to the C runtime with the flow scheduler).

  The task costs in an export are one measurement each and change from run to
  run. ``--cost-from FILE`` (repeatable) reads more exports of the same model and
  takes the smallest cost of every task. ``--max-comm-weight W`` also searches a
  weight ``w`` in ``[1, W]`` for the stop rule (merge as long as ``w`` times the
  communication is not below the number of equations), which gives larger
  clusters when the overhead of a cluster is high.

  .. code-block:: bash

    ./m -parmodClustering=merge_across_levels -parmodExportTaskGraph=taskgraph.json
    julia parmod_optimize_clustering.jl --objective merge_across_levels taskgraph.json

  Options include ``--objective``, ``-a/--algorithm`` (``GWO``, ``Jaya``, ``AVOA``, ``MPA``, … —
  default ``GWO``), ``--pop``, ``--iters``, ``-k/--cores``, ``--seed``, ``-o``,
  and ``--run``/``--exe``. It prints the serial and lower-bound reference heights,
  the optimized height, the speedup, and the improvement over the imported
  clustering. Install the dependency once with:

  .. code-block:: bash

    julia -e 'using Pkg; Pkg.add("JSON"); \
              Pkg.add(url="https://github.com/AbdelazimHussien/MetaheuristicsAlgorithms.jl")'

``parmod_optimize_demo.sh`` *(Bash, end-to-end)*
  Run the whole loop on a model and dump a GraphML/SVG of the clustering at every
  stage — both the optimizations performed inside the executable and the
  metaheuristic optimization performed in Julia — then report the differences:

  .. code-block:: bash

    MODELFILE=ParModelicaDemo.mo CORES=4 STOPTIME=1.0 \
      ./parmod_optimize_demo.sh ParModelicaDemo ./parmod_demo_out
    ./parmod_optimize_demo.sh --clean ./parmod_demo_out   # remove everything regenerable

  It builds the model with ``--parmodauto``, exports the task graph and the
  per-stage clustering, renders them, runs ``parmod_optimize_clustering.jl``,
  re-imports the optimized clustering, and finally compares the graph height
  (executable vs. optimized clustering), the simulation result (default vs.
  optimized clustering — these must match, since only the scheduling changes), and
  the wall-clock time of the two runs. ``ParModelicaDemo.mo`` is a small bundled
  model with a wide, shallow task graph that makes the clustering easy to see.

The optimization workflow
--------------------------

Putting it together, the clustering can be developed entirely outside the runtime
and then used for the real simulation:

.. code-block:: none

  Modelica --omc --parmodauto-->                    executable
  executable --parmodExportTaskGraph-->             taskgraph.json
  taskgraph.json --parmod_optimize_clustering.jl--> optimized.json
  optimized.json --parmodImportClustering-->        executable runs in parallel

Because the optimized clustering only changes how the equations are scheduled, the
simulation results are identical to the default run; only the parallel execution
differs.
