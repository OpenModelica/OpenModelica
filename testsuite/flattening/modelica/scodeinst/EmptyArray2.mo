// name: EmptyArray2
// keywords:
// status: correct
//

model EmptyArray2
  Real x[0];
  Real y = time;
  Real z;
algorithm
  for m in 1:1 loop
    z := if m == 1 then y else x[m - 1];
  end for;
end EmptyArray2;

// Result:
// class EmptyArray2
//   Real y = time;
//   Real z;
// algorithm
//   for m in 1:1 loop
//     z := if m == 1 then y else {}[m - 1];
//   end for;
// end EmptyArray2;
// endResult
