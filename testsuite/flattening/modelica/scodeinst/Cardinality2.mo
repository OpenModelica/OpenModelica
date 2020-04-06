// name: Cardinality2
// keywords: cardinality
// status: correct
// cflags: -d=newInst
//
// Tests the builtin cardinality operator.
//

connector Pin
  Real v;
  flow Real i;
end Pin;

model Resistor
  Pin p;
  Pin n;
  Pin q;
  Integer n_conn;
equation
  connect(p, q);

  if cardinality(p) == 1 then
    n_conn = 1;
  elseif cardinality(p) == 2 then
    n_conn = 2;
  else
    n_conn = 0;
  end if;
end Resistor;

model Cardinality2
  Pin p;
  Resistor R1, R2;
equation
  connect(R1.p, p);
end Cardinality2;

// Result:
// class Cardinality2
//   Real p.v;
//   Real p.i;
//   Real R1.p.v;
//   Real R1.p.i;
//   Real R1.n.v;
//   Real R1.n.i;
//   Real R1.q.v;
//   Real R1.q.i;
//   Integer R1.n_conn;
//   Real R2.p.v;
//   Real R2.p.i;
//   Real R2.n.v;
//   Real R2.n.i;
//   Real R2.q.v;
//   Real R2.q.i;
//   Integer R2.n_conn;
// equation
//   R1.p.v = R1.q.v;
//   (-R1.p.i) - R1.q.i = 0.0;
//   R2.p.v = R2.q.v;
//   (-R2.p.i) - R2.q.i = 0.0;
//   R1.p.v = p.v;
//   p.i = 0.0;
//   R1.p.i - p.i = 0.0;
//   R1.n.i = 0.0;
//   R1.q.i = 0.0;
//   R2.p.i = 0.0;
//   R2.n.i = 0.0;
//   R2.q.i = 0.0;
//   R1.n_conn = 2;
//   R2.n_conn = 1;
// end Cardinality2;
// endResult
