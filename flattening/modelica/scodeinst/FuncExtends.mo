// name: FuncExtends
// keywords:
// status: correct
// cflags: -d=newInst
//

function f
  input Real x;
end f;

function f2
  extends f;
  output Real y = x;
end f2;

model M
  Real x = f2(1.0);
end M;

// Result:
// class M
//   Real x = 1.0;
// end M;
// endResult
