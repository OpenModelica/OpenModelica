// name:     Constant4
// keywords: declaration,array
// status:   correct
//
//
//

class Constant4
  Real x[2];
//  Real y[size(x,1)]; causes infinite loop
end Constant4;

// Result:
// class Constant4
//   Real x[1];
//   Real x[2];
// end Constant4;
// endResult
