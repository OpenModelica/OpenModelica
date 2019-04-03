// name:     SubScript1
// keywords: SubScript,unknown
// status:   correct
//
// checks if subscripts are correct when containing an expression with a parameter
//

model SubScript1
 parameter Integer tmp  = 2;
 Real arraySubs[3*tmp];
equation
end SubScript1;


// Result:
// class SubScript1
//   parameter Integer tmp = 2;
//   Real arraySubs[1];
//   Real arraySubs[2];
//   Real arraySubs[3];
//   Real arraySubs[4];
//   Real arraySubs[5];
//   Real arraySubs[6];
// end SubScript1;
// endResult
