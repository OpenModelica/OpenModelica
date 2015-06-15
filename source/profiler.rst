Modelica Performance Analyzer
#############################

A common problem when simulating models in an equation-based language
like Modelica is that the model may contain non-linear equation systems.
These are solved in each time-step by extrapolating an initial guess and
running a non-linear system solver. If the simulation takes too long to
simulate, it is useful to run the performance analysis tool. The tool
has around 5~25% overhead, which is very low compared to
instruction-level profilers (30x-100x overhead). Due to being based on a
single simulation run, the report may contain spikes in the charts.

When running a simulation for performance analysis, execution times of
user-defined functions as well as linear, non-linear and mixed equation
systems are recorded.

To start a simulation in this mode, just use the measureTime flag of the
simulate command.

>>> simulate(modelname, measureTime = true)

The generated report is in HTML format (with images in the SVG format),
stored in a file modelname\_prof.html, but the XML database and measured
times that generated the report and graphs are also available if you
want to customize the report for comparison with other tools.

Below we use the performance profiler on the simple model A:

.. omc-mos ::
  :clear:
  :hidden:

.. omc-loadstring ::

  model ProfilingTest
    function f
      input Real r;
      output Real o = sin(r);
    end f;
    String s = "abc";
    Real x = f(x) "This is x";
    Real y(start=1);
    Real z1 = cos(z2);
    Real z2 = sin(z1);
  equation
    der(y) = time;
  end ProfilingTest;

We simulate as usual, but set measureTime=true to activate the profiling:

.. omc-mos ::

  setCommandLineOptions("--profiling=blocks+html")
  simulate(ProfilingTest)

.. omc-mos ::
  :hidden:

  :target: ProfilingTest_prof.999.svg
  system("pandoc -o ProfilingTest_prof.rst ProfilingTest_prof.html")
  system("sed -i= 's/:target: ProfilingTest_prof.*/:width: 32px/' ProfilingTest_prof.rst")
  system("mv ProfilingTest_prof.rst ../source/ProfilingTest_prof.inc")
  system("rm ProfilingTest_prof.html")
  system("cp ProfilingTest_prof* ../source/")

.. include :: ProfilingTest_prof.inc

Genenerated JSON for the Example
================================

.. literalinclude :: ../tmp/ProfilingTest_prof.json
  :caption: ProfilingTest_prof.json
  :language: json
