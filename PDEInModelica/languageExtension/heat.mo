model heat "model of a vibrating string with fixed ends"
  parameter Real a = 1; // domain square half length
  parameter DomainRectangle2D omega(Lx=2*a, Ly=2*a);
 DomainLineSegment1D omega(length = L);
  function u0
    input Real x;
    output Real u0 := sin(4*C.pi/L*x);
  end u0;
  field Real u(domain = omega, start = u0);
equation
  pder(u,time,time) - T/mu*pder(u,x,x) = 0   in  omega.interior;
  u = 0; in omega.left + omega.right;
end heat;