// name: CevalRecordReduction1
// keywords:
// status: correct
//

record R
  parameter Integer n;
end R;

model M
  parameter R r[2];
  Real x[sum({r[i].n for i in 1:2})];
end M;

model CevalRecordReduction1
  parameter R a[3] = {R(n = 1), R(n = 2), R(n = 3)};
  M m(r = {a[i] for i in 2:3});
end CevalRecordReduction1;

// Result:
// class CevalRecordReduction1
//   parameter Integer a[1].n = 1;
//   parameter Integer a[2].n = 2;
//   parameter Integer a[3].n = 3;
//   final parameter Integer m.r[1].n = 2;
//   final parameter Integer m.r[2].n = 3;
//   Real m.x[1];
//   Real m.x[2];
//   Real m.x[3];
//   Real m.x[4];
//   Real m.x[5];
// end CevalRecordReduction1;
// endResult
