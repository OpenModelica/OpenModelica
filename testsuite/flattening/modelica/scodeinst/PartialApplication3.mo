// name: PartialApplication3
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
  input Real w;
  output Real z = x + y + w;
end f2;

function f3
  input Real x;
  input Real y;
  output Real z;
algorithm
  z := f1(x, function f2(w = y, y = x));
end f3;

model PartialApplication3
  Real x = f3(time, time);
end PartialApplication3;

// Result:
// function f1
//   input Real x;
//   input f<function>(#Real x) => #Real f;
//   output Real z;
// algorithm
//   z := unbox(f(#(x)));
// end f1;
//
// function f2
//   input Real x;
//   input Real y;
//   input Real w;
//   output Real z = x + y + w;
// end f2;
//
// function f3
//   input Real x;
//   input Real y;
//   output Real z;
// algorithm
//   z := f1(x, function f2(#(x), #(y)));
// end f3;
//
// class PartialApplication3
//   Real x = f3(time, time);
// end PartialApplication3;
// endResult
