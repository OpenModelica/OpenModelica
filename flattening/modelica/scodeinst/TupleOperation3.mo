// name: TupleOperation3
// keywords:
// status: correct
// cflags: -d=newInst
//

function f
  output Integer n1 = 2;
  output Integer n2 = 3;
end f;

model TupleOperation3
  Real x[f()];
end TupleOperation3;

// Result:
// class TupleOperation3
//   Real x[1];
//   Real x[2];
// end TupleOperation3;
// endResult
