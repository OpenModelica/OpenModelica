// name:     BoolArrayTest
// keywords: Arrays, bug #14
// status:   correct
//

model BoolArrayTest
  Boolean b[2]={a,time > 2};          // was bug here
  Boolean a;
  Boolean c;
equation
  a = time > 1;
  c = time > 2;
end BoolArrayTest;

// Result:
// class BoolArrayTest
//   Boolean b[1];
//   Boolean b[2];
//   Boolean a;
//   Boolean c;
// equation
//   b = {a, time > 2.0};
//   a = time > 1.0;
//   c = time > 2.0;
// end BoolArrayTest;
// endResult
