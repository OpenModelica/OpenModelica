// name: Size4
// keywords: size
// status: correct
// cflags: -d=newInst
//
// Tests the builtin size operator.
//

model Size4
  Real x[3];
  constant Integer n = size(x, 1); 
end Size4;


// Result:
// class Size4
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   constant Integer n = 3;
// end Size4;
// endResult
