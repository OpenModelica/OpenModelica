// name: CevalSinh1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalSinh1
  constant Real r1 = sinh(1);
end CevalSinh1;

// Result:
// class CevalSinh1
//   constant Real r1 = 1.175201193643801;
// end CevalSinh1;
// endResult
