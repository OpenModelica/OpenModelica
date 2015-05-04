// name:     NestedSubscriptFor
// keywords: array subscripts for loop #3155
// status:   correct
//
// Checks that nested subscripts using a for loop iterator is handled correctly.
//

model NestedSubscriptFor
  Integer x[3];
  parameter Integer p[3] = {1, 2, 3};
algorithm
  for i in 1:3 loop
    x[p[i]] := i;
  end for;
end NestedSubscriptFor;

// Result:
// class NestedSubscriptFor
//   Integer x[1];
//   Integer x[2];
//   Integer x[3];
//   parameter Integer p[1] = 1;
//   parameter Integer p[2] = 2;
//   parameter Integer p[3] = 3;
// algorithm
//   for i in 1:3 loop
//     x[p[i]] := i;
//   end for;
// end NestedSubscriptFor;
// endResult
