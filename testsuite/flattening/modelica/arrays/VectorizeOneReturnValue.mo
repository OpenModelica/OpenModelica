// name:     VectorizeOneReturnValue
// keywords: Array
// status:   correct
//

model OneReturnValue
  Real a = 1, b = 0, c = 1;

  Real s1[3] = sin({a, b, c});
                // Vector argument, result: {sin(a), sin(b), sin(c)}
  constant Real s2[2, 2] = sin([1, 2; 3, 4]);
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
//   constant Real s2[1,1] = 0.8414709848078965;
//   constant Real s2[1,2] = 0.9092974268256817;
//   constant Real s2[2,1] = 0.1411200080598672;
//   constant Real s2[2,2] = -0.7568024953079282;
// equation
//   s1 = array(sin({a, b, c}[$i0]) for $i0 in 1:3);
// end OneReturnValue;
// endResult
