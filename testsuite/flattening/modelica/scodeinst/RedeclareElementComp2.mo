// name: RedeclareElementComp2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable Real x = 1.0;
end A;

model RedeclareElementComp2
  extends A;

  type MyReal = Real(start = 1.0);
  redeclare MyReal x = 2.0;
end RedeclareElementComp2;  

// Result:
// class RedeclareElementComp2
//   Real x(start = 1.0) = 2.0;
// end RedeclareElementComp2;
// endResult
