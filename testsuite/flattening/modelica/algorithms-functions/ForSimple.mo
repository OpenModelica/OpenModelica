// name: ForSimple
// keywords: for
// status: correct
//
// Tests a simple for statement
//

model ForSimple
  Real rarr[4];
algorithm
  for i in 1:4 loop
    rarr[i] := i + 1.0;
  end for;
end ForSimple;

// Result:
// class ForSimple
//   Real rarr[1];
//   Real rarr[2];
//   Real rarr[3];
//   Real rarr[4];
// algorithm
//   for i in 1:4 loop
//     rarr[i] := 1.0 + /*Real*/(i);
//   end for;
// end ForSimple;
// endResult
