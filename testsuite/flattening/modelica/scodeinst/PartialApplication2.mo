// name: PartialApplication2
// keywords:
// status: correct
// cflags: -d=newInst
//

partial function pf
  input Real x;
  output Real z;
end pf;

function f1
  input Real x;
  input pf f;
  output Real z;
algorithm
  z := f(x);
end f1;

function f2
  input Real x;
  input Real y;
  output Real z = x + y;
end f2;

function f3
  input Real x;
  input Real y;
  output Real z;
algorithm
  z := f1(x, function f2(y = y));
end f3;

model PartialApplication2
  Real x = f3(1.0, 2.0);
end PartialApplication2;

// Result:
// class PartialApplication2
//   Real x = 3.0;
// end PartialApplication2;
// endResult
