model advection "advection equation"
  import PDEDomains.*
  parameter Real L = 1; // length
  parameter Real c = 1;
  parameter DomainLineSegment1D omega(l = L);
  field Real u(domain = omega, start = 0);
equation
  pder(u,time) + c*pder(u,x) = 0; //by default in omega.interior
  u = sin(2*3.14*time)            in omega.left;
end advection;
