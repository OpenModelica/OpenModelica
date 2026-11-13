// name: ForIf
// keywords: for if
// status: correct
//
// Tests an if expression that uses a for iterator as condition.
//

model ForIf
  Integer k[2];
  Integer index;
equation
  for i in 1:2 loop
    k[i] = if index == i then 1 else 0;
  end for;
end ForIf;

// Result:
// class ForIf
//   Integer k[1];
//   Integer k[2];
//   Integer index;
// equation
//   k[1] = if index == 1 then 1 else 0;
//   k[2] = if index == 2 then 1 else 0;
// end ForIf;
// endResult
