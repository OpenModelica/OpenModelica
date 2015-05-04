// name:     SubscriptsFill1
// keywords: array subscripts #2977
// status:   correct
//
// Tests that any missing subscripts are filled in with :.
//

model SubscriptsFill1
  Real x[2, 3] = {{1, 2, 3}, {4, 5, 6}};
  Real y[3] = x[1];
  Real z[3] = x[2];
end SubscriptsFill1;

// Result:
// class SubscriptsFill1
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real z[1];
//   Real z[2];
//   Real z[3];
// equation
//   x = {{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}};
//   y = {x[1,1], x[1,2], x[1,3]};
//   z = {x[2,1], x[2,2], x[2,3]};
// end SubscriptsFill1;
// endResult
