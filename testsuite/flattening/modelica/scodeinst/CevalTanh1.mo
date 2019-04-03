// name: CevalTanh1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalTanh1
  constant Real r1 = tanh(1);
end CevalTanh1;

// Result:
// class CevalTanh1
//   constant Real r1 = 0.7615941559557649;
// end CevalTanh1;
// endResult
