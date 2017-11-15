// name: ForConnect1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

connector C
  Real e;
  flow Real f;
end C;

model ForConnect1
  C c1[3], c2[3];
equation
  for i in 1:3 loop
    connect(c1[i], c2[i]);
  end for;
end ForConnect1;

// Result:
// class ForConnect1
//   Real c1[1].e;
//   Real c1[1].f;
//   Real c1[2].e;
//   Real c1[2].f;
//   Real c1[3].e;
//   Real c1[3].f;
//   Real c2[1].e;
//   Real c2[1].f;
//   Real c2[2].e;
//   Real c2[2].f;
//   Real c2[3].e;
//   Real c2[3].f;
// equation
//   c1[1].e = c2[1].e;
//   (-c1[1].f) + (-c2[1].f) = 0.0;
//   c1[2].e = c2[2].e;
//   (-c1[2].f) + (-c2[2].f) = 0.0;
//   c1[3].e = c2[3].e;
//   (-c1[3].f) + (-c2[3].f) = 0.0;
//   c1[1].f = 0.0;
//   c1[2].f = 0.0;
//   c1[3].f = 0.0;
//   c2[1].f = 0.0;
//   c2[2].f = 0.0;
//   c2[3].f = 0.0;
// end ForConnect1;
// endResult
