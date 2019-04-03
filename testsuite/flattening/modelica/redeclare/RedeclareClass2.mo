// name:     RedeclareClass2
// keywords: redeclare class
// status:   correct
//
// Tests simple redeclaration of inherited classes.
//

package P1
  model M1
    M2 m;
  end M1;

  replaceable model M2
  end M2;
end P1;

package P2
  extends P1;

  redeclare model M2
    Real r;
  end M2;
end P2;

model RedeclareClass2
  P2.M1 m1;
equation
  m1.r = 1.0;
end RedeclareClass2;

// Result:
// class RedeclareClass2
//   Real m2.r;
// equation
//   m2.r = 1.0;
// end RedeclareClass2;
// endResult
