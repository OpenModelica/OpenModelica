// name:     Modification1
// keywords: redeclare, modification
// status:   correct
//
// Checks that modifiers are propagated and merged correctly when redeclaring
// components.
//

model m
  replaceable Real x(max = 4.0);
end m;

model m2
  extends m(replaceable Real x(start = 2.0));
end m2;

model Modification1
  extends m2(replaceable Real x(min = 3.0));
end Modification1;

// Result:
// class Modification1
//   Real x(min = 3.0, max = 4.0);
// end Modification1;
// endResult
