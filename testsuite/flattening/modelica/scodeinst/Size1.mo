// name: Size1
// keywords: size
// status: correct
// cflags: -d=newInst
//
// Tests the builtin size operator.
//

model Size1
  Real x[3];
  Integer y = size(x, 1);
end Size1;

// Result:
// class Size1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Integer y = 3;
// end Size1;
// endResult
