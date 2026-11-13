// name:     RedeclareClass2
// keywords: redeclare class
// status:   correct
//
// Tests simple redeclaration of inherited classes.
//

package P1
  replaceable model M
  end M;
end P1;

package P2
  extends P1;

  redeclare model M
    Real r;
  end M;
end P2;

model RedeclareClass1
  P1.M m1;
  P2.M m2;
equation
  m2.r = 1.0;
end RedeclareClass1;

// Result:
// class RedeclareClass1
//   Real m2.r;
// equation
//   m2.r = 1.0;
// end RedeclareClass1;
// endResult
