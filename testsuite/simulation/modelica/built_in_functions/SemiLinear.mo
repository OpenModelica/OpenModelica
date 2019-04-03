class SemiLinearTest
  parameter Real a=1;
  parameter Real b=2;

  Real c;
  Real x(start=5);
equation
  der(x) = -1;
  c = semiLinear(x,a,b);
end SemiLinearTest;

model SemiLinearTest2 "https://trac.openmodelica.org/OpenModelica/ticket/3765"
  parameter Real k=1000;
  parameter Real d=2.847;
  parameter Real dL=-0.1;
  Real L(start=2.8,fixed=true);
  Real T;
  Real T2;
equation
  der(L)=dL;
  T=semiLinear(d / L - 1, k, 0);
  T2=semiLinear(d / L - 1, k-1, k-d);
end SemiLinearTest2;
