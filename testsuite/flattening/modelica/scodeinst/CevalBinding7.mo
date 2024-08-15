// name: CevalBinding7
// status: correct
// cflags: -d=newInst
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
//   parameter Real c[1].q = 10000.0;
//   parameter Real c[1].w = abs(c[1].q);
//   parameter Real c[2].q = 10000.0;
//   parameter Real c[2].w = abs(c[2].q);
//   parameter Real c[3].q = 10000.0;
//   parameter Real c[3].w = abs(c[3].q);
//   parameter Real c[4].q = 10000.0;
//   parameter Real c[4].w = abs(c[4].q);
//   parameter Real c[5].q = 10000.0;
//   parameter Real c[5].w = abs(c[5].q);
//   parameter Real c[6].q = 10000.0;
//   parameter Real c[6].w = abs(c[6].q);
//   parameter Real b.m = c[1].w + c[2].w + c[3].w + c[4].w + c[5].w + c[6].w;
//   final parameter Real b.a.v = 60000.0;
// end CevalBinding7;
// endResult
