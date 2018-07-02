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
  parameter Integer c = cardinality(u);
  parameter Integer c1 = cardinality(and1.u1);
  parameter Integer c2 = cardinality(and1.u2);
equation
  connect(u, and1.u1);
  connect(u, and1.u2);
end Cardinality3;

// Result:
// class Cardinality3
//   input Boolean u;
//   Boolean and1.u1;
//   Boolean and1.u2;
//   Boolean and1.y;
//   parameter Integer c = 2;
//   parameter Integer c1 = 1;
//   parameter Integer c2 = 1;
// equation
//   u = and1.u2;
//   u = and1.u1;
//   and1.y = and1.u1 and and1.u2;
// end Cardinality3;
// endResult
