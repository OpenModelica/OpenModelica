model advection "advection equation"
  parameter Real L = 1; // length
  parameter DomainLineSegment1D omega(l = L);
  field Real u(domain = omega);
  parameter Real c = 1;
initial equation
  u = if omega.x<0.25 then cos(2*3.14*omega.x) else 0 indomain omega;
equation
  der(u) + c*pder(u,x) = 0 indomain omega;
  u = 1                    indomain omega.left;
  annotation(experiment(GridNodes = 100));
end advection;



