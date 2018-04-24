// name: SubscriptReduction1
// status: correct
// cflags: -d=newInst
//
//

model SubscriptReduction1
  parameter String s[:] = {String(i) for i in 1:3};
end SubscriptReduction1;

// Result:
// class SubscriptReduction1
//   parameter String s[1] = String(1, 0, true);
//   parameter String s[2] = String(2, 0, true);
//   parameter String s[3] = String(3, 0, true);
// end SubscriptReduction1;
// endResult
