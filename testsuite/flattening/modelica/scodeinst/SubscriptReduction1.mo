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
//   parameter String s1[1] = "1";
//   parameter String s1[2] = "2";
//   parameter String s1[3] = "3";
//   parameter String s2[1,1] = "2";
//   parameter String s2[1,2] = "3";
//   parameter String s2[1,3] = "4";
//   parameter String s2[2,1] = "3";
//   parameter String s2[2,2] = "4";
//   parameter String s2[2,3] = "5";
// end SubscriptReduction1;
// endResult
