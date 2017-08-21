// name: RedeclareElementComp1.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable Real x = 1.0;
end A;

model RedeclareElementComp1
  extends A;

  redeclare Real x = 2.0;
end RedeclareElementComp1;  

// Result:
// class B
//   Real m.y;
// end B;
// endResult
