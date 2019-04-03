// name:     AppendElement
// keywords: array
// status:   correct
//
// //??Error - cat not yet implemented
// Drmodelica: 7.5 Array Concatenation and Slice Operations (p. 219)
//
class AppendElement
  Real[1, 3] PA=[1, 2, 3];
  // A row matrix value
  Real[3, 1] PB=[1; 2; 3];
  // A column matrix value
  Real[3] q={1,2,3};
  // A vector value

  Real[1, 4] XA1;
  Real[1, 4] XA2;
  Real[1, 4] XA3;
  Real[1, 4] XA4;
  // Row matrix variables
  Real[4, 1] XB1;
  Real[4, 1] XB2;
  // Column matrix variables
  Real[4] y;
equation
  // Vector variable

  XA1 = [PA, 4];
  // Append OK, since 4 is promoted to {{4}}
  XA2 = cat(2, PA, {{4}});
  // Append OK, same as above but not promoted

  XB1 = [PB; 4];
  // Append OK, result is {{1}, {2}, {3}, {4}}
  XB2 = cat(1, PB, {{2}});
  // Append OK, same result

  y = cat(1, q, {4});
  // Vector append OK, result is {1, 2, 3, 4}

  XA3 = [-1, zeros(1, 2), 1];
  // Append OK, result is {{-1, 0, 0, 1}}
  XA4 = cat(2, {{-1}}, zeros(1, 2), {{1}});
  // Append OK, result is {{-1, 0, 0, 1}}

end AppendElement;


// Result:
// class AppendElement
//   Real PA[1,1];
//   Real PA[1,2];
//   Real PA[1,3];
//   Real PB[1,1];
//   Real PB[2,1];
//   Real PB[3,1];
//   Real q[1];
//   Real q[2];
//   Real q[3];
//   Real XA1[1,1];
//   Real XA1[1,2];
//   Real XA1[1,3];
//   Real XA1[1,4];
//   Real XA2[1,1];
//   Real XA2[1,2];
//   Real XA2[1,3];
//   Real XA2[1,4];
//   Real XA3[1,1];
//   Real XA3[1,2];
//   Real XA3[1,3];
//   Real XA3[1,4];
//   Real XA4[1,1];
//   Real XA4[1,2];
//   Real XA4[1,3];
//   Real XA4[1,4];
//   Real XB1[1,1];
//   Real XB1[2,1];
//   Real XB1[3,1];
//   Real XB1[4,1];
//   Real XB2[1,1];
//   Real XB2[2,1];
//   Real XB2[3,1];
//   Real XB2[4,1];
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real y[4];
// equation
//   PA = {{1.0, 2.0, 3.0}};
//   PB = {{1.0}, {2.0}, {3.0}};
//   q = {1.0, 2.0, 3.0};
//   XA1[1,1] = PA[1,1];
//   XA1[1,2] = PA[1,2];
//   XA1[1,3] = PA[1,3];
//   XA1[1,4] = 4.0;
//   XA2[1,1] = PA[1,1];
//   XA2[1,2] = PA[1,2];
//   XA2[1,3] = PA[1,3];
//   XA2[1,4] = 4.0;
//   XB1[1,1] = PB[1,1];
//   XB1[2,1] = PB[2,1];
//   XB1[3,1] = PB[3,1];
//   XB1[4,1] = 4.0;
//   XB2[1,1] = PB[1,1];
//   XB2[2,1] = PB[2,1];
//   XB2[3,1] = PB[3,1];
//   XB2[4,1] = 2.0;
//   y[1] = q[1];
//   y[2] = q[2];
//   y[3] = q[3];
//   y[4] = 4.0;
//   XA3[1,1] = -1.0;
//   XA3[1,2] = 0.0;
//   XA3[1,3] = 0.0;
//   XA3[1,4] = 1.0;
//   XA4[1,1] = -1.0;
//   XA4[1,2] = 0.0;
//   XA4[1,3] = 0.0;
//   XA4[1,4] = 1.0;
// end AppendElement;
// endResult
