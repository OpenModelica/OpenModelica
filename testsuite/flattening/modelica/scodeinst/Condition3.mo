// name: Condition3
// keywords:
// status: correct
//
//


model M
  parameter Boolean b1 = true;
  parameter Boolean b2 = false;

  Real x if b1;
  Real y if b2;
end M;

model Condition3
  extends M(x = 2, y = 3);
end Condition3;

// Result:
// class Condition3
//   final parameter Boolean b1 = true;
//   final parameter Boolean b2 = false;
//   Real x = 2.0;
// end Condition3;
// endResult
