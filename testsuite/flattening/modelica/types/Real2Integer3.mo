// name:     Real2Integer3
// keywords: type
// status:   correct
//
// No implicit conversion from Real to Integer. Division via 'div'
// gives integer output with integer input.
//

class Real2Integer3
  Integer n1, n2;
algorithm
  n1 := integer(6.6);
  n2 := div(n1,2);
end Real2Integer3;

// Result:
// class Real2Integer3
//   Integer n1;
//   Integer n2;
// algorithm
//   n1 := 6;
//   n2 := div(n1, 2);
// end Real2Integer3;
// [flattening/modelica/types/Real2Integer3.mo:10:3-10:17:writable] Warning: Components are deprecated in class.
// [flattening/modelica/types/Real2Integer3.mo:12:3-12:21:writable] Warning: Algorithm sections are deprecated in class.
//
// endResult
