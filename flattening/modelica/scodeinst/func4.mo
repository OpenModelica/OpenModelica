// name: func4.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Should stream on function variables be allowed?
//

function f
  input Real x;
  stream input Real y;
  input Real z;
  output Real a;
  output Real b;
  output Real c;
algorithm
  a := x;
  b := y;
  c := z;
end f;

model M
  Real x, y, z;
equation
  (x, y, z) = f(x, y, z);
end M;
