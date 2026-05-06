// name:     differentiate functions
// keywords: functions, derivative annotation, numerical, analytical
// status:   correct
//

function f1
  input Real x;
  output Real y;
algorithm
  y := cos(x);
end f1;

function f
  input Real x;
  output Real y;
algorithm
  y := cos(x);
  annotation(derivative=df);
end f;

function df
  input Real x;
  input Real dx;
  output Real dy;
algorithm
  dy := -sin(x)*dx;
end df;

model extfunction
  Real x(start=1),y(start=-1);
equation
 der(x) = f(y)*x;
 der(y) = f1(x)*y;
end extfunction;
