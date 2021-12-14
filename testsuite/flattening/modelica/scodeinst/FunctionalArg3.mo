// name: FunctionalArg3
// keywords:
// status: correct
// cflags: -d=newInst
//

partial function F
  input Real x;
  output Real y;
end F;

function f1
  input F f;
  input Real x;
  output Real y;
algorithm
  y := f(x);
end f1;

function f2
  input Real x;
  input Real z = 1.0;
  output Real y = x * 2 + z;
end f2;

model FunctionalArg3
  constant Real x = f1(f2, 1);
end FunctionalArg3;

// Result:
// class FunctionalArg3
//   constant Real x = 3.0;
// end FunctionalArg3;
// endResult
