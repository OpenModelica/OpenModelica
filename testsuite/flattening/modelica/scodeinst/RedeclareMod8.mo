// name: RedeclareMod8
// keywords:
// status: correct
// cflags: -d=newInst
//

record A
  Real x = 0;
end A;

model PB
  replaceable parameter A a;
end PB;

model B
  extends PB;
end B;

model C
  replaceable parameter A[1] na;
  replaceable B[1] nb;
end C;

model RedeclareMod8
  C c(nb(redeclare A a = c.na));
end RedeclareMod8;

// Result:
// class RedeclareMod8
//   parameter Real c.na[1].x = 0.0;
//   parameter Real c.nb[1].a.x = c.na[1].x;
// end RedeclareMod8;
// endResult
