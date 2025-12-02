// name: CevalBinding7
// status: correct
//
//

model A
  parameter Real v;
equation
  if 0 < v then
  end if;
end A;

model B
  parameter Real m;
  A a(final v = m);
end B;

model C
  parameter Real q;
  parameter Real w = abs(q);
end C;

model CevalBinding7
  C[6] c(q = fill(10000, 6));
  B b(m = sum(c.w));
end CevalBinding7;

// Result:
// class CevalBinding7
//   final parameter Real c[1].q = 1e4;
//   final parameter Real c[1].w = 1e4;
//   final parameter Real c[2].q = 1e4;
//   final parameter Real c[2].w = 1e4;
//   final parameter Real c[3].q = 1e4;
//   final parameter Real c[3].w = 1e4;
//   final parameter Real c[4].q = 1e4;
//   final parameter Real c[4].w = 1e4;
//   final parameter Real c[5].q = 1e4;
//   final parameter Real c[5].w = 1e4;
//   final parameter Real c[6].q = 1e4;
//   final parameter Real c[6].w = 1e4;
//   final parameter Real b.m = 6e4;
//   final parameter Real b.a.v = 6e4;
// end CevalBinding7;
// endResult
