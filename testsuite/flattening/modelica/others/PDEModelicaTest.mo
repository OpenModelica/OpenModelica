model PDEModelicaTest
  model PDE
    constant Real pi = 3.14159;
    DomainLineSegment1D omega(N = 5, L=2);
    field Real u(domain = omega);
  equation
    der(u) + pder(u,x) - pder(u,x,x) = 0  indomain omega;
    u = extrapolateField(u)               indomain omega.right;
  end PDE;

  model PDE2
    extends PDE;
  initial equation
    u = sin(omega.x*2*pi) indomain omega;
  equation
    u = 0                 indomain omega.left;
  end PDE2;

  PDE2 pde2;
end PDEModelicaTest;
