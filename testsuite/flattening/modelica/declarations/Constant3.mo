// name:     Constant3
// keywords: declaration,array
// status:   correct
//
// Basic constant definitions.
//

class Constant3
  constant Integer N = 3;
  Real x[N];
equation
  x[N-1] = 2.0;
  x[{1,N}] = {1,time};
end Constant3;

// Result:
// class Constant3
//   constant Integer N = 3;
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x[2] = 2.0;
//   x[1] = 1.0;
//   x[3] = time;
// end Constant3;
// [flattening/modelica/declarations/Constant3.mo:9:3-9:25:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/Constant3.mo:10:3-10:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/Constant3.mo:12:3-12:15:writable] Warning: Equation sections are deprecated in class.
//
// endResult
