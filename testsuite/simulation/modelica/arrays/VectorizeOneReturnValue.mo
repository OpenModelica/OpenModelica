// name:     VectorizeOneReturnValue
// keywords: Array
// status:   correct
//
//
// Drmodelica: 7.8  Applied to Arrays  element-wise (p. 229)
//
class OneReturnValue
  Real a = 1, b = 0, c = 1;

  Real s1[3] = sin({a, b, c});
                // Vector argument, result: {sin(a), sin(b), sin(c)}
  Real s2[2, 2] = sin([1, 2; 3, 4]);
                // Matrix argument, result: [sin(1), sin(2); sin(3), sin(4)]
end OneReturnValue;

// class OneReturnValue
// Real a;
// Real b;
// Real c;
// Real s1[1];
// Real s1[2];
// Real s1[3];
// Real s2[1,1];
// Real s2[1,2];
// Real s2[2,1];
// Real s2[2,2];
// equation
//   a = 1.0;
//   b = 0.0;
//   c = 1.0;
//   s1 = {sin(a),sin(b),sin(c)};
//   s2[1,1] = 0.841470984807897;
//   s2[1,2] = 0.909297426825682;
//   s2[2,1] = 0.141120008059867;
//   s2[2,2] = -0.756802495307928;
// end OneReturnValue;
