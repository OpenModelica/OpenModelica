// name: Condition10
// keywords:
// status: correct
//

model Condition10
  Real x if true;
  Real y = x;
end Condition10;

// Result:
// class Condition10
//   Real x;
//   Real y = x;
// end Condition10;
// endResult
