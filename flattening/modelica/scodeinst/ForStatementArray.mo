// name: ForStatementArray.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model ForStatementArray
  Real x[5];
algorithm
  for i in {1, 2, 3, 4, 5} loop
    x[i] := i;
  end for;
end ForStatementArray;

// Result:
// class ForStatementArray
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
// algorithm
//   for i in {1, 2, 3, 4, 5} loop
//     x[i] := /*Real*/(i);
//   end for;
// end ForStatementArray;
// endResult
