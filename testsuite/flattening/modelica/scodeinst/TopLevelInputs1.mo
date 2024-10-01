// name: TopLevelInputs1
// keywords:
// status: correct
//

model A
  input Real x;
end A;

record R
  Real y;
end R;

model TopLevelInputs1
  A a;
  input R r;
  input Real z;
end TopLevelInputs1;

// Result:
// class TopLevelInputs1
//   Real a.x;
//   input Real r.y;
//   input Real z;
// end TopLevelInputs1;
// endResult
