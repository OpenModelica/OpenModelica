2D Plotting
===========

This chapter covers the 2D plotting available in OpenModelica via
OMNotebook, OMShell and command line script. The plotting is based on
OMPlot application.

Example
-------

.. omc-loadstring ::

  class HelloWorld
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

Diagrams are now created with the new OMPlot program by using the
following plot command:

.. omc-gnuplot :: helloworld
  :caption: Simple 2D plot of the HelloWorld example.

  x

By re-simulating and saving results at many more points, for example using the
default 500 intervals, a much smoother plot can be obtained.
Note that the default solver method dassl has more internal points than the output points in the initial plot.
The results are identical, except the detailed plot has a smoother curve.

.. omc-mos ::

  0==system("./HelloWorld -override stepSize=0.008")
  res:=strtok(readFile("HelloWorld_res.csv"), "\n");
  res[end]

.. omc-gnuplot :: helloworld-detailed
  :caption: Simple 2D plot of the HelloWorld example with a larger number of output points.

  x

Plotting Commands and their Options
-----------------------------------

All of these commands can have any number of optional arguments to
further customize the the resulting diagram. The available options and
their allowed values are listed below.

+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| **Option**       | **Default value**                   | **Description**                                                                                             |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| fileName         | "<default>"                         | The name of the result-file containing the variables to plot. <default> will read the last simulation result|
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| grid             | "detailed"                          | Sets the grid for the plot i.e simple, detailed, none.                                                      |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| title            | ""                                  | This text will be used as the diagram title.                                                                |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| logX             | false                               | Determines whether or not the horizontal axis is logarithmically scaled.                                    |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| logY             | false                               | Determines whether or not the vertical axis is logarithmically scaled.                                      |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| xLabel           | "time"                              | This text will be used as the horizontal label in the diagram.                                              |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| yLabel           | ""                                  | This text will be used as the vertical label in the diagram.                                                |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| xRange           | {0, 0}                              | Determines the horizontal interval that is visible in the diagram. {0, 0} will select a suitable range.     |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| yRange           | {0, 0}                              | Determines the vertical interval that is visible in the diagram. {0, 0} will select a suitable range.       |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| curveWidth       | 1.0                                 | Defines the width of the curve.                                                                             |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| curveStyle       | 1                                   | Defines the style of the curve.                                                                             |
|                  |                                     |                                                                                                             |
|                  |                                     | SolidLine=1, DashLine=2, DotLine=3, DashDotLine=4, DashDotDotLine=5, Sticks=6, Steps=7.                     |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| legendPosition   | "top"                               | Defines the position of the legend in the diagram. Possible values are left, right, top, bottom and none.   |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| externalWindow   | false                               | Opens a new OMPlot window if set to true otherwise update the current opened window.                        |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| footer           | ""                                  | This text will be used as the diagram footer.                                                               |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| autoScale        | true                                | Use auto scale while plotting.                                                                              |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| forceOMPlot      | false                               | If true launches OMPlot and doesn't call callback function even if it is defined.                           |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
