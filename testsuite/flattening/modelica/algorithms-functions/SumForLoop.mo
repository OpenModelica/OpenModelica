// name:     SumForLoop
// keywords: for statment
// status:   correct
//
// for statment handling
//
// Drmodelica: 9.1 for-Statement (p.288)
//
model SumZ
  parameter Integer n = 5;
  parameter Real[n] z = {10, 20, 30, 40, 50};
  Real sum(start = 0);
algorithm
  sum := 0;
  for i in 1:n loop
    sum := sum + z[i];
  end for;
end SumZ;

// Result:
// class SumZ
//   parameter Integer n = 5;
//   parameter Real z[1] = 10.0;
//   parameter Real z[2] = 20.0;
//   parameter Real z[3] = 30.0;
//   parameter Real z[4] = 40.0;
//   parameter Real z[5] = 50.0;
//   Real sum(start = 0.0);
// algorithm
//   sum := 0.0;
//   for i in 1:n loop
//     sum := sum + z[i];
//   end for;
// end SumZ;
// endResult
