2D Plotting
===========

This chapter covers the 2D plotting available in OpenModelica via
OMNotebook, OMShell and command line script. The plotting is based on
OMPlot application.

Example
-------

class HelloWorld

Real x(start = 1);

parameter Real a = 1;

equation

der(x) = - a \* x;

end HelloWorld;

To create a simple time plot the above model HelloWorld is simulated. To
reduce the amount of simulation data in this example the number of
intervals is limited with the argument numberOfIntervals=10. The
simulation is started with the command below.

simulate(HelloWorld, startTime=0, stopTime=4, numberOfIntervals=10);

When the simulation is finished the file HelloWorld res.plt contains the
simulation data. The contents of the file is the following (some
formatting has been applied).

0 1

4.440892098500626e-013 0.9999999999995559

0.4444444444444444 0.6411803884299349

0.8888888888888888 0.411112290507163

1.333333333333333 0.2635971381157249

1.777777777777778 0.1690133154060587

2.222222222222222 0.1083680232218813

2.666666666666667 0.06948345122279623

3.111111111111112 0.04455142624447787

3.555555555555556 0.02856550078454138

4 0.01831563888872685

Diagrams are now created with the new OMPlot program by using the
following command.

plot(x);

seems to correspond well with the data.

Figure 323: **Simple 2D plot of the HelloWorld example.**

By re-simulating and saving results at many more points, e.g. using the
default 500 intervals, a much smoother plot can be obtained.

simulate(HelloWorld, startTime=0, stopTime=4, numberOfIntervals=500);

plot(x);

Figure 324: **Simple 2D plot of the HelloWorld example with larger
number of points.**

Plotting Commands and their Options
-----------------------------------

All of these commands can have any number of optional arguments to
further customize the the resulting diagram. The available options and
their allowed values are listed below.

+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| **Option **      | **Default value**                   | **Description**                                                                                             |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| fileName         | The result of the last simulation   | The name of the result-file containing the variables to plot                                                |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| grid             | true                                | Determines whether or not a grid is shown in the diagram.                                                   |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| title            | “”                                  | This text will be used as the diagram title.                                                                |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| logX             | false                               | Determines whether or not the horizontal axis is logarithmically scaled.                                    |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| logY             | false                               | Determines whether or not the vertical axis is logarithmically scaled.                                      |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| xLabel           | “time”                              | This text will be used as the horizontal label in the diagram.                                              |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| yLabel           | “”                                  | This text will be used as the vertical label in the diagram.                                                |
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
| legendPosition   | “top”                               | Defines the position of the legend in the diagram. Possible values are left, right, top, bottom and none.   |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
| externalWindow   | false                               | Opens a new OMPlot window if set to true otherwise update the current opened window.                        |
+------------------+-------------------------------------+-------------------------------------------------------------------------------------------------------------+
