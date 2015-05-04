// name:     ArrayEWOpsCEval2
// keywords: array
// status:   correct
//
// Array elementwise operators' constant eveluation: addition

class ArrayEWOpsCEval2
  Real[2] u1,u2,u3;
  Real t;
equation
u1={2,3}.-{4,5};
u2={2,3}.-5;
u3=2 .-{4,5};
t=2 .-4;
end ArrayEWOpsCEval2;

// Result:
// class ArrayEWOpsCEval2
//   Real u1[1];
//   Real u1[2];
//   Real u2[1];
//   Real u2[2];
//   Real u3[1];
//   Real u3[2];
//   Real t;
// equation
//   u1[1] = -2.0;
//   u1[2] = -2.0;
//   u2[1] = -3.0;
//   u2[2] = -2.0;
//   u3[1] = -2.0;
//   u3[2] = -3.0;
//   t = -2.0;
// end ArrayEWOpsCEval2;
// endResult
