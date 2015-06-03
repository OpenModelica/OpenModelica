Modelica Performance Analyzer
=============================

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

simulate(modelname, measureTime = true)

The generated report is in HTML format (with images in the SVG format),
stored in a file modelname\_prof.html, but the XML database and measured
times that generated the report and graphs are also available if you
want to customize the report for comparison with other tools.

Below we use the performance profiler on the simple model A:

.. code-block:: modelica

  model A
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
  end A;

We simulate as usual, but set measureTime=true to activate the
profiling:

simulate(A, measureTime = true)

// // record SimulationResult

// resultFile = "A\_res.mat",

// messages = "Time measurements are stored in A\_prof.html
(human-readable) and A\_prof.xml (for XSL transforms or more details)"

// end SimulationResult;

Example Report Generated for the A Model
----------------------------------------

Information
~~~~~~~~~~~

All times are measured using a real-time wall clock. This means context
switching produces bad worst-case execution times (max times) for
blocks. If you want better results, use a CPU-time clock or run the
command using real-time priviliges (avoiding context switches).

Note that for blocks where the individual execution time is close to the
accuracy of the real-time clock, the maximum measured time may deviate a
lot from the average.

For more details, see the generated file
`*A\_prof.xml* <http://www.ida.liu.se/~marsj/A_prof4/A_prof.xml>`__,
shown in Section 8.1.7 below.

Settings
~~~~~~~~

The settings for the simulation are summarized in the table below:

+--------------------------+-----------------------------------------------------------------------------+
|     **Name**             |     **Value**                                                               |
+--------------------------+-----------------------------------------------------------------------------+
|     Integration method   |     euler                                                                   |
+--------------------------+-----------------------------------------------------------------------------+
|     Output format        |     mat                                                                     |
+--------------------------+-----------------------------------------------------------------------------+
|     Output name          |     `*A\_res.mat* <http://www.ida.liu.se/~marsj/A_prof4/A_res.mat>`__       |
+--------------------------+-----------------------------------------------------------------------------+
|     Output size          |     24.0 kB                                                                 |
+--------------------------+-----------------------------------------------------------------------------+
|     Profiling data       |     `*A\_prof.data* <http://www.ida.liu.se/~marsj/A_prof4/A_prof.data>`__   |
+--------------------------+-----------------------------------------------------------------------------+
|     Profiling size       |     27.3 kB                                                                 |
+--------------------------+-----------------------------------------------------------------------------+

Summary
~~~~~~~

Execution times for different activities:

+-----------------------------+----------------+--------------------+
|     **Task**                |     **Time**   |     **Fraction**   |
+-----------------------------+----------------+--------------------+
|     Pre-Initialization      |     0.000401   |     19.17%         |
+-----------------------------+----------------+--------------------+
|     Initialization          |     0.000046   |     2.20%          |
+-----------------------------+----------------+--------------------+
|     Event-handling          |     0.000036   |     1.72%          |
+-----------------------------+----------------+--------------------+
|     Creating output file    |     0.000264   |     12.62%         |
+-----------------------------+----------------+--------------------+
|     Linearization           |     0.000000   |     0.00%          |
+-----------------------------+----------------+--------------------+
|     Time steps              |     0.001067   |     51.00%         |
+-----------------------------+----------------+--------------------+
|     Overhead                |     0.000273   |     13.05%         |
+-----------------------------+----------------+--------------------+
|     Unknown                 |     0.000406   |     0.24%          |
+-----------------------------+----------------+--------------------+
|     Total simulation time   |     0.002092   |     100.00%        |
+-----------------------------+----------------+--------------------+

Global Steps
~~~~~~~~~~~~

+-------------+-------------+------------------+----------------+------------------------+----------------+-----------------+
| ** **       | **Steps**   | **Total Time**   | **Fraction**   | **Average Time**       | **Max Time**   | **Deviation**   |
+-------------+-------------+------------------+----------------+------------------------+----------------+-----------------+
| |image39|   | 499         | 0.001067         | 51.00%         | 2.13827655310621e-06   | 0.000006611    | 2.09x           |
+-------------+-------------+------------------+----------------+------------------------+----------------+-----------------+

Measured Function Calls
~~~~~~~~~~~~~~~~~~~~~~~

+------------------------+------------+-------------+---------------+----------------+----------------+-----------------+
| ** **                  | **Name**   | **Calls**   | **Time**      | **Fraction**   | **Max Time**   | **Deviation**   |
+------------------------+------------+-------------+---------------+----------------+----------------+-----------------+
| |image40|\ |image41|   | *A.f*      | 1506        | 0.000092990   | 4.45%          | 0.000000448    | 6.26x           |
+------------------------+------------+-------------+---------------+----------------+----------------+-----------------+

Measured Blocks
~~~~~~~~~~~~~~~

+------------------------+-------------------+-------------+---------------+----------------+----------------+-----------------+
| ** **                  | **Name**          | **Calls**   | **Time**      | **Fraction**   | **Max Time**   | **Deviation**   |
+------------------------+-------------------+-------------+---------------+----------------+----------------+-----------------+
| |image42|\ |image43|   | *residualFunc3*   | 2018        | 0.000521137   | 24.91%         | 0.000035456    | 136.30x         |
+------------------------+-------------------+-------------+---------------+----------------+----------------+-----------------+
| |image44|\ |image45|   | *residualFunc1*   | 1506        | 0.000393709   | 18.82%         | 0.000002735    | 9.46x           |
+------------------------+-------------------+-------------+---------------+----------------+----------------+-----------------+

