// name: Size2
// keywords: size
// status: correct
// cflags: -d=newInst
//
// Tests the builtin size operator.
//

model Size2
  Integer x = size({1, 2, 3}, 1);
end Size2;

// Result:
// class Size2
//   Integer x = 3;
// end Size2;
// endResult
