model string "model of a vibrating string"
  parameter Real L = 1; // length
  parameter Real c = 1; // tension/(linear density)
  parameter DomainLineSegment1D omega(length = L);
  field Real u(domain = omega, start = sin(sqrt(c)*omega.x);
  field Real v(domain = omega);
initial equation
  pder(u,time) = 0;
equation
  pder(u,time) - c*pder(v,x) = 0;
  pder(v,time) - pder(u,x) = 0;
  u = if time < 0.5 then sin(2.0*C.pi*time) else 0    in omega.left;
  pder(u,x) = 0                                       in omega.right;
end string;
