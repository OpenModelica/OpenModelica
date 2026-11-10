// name:     AlgorithmForInClass
// keywords: algorithm, for, class
// status:   correct
//
// Tests for-loops in algorithm sections in classes.
//

model AlgorithmForInClass
  Real accum_sum[5];
  parameter Real N = 3;
  Real S[3];
  Real sum2[6];
  Real sum3[3, 3];
  parameter Real v1[3] = {3, 9, 4};
  parameter Real v2[3] = {2, 4, 1};
algorithm
  accum_sum[1] := 1;
  for i in 2:5 loop
    accum_sum[i] := accum_sum[i - 1] + i;
  end for;

  for i in 1:3 loop
    S[i] := v1[i] + v2[i];
  end for;

  sum2[1] := 3;
  for i in 1:3 loop
    for j in 1:3 loop
      sum2[i + j] := v1[i] + v2[j];
      sum3[i, j] := v2[i] + v1[j];
    end for;
  end for;
end AlgorithmForInClass;

// class AlgorithmForInClass
// Real accum_sum[1];
// Real accum_sum[2];
// Real accum_sum[3];
// Real accum_sum[4];
// Real accum_sum[5];
// parameter Real N = 3.0;
// Real S[1];
// Real S[2];
// Real S[3];
// Real sum2[1];
// Real sum2[2];
// Real sum2[3];
// Real sum2[4];
// Real sum2[5];
// Real sum2[6];
// Real sum3[1,1];
// Real sum3[1,2];
// Real sum3[1,3];
// Real sum3[2,1];
// Real sum3[2,2];
// Real sum3[2,3];
// Real sum3[3,1];
// Real sum3[3,2];
// Real sum3[3,3];
// parameter Real v1[1] = 3.0;
// parameter Real v1[2] = 9.0;
// parameter Real v1[3] = 4.0;
// parameter Real v2[1] = 2.0;
// parameter Real v2[2] = 4.0;
// parameter Real v2[3] = 1.0;
// algorithm
//   accum_sum[1] := 1.0;
//   for i in {2,3,4,5} loop
//     accum_sum[i] := accum_sum[i] + Real(i);
//   end for;
//   for i in {1,2,3} loop
//     S[i] := v1[i] + v2[i];
//   end for;
//   sum2[1] := 3.0;
//   for i in {1,2,3} loop
//     for j in {1,2,3} loop
//       sum2[i + j] := v1[i] + v2[j];
//       sum3[i, j] := v2[i] + v1[j];
//     end for;
//   end for;
// end AlgorithmForInClass;
