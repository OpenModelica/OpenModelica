// name:     RedeclareClass3
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

  redeclare replaceable model M2
    Real r;
  end M2;
end P2;

package P3
  extends P2;

  redeclare model M2
    extends P2.M2;
    Real r2;
  end M2;
end P3;

model RedeclareClass3
  P3.M1 m1;
equation
  m1.r = 1.0;
  m2.r2 = 2.0;
end RedeclareClass3;

// Result:
// class RedeclareClass3
//   Real m1.r;
//   Real m2.r2;
// equation
//   m1.r = 1.0;
//   m2.r2 = 2.0;
// end RedeclareClass3;
// endResult
