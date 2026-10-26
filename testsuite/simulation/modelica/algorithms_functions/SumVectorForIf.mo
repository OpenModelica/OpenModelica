// name:     SumVectorForIf
// keywords: for statement, if statement
// status:   correct
//
// Drmodelica: 9.1  if-Statement (p. 292)
//
class SumVector
  Real sum;
  parameter Real v[5] = {100, 200, -300, 400, 500};
  parameter Integer n = size(v, 1);
algorithm
  sum := 0;
  for i in 1:n loop
    if v[i] > 0 then
      sum := sum + v[i];
    elseif v[i] > -1 then
      sum := sum + v[i] - 1;
    else
      sum := sum - v[i];
    end if;
  end for;
end SumVector;

// class SumVector
// Real sum;
// parameter Real v[1] = 100;
// parameter Real v[2] = 200;
// parameter Real v[3] = -300;
// parameter Real v[4] = 400;
// parameter Real v[5] = 500;
// parameter Integer n = 5;
// algorithm
//   sum := 0.0;
//   for i in 1:n loop
//     if v[i] > 0.0 then
//       sum := sum + v[i];
//     elseif v[i] > -1.0 then
//       sum := sum + v[i] - 1.0;
//     else
//       sum := sum - v[i];
//     end if;
//   end for;
// end SumVector;
