// name: ForStatement3
// keywords:
// status: correct
//
//

model ForStatement3
  Real x[5];
algorithm
  for i in 2:2 loop
    x[i] := time;
  end for;
end ForStatement3;

// Result:
// class ForStatement3
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
// algorithm
//   for i in 2:2 loop
//     x[i] := time;
//   end for;
// end ForStatement3;
// endResult
