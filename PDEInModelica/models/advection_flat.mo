/*TODO: finish it!!*/
function PDEDomains.DomainLineSegment1D.shapeFunc
  input Real v;
  output Real x = l*v + a;
end PDEDomains.DomainLineSegment1D.shapeFunc;


model advection_flat "advection equation"
  import C = Modelica.Constants;
  parameter Real L = 1; // length
  parameter Real c = 1;
//  parameter DomainLineSegment1D omega(length = L);
  parameter Real omega.l = L;
  parameter Real omega.a = 0;





  Domain1DInterior DomainLineSegment1D.interior(shape = shapeFunc, range = {0,1});
  Domain1DBoundary DomainLineSegment1D.left(shape = shapeFunc, range = {0,0});
  Domain1DBoundary DomainLineSegment1D.right(shape = shapeFunc, range = {1,1});

  field Real u(domain = omega, start = 1);
equation
  pder(u,time) + c*pder(u,x) = 0  in  omega.interior;
  u = cos(2*pi*time) in omega.left;
end advection_flat;