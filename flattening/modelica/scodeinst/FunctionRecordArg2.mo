// name: FunctionRecordArg2
// keywords:
// status: correct
// cflags:   -d=newInst
//

record R
  Real x = 1.0;
  Real y = 2.0;
end R;

function f
  output Real x;
protected
  R r;
algorithm
  x := r.x;
end f;

model M
  Real x = f();
end M;

// Result:
// class M
//   Real x = 1.0;
// end M;
// endResult
