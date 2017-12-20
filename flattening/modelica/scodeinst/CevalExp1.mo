// name: CevalExp1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalExp1
  constant Real r1 = exp(3.4);
end CevalExp1;

// Result:
// class CevalExp1
//   constant Real r1 = 29.96410004739701;
// end CevalExp1;
// endResult
