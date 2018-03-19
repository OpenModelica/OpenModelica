// name: RedeclareElementComp5
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable parameter Real x = 1.0;
end A;

model RedeclareElementComp5
  extends A;
  redeclare Real x = 3.0;
end RedeclareElementComp5;

// Result:
// class RedeclareElementComp5
//   parameter Real x = 3.0;
// end RedeclareElementComp5;
// endResult
