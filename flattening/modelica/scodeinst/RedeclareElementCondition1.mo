// name: RedeclareElementCondition1
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable Real x = 1.0 if false;
end A;

model RedeclareElementCondition1
  extends A;

  redeclare Real x = 2.0;
end RedeclareElementCondition1;

// Result:
// class RedeclareElementCondition1
// end RedeclareElementCondition1;
// endResult
