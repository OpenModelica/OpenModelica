2D Plotting
===========

This chapter covers the 2D plotting available in OpenModelica via
OMNotebook, OMShell and command line script. The plots are shown in the
OMPlot application, or written into files (see :ref:`plots-in-files`). See
also OMEdit :ref:`omedit-2d-plotting`.

.. _plotting-example :

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

Use ``plot(x)`` to show the plot in OMPlot. With the argument ``outputFile``,
the plot is written into an SVG or a PNG file instead. The plots in this guide
are made that way:

.. omc-plot :: helloworld
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

.. omc-plot :: helloworld-detailed
  :caption: Simple 2D plot of the HelloWorld example with a larger number of output points.

  x

Plot Command Interface
----------------------

Plot command have a number of optional arguments to
further customize the the resulting diagram.

.. omc-mos ::

  list(OpenModelica.Scripting.plot,interfaceOnly=true)

.. _plots-in-files :

Plots in Files
--------------

With the argument ``outputFile``, :ref:`plot`, :ref:`plotAll` and
:ref:`plotParametric` write the plot into an SVG or a PNG file instead of
showing it, as in :ref:`the plots above <plotting-example>`. This does not
need OMPlot or a display, so it also works in scripts that run in a terminal
or on a server.

:ref:`plotFigure` draws a *figure*: one or more plots, one below the other,
each with its own curves and axes. A figure is an
:code:`OpenModelica.Scripting.Figure` record, the record of the ``figures``
annotation of the Modelica Language Specification. Thus ``plotFigure`` can also
draw the figures that :ref:`getModelFigures` gives for a model.

.. omc-plot :: helloworld-figure
  :figure:
  :caption: A figure with two plots of the HelloWorld example.

  Figure(title = "HelloWorld", plots = {
    Plot(title = "State", curves = {Curve(y = "x", legend = "x, at the end %{x}")}),
    Plot(title = "Derivative", curves = {Curve(y = "der(x)", color = "red", pattern = LinePattern.Dash)})})

A curve refers to its variables by name, as a string, and ``%{x}`` shows the
final value of ``x``. The axes show the units of the variables, or their
display units. A curve can also take its values from another result file, to
compare two simulations. The fields ``color``, ``pattern``, ``thickness`` and
``fileName`` of a curve are not part of the ``figures`` annotation.

.. omc-mos ::

  list(OpenModelica.Scripting.Curve)
  list(OpenModelica.Scripting.plotFigure, interfaceOnly=true)

Without ``outputFile``, ``plotFigure`` shows each plot of the figure the way
``plot`` and ``plotParametric`` do.
