// name: RecordExtends2
// keywords:
// status: correct
// cflags: -d=newInst
//

package P
  constant Integer n;

  record R
    Real x[n];
  end R;
end P;

model M1
  package P1 = P(n = 1);
  P1.R r1 = P1.R({1.0});
end M1;

model M2
  package P2 = P(n = 2);
  P2.R r2 = P2.R({1.0, 2.0});
end M2;

model RecordExtends2
  M1 m1;
  M2 m2;
end RecordExtends2;

// Result:
// class RecordExtends2
//   Real m1.r1.x[1];
//   Real m2.r2.x[1];
//   Real m2.r2.x[2];
// equation
//   m1.r1.x = {1.0};
//   m2.r2.x = {1.0, 2.0};
// end RecordExtends2;
// endResult
