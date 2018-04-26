// name: SubscriptCevalIndexRange1
// keywords:
// status: correct
// cflags: -d=newInst
//

model SubscriptCevalIndexRange1
  parameter String x[3] = {String(i) for i in 1:3};
end SubscriptCevalIndexRange1;

// Result:
// class SubscriptCevalIndexRange1
//   parameter String x[1] = String(1, 0, true);
//   parameter String x[2] = String(2, 0, true);
//   parameter String x[3] = String(3, 0, true);
// end SubscriptCevalIndexRange1;
// endResult
