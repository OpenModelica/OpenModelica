// name:     ArrayEWOpsCEval5
// keywords: array
// status:   correct
//
// Array elementwise operators' constant eveluation: power

class ArrayEWOpsCEval5
  Real[2] u1,u2,u3;
  Real t;
equation
u1={2,3}.^{4,5};
u2={2,3}.^5;
u3=2 .^{4,5};
t=2 .^4;
end ArrayEWOpsCEval5;

// Result:
// class ArrayEWOpsCEval5
//   Real u1[1];
//   Real u1[2];
//   Real u2[1];
//   Real u2[2];
//   Real u3[1];
//   Real u3[2];
//   Real t;
// equation
//   u1[1] = 16.0;
//   u1[2] = 243.0;
//   u2[1] = 32.0;
//   u2[2] = 243.0;
//   u3[1] = 16.0;
//   u3[2] = 32.0;
//   t = 16.0;
// end ArrayEWOpsCEval5;
// [flattening/modelica/arrays/ArrayEWOpsCEval5.mo:8:3-8:19:writable] Warning: Components are deprecated in class.
// [flattening/modelica/arrays/ArrayEWOpsCEval5.mo:9:3-9:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/arrays/ArrayEWOpsCEval5.mo:11:1-11:16:writable] Warning: Equation sections are deprecated in class.
//
// endResult
