// name:     Discrete2
// keywords: declaration,unknown
// status:   erroneous
//
// This is not valid, but should it complain now or later?

class Discrete2
  discrete Real x;
equation
  x = sin(time);
end Discrete2;

// Result:
// class Discrete2
//   discrete Real x;
// equation
//   x = sin(time);
// end Discrete2;
// endResult
