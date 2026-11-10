// name:     RedeclareInClassModification.mo [BUG: #3247]
// keywords: redeclare in class modification
// status:   correct
//

model B
  model B2
  replaceable type P = Real;
  P p;
  end B2;
  B2 b2;
end B;

model RedeclareInClassModification
  extends B(B2(redeclare type P = Integer));
  B2.P p;
end RedeclareInClassModification;


// Result:
// class RedeclareInClassModification
//   Integer b2.p;
//   Integer p;
// end RedeclareInClassModification;
// endResult
