// name: CevalLinspace1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalLinspace1
  constant Real x[:] = linspace(1, 10, 5);
end CevalLinspace1;

// Result:
// class CevalLinspace1
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 3.25;
//   constant Real x[3] = 5.5;
//   constant Real x[4] = 7.75;
//   constant Real x[5] = 10.0;
// end CevalLinspace1;
// endResult
