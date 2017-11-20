// name: FunctionExtends1
// keywords:
// status: correct
// cflags: -d=newInst
//

partial function f
  input Real x;
  output Real y;
end f;

function f2
  extends f;
algorithm
  y := x;
end f2;

model M
  Real x = f2(1.0);
end M;

// Result:
// function f2
//   input Real x;
//   output Real y;
// algorithm
//   y := x;
// end f2;
//
// class M
//   Real x = f2(1.0);
// end M;
// endResult
