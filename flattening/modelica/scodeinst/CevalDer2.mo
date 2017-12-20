// name: CevalDer2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalDer2
  constant Real r1[:] = der({{1, 2, 3}, {4, 5, 6}});
end CevalDer2;

// Result:
// class CevalDer2
//   constant Real r1 = {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}};
// end CevalDer2;
// endResult
