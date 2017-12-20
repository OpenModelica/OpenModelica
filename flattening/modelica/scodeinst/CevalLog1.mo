// name: CevalLog1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalLog1
  constant Real r1 = log(100);
end CevalLog1;

// Result:
// class CevalLog1
//   constant Real r1 = 4.605170185988092;
// end CevalLog1;
// endResult
