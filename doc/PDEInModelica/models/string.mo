model string "model of a vibrating string with fixed ends"
  import C = Modelica.Constants;
  parameter Real L = 1; // length
  parameter Real c = 1; // tension/(linear density)
  parameter DomainLineSegment1D omega(length = L);
  parameter field Real u0 = {sin(4*C.pi/L*dom.x) for dom.x in omega.ingerior};
  field Real u(domain = omega, start[0] = u0, start[1] = 0);
equation
  pder(u,time,time) - c*pder(u,x,x) = 0   in omega.interior;
  u = 0                                   in omega.left + omega.right;
end string;