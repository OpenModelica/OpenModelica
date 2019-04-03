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
//   parameter String x[1] = "1";
//   parameter String x[2] = "2";
//   parameter String x[3] = "3";
// end SubscriptCevalIndexRange1;
// endResult
