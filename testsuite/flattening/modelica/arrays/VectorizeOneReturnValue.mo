// name:     VectorizeOneReturnValue
// keywords: Array
// status:   correct
//

class OneReturnValue
  Real a = 1, b = 0, c = 1;

  Real s1[3] = sin({a, b, c});
                // Vector argument, result: {sin(a), sin(b), sin(c)}
  Real s2[2, 2] = sin([1, 2; 3, 4]);
                // Matrix argument, result: [sin(1), sin(2); sin(3), sin(4)]
end OneReturnValue;

// Result:
// class OneReturnValue
//   Real a = 1.0;
//   Real b = 0.0;
//   Real c = 1.0;
//   Real s1[1];
//   Real s1[2];
//   Real s1[3];
//   Real s2[1,1];
//   Real s2[1,2];
//   Real s2[2,1];
//   Real s2[2,2];
// equation
//   s1 = array(sin({a, b, c}[$i0]) for $i0 in 1:3);
//   s2 = array(array(sin({{1.0, 2.0}, {3.0, 4.0}}[$i1,$i2]) for $i2 in 1:2) for $i1 in 1:2);
// end OneReturnValue;
// [flattening/modelica/arrays/VectorizeOneReturnValue.mo:7:3-7:27:writable] Warning: Components are deprecated in class.
// [flattening/modelica/arrays/VectorizeOneReturnValue.mo:9:3-9:30:writable] Warning: Components are deprecated in class.
// [flattening/modelica/arrays/VectorizeOneReturnValue.mo:11:3-11:36:writable] Warning: Components are deprecated in class.
//
// endResult
