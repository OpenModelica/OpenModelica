// name:     ArrayEWOpsCEval3
// keywords: array
// status:   correct
//
// Array elementwise operators' constant eveluation: multiplication

class ArrayEWOpsCEval3
  Real[2] u1,u2,u3;
  Real t;
equation
u1={2,3}.*{4,5};
u2={2,3}.*5;
u3=2 .*{4,5};
t=2 .*4;
end ArrayEWOpsCEval3;

// Result:
// class ArrayEWOpsCEval3
//   Real u1[1];
//   Real u1[2];
//   Real u2[1];
//   Real u2[2];
//   Real u3[1];
//   Real u3[2];
//   Real t;
// equation
//   u1[1] = 8.0;
//   u1[2] = 15.0;
//   u2[1] = 10.0;
//   u2[2] = 15.0;
//   u3[1] = 8.0;
//   u3[2] = 10.0;
//   t = 8.0;
// end ArrayEWOpsCEval3;
// endResult
