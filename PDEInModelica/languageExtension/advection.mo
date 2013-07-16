model advection "advection equation"
  import C = Modelica.Constants;
  parameter Real L = 1; // length
  parameter Real c = 1; 
  parameter DomainLineSegment1D omega(length = L);
  field Real u(domain = omega, start = 1);
equation
  pder(u,time) + c*pder(u,x) = 0  in  omega.interior;
  u = cos(2*C.pi*time) in omega.left; 
end advection;