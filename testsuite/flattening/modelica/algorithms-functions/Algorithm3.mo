// name:     Algorithm3
// keywords: algorithm
// status:   correct
//
// Type checks in algorithms.
//

class Algorithm3
  Integer i=integer(time*10);
  Real x;
algorithm
  x := i;
end Algorithm3;

// Result:
// class Algorithm3
//   Integer i = integer(time * 10.0);
//   Real x;
// algorithm
//   x := /*Real*/(i);
// end Algorithm3;
// [flattening/modelica/algorithms-functions/Algorithm3.mo:9:3-9:29:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/Algorithm3.mo:10:3-10:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/Algorithm3.mo:12:3-12:9:writable] Warning: Algorithm sections are deprecated in class.
//
// endResult
