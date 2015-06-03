Introduction
============

Inline math equations go in like so: :math:`\omega = d\phi/dt`. Display
math should get its own line and be put in in double-dollarsigns:

.. math::
  I = \int \rho \frac{R^{2}}{x} dV

Some Modelica code?

.. code-block:: modelica

  model M
    Real r(start=1.0);
  equation
    der(r) = 2.0;
  end M;

Some C code:

.. code-block:: c

  void f(int a, double b)
  { // abc
    return a + b + "abc";
  }

Some reference to Peter's book :cite:`openmodelica.org:fritzson:2014`.

:cite:`openmodelica.org:tiller:2014` says that...

Cite an article :cite:`openmodelica.org:pop:mic:2014`.

Cite the big one :cite:`openmodelica:current`

.. figure:: logo.svg
  :alt: OpenModelica logotype

  OpenModelica logotype

Here comes an inline image of the |omlogo| logotype.

.. bibliography:: openmodelica.bib extrarefs.bib

.. |omlogo| image:: logo.svg
  :alt: OpenModelica logotype
  :width: 20%
