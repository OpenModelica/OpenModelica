// name:     UsertypeArrayMod
// keywords: modification array type
// status:   correct
//

model UsertypeArrayMod
  type T = Real[3, 2](start = {{1, 2}, {3, 4}, {5, 6}});
  T x[4, 1];
end UsertypeArrayMod;

// Result:
// class UsertypeArrayMod
//   Real x[1,1,1,1](start = 1.0);
//   Real x[1,1,1,2](start = 2.0);
//   Real x[1,1,2,1](start = 3.0);
//   Real x[1,1,2,2](start = 4.0);
//   Real x[1,1,3,1](start = 5.0);
//   Real x[1,1,3,2](start = 6.0);
//   Real x[2,1,1,1](start = 1.0);
//   Real x[2,1,1,2](start = 2.0);
//   Real x[2,1,2,1](start = 3.0);
//   Real x[2,1,2,2](start = 4.0);
//   Real x[2,1,3,1](start = 5.0);
//   Real x[2,1,3,2](start = 6.0);
//   Real x[3,1,1,1](start = 1.0);
//   Real x[3,1,1,2](start = 2.0);
//   Real x[3,1,2,1](start = 3.0);
//   Real x[3,1,2,2](start = 4.0);
//   Real x[3,1,3,1](start = 5.0);
//   Real x[3,1,3,2](start = 6.0);
//   Real x[4,1,1,1](start = 1.0);
//   Real x[4,1,1,2](start = 2.0);
//   Real x[4,1,2,1](start = 3.0);
//   Real x[4,1,2,2](start = 4.0);
//   Real x[4,1,3,1](start = 5.0);
//   Real x[4,1,3,2](start = 6.0);
// end UsertypeArrayMod;
// endResult