Equations
^^^^^^^^^

+-------------------------+-----------------+
| **Name**                | **Variables**   |
+-------------------------+-----------------+
| SES\_ALGORITHM 0        |                 |
+-------------------------+-----------------+
| SES\_SIMPLE\_ASSIGN 1   | *der(y)*        |
+-------------------------+-----------------+
| residualFunc3           | *z2*, *z1*      |
+-------------------------+-----------------+
| residualFunc1           | *x*             |
+-------------------------+-----------------+

Variables
^^^^^^^^^

+--------------+---------------+
| **Name**     | **Comment**   |
+--------------+---------------+
| \ *y*        |               |
+--------------+---------------+
| \ *der(y)*   |               |
+--------------+---------------+
| \ *x*        | This is x     |
+--------------+---------------+
| \ *z1*       |               |
+--------------+---------------+
| \ *z2*       |               |
+--------------+---------------+
| \ *s*        |               |
+--------------+---------------+

Genenerated XML for the Example
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: xml

  <!DOCTYPE doc (View Source for full doctype...)>
  <simulation>
  <modelinfo>
  <name>A</name>
  <prefix>A</prefix>
  <date>2011-03-07 12:55:53</date>
  <method>euler</method>
  <outputFormat>mat</outputFormat>
  <outputFilename>A\_res.mat</outputFilename>
  <outputFilesize>24617</outputFilesize>
  <overheadTime>0.000273</overheadTime>
  <preinitTime>0.000401</preinitTime>
  <initTime>0.000046</initTime>
  <eventTime>0.000036</eventTime>
  <outputTime>0.000264</outputTime>
  <linearizeTime>0.000000</linearizeTime>
  <totalTime>0.002092</totalTime>
  <totalStepsTime>0.001067</totalStepsTime>
  <numStep>499</numStep>
  <maxTime>0.000006611</maxTime>
  </modelinfo>
  <profilingdataheader>
  <filename>A\_prof.data</filename>
  <filesize>28000</filesize>
  <format>
  <uint32>step</uint32>
  <double>time</double>
  <double>cpu time</double>
  <uint32>A.f (calls)</uint32>
  <uint32>residualFunc3 (calls)</uint32>
  <uint32>residualFunc1 (calls)</uint32>
  <double>A.f (cpu time)</double>
  <double>residualFunc3 (cpu time)</double>
  <double>residualFunc1 (cpu time)</double>
  </format>
  </profilingdataheader>
  <variables>
  <variable id="1000" name="y" comment="">
  <info filename="a.mo" startline="8" startcol="3" endline="8" endcol="18" readonly="writable" />
  </variable>
  <variable id="1001" name="der(y)" comment="">
  <info filename="a.mo" startline="8" startcol="3" endline="8" endcol="18" readonly="writable" />
  </variable>
  <variable id="1002" name="x" comment="This is x">
    <info filename="a.mo" startline="7" startcol="3" endline="7" endcol="28" readonly="writable" />
  </variable>
  <variable id="1003" name="z1" comment="">
    <info filename="a.mo" startline="9" startcol="3" endline="9" endcol="20" readonly="writable" />
  </variable>
  <variable id="1004" name="z2" comment="">
    <info filename="a.mo" startline="10" startcol="3" endline="10" endcol="20" readonly="writable" />
  </variable>
  <variable id="1005" name="s" comment="">
    <info filename="a.mo" startline="6" startcol="3" endline="6" endcol="19" readonly="writable" />
  </variable>
  </variables>
  <functions>
  <function id="1006">
  <name>A.f</name>
  <ncall>1506</ncall>
  <time>0.000092990</time>
  <maxTime>0.000000448</maxTime>
  <info filename="a.mo" startline="2" startcol="3" endline="5" endcol="8"
  readonly="writable" />
  </function>
  </functions>
  <equations>
  <equation id="1007" name="SES\_ALGORITHM 0">
  <refs />
  </equation>
  <equation id="1008" name="SES\_SIMPLE\_ASSIGN 1">
  <refs>
  <ref refid="1001" />
  </refs>
  </equation>
  <equation id="1009" name="residualFunc3">
  <refs>
  <ref refid="1004" />
  <ref refid="1003" />
  </refs>
  </equation>
  <equation id="1010" name="residualFunc1">
  <refs>
  <ref refid="1002" />
  </refs>
  </equation>
  </equations>
  <profileblocks>
  <profileblock>
  <ref refid="1009" />
  <ncall>2018</ncall>
  <time>0.000521137</time>
  <maxTime>0.000035456</maxTime>
  </profileblock>
  <profileblock>
  <ref refid="1010" />
  <ncall>1506</ncall>
  <time>0.000393709</time>
  <maxTime>0.000002735</maxTime>
  </profileblock>
  </profileblocks>
  </simulation>

.. |image39| image:: media/image76.png
.. |image40| image:: media/image77.png
.. |image41| image:: media/image78.png
.. |image42| image:: media/image79.png
.. |image43| image:: media/image80.png
.. |image44| image:: media/image81.png
.. |image45| image:: media/image82.png
