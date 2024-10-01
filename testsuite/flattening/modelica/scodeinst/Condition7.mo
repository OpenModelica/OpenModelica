// name: Condition7
// keywords:
// status: correct
//
//

model A
  parameter Boolean b;
  Real x if b;
end A;

model Condition7
  A a[3](b = {false, true, false});
end Condition7;

// Result:
// class Condition7
//   final parameter Boolean a[1].b = false;
//   final parameter Boolean a[2].b = true;
//   Real a[2].x;
//   final parameter Boolean a[3].b = false;
// end Condition7;
// endResult
