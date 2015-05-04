// name:     ReplaceFunction
// keywords: modification
// status:   incorrect
//
// Function arguments must be identical, including their names,
// in functions of the same type.
//

function Sin
  input Real x;
  output Real y;
algorithm
  y:=sin(x);
end Sin;

function Cos
  input Real xx;
  output Real yy;
algorithm
  yy:=cos(xx);
end Cos;

model M
  replaceable function f = Sin;
  Real x;
equation
  x=f(x);
end M;

model ReplaceFunction = M(redeclare function f = Cos);   // Error
