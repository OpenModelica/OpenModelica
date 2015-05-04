// name:     Modification2
// keywords: redeclare, modification
// status:   correct
//
// Checks that modifiers are propagated and merged correctly when redeclaring
// classes.
//

model M
  Real x;
end M;

package P
  replaceable model M = .M;
end P;

package P2
  extends P(replaceable model M = .M(x(start = 2.0)));
end P2;

package P3
  extends P2(replaceable model M = .M(x(min = 3.0)));
end P3;

model Modification2
  P2.M m;
  P3.M m2;
end Modification2;

// Result:
// class Modification2
//   Real m.x(start = 2.0);
//   Real m2.x(min = 2.0, start = 2.0);
// end Modification2;
// endResult
