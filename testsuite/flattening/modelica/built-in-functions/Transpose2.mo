// name:     Transpose2
// keywords: transpose flattening ceval
// status:   correct
//
// Tests fix for bug #1210: http://openmodelica.ida.liu.se:8080/cb/issue/1210
//

class bug1210
  constant Real i[2,2] = transpose({{1.1,2.2},{3.3,4.4}});
  Real r;
equation
  r = i[2,2];
end bug1210;

// Result:
// class bug1210
//   constant Real i[1,1] = 1.1;
//   constant Real i[1,2] = 3.3;
//   constant Real i[2,1] = 2.2;
//   constant Real i[2,2] = 4.4;
//   Real r;
// equation
//   r = 4.4;
// end bug1210;
// endResult
