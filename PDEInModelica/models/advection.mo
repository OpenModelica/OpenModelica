model advection "advection equation"
  annotation(experiment(GridNodes = 100));

  parameter Real L = 1; // length

  parameter PDEDomains.DomainLineSegment1D omega(l = L);

  field Real u(domain = omega, start = 0);

  parameter Real c = 1;

equation
  der(u) + c*der(u,x) = 0;        //by default in omega.interior
  u = sin(2*3.14*time)            in omega.left;
end advection;
