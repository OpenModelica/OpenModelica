// name:     ArrayEWOpsCEval4
// keywords: array
// status:   correct
//
// Array elementwise operators' constant eveluation: division

class ArrayEWOpsCEval4
  Real[2] u1,u2,u3;
  Real t;
equation
u1={2,3}./{4,5};
u2={2,3}./5;
u3=2 ./{4,5};
t=2 ./4;
end ArrayEWOpsCEval4;

// Result:
// class ArrayEWOpsCEval4
//   Real u1[1];
//   Real u1[2];
//   Real u2[1];
//   Real u2[2];
//   Real u3[1];
//   Real u3[2];
//   Real t;
// equation
//   u1[1] = 0.5;
//   u1[2] = 0.6;
//   u2[1] = 0.4;
//   u2[2] = 0.6;
//   u3[1] = 0.5;
//   u3[2] = 0.4;
//   t = 0.5;
// end ArrayEWOpsCEval4;
// endResult
