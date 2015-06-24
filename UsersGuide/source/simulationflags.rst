Small Overview of Simulation Flags
==================================

This chapter contains a :ref:`short overview of simulation flags <cruntime-simflags>`
as well as additional details of the :ref:`numerical integration methods <cruntime-integration-methods>`.

.. _cruntime-simflags :

OpenModelica (C-runtime) Simulation Flags
-----------------------------------------

.. include :: simoptions.inc

.. _cruntime-integration-methods :

Integration Methods
-------------------

This section contains additional information about the different
integration methods in OpenModelica, selected by the method flag
of the :ref:`simulate` command or the :ref:`-s simflag <simflag-s>`.

dassl
~~~~~

Default integration method in OpenModelica.
Adams Moulton; the default uses a colored numerical Jacobian and interval root finding.
To change settings, use simulation flags such as
:ref:`dasslJacobian <simflag-dassljacobian>`,
:ref:`dasslNoRootFinding <simflag-dasslnorootfinding>`,
:ref:`dasslNoRestart <simflag-dasslnorestart>`,
:ref:`initialStepSize <simflag-initialstepsize>`,
:ref:`maxStepSize <simflag-maxstepsize>`,
:ref:`maxIntegrationOrder <simflag-maxintegrationorder>`,
:ref:`noEquidistantTimeGrid <simflag-noequidistanttimegrid>`.

+----------------------+-----------------------------+
| Order:               | 1-5                         |
+----------------------+-----------------------------+
| Step Size Control:   | true                        |
+----------------------+-----------------------------+
| Order Control:       | true                        |
+----------------------+-----------------------------+
| Stability Region:    | variable; depend from order |
+----------------------+-----------------------------+

euler
~~~~~

Explicit Euler.

+----------------------+---------------------+
| Order:               | 1                   |
+----------------------+---------------------+
| Step Size Control:   | false               |
+----------------------+---------------------+
| Order Control:       | false               |
+----------------------+---------------------+
| Stability Region:    | \|(1,0) Padé \| ≤ 1 |
+----------------------+---------------------+

rungekutta
~~~~~~~~~~

Classical Runge-Kutta method.

+----------------------+---------------------+
| Order:               | 4                   |
+----------------------+---------------------+
| Step Size Control:   | false               |
+----------------------+---------------------+
| Order Control:       | false               |
+----------------------+---------------------+
| Stability Region:    | \|(4,0) Padé \| ≤ 1 |
+----------------------+---------------------+

radau1
~~~~~~

Radau IIA with one point.

+----------------------+---------------------+
| Order:               | 1                   |
+----------------------+---------------------+
| Step Size Control:   | false               |
+----------------------+---------------------+
| Order Control:       | false               |
+----------------------+---------------------+
| Stability Region:    | \|(0,1) Padé \| ≤ 1 |
+----------------------+---------------------+

radau3
~~~~~~

Radau IIA with two points.

+----------------------+---------------------+
| Order:               | 3                   |
+----------------------+---------------------+
| Step Size Control:   | false               |
+----------------------+---------------------+
| Order Control:       | false               |
+----------------------+---------------------+
| Stability Region:    | \|(1,2) Padé \| ≤ 1 |
+----------------------+---------------------+

radau5
~~~~~~

Radau IIA with three points.

+----------------------+---------------------+
| Order:               | 5                   |
+----------------------+---------------------+
| Step Size Control:   | false               |
+----------------------+---------------------+
| Order Control:       | false               |
+----------------------+---------------------+
| Stability Region:    | \|(2,3) Padé \| ≤ 1 |
+----------------------+---------------------+

lobatto2
~~~~~~~~

Lobatto IIIA with two points.

+----------------------+---------------------+
| Order:               | 2                   |
+----------------------+---------------------+
| Step Size Control:   | false               |
+----------------------+---------------------+
| Order Control:       | false               |
+----------------------+---------------------+
| Stability Region:    | \|(2,2) Padé \| ≤ 1 |
+----------------------+---------------------+

lobatto4
~~~~~~~~

Lobatto IIIA with three points.

+----------------------+---------------------+
| Order:               | 4                   |
+----------------------+---------------------+
| Step Size Control:   | false               |
+----------------------+---------------------+
| Order Control:       | false               |
+----------------------+---------------------+
| Stability Region:    | \|(3,3) Padé \| ≤ 1 |
+----------------------+---------------------+

lobatto6
~~~~~~~~

Lobatto IIIA with four points.

+----------------------+---------------------+
| Order:               | 6                   |
+----------------------+---------------------+
| Step Size Control:   | false               |
+----------------------+---------------------+
| Order Control:       | false               |
+----------------------+---------------------+
| Stability Region:    | \|(4,4) Padé \| ≤ 1 |
+----------------------+---------------------+

Notes
~~~~~

Simulation flags
:ref:`maxStepSize <simflag-maxstepsize>` and
:ref:`maxIntegrationOrder <simflag-maxintegrationorder>`
specifiy maximum absolute step size and maximum integration order used by
the dassl solver.

General step size without control :math:`\approx \cfrac{\mbox{stopTime} - \mbox{startTime}}{\mbox{numberOfIntervals}}`.
Events change the step size (see `Modelica spec 3.3 p. 88 <https://www.modelica.org/documents/ModelicaSpec33.pdf>`__).

For (a,b) Padé see `wikipedia <http://en.wikipedia.org/wiki/Pad%C3%A9_table>`__.
