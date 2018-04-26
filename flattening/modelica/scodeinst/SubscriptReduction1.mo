// name: SubscriptReduction1
// status: correct
// cflags: -d=newInst
//
//

model SubscriptReduction1
  parameter String s1[:] = {String(i) for i in 1:3};
  parameter String s2[:, :] = {String(i + j) for i in 1:3, j in 1:2};
end SubscriptReduction1;

// Result:
// class SubscriptReduction1
//   parameter String s1[1] = String(1, 0, true);
//   parameter String s1[2] = String(2, 0, true);
//   parameter String s1[3] = String(3, 0, true);
//   parameter String s2[1,1] = String(1 + 1, 0, true);
//   parameter String s2[1,2] = String(2 + 1, 0, true);
//   parameter String s2[1,3] = String(3 + 1, 0, true);
//   parameter String s2[2,1] = String(1 + 2, 0, true);
//   parameter String s2[2,2] = String(2 + 2, 0, true);
//   parameter String s2[2,3] = String(3 + 2, 0, true);
// end SubscriptReduction1;
// endResult
