// name:     Constant5
// keywords: declaration,array
// status:   correct
// cflags: -d=-newInst
//
//
//

class Constant5
  Real x[integer(2.5)];
end Constant5;

// Result:
// class Constant5
//   Real x[1];
//   Real x[2];
// end Constant5;
// endResult
