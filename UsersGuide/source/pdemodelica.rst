PDEModelica1
============

PDEModelica1 is nonstandardised experimental Modelica language extension for 1-dimensional partial differential extensions (PDE).

It is enabled using compiler flag ``--grammar=PDEModelica``. Compiler flags may be set e.g. in OMEdit (Tools->Options->Simulation->OMC Flags) or in the OpenModelica script using command

.. omc-mos ::
  setCommandLineOptions("--grammar=PDEModelica")


PDEModelica1 language elements
------------------------------

Let us introduce new PDEModelica1 language elements by an advection equation example model:


.. omc-loadstring ::

  model Advection "advection equation"
    parameter Real pi = Modelica.Constants.pi;
    parameter DomainLineSegment1D omega(L = 1, N = 100)  "domain";
    field Real u(domain = omega)                         "field";
  initial equation
    u = sin(2*pi*omega.x)                                "IC";
  equation
    der(u) + pder(u,x) = 0   indomain omega              "PDE";
    u = 0                    indomain omega.left         "BC";
    u = extrapolateField(u)  indomain omega.right        "extrapolation";
  end Advection;

The domain ``omega`` represents the geometrical domain where the PDE holds. The domain is
defined using the built-in record ``DomainLineSegment1D``. This   record contains among
others ``L`` – the length of the domain, ``N`` – the number of grid points, ``x`` –
the coordinate variable and the regions ``left``, ``right`` and ``interior``, representing
the left and right boundaries and the interior of the domain.

The field variable ``u`` is defined using a new keyword ``field``. The ``domain``
is a mandatory attribute to specify the domain of the field.

The ``indomain`` operator specifies where the equation containing the field variable holds. It
is utilised in the initial conditions (IC) of the fields, in the PDE and in the boundary
conditions (BC). The syntax is

| ``anEquation indomain aDomain.aRegion;``

If the region is omitted, ``interior`` is the default (e.g. the PDE in the example above).

The IC of the field variable u is written using an expression containing the coordinate
variable ``omega.x``.

The PDE contains a partial space derivative written using the ``pder`` operator. Also
the second derivative is allowed (not in this example), the syntax is e.g. ``pder(u,x,x)``.
It is not necessary to specify the domain of coordinate in pder (to write e.g. ``pder(u,omega.x)``, even though ``x`` is a member of ``omega``.

Limitations
-----------

BCs may be written only in terms of variables that are spatially differentiated currently.

All fields that are spatially differentiated must have either BC or extrapolation at each
boundary. This extrapolation should be done automatically by the compiler, but this has
not been implemented yet. The current workaround is the usage of the ``extrapolateField()``
operator directly in the model.

If-equations are not spported yet, if-expressions must be used instead.

Viewing results
---------------

During translation field variables are replaced with arrays. These arrays may be plotted using :ref:`array-plot` or even better using :ref:`array-parametric-plot` (to plot x-coordinate versus a field).



.. omc-reset ::