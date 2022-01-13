// name: RecordBinding9
// keywords:
// status: correct
// cflags: -d=newInst
//

record R_base
  constant Integer n;
  constant Real[n] d;
end R_base;

record R
  extends R_base(final n = 2, final d = {1, 2});
end R;

record A
  Real[c.n] x;
  parameter R_base c;
end A;

model RecordBinding9
  A a(c = R());
end RecordBinding9;

// Result:
// class RecordBinding9
//   Real a.x[1];
//   Real a.x[2];
//   constant Integer a.c.n = 2;
//   constant Real a.c.d[1] = 1.0;
//   constant Real a.c.d[2] = 2.0;
// end RecordBinding9;
// endResult
