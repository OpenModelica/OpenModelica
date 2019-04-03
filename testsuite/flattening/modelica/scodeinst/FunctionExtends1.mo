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
// class M
//   Real x = 1.0;
// end M;
// endResult
