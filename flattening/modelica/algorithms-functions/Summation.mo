// name:     Summation
// keywords: algorithm, array
// status:   correct
//
// Drmodelica:
//

model Summation
  Real sum;
  Integer n;
  Real a[5] = {1, 3, 6, 9, 12};
algorithm
  sum := 0;
  n := size(a,1);
  while (n > 0) loop
    if (a[n] > 0) then
      sum := sum + a[n];
    end if;
    n := n - 1;
  end while;
end Summation;


// Result:
// class Summation
//   Real sum;
//   Integer n;
//   Real a[1];
//   Real a[2];
//   Real a[3];
//   Real a[4];
//   Real a[5];
// equation
//   a = {1.0, 3.0, 6.0, 9.0, 12.0};
// algorithm
//   sum := 0.0;
//   n := 5;
//   while n > 0 loop
//     if a[n] > 0.0 then
//       sum := sum + a[n];
//     end if;
//     n := -1 + n;
//   end while;
// end Summation;
// endResult
