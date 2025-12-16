2D Plotting
===========

This chapter covers the 2D plotting available in OpenModelica via
OMNotebook, OMShell and command line script. The plotting is based on
OMPlot application. See also OMEdit :ref:`omedit-2d-plotting`.

Example
-------

.. omc-loadstring ::

  model HelloWorld
    Real x(start = 1, fixed = true);
    parameter Real a = 1;
  equation
    der(x) = - a * x;
  end HelloWorld;

To create a simple time plot the above model HelloWorld is simulated. To
reduce the amount of simulation data in this example the number of
intervals is limited with the argument numberOfIntervals=5. The
simulation is started with the command below.

.. omc-mos ::

  simulate(HelloWorld, outputFormat="csv", startTime=0, stopTime=4, numberOfIntervals=5)

When the simulation is finished the file :ref:`HelloWorld_res.csv` contains the
simulation data:

.. literalinclude :: ../tmp/HelloWorld_res.csv
  :name: HelloWorld_res.csv
  :caption: HelloWorld_res.csv

Use `plot(x)` to plot the diagram using OMPlot.

.. omc-gnuplot :: helloworld
  :caption: Simple 2D plot of the HelloWorld example.

  x

By re-simulating and saving results at many more points, for example using the
default 500 intervals, a much smoother plot can be obtained.
Note that the default solver method dassl has more internal points than the output points in the initial plot.
The results are identical, except the detailed plot has a smoother curve.

.. omc-mos ::

  0==system("./HelloWorld -stepSize=0.008")
  res:=strtok(readFile("HelloWorld_res.csv"), "\n");
  res[end]

.. omc-gnuplot :: helloworld-detailed
  :caption: Simple 2D plot of the HelloWorld example with a larger number of output points.

  x

Plot Command Interface
----------------------

Plot command have a number of optional arguments to
further customize the the resulting diagram.

.. omc-mos ::

  list(OpenModelica.Scripting.plot,interfaceOnly=true)
