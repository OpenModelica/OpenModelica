model string "model of a vibrating string with fixed ends"
  import C = Modelica.Constants;
  parameter Real L = 1; // length
  parameter Real T = 1; // tension
  parameter Real mu = 1; // linear density
  parameter DomainLineSegment1D omega(length = L);
  function u0
    input Real x;
    output Real u0 := sin(4*C.pi/L*x);
  end u0;
  field Real u(domain = omega, start = u0);
equation
  pder(u,time,time) - T/mu*pder(u,x,x) = 0   in  omega.interior;
  u = 0; in omega.left + omega.right;
end string;