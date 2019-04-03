// name: expconn4.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

expandable connector EC
  RealInput ri;
end EC;

connector RealInput = input Real;

model M
  EC ec;
  RealInput ri;
equation
  connect(ec.ri, ri);
end M;

// Result:
// class M
//   input Real ec.ri;
//   input Real ri;
// equation
//   ec.ri = ri;
// end M;
// endResult
