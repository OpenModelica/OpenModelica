// name: ForStatement1.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model ForStatement1
  Real x[5];
algorithm
  for i in 1:5 loop
    x[i] := i;
  end for;
end ForStatement1;

// Result:
// class ForStatement1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
// algorithm
//   for i in 1:5 loop
//     x[i] := /*Real*/(i);
//   end for;
// end ForStatement1;
// endResult
