// name: RedeclareElementCondition3
// keywords:
// status: correct
// cflags: -d=newInst
//

package P
  constant Boolean b = false;

  model A
    replaceable Real x = 1.0 if b;
  end A;
end P;

model RedeclareElementCondition3
  extends P.A;

  redeclare Real x = 2.0;
end RedeclareElementCondition3;

// Result:
// class RedeclareElementCondition3
// end RedeclareElementCondition3;
// endResult
