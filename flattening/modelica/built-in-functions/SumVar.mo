// name: SumVar
// keywords: sum bug1700
// status: correct
//
// Testing the built-in sum function on arrays with variable dimensions.
//

function mySum
  input Integer n;
  input Integer v[n];
  output Integer result;
algorithm
  result := sum(v);
end mySum;

model SumVar
  Integer i[3] = {1, 2, 3};
  Integer j;
equation
  j = mySum(3, i);
end SumVar;

// Result:
// function mySum
//   input Integer n;
//   input Integer[n] v;
//   output Integer result;
// algorithm
//   result := sum(v);
// end mySum;
//
// class SumVar
//   Integer i[1];
//   Integer i[2];
//   Integer i[3];
//   Integer j;
// equation
//   i = {1, 2, 3};
//   j = mySum(3, {i[1], i[2], i[3]});
// end SumVar;
// endResult
