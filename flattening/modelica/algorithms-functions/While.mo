// name: While
// keywords: while
// status: correct
//
// Tests a simple while-loop
//

model While
  Integer x;
  Integer y;
algorithm
  x := 2;
  while y < x loop
    y := y + 1;
  end while;
end While;

// Result:
// class While
//   Integer x;
//   Integer y;
// algorithm
//   x := 2;
//   while y < x loop
//     y := 1 + y;
//   end while;
// end While;
// endResult
