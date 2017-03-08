// name: ceval4.mo
// status: correct
// cflags: -d=newInst

model A
  parameter Boolean b1 = 0.1 < 0.0;
  parameter Boolean b2 = 0.1 <= 0.0;
  parameter Boolean b3 = 0.1 > 0.0;
  parameter Boolean b4 = 0.1 >= 0.0;

  parameter Boolean b5 = 1 < 0;
  parameter Boolean b6 = 1 <= 0;
  parameter Boolean b7 = 1 > 0;
  parameter Boolean b8 = 1 >= 0;
  parameter Boolean b9 = 1 == 0;
  parameter Boolean b10 = 1 <> 0;

  parameter Boolean b = b1 or b2 and not b3 or b4 and b5 and not b6 or b7 and not b8 and not b9 and b10;

  parameter Integer n = if b then 2 else 3;
  Real x[n] = {1.0, 2.0, 3.0};
end A;

// Result:
// class A
//   parameter Boolean b1 = 0.1 < 0.0;
//   parameter Boolean b2 = 0.1 <= 0.0;
//   parameter Boolean b3 = 0.1 > 0.0;
//   parameter Boolean b4 = 0.1 >= 0.0;
//   parameter Boolean b5 = 1 < 0;
//   parameter Boolean b6 = 1 <= 0;
//   parameter Boolean b7 = 1 > 0;
//   parameter Boolean b8 = 1 >= 0;
//   parameter Boolean b9 = 1 == 0;
//   parameter Boolean b10 = 1 <> 0;
//   parameter Boolean b = b1 or b2 and not b3 or b4 and b5 and not b6 or b7 and not b8 and not b9 and b10;
//   parameter Integer n = if b then 2 else 3;
//   Real x[1] = 1.0;
//   Real x[2] = 2.0;
//   Real x[3] = 3.0;
// end A;
// endResult
