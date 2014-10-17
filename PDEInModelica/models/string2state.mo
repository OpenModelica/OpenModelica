model string "model of a vibrating string"
  import PDEDomains.*;
  parameter Real L = 1; // length
  parameter Real c = 1; // tension/(linear density)
  parameter DomainLineSegment1D omega(l = L);
  field Real u( domain = omega, start = sin(-2*3.14/sqrt(c)*omega.x) );
  field Real v( domain = omega );
initial equation
  der(u) = 0;
equation
  der(u) - c*der(v,x) = 0;
  der(v) - der(u,x) = 0;
  u = sin(2.0*3.14*time)           in omega.left;
  pder(u,x) = 0                    in omega.right;
end string;
