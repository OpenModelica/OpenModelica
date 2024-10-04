// name: EmptyArray3
// keywords:
// status: correct
//

model EmptyArray3
  Real x[0, 2];
  Real y = time;
  Real z;
algorithm
  for m in 1:1 loop
    z := if m == 1 then y else size(x, m - 1);
  end for;
end EmptyArray3;

// Result:
// class EmptyArray3
//   Real y = time;
//   Real z;
// algorithm
//   for m in 1:1 loop
//     z := if m == 1 then y else {0.0, 2.0}[m - 1];
//   end for;
// end EmptyArray3;
// endResult
