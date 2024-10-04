// name:     ImpureCall1
// keywords:
// status:   correct
//
//

impure function f
  input Real x;
  output Real y = x;
end f;

function f2
  input Real x;
  output Real y;
algorithm
  y := f(x);
end f2;

model ImpureCall1
  Real x = f2(1.0);
end ImpureCall1;

// Result:
// impure function f
//   input Real x;
//   output Real y = x;
// end f;
//
// impure function f2
//   input Real x;
//   output Real y;
// algorithm
//   y := f(x);
// end f2;
//
// class ImpureCall1
//   Real x = f2(1.0);
// end ImpureCall1;
// [flattening/modelica/scodeinst/ImpureCall1.mo:12:1-17:7:writable] Warning: Pure function 'f2' contains a call to impure function 'f'.
//
// endResult
