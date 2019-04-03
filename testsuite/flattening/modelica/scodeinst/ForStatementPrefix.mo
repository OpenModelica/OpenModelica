// name: ForStatementPrefix.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that for loop iterators are not prefixed.
//

model A
  Real x[5];
algorithm
  for i in 1:5 loop
    x[i] := i;
  end for;
end A;

model ForStatementPrefix
  A a;
end ForStatementPrefix;

// Result:
// class ForStatementPrefix
//   Real a.x[1];
//   Real a.x[2];
//   Real a.x[3];
//   Real a.x[4];
//   Real a.x[5];
// algorithm
//   for i in 1:5 loop
//     a.x[i] := /*Real*/(i);
//   end for;
// end ForStatementPrefix;
// endResult
