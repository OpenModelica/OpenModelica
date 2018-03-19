// name: RedeclareElementComp3
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable Real x = 1.0;
end A;

model B
  extends A;
  redeclare parameter Real x = 2.0;
end B;  

model RedeclareElementComp3
  extends B(x = 3.0);
end RedeclareElementComp3;

// Result:
// class RedeclareElementComp3
//   parameter Real x = 3.0;
// end RedeclareElementComp3;
// endResult
