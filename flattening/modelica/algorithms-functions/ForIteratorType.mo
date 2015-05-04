// name:     ForIteratorType
// keywords: for iterator type integer enumeration
// status:   correct
//
// Checks that the iterator in a for loop gets the correct type.
//

model ForIteratorType
  type E = enumeration(one, two, three);
  Integer ints[size(E, 1)];
algorithm
  for e in E loop
    ints[Integer(e)] := Integer(e);
  end for;

  for i in 1:3 loop
    ints[i] := i;
  end for;
end ForIteratorType;

// Result:
// class ForIteratorType
//   Integer ints[1];
//   Integer ints[2];
//   Integer ints[3];
// algorithm
//   for e in {ForIteratorType.E.one, ForIteratorType.E.two, ForIteratorType.E.three} loop
//     ints[Integer(e)] := Integer(e);
//   end for;
//   for i in 1:3 loop
//     ints[i] := i;
//   end for;
// end ForIteratorType;
// endResult
