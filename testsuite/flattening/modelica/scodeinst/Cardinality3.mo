// name: Cardinality3
// keywords: cardinality
// status: correct
// cflags: -d=newInst
//
// Tests the builtin cardinality operator.
//

connector BooleanInput = input Boolean;
connector BooleanOutput = output Boolean;

block And
  BooleanInput u1;
  BooleanInput u2;
  BooleanOutput y;
equation
  y = u1 and u2;
end And;

model Cardinality3
  BooleanInput u;
  And and1;
equation
  assert(cardinality(u) == 2, "cardinality(u) should be 2");
  assert(cardinality(and1.u1) == 1, "cardinality(and1.u1) should be 1");
  assert(cardinality(and1.u2) == 1, "cardinality(and1.u2) should be 1");
  connect(u, and1.u1);
  connect(u, and1.u2);
end Cardinality3;

// Result:
// class Cardinality3
//   input Boolean u;
//   Boolean and1.u1;
//   Boolean and1.u2;
//   Boolean and1.y;
// equation
//   u = and1.u2;
//   u = and1.u1;
//   and1.y = and1.u1 and and1.u2;
// end Cardinality3;
// endResult
