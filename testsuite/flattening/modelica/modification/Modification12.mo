// name:     Modification12
// keywords: modification, attributes, arrays
// status:   correct
//
//

class Modification12
  Real x[:] (min = fill(1,size(x,1))) = {1.0};
end Modification12;

// Result:
// class Modification12
//   Real x[1](min = 1.0);
// equation
//   x = {1.0};
// end Modification12;
// endResult
