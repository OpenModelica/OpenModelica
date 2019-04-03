// name: CevalDer2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalDer2
  constant Real r1[:,:] = der({{1, 2, 3}, {4, 5, 6}});
end CevalDer2;

// Result:
// class CevalDer2
//   constant Real r1[1,1] = 0.0;
//   constant Real r1[1,2] = 0.0;
//   constant Real r1[1,3] = 0.0;
//   constant Real r1[2,1] = 0.0;
//   constant Real r1[2,2] = 0.0;
//   constant Real r1[2,3] = 0.0;
// end CevalDer2;
// endResult
