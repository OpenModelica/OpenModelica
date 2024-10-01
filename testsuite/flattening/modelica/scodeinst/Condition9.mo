// name: Condition9
// keywords:
// status: correct
//
//

connector C
  Real x if false;
end C;

connector C2
  C c if false;
end C2;

model Condition9
  C2 c1;
  C2 c2;
equation
  connect(c1, c2);
end Condition9;

// Result:
// class Condition9
// end Condition9;
// endResult
