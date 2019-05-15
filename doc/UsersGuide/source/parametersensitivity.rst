Parameter Sensitivities with OpenModelica
=========================================

This section describes the use of OpenModelica to compute parameter
sensitivities using forward sensitivity analysis together with the
Sundials/IDA solver.

*Note: this is a very short preliminary description which soon will be
considerably improved, since this a rather new feature and will
continuous improved.*

*Note: OpenModelica version 1.10 or newer is required.*


Background
----------

Parameter sensitivity analysis aims at analyzing the behavior of the
corresponding model states w.r.t. model parameters.

Formally, consider a Modelica model as a DAE system:

.. math::
    F(x, \dot x, y, p, t) = 0 \; x(t_0) = x_0(p)

where
:math:`x(t) \in \mathbf{R}^n` represent state variables,
:math:`\dot x(t) \in \mathbf{R}^n` represent state derivatives,
:math:`y(t) \in \mathbf{R}^k` represent algebraic variables,
:math:`p \in \mathbf{R}^m` model parameters.

For parameter sensitivity analysis the derivatives

.. math::
    \frac{\partial x}{ \partial p}

are required which quantify, according to their mathematical definition,
the impact of parameters :math:`p` on states :math:`x`.
In the Sundials/IDA implementation the derivatives are used to evolve the
solution over the time by:

.. math::
    \dot s_i = \frac{\partial x}{ \partial p_i}


An Example
----------

This section demonstrates the usage of the sensitivities analysis in
OpenModelica on an example. This module is enabled by the following
OpenModelica compiler flag:

.. omc-mos ::
  setCommandLineOptions("--calculateSensitivities");


.. omc-loadstring ::
  :caption: LotkaVolterra.mo
  :name: LotkaVolterra.mo

  model LotkaVolterra
    Real x(start=5, fixed=true),y(start=3, fixed=true);
    parameter Real mu1=5,mu2=2;
    parameter Real lambda1=3,lambda2=1;
  equation
    0 = x*(mu1-lambda1*y) - der(x);
    0 = -y* (mu2 -lambda2*x) - der(y);
  end LotkaVolterra;

Also for the simulation it is needed to set ``IDA`` as solver integration
method and add a further simulation flag ``-idaSensitivity`` to calculate
the parameter sensitivities during the normal simulation.

.. omc-mos ::

  simulate(LotkaVolterra, method="ida", simflags="-idaSensitivity")

Now all calculated sensitivities are stored into the results mat file under
the $Sensitivities block, where all currently every
**top-level** parameter of the Real type is used to calculate the
sensitivities w.r.t. **every state**.

.. omc-gnuplot :: LotkaVolterraSensitivities
  :caption: Results of the sensitivities calculated by IDA solver.

  $Sensitivities.lambda1.x
  $Sensitivities.lambda1.y
  $Sensitivities.lambda2.x
  $Sensitivities.lambda2.y
  $Sensitivities.mu1.x
  $Sensitivities.mu1.y
  $Sensitivities.mu2.x
  $Sensitivities.mu2.y

.. omc-gnuplot :: LotkaVolterraResults
  :caption: Results of the LotkaVolterra equations.

  x
  y

.. omc-reset ::
